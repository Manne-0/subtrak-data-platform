select
    deal_id,
    plan_type as plan,
    signup_amount as setup_amount,
    total_cost as cost_price,
    monthly_payment,
    duration_months as deal_duration,
    warranty_period_months as warranty_duration
from {{ source('subtrak_oltp', 'deals') }}