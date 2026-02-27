{% snapshot snap_company_profiles %}

{{
    config(
        unique_key='symbol',
        strategy='check',
        check_cols=[
            'company_name',
            'exchange',
            'industry',
            'country',
            'market_cap',
            'ipo_date',
            'logo_url',
            'web_url',
            'sector'
        ]
    )
}}

select *
from {{ ref('stg_company_profiles') }}

{% endsnapshot %}
