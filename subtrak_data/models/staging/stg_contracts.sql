select
    id as contract_id,
    customer_id,
    rep_id as sales_rep_id,
    deal_id,
    contract_start as start_date,
    system_id,
    contract_status
from {{ source('subtrak_oltp', 'contracts') }}