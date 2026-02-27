# Ingestion (Finnhub)

Python jobs that pull Finnhub API data and write parquet files to GCS.
For OHLCV candles, `auto` mode tries Finnhub first and falls back to `yfinance` on Finnhub access-denied errors. Backfill now writes candles directly into the same `raw/candles/year=YYYY/month=MM/day=DD` layout as daily runs.

## Environment variables

- `FINNHUB_API_KEY`: Finnhub token
- `GCP_PROJECT_ID`: GCP project ID
- `GCS_BUCKET`: target data lake bucket
- `RAW_PREFIX` (optional, default: `raw`)
- `CANDLES_PROVIDER` (optional, `auto` | `finnhub` | `yfinance`, default: `auto`)
- `FINNHUB_SYMBOLS` (optional CSV list to override default 50 symbols)

## Local setup (uv)

```bash
cd /Users/ting/Programmation/DE/Zoomcamp-final-project/ingestion
uv sync
```

## Run commands

```bash
uv run python -m finnhub_pipeline.runner backfill
uv run python -m finnhub_pipeline.runner daily
uv run python -m finnhub_pipeline.runner weekly-news
uv run python -m finnhub_pipeline.runner monthly-financials
```

Optional date override:

```bash
uv run python -m finnhub_pipeline.runner daily --as-of 2026-02-23
```
