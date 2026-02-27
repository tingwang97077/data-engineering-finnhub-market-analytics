select *
from {{ ref('fct_daily_prices') }}
where volume <= 0
