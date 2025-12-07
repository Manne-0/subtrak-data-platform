{{ config(materialized='table') }}


with recursive billing_cycle as (
select contract_id, start_date,
		start_date::date as billing_date,
		1 as billing_no,
		d.deal_duration
from {{ ref("stg_contracts")}} as c
-- staging.stg_contracts c
join staging.stg_deals d using (deal_id)
where c.deal_id = 2

union all

select contract_id, start_date,
		(billing_date + interval '30 days')::date,
		billing_no + 1,
		deal_duration
from billing_cycle
WHERE billing_no < deal_duration
)

select * from billing_cycle