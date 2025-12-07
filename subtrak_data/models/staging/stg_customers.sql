
select
    id as customer_id,
    initcap(concat(first_name, ' ', last_name)) as customers_fullname,
    email,
    phone_number,
    gender,
    region_id,
    rep_id as sales_rep_id,
    signup_date,
    created_at
from {{ source('subtrak_oltp', 'customers') }}