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

  # This setting will be checked by the OPA policy - now compliant
  uniform_bucket_level_access = true

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

# Create a cost-optimized GCP Compute Engine instance
resource "google_compute_instance" "cost_optimized_vm" {
  name         = var.instance_name
  machine_type = var.machine_type
  zone         = var.zone

  # Use preemptible instance for minimum cost (up to 80% savings)
  scheduling {
    preemptible         = true
    automatic_restart   = false
    on_host_maintenance = "TERMINATE"
  }

  # Use the smallest available boot disk with SSD for better performance
  boot_disk {
    initialize_params {
      image = var.boot_disk_image
      size  = var.boot_disk_size
      type  = "pd-standard" # Standard persistent disk is cheaper than SSD
    }
    auto_delete = true
  }

  # Use minimal network interface
  network_interface {
    network = "default"
    # No external IP to save costs - uncomment next line if external access needed
    # access_config {}
  }

  # Minimal metadata
  metadata = {
    environment = var.environment
    managed_by  = "terraform"
    cost_tier   = "minimal"
  }

  # Enable deletion protection
  deletion_protection = false

  # Use default service account with minimal scopes
  service_account {
    email  = "default"
    scopes = ["cloud-platform"]
  }

  tags = ["cost-optimized", "preemptible"]

  labels = {
    environment   = var.environment
    managed_by    = "terraform"
    cost_tier     = "minimal"
    instance_type = "preemptible"
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

# Output compute instance details
output "instance_name" {
  description = "The name of the compute instance"
  value       = google_compute_instance.cost_optimized_vm.name
}

output "instance_internal_ip" {
  description = "The internal IP address of the compute instance"
  value       = google_compute_instance.cost_optimized_vm.network_interface[0].network_ip
}

output "instance_zone" {
  description = "The zone where the compute instance is deployed"
  value       = google_compute_instance.cost_optimized_vm.zone
}

output "cost_optimization_features" {
  description = "Cost optimization features enabled"
  value = {
    preemptible  = google_compute_instance.cost_optimized_vm.scheduling[0].preemptible
    machine_type = google_compute_instance.cost_optimized_vm.machine_type
    disk_type    = google_compute_instance.cost_optimized_vm.boot_disk[0].initialize_params[0].type
    disk_size    = "${google_compute_instance.cost_optimized_vm.boot_disk[0].initialize_params[0].size}GB"
  }
}