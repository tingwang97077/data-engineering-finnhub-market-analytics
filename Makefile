SHELL := /bin/bash

PROJECT_ROOT := $(abspath $(dir $(lastword $(MAKEFILE_LIST))))
INGESTION_DIR := $(PROJECT_ROOT)/ingestion
DBT_DIR := $(PROJECT_ROOT)/dbt_finnhub

ENV_FILE ?= .env
AS_OF ?= $(shell date -u +%F)
BQ_PROJECT ?= seismic-ground-488312-u6
BQ_LOCATION ?= europe-west9
EXTERNAL_SQL ?= $(DBT_DIR)/sql/create_external_tables.sql
DOCKER_ENV_FILE ?= .env.docker
COMPOSE := docker compose --env-file $(DOCKER_ENV_FILE)

.PHONY: help
help:
	@echo "Available targets:"
	@echo "  ingestion-sync                Install ingestion dependencies with uv"
	@echo "  ingestion-backfill            Run one-shot backfill (AS_OF=YYYY-MM-DD optional)"
	@echo "  ingestion-daily               Run daily candles ingestion"
	@echo "  ingestion-weekly-news         Run weekly news ingestion"
	@echo "  ingestion-monthly-financials  Run monthly profiles/financials ingestion"
	@echo "  bq-external-tables            Create/refresh BigQuery external raw tables"
	@echo "  dbt-setup-profile             Copy example dbt profile to ~/.dbt/profiles.yml"
	@echo "  dbt-deps                      Install dbt packages"
	@echo "  dbt-seed                      Load seed data"
	@echo "  dbt-freshness                 Run source freshness checks"
	@echo "  dbt-build                     Build dbt models/tests/snapshots"
	@echo "  dbt-build-full-refresh        Full refresh dbt build"
	@echo "  qa-all                        Run freshness + build"
	@echo "  docker-config                 Validate docker-compose config"
	@echo "  docker-build                  Build all Docker images"
	@echo "  docker-up-airflow             Start Postgres + Airflow services"
	@echo "  docker-down                   Stop all services"
	@echo "  docker-reset                  Stop all services and remove volumes"
	@echo "  docker-logs                   Tail Airflow logs"
	@echo "  docker-ingestion-backfill     Run backfill ingestion in container"
	@echo "  docker-ingestion-daily        Run daily ingestion in container"
	@echo "  docker-ingestion-weekly-news  Run weekly news ingestion in container"
	@echo "  docker-ingestion-monthly      Run monthly fundamentals ingestion in container"
	@echo "  docker-bq-external-tables     Create raw external tables via bq in container"
	@echo "  docker-dbt-deps               Run dbt deps in container"
	@echo "  docker-dbt-seed               Run dbt seed in container"
	@echo "  docker-dbt-freshness          Run dbt source freshness in container"
	@echo "  docker-dbt-build              Run dbt build in container"
	@echo "  docker-terraform-init         Run terraform init in container"
	@echo "  docker-terraform-plan         Run terraform plan in container"
	@echo "  docker-terraform-apply        Run terraform apply in container"

.PHONY: ingestion-sync
ingestion-sync:
	cd $(INGESTION_DIR) && uv sync

.PHONY: ingestion-backfill
ingestion-backfill:
	cd $(INGESTION_DIR) && UV_CACHE_DIR=/tmp/uv-cache uv run --env-file $(ENV_FILE) python -m finnhub_pipeline.runner backfill --as-of $(AS_OF)

.PHONY: ingestion-daily
ingestion-daily:
	cd $(INGESTION_DIR) && UV_CACHE_DIR=/tmp/uv-cache uv run --env-file $(ENV_FILE) python -m finnhub_pipeline.runner daily

.PHONY: ingestion-weekly-news
ingestion-weekly-news:
	cd $(INGESTION_DIR) && UV_CACHE_DIR=/tmp/uv-cache uv run --env-file $(ENV_FILE) python -m finnhub_pipeline.runner weekly-news

