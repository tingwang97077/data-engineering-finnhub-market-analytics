# Terraform - Finnhub Market Analytics

This stack provisions:
- One GCS bucket for the data lake
- One BigQuery dataset for the warehouse
- One service account for data pipelines
- IAM bindings for GCS and BigQuery access

## Usage

```bash
cd terraform
cp terraform.tfvars.example terraform.tfvars
# edit terraform.tfvars with your values
terraform init
terraform plan
terraform apply
```

## Notes

- `bucket_name` must be globally unique.
- The dataset is protected with `delete_contents_on_destroy = false`.
- The bucket enforces `public_access_prevention = enforced`.
