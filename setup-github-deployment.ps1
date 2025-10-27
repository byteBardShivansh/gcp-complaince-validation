# Quick Setup Script for GCP Cost-Optimized Infrastructure
# This script helps you prepare for GitHub Actions deployment

param(
    [string]$ProjectId = "",
    [string]$ServiceAccountName = "github-actions-terraform",
    [switch]$CreateServiceAccount = $false,
    [switch]$ShowSecretsSetup = $false
)

Write-Host "🚀 GCP Cost-Optimized Infrastructure Setup" -ForegroundColor Green
Write-Host "==========================================" -ForegroundColor Green

# Check if gcloud is installed
try {
    $gcloudVersion = gcloud version 2>$null
    if (-not $gcloudVersion) {
        throw "gcloud not found"
    }
    Write-Host "✅ Google Cloud SDK is installed" -ForegroundColor Green
} catch {
    Write-Host "❌ Google Cloud SDK not found. Please install it first:" -ForegroundColor Red
    Write-Host "   https://cloud.google.com/sdk/docs/install" -ForegroundColor Yellow
    exit 1
}

# Get current project if not specified
if (-not $ProjectId) {
    try {
        $ProjectId = gcloud config get-value project 2>$null
        if ($ProjectId) {
            Write-Host "📋 Using current project: $ProjectId" -ForegroundColor Cyan
        } else {
            Write-Host "❌ No project specified. Please set with: gcloud config set project PROJECT_ID" -ForegroundColor Red
            exit 1
        }
    } catch {
        Write-Host "❌ Unable to determine current project. Please specify -ProjectId parameter" -ForegroundColor Red
        exit 1
    }
}

Write-Host ""
Write-Host "🔧 PROJECT SETUP CHECKLIST" -ForegroundColor Yellow
Write-Host "===========================" -ForegroundColor Yellow

# Check authentication
try {
    $currentAccount = gcloud auth list --filter="status:ACTIVE" --format="value(account)" 2>$null
    if ($currentAccount) {
        Write-Host "✅ Authenticated as: $currentAccount" -ForegroundColor Green
    } else {
        Write-Host "❌ Not authenticated. Please run: gcloud auth login" -ForegroundColor Red
        exit 1
    }
} catch {
    Write-Host "❌ Authentication check failed" -ForegroundColor Red
    exit 1
}

# Check if billing is enabled
Write-Host "💳 Checking billing status..." -ForegroundColor Cyan
try {
    $billingAccount = gcloud billing projects describe $ProjectId --format="value(billingAccountName)" 2>$null
    if ($billingAccount) {
        Write-Host "✅ Billing is enabled" -ForegroundColor Green
    } else {
        Write-Host "⚠️  Billing may not be enabled. Please enable billing in the Console:" -ForegroundColor Yellow
        Write-Host "   https://console.cloud.google.com/billing/linkedaccount?project=$ProjectId" -ForegroundColor Yellow
    }
} catch {
    Write-Host "⚠️  Unable to check billing status" -ForegroundColor Yellow
}

# Check required APIs
Write-Host "🔌 Checking required APIs..." -ForegroundColor Cyan
$requiredApis = @(
    "compute.googleapis.com",
    "storage.googleapis.com",
    "iam.googleapis.com"
)

foreach ($api in $requiredApis) {
    try {
        $apiStatus = gcloud services list --enabled --filter="name:$api" --format="value(name)" 2>$null
        if ($apiStatus) {
            Write-Host "✅ $api is enabled" -ForegroundColor Green
        } else {
            Write-Host "⚠️  $api is not enabled. Enabling..." -ForegroundColor Yellow
            gcloud services enable $api 2>$null
            Write-Host "✅ $api enabled" -ForegroundColor Green
        }
    } catch {
        Write-Host "⚠️  Unable to check $api status" -ForegroundColor Yellow
    }
}

# Service Account Management
Write-Host ""
Write-Host "🔐 SERVICE ACCOUNT SETUP" -ForegroundColor Yellow
Write-Host "=========================" -ForegroundColor Yellow

$serviceAccountEmail = "$ServiceAccountName@$ProjectId.iam.gserviceaccount.com"

# Check if service account exists
try {
    $existingAccount = gcloud iam service-accounts describe $serviceAccountEmail 2>$null
    if ($existingAccount) {
        Write-Host "✅ Service account '$ServiceAccountName' already exists" -ForegroundColor Green
    } else {
        if ($CreateServiceAccount) {
            Write-Host "🔨 Creating service account '$ServiceAccountName'..." -ForegroundColor Cyan
            gcloud iam service-accounts create $ServiceAccountName --description="Service account for GitHub Actions Terraform deployments" --display-name="GitHub Actions Terraform" 2>$null
            Write-Host "✅ Service account created" -ForegroundColor Green
        } else {
            Write-Host "❌ Service account '$ServiceAccountName' does not exist" -ForegroundColor Red
            Write-Host "   Run with -CreateServiceAccount to create it" -ForegroundColor Yellow
            Write-Host "   Or create manually: gcloud iam service-accounts create $ServiceAccountName" -ForegroundColor Yellow
        }
    }
} catch {
    Write-Host "❌ Error checking service account" -ForegroundColor Red
}

