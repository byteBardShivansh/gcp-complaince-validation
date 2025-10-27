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

# Compute Instance Variables
variable "instance_name" {
  description = "The name of the compute instance"
  type        = string
  default     = "cost-optimized-vm"
}

variable "machine_type" {
  description = "The machine type for the compute instance (smallest available for minimum cost)"
  type        = string
  default     = "e2-micro" # Lowest cost machine type, eligible for Always Free tier
}

variable "zone" {
  description = "The zone for the compute instance"
  type        = string
  default     = "us-central1-a" # Usually has lower costs
}

variable "boot_disk_image" {
  description = "The boot disk image for the compute instance"
  type        = string
  default     = "debian-cloud/debian-11" # Free and lightweight
}

variable "boot_disk_size" {
  description = "The size of the boot disk in GB"
  type        = number
  default     = 10 # Minimum size for cost optimization
}