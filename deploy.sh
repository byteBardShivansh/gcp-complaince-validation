#!/bin/bash

# GCP Cost-Optimized Compute Instance Deployment Script
# This script deploys the most cost-effective GCP compute instance

set -e

echo "🚀 GCP Cost-Optimized Compute Instance Deployment"
echo "=================================================="

# Check if terraform.tfvars exists
if [ ! -f "terraform.tfvars" ]; then
    echo "⚠️  Creating terraform.tfvars from example..."
    cp terraform.tfvars.example terraform.tfvars
    echo "✅ Please edit terraform.tfvars with your actual GCP project ID before proceeding"
    echo "   Required fields: project_id, bucket_name"
    exit 1
fi

# Initialize Terraform
echo "📦 Initializing Terraform..."
terraform init

# Format check
echo "🔍 Checking Terraform formatting..."
terraform fmt -check

# Validate configuration
echo "✅ Validating Terraform configuration..."
terraform validate

# Create execution plan
echo "📋 Creating Terraform execution plan..."
terraform plan -out=tfplan

# Show cost optimization summary
echo ""
echo "💰 COST OPTIMIZATION FEATURES:"
echo "==============================="
echo "✅ Preemptible Instance: Up to 80% cost savings"
echo "✅ Machine Type: e2-micro (Always Free tier eligible)"
echo "✅ Boot Disk: 10GB Standard Persistent Disk (minimum cost)"
echo "✅ Operating System: Ubuntu 20.04 LTS (free)"
echo "✅ Network: No external IP (reduces costs)"
echo "✅ Auto-delete boot disk on instance termination"
echo ""

# Estimated monthly cost (approximate)
echo "💵 ESTIMATED MONTHLY COST:"
echo "=========================="
echo "Preemptible e2-micro: ~$3.50/month (if running 24/7)"
echo "Boot Disk (10GB standard): ~$0.40/month"
echo "Total estimated: ~$3.90/month"
echo ""
echo "Note: Actual costs may vary based on usage patterns and region"
echo "Preemptible instances can be interrupted, providing maximum savings"
echo ""

# Apply with confirmation
read -p "🤔 Do you want to apply this cost-optimized configuration? (y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "🏗️  Applying Terraform configuration..."
    terraform apply tfplan
    
    echo ""
    echo "🎉 Deployment completed successfully!"
    echo ""
    echo "📊 To view your resources:"
    echo "terraform show"
    echo ""
    echo "🧹 To destroy resources when done:"
    echo "terraform destroy"
    echo ""
    echo "💡 Cost Monitoring Tips:"
    echo "- Set up billing alerts in GCP Console"
    echo "- Monitor usage in Cloud Console"
    echo "- Use 'gcloud compute instances describe' to check status"
    echo "- Remember: Preemptible instances can be stopped by GCP at any time"
else
    echo "❌ Deployment cancelled"
    rm -f tfplan
fi