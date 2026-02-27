output "bucket_name" {
  description = "Name of the GCS data lake bucket"
  value       = google_storage_bucket.finnhub_data_lake.name
}

output "dataset_id" {
  description = "BigQuery dataset ID"
  value       = google_bigquery_dataset.finnhub_dw.dataset_id
}

output "service_account_email" {
  description = "Service account used by data pipelines"
  value       = google_service_account.pipeline.email
}
