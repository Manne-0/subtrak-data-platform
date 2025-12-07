
select
    id as sales_rep_id,
    initcap(concat(first_name, ' ', last_name)) as sales_rep_fullname,
    gender,
    date_joined as entry_date,
    date_left as exit_date,
    region_id,
    created_at
from {{ source('subtrak_oltp', 'reps') }}