{{ config(materialized='table') }}

with date_log as 
(select contract_id, start_date, min(payment_date) as payment_date, paid_months from
(
select p.contract_id, c.start_date, payment_date, 
		sum(amount) over (partition by contract_id order by payment_date) as total_paid,
		floor((((sum(amount) over (partition by contract_id order by payment_date)) - setup_amount)+monthly_payment)/monthly_payment) as paid_months
from {{ ref ("stg_payments")}} p
join {{ref ("stg_deals")}} d using (deal_id)
join {{ref ("stg_contracts")}} c using (contract_id)
where p.deal_id = 2) a
group by 1,2,4
),

paid_base as 
(
select p.contract_id, payment_date, 
		sum(amount) over (partition by contract_id order by payment_date) as total_paid, monthly_payment,
		((payment_date::date - start_date::date)::numeric/30) +1 as expected_paid_months,
(((date_trunc('month', payment_date) + INTERVAL '1 month - 1 day')::date - start_date::date)::numeric / 30) + 1 AS expp2

from {{ref ("stg_payments")}} p
join {{ref ("stg_deals")}} d using (deal_id)
join {{ref ("stg_contracts")}} c using (contract_id)
where c.deal_id = 2
),

payment_cycle as 
(
select dl.*, pb.total_paid, total_paid - LAG(total_paid, 1, 0) OVER (
        PARTITION BY dl.contract_id
        ORDER BY dl.payment_date
    ) AS actual_paid_amount,
	pb.monthly_payment,
paid_months - LAG(paid_months, 1, 0) OVER (
        PARTITION BY dl.contract_id
        ORDER BY dl.payment_date
    ) AS paid_diff
	
from date_log dl
join paid_base pb
on dl.contract_id = pb.contract_id
and dl.payment_date = pb.payment_date
)

select
contract_id, start_date, payment_date,paid_months, total_paid, paid_diff,
row_number() over(partition by contract_id order by payment_date) as payment_rank
from payment_cycle
join generate_series(1, paid_diff) as n on TRUE


