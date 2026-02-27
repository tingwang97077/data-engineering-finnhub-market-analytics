# Airflow DAGs

DAG file: `/Users/ting/Programmation/DE/Zoomcamp-final-project/airflow/dags/finnhub_ingestion.py`

Defined DAGs:
- `finnhub_backfill` (manual trigger)
- `finnhub_daily` (weekday daily)
- `finnhub_weekly_news` (weekly)
- `finnhub_monthly_financials` (monthly)

Required env vars in Airflow worker/scheduler:
- `FINNHUB_API_KEY`
- `GCP_PROJECT_ID`
- `GCS_BUCKET`
- `GOOGLE_APPLICATION_CREDENTIALS` (if needed by your auth mode)

The DAG imports Python code from `ingestion/src`, so both folders must be mounted in the Airflow environment.
