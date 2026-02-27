"""Airflow DAGs for Finnhub ingestion frequencies."""

from __future__ import annotations

import sys
from datetime import datetime, timedelta
from pathlib import Path

from airflow import DAG
from airflow.operators.python import PythonOperator

REPO_ROOT = Path(__file__).resolve().parents[2]
INGESTION_SRC = REPO_ROOT / "ingestion" / "src"
if str(INGESTION_SRC) not in sys.path:
    sys.path.append(str(INGESTION_SRC))

from finnhub_pipeline.config import PipelineConfig  # noqa: E402
from finnhub_pipeline.jobs import (  # noqa: E402
    run_backfill,
    run_daily,
    run_monthly_fundamentals,
    run_weekly_news,
)

DEFAULT_ARGS = {
    "owner": "data-engineering",
    "depends_on_past": False,
    "retries": 2,
    "retry_delay": timedelta(minutes=5),
}


def backfill_task() -> None:
    run_backfill(PipelineConfig.from_env())


def daily_task() -> None:
    run_daily(PipelineConfig.from_env())


def weekly_news_task() -> None:
    run_weekly_news(PipelineConfig.from_env())


def monthly_financials_task() -> None:
    run_monthly_fundamentals(PipelineConfig.from_env())


with DAG(
    dag_id="finnhub_backfill",
    default_args=DEFAULT_ARGS,
    description="One-shot backfill for Finnhub candles/profiles/financials",
    schedule=None,
    start_date=datetime(2026, 1, 1),
    catchup=False,
    tags=["finnhub", "backfill"],
) as dag_backfill:
    PythonOperator(
        task_id="run_backfill",
        python_callable=backfill_task,
    )


with DAG(
    dag_id="finnhub_daily",
    default_args=DEFAULT_ARGS,
    description="Daily candles ingestion",
    schedule="0 22 * * 1-5",
    start_date=datetime(2026, 1, 1),
    catchup=False,
    tags=["finnhub", "daily"],
) as dag_daily:
    PythonOperator(
        task_id="run_daily_candles",
        python_callable=daily_task,
    )


with DAG(
    dag_id="finnhub_weekly_news",
    default_args=DEFAULT_ARGS,
    description="Weekly company news ingestion",
    schedule="0 6 * * 1",
    start_date=datetime(2026, 1, 1),
    catchup=False,
    tags=["finnhub", "weekly"],
) as dag_weekly:
    PythonOperator(
        task_id="run_weekly_news",
        python_callable=weekly_news_task,
    )


with DAG(
    dag_id="finnhub_monthly_financials",
    default_args=DEFAULT_ARGS,
    description="Monthly profiles and financial metrics ingestion",
    schedule="0 7 1 * *",
    start_date=datetime(2026, 1, 1),
    catchup=False,
    tags=["finnhub", "monthly"],
) as dag_monthly:
    PythonOperator(
        task_id="run_monthly_financials",
        python_callable=monthly_financials_task,
    )
