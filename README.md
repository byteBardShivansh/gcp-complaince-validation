# GCP Compliance Validation with Terraform and OPA

This repository demonstrates how to implement compliance validation for Google Cloud Platform (GCP) resources using Terraform and Open Policy Agent (OPA).

## Overview

This project implements a compliance validation pipeline that:
1. Creates GCP resources using Terraform
2. Validates resource configurations against OPA policies
3. Automatically blocks non-compliant deployments
4. Uses GitHub Actions for CI/CD automation

## Architecture

```
┌─────────────────┐    ┌──────────────────┐    ┌─────────────────┐
│   Terraform     │───▶│  OPA Policy      │───▶│  GitHub Actions │
│   Configuration │    │  Validation      │    │  CI/CD Pipeline │
└─────────────────┘    └──────────────────┘    └─────────────────┘
```

## Directory Structure

```
├── .github/workflows/
│   └── terraform.yml           # GitHub Actions workflow
├── policy/
│   └── storagepolicy.rego      # OPA policy for GCS buckets
├── main.tf                     # Terraform main configuration
├── variables.tf                # Terraform variables
├── terraform.tfvars.example    # Example variables file
└── README.md                   # This file
```

## Features

### Terraform Configuration
- Defines a Google Cloud Storage bucket
- Sets `uniform_bucket_level_access = false` (intentionally non-compliant)
- Includes versioning and lifecycle rules

### OPA Policy
- Validates GCS bucket configurations
- Enforces `uniform_bucket_level_access = true` requirement
- Provides detailed violation messages

### GitHub Actions Workflow
- Automated Terraform planning and validation
- OPA policy evaluation
- PR comments with compliance results
- Conditional deployment based on compliance

## Getting Started

### Prerequisites

1. **GCP Project**: Active Google Cloud Platform project
2. **Service Account**: GCP service account with appropriate permissions
3. **GitHub Secrets**: Configure the following secrets in your repository:
   - `GCP_SA_KEY`: Service account JSON key
   - `GCP_PROJECT_ID`: Your GCP project ID

### Setup Instructions

1. **Clone the repository**:
   ```bash
   git clone <repository-url>
   cd gcp-compliance-validation
   ```

2. **Configure Terraform variables**:
   ```bash
   cp terraform.tfvars.example terraform.tfvars
   # Edit terraform.tfvars with your actual values
   ```

3. **Set up GCP authentication** (for local development):
   ```bash
   gcloud auth application-default login
   export GOOGLE_PROJECT=your-project-id
   ```

4. **Initialize Terraform**:
   ```bash
   terraform init
   ```

## Local Testing

### Test Terraform Configuration
```bash
# Format check
terraform fmt -check

# Validate configuration
terraform validate

# Create execution plan
terraform plan
```

### Test OPA Policy
```bash
# Install OPA (if not already installed)
curl -L -o opa https://openpolicyagent.org/downloads/latest/opa_linux_amd64
chmod +x opa
sudo mv opa /usr/local/bin/

# Generate JSON plan
terraform plan -out=tfplan
terraform show -json tfplan > tfplan.json

# Run policy evaluation
opa eval -d policy/ -i tfplan.json "data.terraform.gcs.policy_summary"
```

## Policy Details

The OPA policy (`policy/storagepolicy.rego`) enforces the following rules:

1. **Uniform Bucket Level Access**: All GCS buckets must have `uniform_bucket_level_access = true`
2. **Explicit Configuration**: The setting must be explicitly defined (not relying on defaults)

### Policy Violations

The current configuration intentionally violates the policy to demonstrate the validation:
- `uniform_bucket_level_access = false` in `main.tf`

To make the configuration compliant, change:
```hcl
uniform_bucket_level_access = true
```

## GitHub Actions Workflow

The workflow (`.github/workflows/terraform.yml`) includes:

### Triggers
- Push to `main` or `develop` branches
- Pull requests to `main` branch
- Manual workflow dispatch

### Steps
1. **Setup**: Install Terraform and OPA
2. **Authentication**: Authenticate with GCP
3. **Validation**: Format, validate, and plan Terraform
4. **Policy Check**: Convert plan to JSON and run OPA evaluation
5. **Results**: Comment on PRs with compliance status
6. **Deployment**: Apply changes if compliant (main branch only)

### Required Secrets

Configure these in your GitHub repository settings:

| Secret | Description | Example |
|--------|-------------|---------|
| `GCP_SA_KEY` | Service account JSON key | `{"type": "service_account", ...}` |
| `GCP_PROJECT_ID` | Your GCP project ID | `my-gcp-project-123` |

## Service Account Permissions

Your GCP service account needs the following IAM roles:

- `Storage Admin` (for bucket creation)
- `Project IAM Admin` (if managing IAM policies)
- `Service Usage Consumer` (for API access)

## Customization

### Adding New Policies

1. Create a new `.rego` file in the `policy/` directory
2. Follow the package naming convention: `package terraform.<resource_type>`
3. Implement `deny` rules for violations
4. Update the workflow to reference new policies

### Example: Compute Instance Policy
```rego
package terraform.compute

deny[msg] {
    input.planned_values.root_module.resources[_].type == "google_compute_instance"
    resource := input.planned_values.root_module.resources[_]
    resource.values.machine_type == "n1-standard-1"
    msg := "Machine type n1-standard-1 is deprecated"
}
```

## Troubleshooting

### Common Issues

1. **Authentication Errors**:
   - Verify `GCP_SA_KEY` secret is valid JSON
   - Check service account permissions

2. **Policy Evaluation Failures**:
   - Validate Rego syntax: `opa fmt policy/`
   - Test policies locally before committing

3. **Terraform Plan Failures**:
   - Ensure all required variables are set
   - Check resource quotas and limits

### Debug Mode

Enable debug output in the workflow by adding:
```yaml
env:
  TF_LOG: DEBUG
  OPA_LOG_LEVEL: debug
```

## Contributing

1. Fork the repository
2. Create a feature branch
3. Add tests for new policies
4. Submit a pull request

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Resources

- [Terraform Google Provider Documentation](https://registry.terraform.io/providers/hashicorp/google/latest/docs)
- [Open Policy Agent Documentation](https://www.openpolicyagent.org/docs/)
- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [GCP Security Best Practices](https://cloud.google.com/security/best-practices)