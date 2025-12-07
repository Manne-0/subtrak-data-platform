select
    id as region_id,
    region_name
from {{ source('subtrak_oltp', 'regions') }}