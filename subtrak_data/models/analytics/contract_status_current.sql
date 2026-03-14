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

contract_metrics as 
(
	select 
	
		contract_id,
		
		count(*) as total_billing_cycles,
		count(case when payment_date is not null then contract_id end) as cycles_paid,
		count(case when payment_date is null then contract_id end) as cycles_unpaid,
	
		min(cost_price) cost_price,
		max(case when payment_date is not null then total_paid end) as total_amount_paid,
		sum(case when payment_date is null then expected_amount end) as total_amount_outstanding,
	
	
		sum(case when payment_timing = 'on-time' then 1 else 0 end) as ontime_payments,
		sum(case when payment_timing in ('grace_period', 'late') then 1 else 0 end) as late_payments,
	
	
		max(case when payment_date is not null then due_date end)::date as last_due_date,
		max(case when payment_date is not null then payment_date end) as last_payment_date,
		min(case when payment_date is null then due_date end)::date as next_due_date,
	
		current_date - (min(case when payment_date is null then due_date end)) as days_overdue
	
		
		
		
	from billing_cycles
	group by contract_id
),

contract_status as 
(
	select
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
		coalesce(cm.days_overdue,0) as days_overdue,

		case
			when cm.total_billing_cycles = cm.cycles_paid or c.deal_id = 1 then 'completed'
			when current_date < cm.next_due_date then 'enabled'
			when current_date >= cm.next_due_date then 'locked'
			else 'unknown'
		end as system_status,

		case
			when cm.days_overdue >= 90 then 'lost'
			when c.deal_id = 1 then 'owner'
			when cm.total_billing_cycles = cm.cycles_paid and current_date >= c.start_date + (d.deal_duration * interval '30 days') then 'owner'
			when cm.total_billing_cycles = cm.cycles_paid and current_date < c.start_date + (d.deal_duration * interval '30 days') then 'active'
			else 'active'
		end as contract_status

	from contracts c
	join deals d on c.deal_id = d.deal_id
	left join contract_metrics cm on c.contract_id = cm.contract_id
		
)
select 
    * 
from contract_status

