# Finnhub Market Analytics

Open-source market analytics platform on a curated universe of 50 U.S. large-cap stocks across 11 GICS sectors.
It ingests market data to GCS, transforms it in BigQuery with dbt, and serves visual analytics in Looker Studio.

## Business Questions

1. Which sectors outperform over the last 12 months?
2. Which sectors are the most volatile?

## Architecture

![img](/docs/images/architecture.png)

### Architecture Notes

- Data sources: `Finnhub API` with `yfinance` fallback for candles.
- Containerized runtime: Docker Compose for Airflow, ingestion, dbt, Terraform, and GCP CLI tooling.
- Cloud layer: GCS data lake + BigQuery raw/external + BigQuery marts/metrics.
- Transformation : dbt models and tests
- BI : Looker Studio dashboard

```text
[Terraform] -> [GCP: GCS bucket + BigQuery datasets + IAM]

[Docker Compose] -> [Airflow] -> triggers -> [Python ingestion (uv)]
[Docker Compose] -> [dbt]
[Docker Compose] -> [terraform]
[Docker Compose] -> [gcloud/bq]

[Finnhub API] --------------------> [Python ingestion (uv)] -> [GCS raw Parquet (Hive)]
[yfinance fallback for candles] --> [Python ingestion (uv)] -> [GCS raw Parquet (Hive)]

[GCS raw Parquet] -> [BigQuery external tables: finnhub_raw]
[BigQuery finnhub_raw] -> [dbt: stg -> int -> marts -> metrics]
[dbt] -> [BigQuery curated datasets: finnhub_dw_mart + finnhub_dw_metrics]
[BigQuery curated datasets] -> [Looker Studio dashboard]
```

## Dimensional Model Design

### Star Schema

![img](docs/images/star_schema.png)

The central fact table is `fct_daily_prices`, linked to shared dimensions `dim_dates` and `dim_companies`.
Additional facts `fct_company_news` and `fct_company_financials` reuse the same dimensions for consistent filtering by date, symbol, and sector.

## Repository Structure

```text
airflow/          # Airflow DAGs + Dockerfile
ingestion/        # Finnhub ingestion package + CLI + Dockerfile
dbt_finnhub/      # dbt project + Dockerfile
terraform/        # IaC (GCS, BigQuery, SA, IAM)
docker-compose.yml
Makefile
```

## Prerequisites

- Docker + Docker Compose plugin
- Google Cloud project: `your_gcp_project`
- BigQuery location: `your_bq_location`
- Local ADC auth: `your_gcloud_auth`
- Finnhub API key

## Personal Setup (Bring Your Own Credentials)

**Each contributor must use their own cloud project, API key, and local config.**

### 1) Copy templates

```bash
cp .env.docker.example .env.docker
cp terraform/terraform.tfvars.example terraform/terraform.tfvars
mkdir -p ~/.dbt
cp dbt_finnhub/profiles.yml.example ~/.dbt/profiles.yml
```

### 2) Replace values with your own

- `.env.docker`
  - `GCP_PROJECT_ID`
  - `GCS_BUCKET`
  - `BQ_LOCATION`
  - `FINNHUB_API_KEY`
  - optional: `GOOGLE_APPLICATION_CREDENTIALS`
- `terraform/terraform.tfvars`
  - `project_id`
  - `bucket_name`
  - `region` / `location`
  - `labels.owner`
- `~/.dbt/profiles.yml`
  - `project`
  - `dataset`
  - `location`
  - `method` (`oauth` locally, or `service-account` in CI)

### 3) Authenticate against your GCP project

```bash
gcloud config set project <YOUR_GCP_PROJECT_ID>
gcloud auth application-default login
```

### 4) Quick sanity check

```bash
make docker-config
```

If placeholders such as `replace_me` are still present, do not run ingestion yet.

### Security rules

- Never commit `.env.docker`, `terraform.tfvars`, or service account keys.
- Keep secrets in local files or GitHub Secrets only.
- Commit only `*.example` templates.

## Docker Quickstart (Recommended)

### 1) Configure environment

```bash
cp .env.docker.example .env.docker
# edit .env.docker: FINNHUB_API_KEY, GCP_PROJECT_ID, GCS_BUCKET, etc.
```

### 2) Validate and build containers

```bash
make docker-config
make docker-build
```

### 3) Start Airflow stack

```bash
make docker-up-airflow
```

Airflow UI: `http://localhost:8080`  
Default credentials from `.env.docker`: `airflow / airflow`

### 4) Run ingestion jobs in containers

```bash
make docker-ingestion-backfill AS_OF=2026-02-23
make docker-ingestion-daily
make docker-ingestion-weekly-news
make docker-ingestion-monthly
```

### 5) Create external raw tables in BigQuery

```bash
make docker-bq-external-tables BQ_PROJECT=seismic-ground-488312-u6 BQ_LOCATION=europe-west9
```

### 6) Run dbt in container

```bash
make docker-dbt-deps
make docker-dbt-seed
make docker-dbt-freshness
make docker-dbt-build
```

### 7) (Optional) Run Terraform in container

```bash
make docker-terraform-init
make docker-terraform-plan
# make docker-terraform-apply
```

### 8) Stop stack

```bash
make docker-down
# optional hard reset (removes postgres volume)
# make docker-reset
```

## Local (non-Docker) Workflow

You can still run the existing local workflow with `uv`, `dbt`, `bq`, and `terraform`.
Run `make help` for both local and Docker targets.

## Looker Studio Sources

- `your_gcp_project_id.finnhub_dw_metrics.sector_performance`
- `your_gcp_project_id.finnhub_dw_metrics.sector_volatility`
- `your_gcp_project_id.finnhub_dw_mart.fct_daily_prices`
- `your_gcp_project_id.finnhub_dw_metrics.monthly_top_worst_sector`

## Limits / Design Decisions

- Universe is a curated sample of 50 stocks (not top-50 dynamic ranking).
- Some Finnhub keys cannot access `stock/candle`, ingestion auto-falls back to `yfinance`.
- Data quality for news/fundamentals depends on API coverage.
- Region is pinned to `europe-west9` for reproducibility.

## CI/CD (GitHub Actions)

`/.github/workflows/ci.yml`:
- Trigger: `pull_request` + `push` on `main`
- `lint`: `ruff check ingestion/src airflow/dags`
- `smoke-tests`: install ingestion deps, `compileall`, run unit tests if present
- `dbt-parse`: `dbt deps` + `dbt parse`

`/.github/workflows/cd-terraform.yml`:
- Trigger: PR/push on `terraform/**` + manual `workflow_dispatch`
- Auth: GCP Workload Identity Federation (OIDC)
- Steps: `terraform fmt -check`, `init`, `validate`, `plan`
- Apply: manual only (`workflow_dispatch` with `apply=true`)

GitHub repository settings required for CI/CD:
- Variables: `GCP_PROJECT_ID`, `GCS_BUCKET` (optional: `GCP_REGION`, `BQ_LOCATION`, `ENVIRONMENT`)
- Secrets: `GCP_WORKLOAD_IDENTITY_PROVIDER`, `GCP_SERVICE_ACCOUNT`

## Current Outputs

- Sector cumulative return time series
  ![screenshot](docs/images/sector_cumulative_return.png)
- Sector annualized volatility ranking
  ![screenshot](docs/images/sector_volatility.png)

