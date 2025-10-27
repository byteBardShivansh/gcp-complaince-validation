# GCP Cost-Optimized Compute Instance Deployment Script (PowerShell)
# This script deploys the most cost-effective GCP compute instance

param(
    [switch]$AutoApprove = $false
)

Write-Host "🚀 GCP Cost-Optimized Compute Instance Deployment" -ForegroundColor Green
Write-Host "==================================================" -ForegroundColor Green

# Check if terraform.tfvars exists
if (-not (Test-Path "terraform.tfvars")) {
    Write-Host "⚠️  Creating terraform.tfvars from example..." -ForegroundColor Yellow
    Copy-Item "terraform.tfvars.example" "terraform.tfvars"
    Write-Host "✅ Please edit terraform.tfvars with your actual GCP project ID before proceeding" -ForegroundColor Red
    Write-Host "   Required fields: project_id, bucket_name" -ForegroundColor Red
    exit 1
}

try {
    # Initialize Terraform
    Write-Host "📦 Initializing Terraform..." -ForegroundColor Cyan
    terraform init
    if ($LASTEXITCODE -ne 0) { throw "Terraform init failed" }

    # Format check
    Write-Host "🔍 Checking Terraform formatting..." -ForegroundColor Cyan
    terraform fmt -check
    if ($LASTEXITCODE -ne 0) { 
        Write-Host "⚠️  Formatting issues detected. Running terraform fmt..." -ForegroundColor Yellow
        terraform fmt
    }

    # Validate configuration
    Write-Host "✅ Validating Terraform configuration..." -ForegroundColor Cyan
    terraform validate
    if ($LASTEXITCODE -ne 0) { throw "Terraform validation failed" }

    # Create execution plan
    Write-Host "📋 Creating Terraform execution plan..." -ForegroundColor Cyan
    terraform plan -out=tfplan
    if ($LASTEXITCODE -ne 0) { throw "Terraform plan failed" }

    # Show cost optimization summary
    Write-Host ""
    Write-Host "💰 COST OPTIMIZATION FEATURES:" -ForegroundColor Green
    Write-Host "===============================" -ForegroundColor Green
    Write-Host "✅ Preemptible Instance: Up to 80% cost savings" -ForegroundColor Green
    Write-Host "✅ Machine Type: e2-micro (Always Free tier eligible)" -ForegroundColor Green
    Write-Host "✅ Boot Disk: 10GB Standard Persistent Disk (minimum cost)" -ForegroundColor Green
    Write-Host "✅ Operating System: Ubuntu 20.04 LTS (free)" -ForegroundColor Green
    Write-Host "✅ Network: No external IP (reduces costs)" -ForegroundColor Green
    Write-Host "✅ Auto-delete boot disk on instance termination" -ForegroundColor Green
    Write-Host ""

    # Estimated monthly cost (approximate)
    Write-Host "💵 ESTIMATED MONTHLY COST:" -ForegroundColor Yellow
    Write-Host "==========================" -ForegroundColor Yellow
    Write-Host "Preemptible e2-micro: ~`$3.50/month (if running 24/7)" -ForegroundColor Yellow
    Write-Host "Boot Disk (10GB standard): ~`$0.40/month" -ForegroundColor Yellow
    Write-Host "Total estimated: ~`$3.90/month" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Note: Actual costs may vary based on usage patterns and region" -ForegroundColor Gray
    Write-Host "Preemptible instances can be interrupted, providing maximum savings" -ForegroundColor Gray
    Write-Host ""

    # Apply with confirmation
    if (-not $AutoApprove) {
        $response = Read-Host "🤔 Do you want to apply this cost-optimized configuration? (y/N)"
        if ($response -notmatch "^[Yy]$") {
            Write-Host "❌ Deployment cancelled" -ForegroundColor Red
            Remove-Item "tfplan" -ErrorAction SilentlyContinue
            exit 0
        }
    }

    Write-Host "🏗️  Applying Terraform configuration..." -ForegroundColor Cyan
    if ($AutoApprove) {
        terraform apply -auto-approve tfplan
    } else {
        terraform apply tfplan
    }
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host ""
        Write-Host "🎉 Deployment completed successfully!" -ForegroundColor Green
        Write-Host ""
        Write-Host "📊 To view your resources:" -ForegroundColor Cyan
        Write-Host "terraform show" -ForegroundColor White
        Write-Host ""
        Write-Host "🧹 To destroy resources when done:" -ForegroundColor Cyan
        Write-Host "terraform destroy" -ForegroundColor White
        Write-Host ""
        Write-Host "💡 Cost Monitoring Tips:" -ForegroundColor Cyan
        Write-Host "- Set up billing alerts in GCP Console" -ForegroundColor White
        Write-Host "- Monitor usage in Cloud Console" -ForegroundColor White
        Write-Host "- Use 'gcloud compute instances describe' to check status" -ForegroundColor White
        Write-Host "- Remember: Preemptible instances can be stopped by GCP at any time" -ForegroundColor White
    } else {
        throw "Terraform apply failed"
    }

} catch {
    Write-Host "❌ Error: $_" -ForegroundColor Red
    exit 1
} finally {
    # Clean up plan file
    Remove-Item "tfplan" -ErrorAction SilentlyContinue
}