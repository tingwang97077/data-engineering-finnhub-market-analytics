{{
    config(
        enabled=var('enable_news_models', false),
        materialized='incremental',
        unique_key='news_id',
        partition_by={"field": "date_key", "data_type": "date", "granularity": "day"},
        cluster_by=['symbol', 'source']
    )
}}

with news as (
    select *
    from {{ ref('stg_company_news') }}
)

select
    {{ dbt_utils.generate_surrogate_key([
        'symbol',
        "cast(news_ts as string)",
        'headline',
        'url'
    ]) }} as news_id,
    symbol,
    date_key,
    news_ts,
    headline,
    summary,
    source,
    category,
    url,
    image,
    _loaded_at
from news
{% if is_incremental() %}
where date_key > (
    select coalesce(max(date_key), date('1900-01-01'))
    from {{ this }}
)
{% endif %}
