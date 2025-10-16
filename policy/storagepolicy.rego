package terraform.gcs

# Policy to enforce uniform bucket level access on GCS buckets
# This policy will deny any bucket that has uniform_bucket_level_access set to false

# Debug rule to show what we're looking at
debug_resources[resource] {
    resource := input.planned_values.root_module.resources[_]
    resource.type == "google_storage_bucket"
}

# Alternative path check for resource changes  
debug_resource_changes[resource] {
    resource := input.resource_changes[_]
    resource.type == "google_storage_bucket"
}

# Main rule that checks for policy violations in planned_values
deny[msg] {
    # Check all planned changes in the Terraform plan
    input.planned_values.root_module.resources[_].type == "google_storage_bucket"
    resource := input.planned_values.root_module.resources[_]
    
    # Check if uniform_bucket_level_access is set to false
    resource.values.uniform_bucket_level_access == false
    
    bucket_name := resource.values.name
    msg := sprintf("Policy violation: GCS bucket '%s' has uniform_bucket_level_access set to false. This is not allowed for security compliance.", [bucket_name])
}

# Alternative rule for resource_changes path
deny[msg] {
    # Check resource changes (alternative path in Terraform JSON)
    input.resource_changes[_].type == "google_storage_bucket"
    change := input.resource_changes[_]
    change.change.actions[_] == "create"
    
    # Check if uniform_bucket_level_access is set to false
    change.change.after.uniform_bucket_level_access == false
    
    bucket_name := change.change.after.name
    msg := sprintf("Policy violation: GCS bucket '%s' has uniform_bucket_level_access set to false. This is not allowed for security compliance.", [bucket_name])
}

# Additional rule to check for missing uniform_bucket_level_access setting in planned_values
deny[msg] {
    input.planned_values.root_module.resources[_].type == "google_storage_bucket"
    resource := input.planned_values.root_module.resources[_]
    
    # Check if uniform_bucket_level_access is not defined (should default to true)
    not resource.values.uniform_bucket_level_access
    
    bucket_name := resource.values.name
    msg := sprintf("Policy violation: GCS bucket '%s' does not have uniform_bucket_level_access explicitly set. Please set it to true for security compliance.", [bucket_name])
}

# Additional rule for resource_changes path
deny[msg] {
    input.resource_changes[_].type == "google_storage_bucket"
    change := input.resource_changes[_]
    change.change.actions[_] == "create"
    
    # Check if uniform_bucket_level_access is not defined
    not change.change.after.uniform_bucket_level_access
    
    bucket_name := change.change.after.name
    msg := sprintf("Policy violation: GCS bucket '%s' does not have uniform_bucket_level_access explicitly set. Please set it to true for security compliance.", [bucket_name])
}

# Helper rule to check if the plan is compliant
compliant {
    count(deny) == 0
}

# Rule to provide policy summary
policy_summary = result {
    violations := deny
    result := {
        "total_violations": count(violations),
        "compliant": count(violations) == 0,
        "violations": violations,
        "debug_info": {
            "planned_resources": debug_resources,
            "resource_changes": debug_resource_changes
        }
    }
}