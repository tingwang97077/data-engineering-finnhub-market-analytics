FROM ghcr.io/astral-sh/uv:python3.11-bookworm-slim

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    UV_COMPILE_BYTECODE=1 \
    UV_LINK_MODE=copy

WORKDIR /app/ingestion

COPY ingestion/pyproject.toml ingestion/uv.lock /app/ingestion/
RUN uv sync --frozen --no-dev --no-install-project

COPY ingestion /app/ingestion
RUN uv sync --frozen --no-dev

ENTRYPOINT ["uv", "run", "python", "-m", "finnhub_pipeline.runner"]
CMD ["daily"]
