# GitHub Secrets Setup Guide

This document explains how to set up the required GitHub secrets for the cost-optimized GCP infrastructure deployment.

## Required Secrets

### 1. GCP_SA_KEY
**Description**: Google Cloud Service Account JSON key
**Purpose**: Authenticate GitHub Actions with Google Cloud Platform

**Steps to create:**
1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Navigate to "IAM & Admin" → "Service Accounts"
3. Click "Create Service Account"
4. Name: `github-actions-terraform`
5. Description: `Service account for GitHub Actions Terraform deployments`
6. Click "Create and Continue"
7. Add roles:
   - `Compute Admin` (for VM management)
   - `Storage Admin` (for bucket management)
   - `Service Account User`
   - `Project IAM Admin` (if managing IAM)
8. Click "Done"
9. Click on the created service account
10. Go to "Keys" tab → "Add Key" → "Create new key"
11. Choose "JSON" format and download
12. Copy the entire JSON content

**In GitHub:**
1. Go to your repository
2. Settings → Secrets and variables → Actions
3. Click "New repository secret"
4. Name: `GCP_SA_KEY`
5. Value: Paste the entire JSON content
6. Click "Add secret"

### 2. GCP_PROJECT_ID
**Description**: Your Google Cloud Project ID
**Purpose**: Specify which GCP project to deploy resources to

**Steps:**
1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. In the top bar, note your Project ID (not the project name)
3. Copy the Project ID

**In GitHub:**
1. Repository → Settings → Secrets and variables → Actions
2. Click "New repository secret"
3. Name: `GCP_PROJECT_ID`
4. Value: Your project ID (e.g., `my-gcp-project-123456`)
5. Click "Add secret"

### 3. GCP_BUCKET_NAME (Optional)
**Description**: Base name for Cloud Storage bucket
**Purpose**: Create uniquely named storage buckets

**Note**: If not provided, the workflow will use `{PROJECT_ID}-compliance-bucket-{RUN_NUMBER}`

**In GitHub:**
1. Repository → Settings → Secrets and variables → Actions
2. Click "New repository secret"
3. Name: `GCP_BUCKET_NAME`
4. Value: Base name for bucket (e.g., `my-company-compliance`)
5. Click "Add secret"

## Verification

After setting up secrets, you can verify them by:

1. Going to your repository
2. Settings → Secrets and variables → Actions
3. You should see:
   - ✅ `GCP_SA_KEY`
   - ✅ `GCP_PROJECT_ID`
   - ✅ `GCP_BUCKET_NAME` (optional)

## Security Best Practices

### Service Account Permissions
- Use principle of least privilege
- Only grant necessary roles
- Regularly audit permissions
- Consider using Workload Identity Federation for enhanced security

### Secret Management
- Never commit secrets to repository
- Use environment-specific secrets for different deployments
- Rotate service account keys regularly
- Monitor secret usage in audit logs

## Testing Secrets

Create a simple test workflow to verify secrets work:

```yaml
name: Test GCP Authentication
on:
  workflow_dispatch:

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
    - name: Authenticate to Google Cloud
      uses: google-github-actions/auth@v1
      with:
        credentials_json: ${{ secrets.GCP_SA_KEY }}
    
    - name: Set up Cloud SDK
      uses: google-github-actions/setup-gcloud@v1
    
    - name: Test Authentication
      run: |
        echo "Project ID: ${{ secrets.GCP_PROJECT_ID }}"
        gcloud config list
        gcloud projects describe ${{ secrets.GCP_PROJECT_ID }}
```

## Troubleshooting

### Common Issues

1. **Invalid JSON Key**
   - Ensure the entire JSON is copied correctly
   - Check for extra spaces or line breaks
   - Verify the service account exists and is enabled

2. **Insufficient Permissions**
   - Verify service account has required roles
   - Check if APIs are enabled (Compute Engine, Cloud Storage)
   - Ensure billing is enabled on the project

3. **Project ID Issues**
   - Use Project ID, not Project Name
   - Verify the project exists and you have access
   - Check for typos in the project ID

4. **Bucket Name Conflicts**
   - Bucket names must be globally unique
   - Use a unique prefix or suffix
   - Consider using project ID + timestamp

## Environment-Specific Secrets

For multiple environments (dev/staging/prod), consider using environment-specific secrets:

- `GCP_SA_KEY_DEV`
- `GCP_SA_KEY_STAGING` 
- `GCP_SA_KEY_PROD`
- `GCP_PROJECT_ID_DEV`
- `GCP_PROJECT_ID_STAGING`
- `GCP_PROJECT_ID_PROD`

## Additional Resources

- [GitHub Secrets Documentation](https://docs.github.com/en/actions/security-guides/encrypted-secrets)
- [Google Cloud Service Accounts](https://cloud.google.com/iam/docs/service-accounts)
- [GitHub Actions for Google Cloud](https://github.com/google-github-actions)