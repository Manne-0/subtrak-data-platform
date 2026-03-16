{{
    config(
        materialized='table'
    )
}}


with contracts as (
    select * from {{ ref('stg_contracts') }}
),

customers as (
    select * from {{ ref('stg_customers') }}
),

reps as (
    select * from {{ ref('stg_reps') }}
),

regions as (
    select * from {{ ref('stg_regions') }}
),

deals as (
    select * from {{ ref('stg_deals') }}
)

select
    c.contract_id,
    c.start_date as contract_start_date,
    c.system_id,
    
    -- Customer attributes
    cust.customer_id,
    cust.customer_fullname,
    cust.email as customer_email,
    cust.phone_number as customer_phone,
    cust.gender as customer_gender,
    cust.signup_date as customer_signup_date,
    
    -- Rep attributes
    r.sales_rep_id,
    r.sales_rep_fullname,
    r.gender as rep_gender,
    r.entry_date as rep_date_joined,
    r.exit_date as rep_date_left,
    
    -- Region attributes
    reg.region_id,
    reg.region_name,
    
    -- Deal attributes
    d.deal_id,
    d.plan,
    d.cost_price,
    d.deal_duration,
    d.monthly_payment,
    d.warranty_duration,
    
    date_part('year', c.start_date) as contract_start_year,
    date_part('quarter', c.start_date) as contract_start_quarter,
    date_part('month', c.start_date) as contract_start_month,
    to_char(c.start_date, 'YYYY-MM') as contract_start_month_key
    
    
from contracts c
left join customers cust on c.customer_id = cust.customer_id
left join reps r on c.sales_rep_id = r.sales_rep_id
left join regions reg on cust.region_id = reg.region_id
left join deals d on c.deal_id = d.deal_id