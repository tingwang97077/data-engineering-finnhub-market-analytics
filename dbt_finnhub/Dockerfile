FROM python:3.11-slim

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    DBT_PROFILES_DIR=/app/profiles

WORKDIR /app/dbt_finnhub

RUN pip install --no-cache-dir --upgrade pip \
    && pip install --no-cache-dir dbt-core==1.11.6 dbt-bigquery==1.11.0

COPY dbt_finnhub /app/dbt_finnhub

ENTRYPOINT ["dbt"]
CMD ["--version"]
