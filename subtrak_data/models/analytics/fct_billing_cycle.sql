{{
    config(
        materialized='table',
        schema='analytics'
    )
}}


with contracts as 
(
    select * from {{ ref('stg_contracts') }}
),
deals as 
(
    select * from {{ ref('stg_deals') }}
),
payments as 
(
    select * from {{ ref('payment_log') }}
),

-------this generates the billing cycle for each contract-----
billing_schedule as 
(
    select
    c.contract_id,
    c.customer_id,
    c.sales_rep_id,
    c.deal_id,
    c.start_date as contract_start_date,
    c.start_date + (d.deal_duration * interval '30 days') as contract_end_date,
    d.plan,
    d.deal_duration,
    d.cost_price,
    d.monthly_payment as repayment_amount,

    gs.cycle_number,

    (c.start_date + (gs.cycle_number - 1) * interval '30 days')::date as due_date,

    case
        when gs.cycle_number = 1
        then d.setup_amount
        else d.monthly_payment
    end as expected_amount

from contracts c
join deals d using(deal_id)
cross join generate_series(1, d.deal_duration) as gs(cycle_number)
where d.deal_duration > 0
         
),

billings_with_payments as 
(
    select
        bs.*,
        payment_date,
        paid_months,
        total_paid,
        paid_diff as paid_for,
        paid_diff * repayment_amount as amount_paid,
        payment_rank as payment_cycle

    from billing_schedule as bs
    left join payments as p
    on bs.contract_id = p.contract_id
    and bs.cycle_number = p.payment_rank
),

timing_analysis as 
(
    select
        *,
        (payment_date - due_date) as days_from_due_date,

        --payment timing. will be used for repayment incentives--
        case
            when payment_date <= due_date then 'on-time'
            when payment_date <= due_date + interval '5 days' then 'grace_period'
            else 'late'
        end as payment_timing
    from billings_with_payments
)
select * from timing_analysis