"""Runtime configuration for Finnhub ingestion."""

from __future__ import annotations

import os
from dataclasses import dataclass, field

from .universe import US_SYMBOLS


@dataclass(frozen=True)
class PipelineConfig:
    api_key: str
    gcp_project_id: str
    gcs_bucket: str
    raw_prefix: str = "raw"
    timeout_seconds: int = 30
    per_call_sleep_seconds: float = 1.1
    max_retries: int = 3
    candles_provider: str = "auto"
    symbols: list[str] = field(default_factory=lambda: list(US_SYMBOLS))

    @classmethod
    def from_env(cls) -> "PipelineConfig":
        api_key = os.getenv("FINNHUB_API_KEY")
        if not api_key:
            raise ValueError("FINNHUB_API_KEY is required")

        bucket = os.getenv("GCS_BUCKET")
        if not bucket:
            raise ValueError("GCS_BUCKET is required")

        project_id = os.getenv("GCP_PROJECT_ID")
        if not project_id:
            raise ValueError("GCP_PROJECT_ID is required")

        symbols_override = os.getenv("FINNHUB_SYMBOLS", "").strip()
        symbols = [s.strip() for s in symbols_override.split(",") if s.strip()] or list(US_SYMBOLS)

        candles_provider = os.getenv("CANDLES_PROVIDER", "auto").strip().lower()
        if candles_provider not in {"auto", "finnhub", "yfinance"}:
            raise ValueError("CANDLES_PROVIDER must be one of: auto, finnhub, yfinance")

        return cls(
            api_key=api_key,
            gcp_project_id=project_id,
            gcs_bucket=bucket,
            raw_prefix=os.getenv("RAW_PREFIX", "raw"),
            timeout_seconds=int(os.getenv("FINNHUB_TIMEOUT_SECONDS", "30")),
            per_call_sleep_seconds=float(os.getenv("FINNHUB_CALL_SLEEP_SECONDS", "1.1")),
            max_retries=int(os.getenv("FINNHUB_MAX_RETRIES", "3")),
            candles_provider=candles_provider,
            symbols=symbols,
        )
