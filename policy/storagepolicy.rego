package terraform.gcs

import rego.v1

# Policy to enforce uniform bucket level access on GCS buckets
# This policy will deny any bucket that has uniform_bucket_level_access set to false

# Main rule that checks for policy violations
deny contains msg if {
    # Check all planned changes in the Terraform plan
    input.planned_values.root_module.resources[_].type == "google_storage_bucket"
    resource := input.planned_values.root_module.resources[_]
    
    # Check if uniform_bucket_level_access is set to false
    resource.values.uniform_bucket_level_access == false
    
    msg := sprintf("Policy violation: GCS bucket '%s' has uniform_bucket_level_access set to false. This is not allowed for security compliance.", [resource.values.name])
}

# Additional rule to check for missing uniform_bucket_level_access setting
deny contains msg if {
    input.planned_values.root_module.resources[_].type == "google_storage_bucket"
    resource := input.planned_values.root_module.resources[_]
    
    # Check if uniform_bucket_level_access is not defined (should default to true)
    not "uniform_bucket_level_access" in object.keys(resource.values)
    
    msg := sprintf("Policy violation: GCS bucket '%s' does not have uniform_bucket_level_access explicitly set. Please set it to true for security compliance.", [resource.values.name])
}

# Helper rule to check if the plan is compliant
compliant if {
    count(deny) == 0
}

# Rule to provide policy summary
policy_summary := {
    "total_violations": count(deny),
    "compliant": compliant,
    "violations": deny
}