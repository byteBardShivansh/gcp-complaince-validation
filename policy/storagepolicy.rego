package terraform.gcs

# Policy to enforce uniform bucket level access on GCS buckets
# This policy will deny any bucket that has uniform_bucket_level_access set to false

# Main rule that checks for policy violations
deny[msg] {
    # Check all planned changes in the Terraform plan
    input.planned_values.root_module.resources[_].type == "google_storage_bucket"
    resource := input.planned_values.root_module.resources[_]
    
    # Check if uniform_bucket_level_access is set to false
    resource.values.uniform_bucket_level_access == false
    
    bucket_name := resource.values.name
    msg := sprintf("GCS bucket '%s' has uniform_bucket_level_access set to false. Security policy requires it to be true.", [bucket_name])
}

# Rule to provide policy summary
policy_summary = result {
    violations := deny
    result := {
        "total_violations": count(violations),
        "compliant": count(violations) == 0,
        "violations": violations
    }
}