.PHONY: ingestion-monthly-financials
ingestion-monthly-financials:
	cd $(INGESTION_DIR) && UV_CACHE_DIR=/tmp/uv-cache uv run --env-file $(ENV_FILE) python -m finnhub_pipeline.runner monthly-financials

.PHONY: bq-external-tables
bq-external-tables:
	bq --project_id=$(BQ_PROJECT) --location=$(BQ_LOCATION) query --use_legacy_sql=false < $(EXTERNAL_SQL)

.PHONY: dbt-setup-profile
dbt-setup-profile:
	mkdir -p ~/.dbt
	cp $(DBT_DIR)/profiles.yml.example ~/.dbt/profiles.yml

.PHONY: dbt-deps
dbt-deps:
	cd $(DBT_DIR) && dbt deps

.PHONY: dbt-seed
dbt-seed:
	cd $(DBT_DIR) && dbt seed --select sector_mapping

.PHONY: dbt-freshness
dbt-freshness:
	cd $(DBT_DIR) && dbt source freshness

.PHONY: dbt-build
dbt-build:
	cd $(DBT_DIR) && dbt build

.PHONY: dbt-build-full-refresh
dbt-build-full-refresh:
	cd $(DBT_DIR) && dbt build --full-refresh

.PHONY: qa-all
qa-all: dbt-freshness dbt-build

.PHONY: docker-config
docker-config:
	$(COMPOSE) --profile tools config >/dev/null
	@echo "docker-compose config is valid."

.PHONY: docker-build
docker-build:
	$(COMPOSE) --profile tools build

.PHONY: docker-up-airflow
docker-up-airflow:
	$(COMPOSE) up -d postgres airflow-init airflow-webserver airflow-scheduler

.PHONY: docker-down
docker-down:
	$(COMPOSE) down

.PHONY: docker-reset
docker-reset:
	$(COMPOSE) down -v

.PHONY: docker-logs
docker-logs:
	$(COMPOSE) logs -f airflow-webserver airflow-scheduler

.PHONY: docker-ingestion-backfill
docker-ingestion-backfill:
	$(COMPOSE) --profile tools run --rm ingestion backfill --as-of $(AS_OF)

.PHONY: docker-ingestion-daily
docker-ingestion-daily:
	$(COMPOSE) --profile tools run --rm ingestion daily

.PHONY: docker-ingestion-weekly-news
docker-ingestion-weekly-news:
	$(COMPOSE) --profile tools run --rm ingestion weekly-news

.PHONY: docker-ingestion-monthly
docker-ingestion-monthly:
	$(COMPOSE) --profile tools run --rm ingestion monthly-financials

.PHONY: docker-bq-external-tables
docker-bq-external-tables:
	$(COMPOSE) --profile tools run --rm gcloud /bin/sh -lc "bq --project_id=$(BQ_PROJECT) --location=$(BQ_LOCATION) query --use_legacy_sql=false < /workspace/dbt_finnhub/sql/create_external_tables.sql"

.PHONY: docker-dbt-deps
docker-dbt-deps:
	$(COMPOSE) --profile tools run --rm dbt deps

.PHONY: docker-dbt-seed
docker-dbt-seed:
	$(COMPOSE) --profile tools run --rm dbt seed --select sector_mapping

.PHONY: docker-dbt-freshness
docker-dbt-freshness:
	$(COMPOSE) --profile tools run --rm dbt source freshness

.PHONY: docker-dbt-build
docker-dbt-build:
	$(COMPOSE) --profile tools run --rm dbt build

.PHONY: docker-terraform-init
docker-terraform-init:
	$(COMPOSE) --profile tools run --rm terraform init

.PHONY: docker-terraform-plan
docker-terraform-plan:
	$(COMPOSE) --profile tools run --rm terraform plan

.PHONY: docker-terraform-apply
docker-terraform-apply:
	$(COMPOSE) --profile tools run --rm terraform apply
