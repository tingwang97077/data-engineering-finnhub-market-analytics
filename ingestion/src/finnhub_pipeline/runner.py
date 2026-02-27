"""CLI entrypoint for Finnhub ingestion jobs."""

from __future__ import annotations

import argparse
from datetime import date

from .config import PipelineConfig
from .jobs import run_backfill, run_daily, run_monthly_fundamentals, run_weekly_news


def _parse_date(value: str | None) -> date | None:
    if not value:
        return None
    return date.fromisoformat(value)


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description="Finnhub ingestion CLI")
    parser.add_argument(
        "command",
        choices=["backfill", "daily", "weekly-news", "monthly-financials"],
        help="Job command",
    )
    parser.add_argument(
        "--as-of",
        default=None,
        help="Override run date in YYYY-MM-DD (UTC)",
    )
    return parser


def main() -> None:
    args = build_parser().parse_args()
    config = PipelineConfig.from_env()
    as_of = _parse_date(args.as_of)

    if args.command == "backfill":
        run_backfill(config, as_of=as_of)
    elif args.command == "daily":
        run_daily(config, as_of=as_of)
    elif args.command == "weekly-news":
        run_weekly_news(config, as_of=as_of)
    elif args.command == "monthly-financials":
        run_monthly_fundamentals(config, as_of=as_of)
    else:
        raise ValueError(f"Unsupported command: {args.command}")


if __name__ == "__main__":
    main()
