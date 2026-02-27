with sector_daily as (
    select
        date_key,
        sector,
        avg(daily_return) as avg_daily_return,
        avg(log_return) as avg_log_return
    from {{ ref('fct_daily_prices') }}
    where sector is not null
    group by 1, 2
)

select
    date_key,
    sector,
    avg_daily_return,
    avg_daily_return * 100 as avg_daily_return_pct,
    exp(sum(coalesce(avg_log_return, 0.0)) over (
        partition by sector
        order by date_key
        rows between unbounded preceding and current row
    )) - 1 as cumulative_return,
    (exp(sum(coalesce(avg_log_return, 0.0)) over (
        partition by sector
        order by date_key
        rows between unbounded preceding and current row
    )) - 1) * 100 as cumulative_return_pct
from sector_daily
