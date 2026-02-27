{{
    config(
        materialized='incremental',
        unique_key=['symbol', 'date_key'],
        partition_by={"field": "date_key", "data_type": "date", "granularity": "month"},
        cluster_by=['symbol']
    )
}}

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
from {{ ref('stg_company_financials') }}
{% if is_incremental() %}
where date_key > (
    select coalesce(max(date_key), date('1900-01-01'))
    from {{ this }}
)
{% endif %}
