# Configure the Google Cloud Provider
terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 4.0"
    }
  }
  required_version = ">= 1.0"
}

provider "google" {
  project = var.project_id
  region  = var.region
}

# Create a Google Cloud Storage bucket with uniform_bucket_level_access set to false
# This will trigger the OPA policy violation and block deployment
resource "google_storage_bucket" "example_bucket" {
  name          = var.bucket_name
  location      = var.region
  force_destroy = true

  # This setting will be checked by the OPA policy - intentionally non-compliant
  uniform_bucket_level_access = false

  versioning {
    enabled = true
  }

  lifecycle_rule {
    condition {
      age = 30
    }
    action {
      type = "Delete"
    }
  }

  labels = {
    environment = var.environment
    managed_by  = "terraform"
  }
}

# Output the bucket URL
output "bucket_url" {
  description = "The URL of the created bucket"
  value       = google_storage_bucket.example_bucket.url
}

output "bucket_name" {
  description = "The name of the created bucket"
  value       = google_storage_bucket.example_bucket.name
}