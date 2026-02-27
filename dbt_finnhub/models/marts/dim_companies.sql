with sector_map as (
    select
        upper(trim(symbol)) as symbol,
        sector
    from {{ ref('sector_mapping') }}
),

profiles as (
    select
        case
            when upper(trim(symbol)) = 'BRK-B' then 'BRK.B'
            else upper(trim(symbol))
        end as symbol,
        company_name,
        industry,
        country,
        market_cap,
        ipo_date,
        logo_url,
        web_url,
        exchange,
        _loaded_at
    from {{ ref('stg_company_profiles') }}
),

deduplicated_profiles as (
    select
        *,
        row_number() over (
            partition by symbol
            order by _loaded_at desc
        ) as row_num
    from profiles
)

select
    s.symbol,
    coalesce(p.company_name, s.symbol) as company_name,
    s.sector,
    p.industry,
    p.country,
    p.market_cap,
    p.ipo_date,
    p.logo_url,
    p.web_url,
    p.exchange,
    p._loaded_at
from sector_map s
left join deduplicated_profiles p
    on s.symbol = p.symbol
   and p.row_num = 1
