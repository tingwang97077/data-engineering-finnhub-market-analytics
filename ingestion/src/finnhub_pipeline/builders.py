"""Build normalized tabular records from Finnhub responses."""

from __future__ import annotations

from datetime import datetime, timezone

import pandas as pd


def _loaded_at_utc() -> datetime:
    return datetime.now(timezone.utc)


def candles_to_df(symbol: str, payload: dict) -> pd.DataFrame:
    if not payload or payload.get("s") == "no_data":
        return pd.DataFrame()

    data = {
        "symbol": symbol,
        "trading_date": pd.to_datetime(payload.get("t", []), unit="s", utc=True).date,
        "open": payload.get("o", []),
        "high": payload.get("h", []),
        "low": payload.get("l", []),
        "close": payload.get("c", []),
        "volume": payload.get("v", []),
        "_loaded_at": _loaded_at_utc(),
    }
    return pd.DataFrame(data)


def profile_to_df(payloads: list[dict]) -> pd.DataFrame:
    if not payloads:
        return pd.DataFrame()

    rows = []
    loaded_at = _loaded_at_utc()
    for p in payloads:
        if not p or not p.get("ticker"):
            continue
        rows.append(
            {
                "symbol": p.get("ticker"),
                "company_name": p.get("name"),
                "exchange": p.get("exchange"),
                "industry": p.get("finnhubIndustry"),
                "country": p.get("country"),
                "market_cap": p.get("marketCapitalization"),
                "logo_url": p.get("logo"),
                "ipo_date": p.get("ipo"),
                "web_url": p.get("weburl"),
                "_loaded_at": loaded_at,
            }
        )
    return pd.DataFrame(rows)


def news_to_df(symbol: str, payload: list[dict]) -> pd.DataFrame:
    if not payload:
        return pd.DataFrame()

    loaded_at = _loaded_at_utc()
    rows = []
    for n in payload:
        rows.append(
            {
                "symbol": symbol,
                "datetime": pd.to_datetime(n.get("datetime"), unit="s", utc=True),
                "headline": n.get("headline"),
                "summary": n.get("summary"),
                "source": n.get("source"),
                "category": n.get("category"),
                "url": n.get("url"),
                "image": n.get("image"),
                "_loaded_at": loaded_at,
            }
        )
    return pd.DataFrame(rows)


def financials_to_df(symbol: str, payload: dict) -> pd.DataFrame:
    if not payload:
        return pd.DataFrame()

    metric = payload.get("metric", {})
    return pd.DataFrame(
        [
            {
                "symbol": symbol,
                "pe_ratio": metric.get("peBasicExclExtraTTM"),
                "pb_ratio": metric.get("pbAnnual"),
                "eps_ttm": metric.get("epsTTM"),
                "dividend_yield": metric.get("dividendYieldIndicatedAnnual"),
                "beta": metric.get("beta"),
                "week_52_high": metric.get("52WeekHigh"),
                "week_52_low": metric.get("52WeekLow"),
                "market_cap": metric.get("marketCapitalization"),
                "_loaded_at": _loaded_at_utc(),
            }
        ]
    )
