# GCP Cost Monitoring Script
# This script helps monitor and optimize costs for your GCP resources

param(
    [string]$ProjectId = "",
    [switch]$ShowDetailed = $false
)

Write-Host "💰 GCP Cost Monitoring Dashboard" -ForegroundColor Green
Write-Host "=================================" -ForegroundColor Green

# Get project ID from terraform.tfvars if not provided
if (-not $ProjectId -and (Test-Path "terraform.tfvars")) {
    $tfvarsContent = Get-Content "terraform.tfvars" -Raw
    if ($tfvarsContent -match 'project_id\s*=\s*"([^"]+)"') {
        $ProjectId = $matches[1]
        Write-Host "📋 Using project ID from terraform.tfvars: $ProjectId" -ForegroundColor Cyan
    }
}

if (-not $ProjectId) {
    Write-Host "❌ Please provide project ID or ensure terraform.tfvars contains project_id" -ForegroundColor Red
    exit 1
}

try {
    # Check if gcloud is installed and authenticated
    Write-Host "🔐 Checking GCP authentication..." -ForegroundColor Cyan
    $authStatus = gcloud auth list --filter="status:ACTIVE" --format="value(account)" 2>$null
    if (-not $authStatus) {
        Write-Host "❌ No active GCP authentication found. Please run: gcloud auth login" -ForegroundColor Red
        exit 1
    }
    Write-Host "✅ Authenticated as: $authStatus" -ForegroundColor Green

    # Set the project
    gcloud config set project $ProjectId 2>$null

    Write-Host ""
    Write-Host "🏗️  CURRENT INFRASTRUCTURE STATUS" -ForegroundColor Yellow
    Write-Host "==================================" -ForegroundColor Yellow

    # Check Compute Engine instances
    Write-Host "🖥️  Compute Engine Instances:" -ForegroundColor Cyan
    $instances = gcloud compute instances list --format="table(name,zone,machineType.basename(),status,scheduling.preemptible)" 2>$null
    if ($instances) {
        Write-Host $instances
    } else {
        Write-Host "   No compute instances found" -ForegroundColor Gray
    }

    Write-Host ""
    
    # Check Storage buckets
    Write-Host "🪣 Cloud Storage Buckets:" -ForegroundColor Cyan
    $buckets = gcloud storage buckets list --format="table(name,location,storageClass)" 2>$null
    if ($buckets) {
        Write-Host $buckets
    } else {
        Write-Host "   No storage buckets found" -ForegroundColor Gray
    }

    Write-Host ""
    Write-Host "💡 COST OPTIMIZATION RECOMMENDATIONS" -ForegroundColor Green
    Write-Host "====================================" -ForegroundColor Green

    # Check for non-preemptible instances
    $nonPreemptibleInstances = gcloud compute instances list --filter="scheduling.preemptible=false" --format="value(name)" 2>$null
    if ($nonPreemptibleInstances) {
        Write-Host "⚠️  Non-preemptible instances found:" -ForegroundColor Yellow
        foreach ($instance in $nonPreemptibleInstances) {
            Write-Host "   - $instance (Consider making preemptible for 80% savings)" -ForegroundColor Yellow
        }
    } else {
        Write-Host "✅ All instances are preemptible (cost-optimized)" -ForegroundColor Green
    }

    # Check for running instances
    $runningInstances = gcloud compute instances list --filter="status=RUNNING" --format="value(name)" 2>$null
    if ($runningInstances) {
        Write-Host ""
        Write-Host "🔥 Currently running instances:" -ForegroundColor Red
        foreach ($instance in $runningInstances) {
            Write-Host "   - $instance (accruing charges)" -ForegroundColor Red
        }
        Write-Host "   💡 Stop instances when not needed: gcloud compute instances stop INSTANCE_NAME" -ForegroundColor Cyan
    }

    Write-Host ""
    Write-Host "📊 COST ESTIMATION (Approximate)" -ForegroundColor Yellow
    Write-Host "=================================" -ForegroundColor Yellow

    # Count instances by type
    $e2MicroCount = (gcloud compute instances list --filter="machineType:e2-micro" --format="value(name)" 2>$null | Measure-Object).Count
    $runningE2MicroCount = (gcloud compute instances list --filter="machineType:e2-micro AND status=RUNNING" --format="value(name)" 2>$null | Measure-Object).Count

    if ($e2MicroCount -gt 0) {
        $monthlyCost = $runningE2MicroCount * 3.50
        $diskCost = $e2MicroCount * 0.40
        $totalCost = $monthlyCost + $diskCost

        Write-Host "💰 Current monthly estimate:" -ForegroundColor Green
        Write-Host "   - Running e2-micro instances: $runningE2MicroCount × `$3.50 = `$$monthlyCost" -ForegroundColor White
        Write-Host "   - Boot disks (10GB each): $e2MicroCount × `$0.40 = `$$diskCost" -ForegroundColor White
        Write-Host "   - Total estimated: `$$totalCost/month" -ForegroundColor Green
        Write-Host ""
        Write-Host "   Note: This assumes preemptible instances running 24/7" -ForegroundColor Gray
        Write-Host "   Actual costs will be lower due to preemptible interruptions" -ForegroundColor Gray
    }

    Write-Host ""
    Write-Host "🎯 OPTIMIZATION ACTIONS" -ForegroundColor Cyan
    Write-Host "=======================" -ForegroundColor Cyan
    Write-Host "1. Stop unused instances: gcloud compute instances stop INSTANCE_NAME" -ForegroundColor White
    Write-Host "2. Delete unused instances: gcloud compute instances delete INSTANCE_NAME" -ForegroundColor White
    Write-Host "3. Set up billing alerts in GCP Console" -ForegroundColor White
    Write-Host "4. Use sustained use discounts for long-running workloads" -ForegroundColor White
    Write-Host "5. Consider committed use discounts for predictable workloads" -ForegroundColor White

    if ($ShowDetailed) {
        Write-Host ""
        Write-Host "📈 DETAILED RESOURCE INFORMATION" -ForegroundColor Magenta
        Write-Host "=================================" -ForegroundColor Magenta
        
        # Detailed instance information
        $detailedInstances = gcloud compute instances list --format="table(name,zone,machineType,status,scheduling.preemptible,disks[].diskSizeGb.list():label=DISK_SIZE_GB)" 2>$null
        if ($detailedInstances) {
            Write-Host $detailedInstances
        }
    }

} catch {
    Write-Host "❌ Error occurred: $_" -ForegroundColor Red
    Write-Host "💡 Make sure you have gcloud CLI installed and are authenticated" -ForegroundColor Yellow
    Write-Host "   Install: https://cloud.google.com/sdk/docs/install" -ForegroundColor Yellow
    Write-Host "   Authenticate: gcloud auth login" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "🔗 Useful Links:" -ForegroundColor Cyan
Write-Host "- GCP Console: https://console.cloud.google.com/" -ForegroundColor White
Write-Host "- Billing Dashboard: https://console.cloud.google.com/billing/" -ForegroundColor White
Write-Host "- Cost Calculator: https://cloud.google.com/products/calculator/" -ForegroundColor White