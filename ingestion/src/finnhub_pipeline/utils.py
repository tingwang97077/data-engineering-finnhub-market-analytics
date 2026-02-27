"""Utility helpers for date handling."""

from __future__ import annotations

from datetime import date, datetime, timedelta, timezone


def utcnow() -> datetime:
    return datetime.now(timezone.utc)


def to_unix_ts(day: date) -> int:
    return int(datetime(day.year, day.month, day.day, tzinfo=timezone.utc).timestamp())


def today_utc() -> date:
    return utcnow().date()


def one_year_ago(from_day: date) -> date:
    return from_day - timedelta(days=365)


def previous_n_days(from_day: date, days: int) -> date:
    return from_day - timedelta(days=days)
