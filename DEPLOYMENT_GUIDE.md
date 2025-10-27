# Cost-Optimized GCP Compute Instance Deployment Guide

## 🎯 Overview
This guide will help you deploy the most cost-effective GCP Compute Engine instance possible while maintaining functionality.

## 💰 Cost Optimization Features

### Implemented Optimizations
- ✅ **Preemptible Instance**: Up to 80% cost savings
- ✅ **e2-micro Machine Type**: Smallest available, eligible for Always Free tier
- ✅ **10GB Standard Persistent Disk**: Minimum size, standard disk type
- ✅ **Ubuntu 20.04 LTS**: Free operating system
- ✅ **No External IP**: Eliminates external IP charges
- ✅ **Auto-delete Boot Disk**: Prevents orphaned disk charges

### Estimated Monthly Cost
- **Preemptible e2-micro**: ~$3.50/month (if running 24/7)
- **Boot Disk (10GB standard)**: ~$0.40/month
- **Total**: ~$3.90/month

*Note: Actual costs will be lower due to preemptible interruptions*

## 🚀 Quick Deployment

### Prerequisites
1. **GCP Project** with billing enabled
2. **Terraform** installed ([Download](https://www.terraform.io/downloads.html))
3. **gcloud CLI** installed and authenticated ([Install Guide](https://cloud.google.com/sdk/docs/install))

### Step 1: Setup Configuration
```powershell
# Copy the example configuration
Copy-Item terraform.tfvars.example terraform.tfvars

# Edit terraform.tfvars with your details
# Required: project_id, bucket_name (must be globally unique)
```

### Step 2: Deploy Using Script
```powershell
# Use the PowerShell deployment script
.\deploy.ps1

# Or for auto-approval (no prompts)
.\deploy.ps1 -AutoApprove
```

### Step 3: Manual Deployment (Alternative)
```powershell
# Initialize Terraform
terraform init

# Plan deployment
terraform plan

# Apply configuration
terraform apply
```

## 📊 Cost Monitoring

### Monitor Your Costs
```powershell
# Check current resource status and costs
.\monitor-costs.ps1

# Show detailed resource information
.\monitor-costs.ps1 -ShowDetailed

# Specify project ID explicitly
.\monitor-costs.ps1 -ProjectId "your-project-id"
```

### Key Commands
```bash
# List all instances
gcloud compute instances list

# Stop an instance (saves money)
gcloud compute instances stop INSTANCE_NAME

# Start an instance
gcloud compute instances start INSTANCE_NAME

# Delete an instance (stops all charges)
gcloud compute instances delete INSTANCE_NAME
```

## 🔧 Configuration Options

### Variables (terraform.tfvars)
```hcl
# Required
project_id = "your-gcp-project-id"
bucket_name = "your-unique-bucket-name"

# Optional - Cost Optimization Settings
instance_name = "cost-optimized-vm"
machine_type = "e2-micro"              # Smallest/cheapest
zone = "us-central1-a"                 # Often cheapest zone
boot_disk_size = 10                    # Minimum size
boot_disk_image = "ubuntu-os-cloud/ubuntu-2004-lts"
```

### Machine Type Options (Cost Ordered)
1. **e2-micro** - $3.50/month (preemptible) - **RECOMMENDED**
2. **f1-micro** - $3.88/month (preemptible)
3. **e2-small** - $7.00/month (preemptible)
4. **g1-small** - $7.75/month (preemptible)

## 🛡️ Compliance Policies

### OPA Policies Included
1. **Storage Policy** (`policy/storagepolicy.rego`)
   - Enforces uniform bucket level access
   
2. **Compute Policy** (`policy/computepolicy.rego`)
   - Enforces preemptible instances
   - Validates cost-effective machine types
   - Checks disk size limits
   - Ensures proper labeling

### Policy Validation
```powershell
# Generate plan and validate policies
terraform plan -out=tfplan
terraform show -json tfplan > tfplan.json

# Install OPA (if needed)
# Download from: https://www.openpolicyagent.org/docs/latest/integration/

# Run policy validation
opa eval -d policy/ -i tfplan.json "data.terraform.compute.policy_summary"
```

## 💡 Best Practices

### Cost Management
1. **Use Preemptible Instances**: 80% cost savings, perfect for dev/test
2. **Stop When Not Needed**: Stopped instances don't incur compute charges
3. **Set Billing Alerts**: Get notified before overspending
4. **Use Sustained Use Discounts**: Automatic discounts for long-running instances
5. **Monitor Resource Usage**: Regular audits prevent waste

### Preemptible Instance Considerations
- **Can be interrupted**: GCP can stop them at any time with 30 seconds notice
- **Maximum 24-hour runtime**: Automatically stopped after 24 hours
- **Perfect for**: Development, testing, batch processing, fault-tolerant applications
- **Not suitable for**: Production databases, critical services requiring high availability

### Security Best Practices
- **No External IP**: Use IAP for secure access
- **Minimal Service Account Permissions**: Follow principle of least privilege
- **Regular Updates**: Keep OS and software updated
- **Network Security**: Use VPC firewall rules appropriately

## 🔍 Troubleshooting

### Common Issues

#### 1. Authentication Errors
```powershell
# Check authentication
gcloud auth list

# Re-authenticate
gcloud auth login

# Set project
gcloud config set project YOUR_PROJECT_ID
```

#### 2. Quota Exceeded
- Check GCP Console quotas
- Request quota increases if needed
- Try different regions/zones

#### 3. Billing Not Enabled
- Enable billing in GCP Console
- Verify payment method is valid

#### 4. Name Conflicts
- Bucket names must be globally unique
- Instance names must be unique within project/zone

### Useful Commands
```powershell
# Check Terraform state
terraform show

# View current configuration
terraform plan

# Import existing resources
terraform import google_compute_instance.cost_optimized_vm projects/PROJECT_ID/zones/ZONE/instances/INSTANCE_NAME

# Clean up everything
terraform destroy
```

## 📈 Scaling Considerations

### When to Scale Up
- CPU utilization consistently > 80%
- Memory pressure indicators
- Application performance degradation

### Scaling Options
1. **Vertical Scaling**: Increase machine type
2. **Horizontal Scaling**: Add more preemptible instances
3. **Auto Scaling**: Use managed instance groups

### Cost-Effective Scaling
```hcl
# Example: Multiple small instances instead of one large
resource "google_compute_instance" "cost_optimized_vm" {
  count = var.instance_count  # Scale horizontally
  name  = "${var.instance_name}-${count.index + 1}"
  # ... rest of configuration
}
```

## 🔗 Additional Resources

- [GCP Always Free Tier](https://cloud.google.com/free/docs/gcp-free-tier)
- [Preemptible VM Instances](https://cloud.google.com/compute/docs/instances/preemptible)
- [GCP Pricing Calculator](https://cloud.google.com/products/calculator)
- [Cost Optimization Best Practices](https://cloud.google.com/architecture/framework/cost-optimization)
- [Terraform Google Provider Docs](https://registry.terraform.io/providers/hashicorp/google/latest/docs)

## 📞 Support

For issues or questions:
1. Check the troubleshooting section above
2. Review GCP documentation
3. Check Terraform provider documentation
4. Use GCP Support (if you have a support plan)