package terraform.gcs

import rego.v1

# Policy to enforce uniform bucket level access on GCS buckets
# This policy will deny any bucket that has uniform_bucket_level_access set to false

# Debug rule to show what we're looking at
debug_resources := resources if {
    resources := [resource |
        resource := input.planned_values.root_module.resources[_]
        resource.type == "google_storage_bucket"
    ]
}

# Alternative path check for resource changes
debug_resource_changes := resources if {
    resources := [resource |
        resource := input.resource_changes[_]
        resource.type == "google_storage_bucket"
    ]
}

# Main rule that checks for policy violations in planned_values
deny contains msg if {
    # Check all planned changes in the Terraform plan
    input.planned_values.root_module.resources[_].type == "google_storage_bucket"
    resource := input.planned_values.root_module.resources[_]
    
    # Check if uniform_bucket_level_access is set to false
    resource.values.uniform_bucket_level_access == false
    
    bucket_name := resource.values.name
    msg := sprintf("Policy violation: GCS bucket '%s' has uniform_bucket_level_access set to false. This is not allowed for security compliance.", [bucket_name])
}

# Alternative rule for resource_changes path
deny contains msg if {
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
deny contains msg if {
    input.planned_values.root_module.resources[_].type == "google_storage_bucket"
    resource := input.planned_values.root_module.resources[_]
    
    # Check if uniform_bucket_level_access is not defined (should default to true)
    not "uniform_bucket_level_access" in object.keys(resource.values)
    
    bucket_name := resource.values.name
    msg := sprintf("Policy violation: GCS bucket '%s' does not have uniform_bucket_level_access explicitly set. Please set it to true for security compliance.", [bucket_name])
}

# Additional rule for resource_changes path
deny contains msg if {
    input.resource_changes[_].type == "google_storage_bucket"
    change := input.resource_changes[_]
    change.change.actions[_] == "create"
    
    # Check if uniform_bucket_level_access is not defined
    not "uniform_bucket_level_access" in object.keys(change.change.after)
    
    bucket_name := change.change.after.name
    msg := sprintf("Policy violation: GCS bucket '%s' does not have uniform_bucket_level_access explicitly set. Please set it to true for security compliance.", [bucket_name])
}

# Helper rule to check if the plan is compliant
compliant if {
    count(deny) == 0
}

# Rule to provide policy summary
policy_summary := {
    "total_violations": count(deny),
    "compliant": compliant,
    "violations": deny,
    "debug_info": {
        "planned_resources": debug_resources,
        "resource_changes": debug_resource_changes,
        "input_keys": object.keys(input)
    }
}