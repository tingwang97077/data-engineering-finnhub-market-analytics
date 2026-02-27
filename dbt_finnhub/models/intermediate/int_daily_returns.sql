with prices as (
    select *
    from {{ ref('stg_candles') }}
),

with_lag as (
    select
        *,
        lag(close) over (
            partition by symbol
            order by date_key
        ) as prev_close
    from prices
)

select
    symbol,
    date_key,
    open,
    high,
    low,
    close,
    volume,
    {{ safe_divide('close - prev_close', 'prev_close') }} as daily_return,
    case
        when prev_close > 0 and close > 0 then ln({{ safe_divide('close', 'prev_close') }})
        else null
    end as log_return,
    _loaded_at
from with_lag
where prev_close is not null
