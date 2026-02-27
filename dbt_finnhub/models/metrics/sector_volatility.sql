with base as (
    select
        sector,
        daily_return
    from {{ ref('fct_daily_prices') }}
    where sector is not null
      and date_key >= date_sub(current_date(), interval 12 month)
),

aggregated as (
    select
        sector,
        avg(daily_return) as avg_daily_return,
        stddev_pop(daily_return) as stddev_daily_return
    from base
    group by 1
)

select
    sector,
    avg_daily_return * 252 as annualized_return,
    stddev_daily_return * sqrt(252) as annualized_volatility,
    {{ safe_divide('avg_daily_return * 252', 'stddev_daily_return * sqrt(252)') }} as return_risk_ratio
from aggregated
