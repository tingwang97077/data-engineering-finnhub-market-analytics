with all_dates as (
    select date_key
    from {{ ref('stg_candles') }}

    union all

    select date_key
    from {{ ref('stg_company_financials') }}

    {% if var('enable_news_models', false) %}
    union all

    select date_key
    from {{ ref('stg_company_news') }}
    {% endif %}
),

bounds as (
    select
        coalesce(min(date_key), date_sub(current_date(), interval 365 day)) as min_date,
        coalesce(max(date_key), current_date()) as max_date
    from all_dates
),

date_spine as (
    select
        day as date_key
    from bounds,
    unnest(generate_date_array(min_date, max_date)) as day
),

trading_days as (
    select distinct date_key
    from {{ ref('stg_candles') }}
)

select
    cast(ds.date_key as date) as date_key,
    extract(year from ds.date_key) as year,
    extract(quarter from ds.date_key) as quarter,
    extract(month from ds.date_key) as month,
    extract(isoweek from ds.date_key) as week_of_year,
    extract(dayofweek from ds.date_key) as day_of_week,
    case when td.date_key is not null then true else false end as is_trading
from date_spine ds
left join trading_days td
    on cast(ds.date_key as date) = td.date_key
