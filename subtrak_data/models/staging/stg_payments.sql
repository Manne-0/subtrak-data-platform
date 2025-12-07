select
    id as payment_id,
    contract_id,
    deal_id,
    amount,
    payment_date,
    payment_method,
    payment_status
from {{ source('subtrak_oltp', 'payments') }}