# Assign required roles
if ($CreateServiceAccount -or $existingAccount) {
    Write-Host "🛡️  Assigning required roles..." -ForegroundColor Cyan
    $requiredRoles = @(
        "roles/compute.admin",
        "roles/storage.admin",
        "roles/iam.serviceAccountUser"
    )
    
    foreach ($role in $requiredRoles) {
        try {
            gcloud projects add-iam-policy-binding $ProjectId --member="serviceAccount:$serviceAccountEmail" --role="$role" --quiet 2>$null
            Write-Host "✅ Assigned $role" -ForegroundColor Green
        } catch {
            Write-Host "⚠️  Failed to assign $role" -ForegroundColor Yellow
        }
    }
}

# Generate service account key
Write-Host ""
Write-Host "🔑 SERVICE ACCOUNT KEY" -ForegroundColor Yellow
Write-Host "======================" -ForegroundColor Yellow

$keyFileName = "$ServiceAccountName-key.json"

if (Test-Path $keyFileName) {
    Write-Host "⚠️  Key file '$keyFileName' already exists" -ForegroundColor Yellow
    $overwrite = Read-Host "Overwrite existing key? (y/N)"
    if ($overwrite -notmatch "^[Yy]$") {
        Write-Host "Skipping key generation" -ForegroundColor Gray
    } else {
        Remove-Item $keyFileName -Force
    }
}

if (-not (Test-Path $keyFileName)) {
    try {
        Write-Host "🔨 Generating service account key..." -ForegroundColor Cyan
        gcloud iam service-accounts keys create $keyFileName --iam-account=$serviceAccountEmail 2>$null
        Write-Host "✅ Service account key saved to: $keyFileName" -ForegroundColor Green
        Write-Host "⚠️  IMPORTANT: Keep this key secure and never commit it to version control!" -ForegroundColor Red
    } catch {
        Write-Host "❌ Failed to generate service account key" -ForegroundColor Red
    }
}

# GitHub Secrets Setup Instructions
Write-Host ""
Write-Host "🐙 GITHUB SECRETS SETUP" -ForegroundColor Yellow
Write-Host "========================" -ForegroundColor Yellow

if (Test-Path $keyFileName) {
    $keyContent = Get-Content $keyFileName -Raw
    
    Write-Host "📋 GitHub Secrets to create:" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "1. GCP_SA_KEY" -ForegroundColor White
    Write-Host "   Value: (Copy the content from $keyFileName)" -ForegroundColor Gray
    Write-Host ""
    Write-Host "2. GCP_PROJECT_ID" -ForegroundColor White
    Write-Host "   Value: $ProjectId" -ForegroundColor Gray
    Write-Host ""
    Write-Host "3. GCP_BUCKET_NAME (optional)" -ForegroundColor White
    Write-Host "   Value: $ProjectId-compliance-bucket" -ForegroundColor Gray
    Write-Host ""
    
    if ($ShowSecretsSetup) {
        Write-Host "📄 GCP_SA_KEY Content:" -ForegroundColor Yellow
        Write-Host "======================" -ForegroundColor Yellow
        Write-Host $keyContent -ForegroundColor Gray
        Write-Host ""
    }
}

Write-Host "🔗 NEXT STEPS" -ForegroundColor Green
Write-Host "=============" -ForegroundColor Green
Write-Host "1. Go to your GitHub repository" -ForegroundColor White
Write-Host "2. Settings → Secrets and variables → Actions" -ForegroundColor White
Write-Host "3. Create the required secrets (see GITHUB_SECRETS_SETUP.md)" -ForegroundColor White
Write-Host "4. Push your code to trigger the workflow" -ForegroundColor White
Write-Host "5. Monitor deployment in Actions tab" -ForegroundColor White
Write-Host ""
Write-Host "💰 Expected Monthly Cost: ~`$3.92" -ForegroundColor Green
Write-Host "📊 Monitor costs: https://console.cloud.google.com/billing/" -ForegroundColor Cyan
Write-Host ""
Write-Host "📚 Documentation:" -ForegroundColor Cyan
Write-Host "- DEPLOYMENT_GUIDE.md - Comprehensive deployment guide" -ForegroundColor White
Write-Host "- GITHUB_SECRETS_SETUP.md - GitHub secrets setup instructions" -ForegroundColor White
Write-Host ""

# Clean up key file prompt
if (Test-Path $keyFileName) {
    $cleanup = Read-Host "🧹 Delete the service account key file? (recommended after setting up GitHub secrets) (y/N)"
    if ($cleanup -match "^[Yy]$") {
        Remove-Item $keyFileName -Force
        Write-Host "✅ Key file deleted" -ForegroundColor Green
    } else {
        Write-Host "⚠️  Remember to delete '$keyFileName' after setting up GitHub secrets!" -ForegroundColor Yellow
    }
}