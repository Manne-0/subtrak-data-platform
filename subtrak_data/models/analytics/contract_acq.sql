{{ config(materialized='table') }}



with base as (
    select
        c.contract_id,
        c.sales_rep_id,
		r.sales_rep_fullname,
        r.region_id,
		c.start_date as acquisition_month,
        c.customer_id,

        d.deal_id,
        d.plan,
        d.cost_price,
		d.setup_amount,
		d.monthly_payment,
		d.deal_duration,

        case 
            when d.deal_id = 1 then 0.05
            when d.deal_id = 2 then 0.175
        end as commission_rate,

        round(
        case 
            when d.deal_id = 1 then cost_price * 0.05
            when d.deal_id = 2 then setup_amount * 0.175
        end) as commission_amount
    from {{ ref ('stg_contracts') }} c
    join {{ ref ('stg_deals')}} d using (deal_id)
    join {{ ref ('stg_reps')}} r using (sales_rep_id)
)

select *
from base