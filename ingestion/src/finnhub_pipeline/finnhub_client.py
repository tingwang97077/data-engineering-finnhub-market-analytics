"""Thin Finnhub client with basic retry and throttling."""

from __future__ import annotations

import time
from datetime import datetime, timedelta, timezone
from typing import Any

import finnhub
import pandas as pd
import yfinance as yf


class FinnhubClient:
    def __init__(self, api_key: str, timeout_seconds: int = 30, max_retries: int = 3, sleep_seconds: float = 1.1):
        self.api_key = api_key
        self.timeout_seconds = timeout_seconds
        self.max_retries = max_retries
        self.sleep_seconds = sleep_seconds
        self.client = finnhub.Client(api_key=api_key)

    def _request(self, fn, *args, **kwargs) -> Any:
        for attempt in range(1, self.max_retries + 1):
            try:
                data = fn(*args, **kwargs)
                time.sleep(self.sleep_seconds)
                return data
            except Exception:
                if attempt == self.max_retries:
                    raise

            # Exponential backoff for transient errors and rate limits.
            time.sleep((2 ** (attempt - 1)) + self.sleep_seconds)

        raise RuntimeError("Unexpected request retry flow")

    @staticmethod
    def is_access_denied_error(exc: Exception) -> bool:
        status_code = getattr(exc, "status_code", None)
        if status_code == 403:
            return True
        return "don't have access to this resource" in str(exc).lower()

    def stock_candles(self, symbol: str, from_ts: int, to_ts: int, resolution: str = "D") -> dict[str, Any]:
        return self._request(
            self.client.stock_candles,
            symbol,
            resolution,
            from_ts,
            to_ts,
        )

    def stock_candles_yfinance(self, symbol: str, from_ts: int, to_ts: int) -> dict[str, Any]:
        yf_symbol = symbol.replace(".", "-")
        start_dt = datetime.fromtimestamp(from_ts, tz=timezone.utc)
        end_dt = datetime.fromtimestamp(to_ts, tz=timezone.utc) + timedelta(days=1)

        frame = yf.download(
            yf_symbol,
            start=start_dt,
            end=end_dt,
            interval="1d",
            auto_adjust=False,
            progress=False,
            threads=False,
        )

        if frame is None or frame.empty:
            return {"s": "no_data", "t": [], "o": [], "h": [], "l": [], "c": [], "v": []}

        if isinstance(frame.columns, pd.MultiIndex):
            frame.columns = frame.columns.get_level_values(0)

        frame = frame.reset_index()
        frame["Date"] = pd.to_datetime(frame["Date"], utc=True)

        return {
            "s": "ok",
            "t": [int(ts.timestamp()) for ts in frame["Date"]],
            "o": frame["Open"].fillna(0.0).astype(float).tolist(),
            "h": frame["High"].fillna(0.0).astype(float).tolist(),
            "l": frame["Low"].fillna(0.0).astype(float).tolist(),
            "c": frame["Close"].fillna(0.0).astype(float).tolist(),
            "v": frame["Volume"].fillna(0).astype(int).tolist(),
        }

    def company_profile(self, symbol: str) -> dict[str, Any]:
        return self._request(self.client.company_profile2, symbol=symbol)

    def company_news(self, symbol: str, start_date: str, end_date: str) -> list[dict[str, Any]]:
        payload = self._request(self.client.company_news, symbol, start_date, end_date)
        return payload if isinstance(payload, list) else []

    def basic_financials(self, symbol: str) -> dict[str, Any]:
        return self._request(self.client.company_basic_financials, symbol, "all")
