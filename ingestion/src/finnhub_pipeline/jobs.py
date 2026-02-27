"""High-level ingestion jobs by frequency."""

from __future__ import annotations

import logging
from datetime import date

import pandas as pd

from .builders import candles_to_df, financials_to_df, news_to_df, profile_to_df
from .config import PipelineConfig
from .finnhub_client import FinnhubClient
from .storage import GCSParquetSink
from .utils import one_year_ago, previous_n_days, to_unix_ts, today_utc

logger = logging.getLogger(__name__)


def _concat_non_empty(frames: list[pd.DataFrame]) -> pd.DataFrame:
    valid = [f for f in frames if not f.empty]
    if not valid:
        return pd.DataFrame()
    return pd.concat(valid, ignore_index=True)


def _write_candles_partitioned(
    sink: GCSParquetSink,
    candles_df: pd.DataFrame,
    raw_prefix: str,
) -> None:
    if candles_df.empty:
        return

    by_day = candles_df.groupby("trading_date", sort=True)
    for trading_day, frame in by_day:
        day_str = trading_day.isoformat()
        object_path = (
            f"{raw_prefix}/candles/year={trading_day.year}/month={trading_day.month:02d}/"
            f"day={trading_day.day:02d}/candles_{day_str}.parquet"
        )
        sink.write_dataframe(frame.reset_index(drop=True), object_path)


def _fetch_candles_payload(
    client: FinnhubClient,
    symbol: str,
    from_ts: int,
    to_ts: int,
    candles_mode: str,
) -> tuple[dict, str]:
    if candles_mode == "yfinance":
        return client.stock_candles_yfinance(symbol, from_ts, to_ts), "yfinance"

    if candles_mode == "finnhub":
        return client.stock_candles(symbol, from_ts, to_ts, resolution="D"), "finnhub"

    try:
        return client.stock_candles(symbol, from_ts, to_ts, resolution="D"), "finnhub"
    except Exception as exc:
        if not client.is_access_denied_error(exc):
            raise
        logger.warning(
            "Finnhub candle access denied for %s. Falling back to yfinance for remaining symbols.",
            symbol,
        )
        return client.stock_candles_yfinance(symbol, from_ts, to_ts), "yfinance"


def run_backfill(config: PipelineConfig, as_of: date | None = None) -> None:
    end_day = as_of or today_utc()
    start_day = one_year_ago(end_day)

    client = FinnhubClient(
        api_key=config.api_key,
        timeout_seconds=config.timeout_seconds,
        max_retries=config.max_retries,
        sleep_seconds=config.per_call_sleep_seconds,
    )
    sink = GCSParquetSink(project_id=config.gcp_project_id, bucket_name=config.gcs_bucket)

    candle_frames: list[pd.DataFrame] = []
    profile_payloads: list[dict] = []
    financial_frames: list[pd.DataFrame] = []

    candles_mode = config.candles_provider

    for symbol in config.symbols:
        candles_payload, used_mode = _fetch_candles_payload(
            client,
            symbol,
            to_unix_ts(start_day),
            to_unix_ts(end_day),
            candles_mode,
        )
        if candles_mode == "auto" and used_mode == "yfinance":
            candles_mode = "yfinance"

        candle_frames.append(
            candles_to_df(symbol, candles_payload)
        )
        profile_payloads.append(client.company_profile(symbol))
        financial_frames.append(financials_to_df(symbol, client.basic_financials(symbol)))

    candles_df = _concat_non_empty(candle_frames)
    profiles_df = profile_to_df(profile_payloads)
    financials_df = _concat_non_empty(financial_frames)

    _write_candles_partitioned(sink, candles_df, config.raw_prefix)

    profiles_path = (
        f"{config.raw_prefix}/company_profiles/year={end_day.year}/month={end_day.month:02d}/"
        f"profiles_{end_day.isoformat()}.parquet"
    )
    financials_path = (
        f"{config.raw_prefix}/company_financials/year={end_day.year}/month={end_day.month:02d}/"
        f"financials_{end_day.year}-{end_day.month:02d}.parquet"
    )
    sink.write_dataframe(profiles_df, profiles_path)
    sink.write_dataframe(financials_df, financials_path)


