with source as (
    select *
    from {{ source('finnhub_raw', 'raw_candles') }}
),

deduplicated as (
    select
        *,
        row_number() over (
            partition by upper(trim(symbol)), cast(trading_date as date)
            order by cast(_loaded_at as timestamp) desc
        ) as row_num
    from source
)

select
    upper(trim(symbol)) as symbol,
    cast(trading_date as date) as date_key,
    cast(open as float64) as open,
    cast(high as float64) as high,
    cast(low as float64) as low,
    cast(close as float64) as close,
    cast(volume as int64) as volume,
    cast(_loaded_at as timestamp) as _loaded_at
from deduplicated
where row_num = 1
  and symbol is not null
  and close is not null
  and cast(volume as int64) > 0
