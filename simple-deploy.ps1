# Simple GCP Deployment Script
# Just deploy without complex policies

param(
    [string]$ProjectId = "",
    [string]$BucketName = "",
    [switch]$AutoApprove = $false
)

Write-Host "🚀 Simple GCP Cost-Optimized Deployment" -ForegroundColor Green
Write-Host "=======================================" -ForegroundColor Green

# Get project ID if not provided
if (-not $ProjectId) {
    try {
        $ProjectId = gcloud config get-value project 2>$null
        if ($ProjectId) {
            Write-Host "📋 Using current project: $ProjectId" -ForegroundColor Cyan
        } else {
            $ProjectId = Read-Host "Enter your GCP Project ID"
        }
    } catch {
        $ProjectId = Read-Host "Enter your GCP Project ID"
    }
}

# Set bucket name
if (-not $BucketName) {
    $BucketName = "$ProjectId-simple-bucket-$(Get-Date -Format 'yyyyMMdd-HHmm')"
}

Write-Host "💰 What will be deployed:" -ForegroundColor Yellow
Write-Host "- Preemptible e2-micro VM: ~`$3.50/month" -ForegroundColor White
Write-Host "- 10GB standard disk: ~`$0.40/month" -ForegroundColor White
Write-Host "- Cloud Storage bucket: ~`$0.02/month" -ForegroundColor White
Write-Host "- Total estimated: ~`$3.92/month" -ForegroundColor Green
Write-Host ""

# Create terraform.tfvars
Write-Host "📝 Creating configuration..." -ForegroundColor Cyan
$tfvarsContent = @"
project_id = "$ProjectId"
region = "us-central1"
bucket_name = "$BucketName"
environment = "development"
instance_name = "simple-cost-vm"
machine_type = "e2-micro"
zone = "us-central1-a"
boot_disk_image = "ubuntu-os-cloud/ubuntu-2004-lts"
boot_disk_size = 10
"@

$tfvarsContent | Out-File -FilePath "terraform.tfvars" -Encoding UTF8
Write-Host "✅ Configuration created" -ForegroundColor Green

try {
    # Initialize Terraform
    Write-Host "🔧 Initializing Terraform..." -ForegroundColor Cyan
    terraform init
    if ($LASTEXITCODE -ne 0) { throw "Terraform init failed" }

    # Validate
    Write-Host "✅ Validating configuration..." -ForegroundColor Cyan
    terraform validate
    if ($LASTEXITCODE -ne 0) { throw "Terraform validation failed" }

    # Plan
    Write-Host "📋 Creating deployment plan..." -ForegroundColor Cyan
    terraform plan
    if ($LASTEXITCODE -ne 0) { throw "Terraform plan failed" }

    # Apply
    if (-not $AutoApprove) {
        $response = Read-Host "🤔 Deploy this infrastructure? (y/N)"
        if ($response -notmatch "^[Yy]$") {
            Write-Host "❌ Deployment cancelled" -ForegroundColor Red
            exit 0
        }
    }

    Write-Host "🚀 Deploying infrastructure..." -ForegroundColor Green
    if ($AutoApprove) {
        terraform apply -auto-approve
    } else {
        terraform apply
    }
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host ""
        Write-Host "🎉 Deployment completed successfully!" -ForegroundColor Green
        Write-Host ""
        Write-Host "📊 Resources created:" -ForegroundColor Cyan
        terraform output
        Write-Host ""
        Write-Host "💡 Next steps:" -ForegroundColor Yellow
        Write-Host "- Check GCP Console: https://console.cloud.google.com/compute/" -ForegroundColor White
        Write-Host "- Monitor costs: https://console.cloud.google.com/billing/" -ForegroundColor White
        Write-Host "- Stop VM when not needed: gcloud compute instances stop simple-cost-vm" -ForegroundColor White
        Write-Host ""
        Write-Host "🧹 To destroy later: terraform destroy" -ForegroundColor Gray
    } else {
        throw "Terraform apply failed"
    }

} catch {
    Write-Host "❌ Error: $_" -ForegroundColor Red
    Write-Host ""
    Write-Host "💡 Common fixes:" -ForegroundColor Yellow
    Write-Host "1. Check authentication: gcloud auth list" -ForegroundColor White
    Write-Host "2. Enable APIs: gcloud services enable compute.googleapis.com storage.googleapis.com" -ForegroundColor White
    Write-Host "3. Check billing: https://console.cloud.google.com/billing/" -ForegroundColor White
    exit 1
}