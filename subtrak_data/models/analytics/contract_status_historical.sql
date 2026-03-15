{{ config(materialized='table') }}


with contracts as 
(
    select * from {{ ref('stg_contracts') }}
),

deals as 
(
    select * from {{ ref('stg_deals') }}
),

billing_cycles as 
(
    select * from {{ ref('fct_billing_cycle') }}
),

-- Generate all month-end dates
month_ends as (
    select 
        (generate_series(
            date_trunc('month', min(start_date))::date,
            date_trunc('month', max(start_date))::date,
            interval '1 month'
        )::date + interval '1 month - 1 day')::date as snapshot_date
    from contracts
),

-- Calculate metrics for each snapshot_date
contract_metrics as 
(
    select 
        me.snapshot_date,  
        bc.contract_id,
        
        count(case when bc.contract_start_date <= me.snapshot_date then bc.contract_id end) as total_billing_cycles,
        count(case when bc.contract_start_date <= me.snapshot_date and bc.payment_date is not null and bc.payment_date <= me.snapshot_date then bc.contract_id end) as cycles_paid,
        count(case when bc.contract_start_date <= me.snapshot_date and (bc.payment_date is null or bc.payment_date > me.snapshot_date) then bc.contract_id end) as cycles_unpaid,
        
        min(bc.cost_price) cost_price,
        
        max(case when bc.contract_start_date <= me.snapshot_date and bc.payment_date is not null and bc.payment_date <= me.snapshot_date then bc.total_paid end) as total_amount_paid,
        sum(case when bc.contract_start_date <= me.snapshot_date and (bc.payment_date is null or bc.payment_date > me.snapshot_date) then bc.expected_amount end) as total_amount_outstanding,
        
        sum(case when bc.contract_start_date <= me.snapshot_date and (bc.payment_date <= me.snapshot_date and bc.payment_timing = 'on-time') then 1 else 0 end) as ontime_payments,
        sum(case when bc.contract_start_date <= me.snapshot_date and (bc.payment_date <= me.snapshot_date and bc.payment_timing in ('grace_period', 'late')) then 1 else 0 end) as late_payments,
        
        min(case when bc.contract_start_date <= me.snapshot_date and bc.payment_date <= me.snapshot_date then bc.due_date end) as last_due_date,
        max(case when bc.contract_start_date <= me.snapshot_date and bc.payment_date <= me.snapshot_date then bc.payment_date end) as last_payment_date,
        min(case when bc.contract_start_date <= me.snapshot_date and (bc.payment_date is null or bc.payment_date > me.snapshot_date) then bc.due_date end) as next_due_date,
        
        -- Calculate days overdue as of snapshot_date
        me.snapshot_date - (min(case when bc.payment_date is null or bc.payment_date > me.snapshot_date then bc.due_date end)) as days_overdue	
        
    from month_ends me 
    cross join billing_cycles bc
    where bc.contract_start_date <= me.snapshot_date  -- Only contracts that existed at snapshot
    group by me.snapshot_date, bc.contract_id
),
contract_status as 
(
select
    cm.snapshot_date,
    to_char(cm.snapshot_date, 'YYYY-MM') as snapshot_month_key,  -- Added: useful for grouping
    c.contract_id,
    c.customer_id,
    c.deal_id,
    c.sales_rep_id,
    c.start_date as contract_start_date,
    (c.start_date + (d.deal_duration * interval '30 days'))::date as contract_end_date,
    d.plan,
    cm.total_billing_cycles,
    cm.cycles_paid,
    cm.cycles_unpaid,
    cm.total_amount_paid,
    cm.total_amount_outstanding,
    cm.ontime_payments,
    cm.late_payments,
    cm.last_due_date,
    cm.last_payment_date,
    cm.next_due_date,
    coalesce(cm.days_overdue, 0) as days_overdue,
    
    -- System status uses snapshot_date instead of current_date
    case
        when cm.total_billing_cycles = cm.cycles_paid or c.deal_id = 1 then 'completed'
        when cm.snapshot_date < cm.next_due_date then 'enabled'
        when cm.snapshot_date >= cm.next_due_date then 'locked'
        else 'unknown'
    end as system_status,
    
    -- Contract status uses snapshot_date for "as of" logic
    case
        when cm.days_overdue >= 90 then 'lost'
        when c.deal_id = 1 then 'owner'
        when cm.total_billing_cycles = cm.cycles_paid and cm.snapshot_date >= c.start_date + (d.deal_duration * interval '30 days') then 'owner'
        when cm.total_billing_cycles = cm.cycles_paid and cm.snapshot_date < c.start_date + (d.deal_duration * interval '30 days') then 'active'
        else 'active'
    end as contract_status,

	case 
		when coalesce(days_overdue, 0) >= 61 then 'high_risk'
		when coalesce(days_overdue, 0) >= 30 then 'medium_risk'
		when coalesce(days_overdue, 0) >= 6 then 'low_risk'
		else 'good_standing'
	end as risk_category
    
from contracts c
join deals d on c.deal_id = d.deal_id
join contract_metrics cm on c.contract_id = cm.contract_id
order by cm.snapshot_date desc, c.contract_id
)
select
    {{ dbt_utils.generate_surrogate_key(['contract_id', 'snapshot_date']) }} as historical_status_key,
    *
from contract_status