def run_daily(config: PipelineConfig, as_of: date | None = None) -> None:
    run_day = as_of or today_utc()
    start_day = previous_n_days(run_day, 7)

    client = FinnhubClient(
        api_key=config.api_key,
        timeout_seconds=config.timeout_seconds,
        max_retries=config.max_retries,
        sleep_seconds=config.per_call_sleep_seconds,
    )
    sink = GCSParquetSink(project_id=config.gcp_project_id, bucket_name=config.gcs_bucket)

    candle_frames = []
    candles_mode = config.candles_provider
    for symbol in config.symbols:
        payload, used_mode = _fetch_candles_payload(
            client,
            symbol,
            to_unix_ts(start_day),
            to_unix_ts(run_day),
            candles_mode,
        )
        if candles_mode == "auto" and used_mode == "yfinance":
            candles_mode = "yfinance"
        candle_frames.append(candles_to_df(symbol, payload))

    candles_df = _concat_non_empty(candle_frames)
    object_path = (
        f"{config.raw_prefix}/candles/year={run_day.year}/month={run_day.month:02d}/"
        f"day={run_day.day:02d}/candles_{run_day.isoformat()}.parquet"
    )
    sink.write_dataframe(candles_df, object_path)


def run_weekly_news(config: PipelineConfig, as_of: date | None = None) -> None:
    end_day = as_of or today_utc()
    start_day = previous_n_days(end_day, 7)

    client = FinnhubClient(
        api_key=config.api_key,
        timeout_seconds=config.timeout_seconds,
        max_retries=config.max_retries,
        sleep_seconds=config.per_call_sleep_seconds,
    )
    sink = GCSParquetSink(project_id=config.gcp_project_id, bucket_name=config.gcs_bucket)

    news_frames: list[pd.DataFrame] = []
    for symbol in config.symbols:
        payload = client.company_news(symbol, start_day.isoformat(), end_day.isoformat())
        news_frames.append(news_to_df(symbol, payload))

    news_df = _concat_non_empty(news_frames)
    week_number = end_day.isocalendar().week
    object_path = (
        f"{config.raw_prefix}/company_news/year={end_day.year}/week={week_number:02d}/"
        f"news_{end_day.year}-W{week_number:02d}.parquet"
    )
    sink.write_dataframe(news_df, object_path)


def run_monthly_fundamentals(config: PipelineConfig, as_of: date | None = None) -> None:
    run_day = as_of or today_utc()

    client = FinnhubClient(
        api_key=config.api_key,
        timeout_seconds=config.timeout_seconds,
        max_retries=config.max_retries,
        sleep_seconds=config.per_call_sleep_seconds,
    )
    sink = GCSParquetSink(project_id=config.gcp_project_id, bucket_name=config.gcs_bucket)

    profile_payloads: list[dict] = []
    financial_frames: list[pd.DataFrame] = []

    for symbol in config.symbols:
        profile_payloads.append(client.company_profile(symbol))
        financial_frames.append(financials_to_df(symbol, client.basic_financials(symbol)))

    profiles_df = profile_to_df(profile_payloads)
    financials_df = _concat_non_empty(financial_frames)

    profiles_path = (
        f"{config.raw_prefix}/company_profiles/year={run_day.year}/month={run_day.month:02d}/"
        f"profiles_{run_day.isoformat()}.parquet"
    )
    financials_path = (
        f"{config.raw_prefix}/company_financials/year={run_day.year}/month={run_day.month:02d}/"
        f"financials_{run_day.year}-{run_day.month:02d}.parquet"
    )

    sink.write_dataframe(profiles_df, profiles_path)
    sink.write_dataframe(financials_df, financials_path)
