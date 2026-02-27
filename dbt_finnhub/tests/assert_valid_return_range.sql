select *
from {{ ref('fct_daily_prices') }}
where abs(daily_return) > 0.5
