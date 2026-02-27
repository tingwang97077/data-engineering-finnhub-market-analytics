{{
    config(
        materialized='incremental',
        unique_key=['symbol', 'date_key'],
        partition_by={"field": "date_key", "data_type": "date", "granularity": "day"},
        cluster_by=['symbol', 'sector']
    )
}}

with returns as (
    select *
    from {{ ref('int_daily_returns') }}
),

companies as (
    select symbol, sector
    from {{ ref('dim_companies') }}
),

volume_stats as (
    select *
    from {{ ref('int_volume_stats') }}
),

joined as (
    select
        r.symbol,
        r.date_key,
        c.sector,
        r.open,
        r.high,
        r.low,
        r.close,
        r.volume,
        r.daily_return,
        r.log_return,
        exp(sum(coalesce(r.log_return, 0.0)) over (
            partition by r.symbol
            order by r.date_key
            rows between unbounded preceding and current row
        )) - 1 as cumulative_return,
        v.volume_sma_20,
        v.volume_zscore,
        r._loaded_at
    from returns r
    left join companies c
        on r.symbol = c.symbol
    left join volume_stats v
        on r.symbol = v.symbol
       and r.date_key = v.date_key
)

select *
from joined
{% if is_incremental() %}
where date_key > (
    select coalesce(max(date_key), date('1900-01-01'))
    from {{ this }}
)
{% endif %}
