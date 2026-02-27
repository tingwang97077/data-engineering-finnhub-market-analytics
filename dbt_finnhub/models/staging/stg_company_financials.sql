with source as (
    select
        *,
        to_json_string(s) as row_json
    from {{ source('finnhub_raw', 'raw_company_financials') }}
    as s
),

normalized as (
    select
        case
            when upper(trim(symbol)) = 'BRK-B' then 'BRK.B'
            else upper(trim(symbol))
        end as symbol,
        cast(cast(_loaded_at as timestamp) as date) as date_key,
        cast(pe_ratio as float64) as pe_ratio,
        cast(pb_ratio as float64) as pb_ratio,
        cast(eps_ttm as float64) as eps_ttm,
        cast(dividend_yield as float64) as dividend_yield,
        cast(beta as float64) as beta,
        cast(
            coalesce(
                json_value(row_json, '$.\"52_week_high\"'),
                json_value(row_json, '$.week_52_high')
            ) as float64
        ) as week_52_high,
        cast(
            coalesce(
                json_value(row_json, '$.\"52_week_low\"'),
                json_value(row_json, '$.week_52_low')
            ) as float64
        ) as week_52_low,
        cast(market_cap as float64) as market_cap,
        cast(_loaded_at as timestamp) as _loaded_at
    from source
),

deduplicated as (
    select
        *,
        row_number() over (
            partition by symbol, date_key
            order by _loaded_at desc
        ) as row_num
    from normalized
)

select
    symbol,
    date_key,
    pe_ratio,
    pb_ratio,
    eps_ttm,
    dividend_yield,
    beta,
    week_52_high,
    week_52_low,
    market_cap,
    _loaded_at
from deduplicated
where row_num = 1
  and symbol is not null
