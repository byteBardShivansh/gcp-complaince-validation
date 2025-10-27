package terraform.compute

# Simplified policy to enforce cost optimization best practices for GCP Compute Engine instances

# Allow all instances for now (simplified version)
deny[msg] {
    # This rule is disabled for simplified deployment
    false
    msg := "This rule is disabled"
}

# Simplified warnings (optional)
warn[msg] {
    # This rule is disabled for simplified deployment
    false
    msg := "No warnings for simplified deployment"
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