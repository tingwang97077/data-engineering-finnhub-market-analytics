# dbt Finnhub

This project builds staging, intermediate, marts, and metrics models for the Finnhub market analytics pipeline.

## Prerequisites

- BigQuery dataset for curated models: `finnhub_dw`
- BigQuery dataset for raw external tables: `finnhub_raw`
- GCS raw data written by ingestion jobs under `gs://<bucket>/raw/...`
- BigQuery location aligned to `europe-west9` for both datasets

## Setup

```bash
cd /Users/ting/Programmation/DE/Zoomcamp-final-project/dbt_finnhub
cp profiles.yml.example ~/.dbt/profiles.yml
```

Install dbt CLI with the BigQuery adapter and fetch packages:

```bash
uv tool install dbt-core --with dbt-bigquery
dbt deps
```

## Typical run order

```bash
# 1) Create external raw tables first
bq query --use_legacy_sql=false < sql/create_external_tables.sql

# 2) Build everything
cd /Users/ting/Programmation/DE/Zoomcamp-final-project/dbt_finnhub
dbt build
```

## Notes

- `fct_daily_prices` is incremental and partitioned by `date_key`.
- Candle data quality tests include positive volume and return range assertions.
- Candles fallback source (`yfinance`) is transparent to dbt because dbt reads raw parquet outputs in GCS.
