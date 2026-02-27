-- Update these values if your project or bucket changed.
DECLARE project_id STRING DEFAULT 'seismic-ground-488312-u6';
DECLARE raw_dataset STRING DEFAULT 'finnhub_raw';
DECLARE bucket_name STRING DEFAULT 'seismic-ground-488312-u6-de-zoomcamp-final-project-finnhub';
DECLARE bq_location STRING DEFAULT 'europe-west9';

EXECUTE IMMEDIATE FORMAT(
  "CREATE SCHEMA IF NOT EXISTS `%s.%s` OPTIONS(location='%s')",
  project_id,
  raw_dataset,
  bq_location
);

EXECUTE IMMEDIATE FORMAT("""
CREATE OR REPLACE EXTERNAL TABLE `%s.%s.raw_candles`
WITH PARTITION COLUMNS
OPTIONS (
  format = 'PARQUET',
  uris = ['gs://%s/raw/candles/*'],
  hive_partition_uri_prefix = 'gs://%s/raw/candles',
  require_hive_partition_filter = FALSE
)
""", project_id, raw_dataset, bucket_name, bucket_name);

EXECUTE IMMEDIATE FORMAT("""
CREATE OR REPLACE EXTERNAL TABLE `%s.%s.raw_company_profiles`
WITH PARTITION COLUMNS
OPTIONS (
  format = 'PARQUET',
  uris = ['gs://%s/raw/company_profiles/*'],
  hive_partition_uri_prefix = 'gs://%s/raw/company_profiles',
  require_hive_partition_filter = FALSE
)
""", project_id, raw_dataset, bucket_name, bucket_name);

EXECUTE IMMEDIATE FORMAT("""
CREATE OR REPLACE EXTERNAL TABLE `%s.%s.raw_company_news`
WITH PARTITION COLUMNS
OPTIONS (
  format = 'PARQUET',
  uris = ['gs://%s/raw/company_news/*'],
  hive_partition_uri_prefix = 'gs://%s/raw/company_news',
  require_hive_partition_filter = FALSE
)
""", project_id, raw_dataset, bucket_name, bucket_name);

EXECUTE IMMEDIATE FORMAT("""
CREATE OR REPLACE EXTERNAL TABLE `%s.%s.raw_company_financials`
WITH PARTITION COLUMNS
OPTIONS (
  format = 'PARQUET',
  uris = ['gs://%s/raw/company_financials/*'],
  hive_partition_uri_prefix = 'gs://%s/raw/company_financials',
  require_hive_partition_filter = FALSE
)
""", project_id, raw_dataset, bucket_name, bucket_name);
