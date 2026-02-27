with source as (
    select *
    from {{ source('finnhub_raw', 'raw_company_profiles') }}
),

deduplicated as (
    select
        *,
        row_number() over (
            partition by upper(trim(symbol))
            order by cast(_loaded_at as timestamp) desc
        ) as row_num
    from source
),

sector_map as (
    select
        upper(trim(symbol)) as symbol,
        sector
    from {{ ref('sector_mapping') }}
),

sector_map_aliases as (
    select symbol as symbol_key, sector
    from sector_map

    union distinct

    select replace(symbol, '.', '-') as symbol_key, sector
    from sector_map

    union distinct

    select replace(symbol, '-', '.') as symbol_key, sector
    from sector_map
)

select
    upper(trim(d.symbol)) as symbol,
    d.company_name,
    coalesce(
        m.sector,
        case
            when lower(coalesce(d.industry, '')) like '%technology%' then 'Technology'
            when lower(coalesce(d.industry, '')) like '%health%' then 'Healthcare'
            when lower(coalesce(d.industry, '')) like '%pharma%' then 'Healthcare'
            when lower(coalesce(d.industry, '')) like '%biotech%' then 'Healthcare'
            when lower(coalesce(d.industry, '')) like '%bank%' then 'Financials'
            when lower(coalesce(d.industry, '')) like '%insurance%' then 'Financials'
            when lower(coalesce(d.industry, '')) like '%financial%' then 'Financials'
            when lower(coalesce(d.industry, '')) like '%consumer cyclical%' then 'Consumer Discretionary'
            when lower(coalesce(d.industry, '')) like '%retail%' then 'Consumer Discretionary'
            when lower(coalesce(d.industry, '')) like '%automobile%' then 'Consumer Discretionary'
            when lower(coalesce(d.industry, '')) like '%restaurant%' then 'Consumer Discretionary'
            when lower(coalesce(d.industry, '')) like '%consumer defensive%' then 'Consumer Staples'
            when lower(coalesce(d.industry, '')) like '%beverage%' then 'Consumer Staples'
            when lower(coalesce(d.industry, '')) like '%household%' then 'Consumer Staples'
            when lower(coalesce(d.industry, '')) like '%industrial%' then 'Industrials'
            when lower(coalesce(d.industry, '')) like '%aerospace%' then 'Industrials'
            when lower(coalesce(d.industry, '')) like '%transport%' then 'Industrials'
            when lower(coalesce(d.industry, '')) like '%energy%' then 'Energy'
            when lower(coalesce(d.industry, '')) like '%oil%' then 'Energy'
            when lower(coalesce(d.industry, '')) like '%gas%' then 'Energy'
            when lower(coalesce(d.industry, '')) like '%communication%' then 'Communication Services'
            when lower(coalesce(d.industry, '')) like '%media%' then 'Communication Services'
            when lower(coalesce(d.industry, '')) like '%entertainment%' then 'Communication Services'
            when lower(coalesce(d.industry, '')) like '%telecom%' then 'Communication Services'
            when lower(coalesce(d.industry, '')) like '%utility%' then 'Utilities'
            when lower(coalesce(d.industry, '')) like '%real estate%' then 'Real Estate'
            when lower(coalesce(d.industry, '')) like '%material%' then 'Materials'
            when lower(coalesce(d.industry, '')) like '%chemical%' then 'Materials'
            else 'Financials'
        end
    ) as sector,
    d.industry,
    d.country,
    cast(d.market_cap as float64) as market_cap,
    cast(d.ipo_date as date) as ipo_date,
    d.logo_url,
    d.web_url,
    d.exchange,
    cast(d._loaded_at as timestamp) as _loaded_at
from deduplicated d
left join sector_map_aliases m
    on upper(trim(d.symbol)) = m.symbol_key
where row_num = 1
  and d.symbol is not null
