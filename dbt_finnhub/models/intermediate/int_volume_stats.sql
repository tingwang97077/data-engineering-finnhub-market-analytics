with candles as (
    select symbol, date_key, volume
    from {{ ref('stg_candles') }}
),

stats as (
    select
        symbol,
        date_key,
        volume,
        avg(volume) over (
            partition by symbol
            order by date_key
            rows between 19 preceding and current row
        ) as volume_sma_20,
        stddev_pop(volume) over (
            partition by symbol
            order by date_key
            rows between 19 preceding and current row
        ) as volume_stddev_20
    from candles
)

select
    symbol,
    date_key,
    volume_sma_20,
    {{ safe_divide('volume - volume_sma_20', 'nullif(volume_stddev_20, 0)') }} as volume_zscore
from stats
