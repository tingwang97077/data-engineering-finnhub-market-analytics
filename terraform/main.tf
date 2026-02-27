locals {
  common_labels = merge(
    {
      project     = "finnhub-market-analytics"
      environment = var.environment
      managed_by  = "terraform"
    },
    var.labels
  )
}

resource "google_storage_bucket" "finnhub_data_lake" {
  name                        = var.bucket_name
  location                    = var.region
  project                     = var.project_id
  storage_class               = var.bucket_storage_class
  force_destroy               = false
  uniform_bucket_level_access = var.enable_uniform_bucket_level_access

  versioning {
    enabled = true
  }

  public_access_prevention = "enforced"

  lifecycle_rule {
    condition {
      age = 90
    }

    action {
      type          = "SetStorageClass"
      storage_class = "NEARLINE"
    }
  }

  labels = local.common_labels
}

resource "google_bigquery_dataset" "finnhub_dw" {
  project                    = var.project_id
  dataset_id                 = var.dataset_id
  friendly_name              = "Finnhub Data Warehouse"
  description                = "Curated warehouse for Finnhub market analytics"
  location                   = var.location
  delete_contents_on_destroy = false
  max_time_travel_hours      = 168

  labels = local.common_labels
}

resource "google_service_account" "pipeline" {
  project      = var.project_id
  account_id   = var.service_account_id
  display_name = "Finnhub Pipeline Service Account"
  description  = "Used by orchestrators (e.g. Airflow) for ingestion and transformation workloads"
}

resource "google_storage_bucket_iam_member" "pipeline_object_admin" {
  bucket = google_storage_bucket.finnhub_data_lake.name
  role   = "roles/storage.objectAdmin"
  member = "serviceAccount:${google_service_account.pipeline.email}"
}

resource "google_bigquery_dataset_iam_member" "pipeline_data_editor" {
  project    = google_bigquery_dataset.finnhub_dw.project
  dataset_id = google_bigquery_dataset.finnhub_dw.dataset_id
  role       = "roles/bigquery.dataEditor"
  member     = "serviceAccount:${google_service_account.pipeline.email}"
}

resource "google_project_iam_member" "pipeline_job_user" {
  project = var.project_id
  role    = "roles/bigquery.jobUser"
  member  = "serviceAccount:${google_service_account.pipeline.email}"
}
