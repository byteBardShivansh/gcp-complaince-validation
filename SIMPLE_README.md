# Simple GCP Cost-Optimized Deployment

## Quick Start (Local)

1. **Authenticate with GCP:**
   ```powershell
   gcloud auth login
   gcloud config set project YOUR_PROJECT_ID
   ```

2. **Deploy locally:**
   ```powershell
   .\simple-deploy.ps1
   ```

That's it! 🎉

## Quick Start (GitHub Actions)

1. **Set up GitHub secrets:**
   - `GCP_SA_KEY` - Your service account JSON key
   - `GCP_PROJECT_ID` - Your GCP project ID

2. **Push to main branch** - deployment happens automatically!

## What Gets Deployed

- ✅ **Preemptible e2-micro VM** (~$3.50/month)
- ✅ **10GB standard disk** (~$0.40/month)  
- ✅ **Cloud Storage bucket** (~$0.02/month)
- 💰 **Total: ~$3.92/month**

## Simple Commands

```powershell
# Deploy
.\simple-deploy.ps1 -ProjectId "your-project" -AutoApprove

# Check what's running
gcloud compute instances list

# Stop VM (saves money)
gcloud compute instances stop simple-cost-vm

# Start VM
gcloud compute instances start simple-cost-vm

# Destroy everything
terraform destroy
```

## No Complex Policies

This version skips the complex OPA policy validation and just deploys cost-optimized infrastructure directly. Perfect for getting started quickly!

## Need Help?

1. **Authentication issues:** Run `gcloud auth login`
2. **Billing issues:** Enable billing in GCP Console
3. **API issues:** Run `gcloud services enable compute.googleapis.com storage.googleapis.com`

Simple and effective! 🚀