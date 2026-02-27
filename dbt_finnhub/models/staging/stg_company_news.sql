{{ config(enabled=var('enable_news_models', false)) }}

with source as (
    select *
    from {{ source('finnhub_raw', 'raw_company_news') }}
),

deduplicated as (
    select
        *,
        row_number() over (
            partition by upper(trim(symbol)), cast(datetime as timestamp), coalesce(url, headline)
            order by cast(_loaded_at as timestamp) desc
        ) as row_num
    from source
)

select
    upper(trim(symbol)) as symbol,
    cast(datetime as timestamp) as news_ts,
    cast(cast(datetime as timestamp) as date) as date_key,
    headline,
    summary,
    source,
    category,
    url,
    image,
    cast(_loaded_at as timestamp) as _loaded_at
from deduplicated
where row_num = 1
  and symbol is not null
  and datetime is not null
