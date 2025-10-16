# Variables for the Terraform configuration

variable "project_id" {
  description = "The GCP project ID"
  type        = string
  default     = "your-gcp-project-id"
}

variable "region" {
  description = "The GCP region for resources"
  type        = string
  default     = "us-central1"
}

variable "bucket_name" {
  description = "The name of the GCS bucket"
  type        = string
  default     = "example-compliance-bucket"
}

variable "environment" {
  description = "Environment tag for resources"
  type        = string
  default     = "development"
}