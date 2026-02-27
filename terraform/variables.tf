variable "project_id" {
  description = "GCP project ID"
  type        = string
}

variable "region" {
  description = "Primary GCP region"
  type        = string
  default     = "europe-west9"
}

variable "location" {
  description = "Location for BigQuery dataset"
  type        = string
  default     = "europe-west9"
}

variable "environment" {
  description = "Environment name used in resource labels"
  type        = string
  default     = "dev"
}

variable "bucket_name" {
  description = "Globally unique GCS bucket name for the Finnhub data lake"
  type        = string
}

variable "bucket_storage_class" {
  description = "Storage class for GCS bucket"
  type        = string
  default     = "STANDARD"
}

variable "dataset_id" {
  description = "BigQuery dataset ID"
  type        = string
  default     = "finnhub_dw"
}

variable "service_account_id" {
  description = "Service account ID (without domain suffix)"
  type        = string
  default     = "finnhub-pipeline-sa"

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{4,28}[a-z0-9]$", var.service_account_id))
    error_message = "service_account_id must be 6-30 chars, start with a letter, and contain only lowercase letters, digits, and hyphens."
  }
}

variable "enable_uniform_bucket_level_access" {
  description = "Enable uniform bucket-level access"
  type        = bool
  default     = true
}

variable "labels" {
  description = "Additional labels applied to resources"
  type        = map(string)
  default     = {}
}
