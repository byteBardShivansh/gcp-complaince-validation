package terraform.compute

# Policy to enforce cost optimization best practices for GCP Compute Engine instances
# This policy ensures instances follow minimum cost guidelines

# Deny non-preemptible instances unless explicitly allowed
deny[msg] {
    input.planned_values.root_module.resources[_].type == "google_compute_instance"
    resource := input.planned_values.root_module.resources[_]
    
    # Check if preemptible is not set to true
    not resource.values.scheduling[_].preemptible == true
    
    instance_name := resource.values.name
    msg := sprintf("Compute instance '%s' is not preemptible. For cost optimization, use preemptible instances which can save up to 80%% on costs.", [instance_name])
}

# Warn about expensive machine types
warn[msg] {
    input.planned_values.root_module.resources[_].type == "google_compute_instance"
    resource := input.planned_values.root_module.resources[_]
    
    # List of cost-effective machine types
    cost_effective_types := [
        "e2-micro", "e2-small", "e2-medium",
        "f1-micro", "g1-small",
        "n1-standard-1", "n2-standard-2"
    ]
    
    machine_type := resource.values.machine_type
    not machine_type in cost_effective_types
    
    instance_name := resource.values.name
    msg := sprintf("Compute instance '%s' uses machine type '%s' which may not be cost-optimal. Consider using e2-micro, f1-micro, or other small machine types for cost savings.", [instance_name, machine_type])
}

# Deny large boot disks
deny[msg] {
    input.planned_values.root_module.resources[_].type == "google_compute_instance"
    resource := input.planned_values.root_module.resources[_]
    
    boot_disk_size := resource.values.boot_disk[_].initialize_params[_].size
    boot_disk_size > 50
    
    instance_name := resource.values.name
    msg := sprintf("Compute instance '%s' has boot disk size of %dGB. For cost optimization, keep boot disk size under 50GB unless specifically required.", [instance_name, boot_disk_size])
}

# Warn about SSD usage for cost optimization
warn[msg] {
    input.planned_values.root_module.resources[_].type == "google_compute_instance"
    resource := input.planned_values.root_module.resources[_]
    
    disk_type := resource.values.boot_disk[_].initialize_params[_].type
    disk_type == "pd-ssd"
    
    instance_name := resource.values.name
    msg := sprintf("Compute instance '%s' uses SSD persistent disk. Consider using 'pd-standard' for cost savings unless high IOPS is required.", [instance_name])
}

# Ensure instances have cost optimization labels
deny[msg] {
    input.planned_values.root_module.resources[_].type == "google_compute_instance"
    resource := input.planned_values.root_module.resources[_]
    
    not resource.values.labels.cost_tier
    
    instance_name := resource.values.name
    msg := sprintf("Compute instance '%s' is missing 'cost_tier' label. This label is required for cost tracking and optimization.", [instance_name])
}

# Rule to provide policy summary
policy_summary = result {
    violations := deny
    warnings := warn
    result := {
        "total_violations": count(violations),
        "total_warnings": count(warnings),
        "compliant": count(violations) == 0,
        "violations": violations,
        "warnings": warnings
    }
}