# GitHub Actions Deployment Setup Guide

## Overview

This guide provides step-by-step instructions for setting up GitHub Actions CI/CD workflows to deploy the Simple iPaaS platform to Azure using Terraform.

## Prerequisites

Before setting up the workflows, ensure you have:

- [ ] GitHub repository created for this project
- [ ] Azure subscription with appropriate permissions
- [ ] Azure CLI installed locally (`az login`)
- [ ] Terraform >= 1.5.0 installed locally (for initial setup)
- [ ] Azure Storage Account for Terraform state (backend)

---

## Step 1: Provision Azure Service Principal

Create a Service Principal for GitHub Actions to authenticate with Azure:

```bash
# Login to Azure
az login

# Set your subscription
az account set --subscription "<subscription-id>"

# Create Service Principal with Contributor role
az ad sp create-for-rbac \
  --name "sp-github-simple-ipaas" \
  --role Contributor \
  --scopes /subscriptions/<subscription-id> \
  --sdk-auth
```

**Save the JSON output** - you'll need these values for GitHub Secrets:
- `clientId` → `AZURE_CLIENT_ID`
- `clientSecret` → `AZURE_CLIENT_SECRET`
- `subscriptionId` → `AZURE_SUBSCRIPTION_ID`
- `tenantId` → `AZURE_TENANT_ID`

---

## Step 2: Create Terraform State Backend

Set up Azure Storage Account for storing Terraform state:

```bash
# Variables
RESOURCE_GROUP_NAME="rg-terraform-state"
STORAGE_ACCOUNT_NAME="sttfstate<uniqueid>"  # Must be globally unique
CONTAINER_NAME="tfstate"
LOCATION="francecentral"

# Create resource group
az group create --name $RESOURCE_GROUP_NAME --location $LOCATION

# Create storage account
az storage account create \
  --name $STORAGE_ACCOUNT_NAME \
  --resource-group $RESOURCE_GROUP_NAME \
  --location $LOCATION \
  --sku Standard_LRS \
  --encryption-services blob

# Create blob container
az storage container create \
  --name $CONTAINER_NAME \
  --account-name $STORAGE_ACCOUNT_NAME
```

**Save these values** for GitHub Secrets:
- `RESOURCE_GROUP_NAME` → `TF_BACKEND_RESOURCE_GROUP`
- `STORAGE_ACCOUNT_NAME` → `TF_BACKEND_STORAGE_ACCOUNT`
- `CONTAINER_NAME` → `TF_BACKEND_CONTAINER`

---

## Step 3: Configure GitHub Secrets

Navigate to your GitHub repository: **Settings → Secrets and variables → Actions**

### Required Secrets

Add the following repository secrets:

| Secret Name | Description | Example Value |
|-------------|-------------|---------------|
| `AZURE_CLIENT_ID` | Service Principal Client ID | `a1b2c3d4-...` |
| `AZURE_CLIENT_SECRET` | Service Principal Secret | `your-secret-value` |
| `AZURE_SUBSCRIPTION_ID` | Azure Subscription ID | `12345678-...` |
| `AZURE_TENANT_ID` | Azure AD Tenant ID | `87654321-...` |
| `TF_BACKEND_RESOURCE_GROUP` | Backend resource group | `rg-terraform-state` |
| `TF_BACKEND_STORAGE_ACCOUNT` | Backend storage account | `sttfstate<uniqueid>` |
| `TF_BACKEND_CONTAINER` | Backend container name | `tfstate` |
| `TF_BACKEND_KEY` | State file key (dev) | `simple-ipaas-dev.tfstate` |

### Adding Secrets via GitHub UI

1. Go to **Repository → Settings → Secrets and variables → Actions**
2. Click **New repository secret**
3. Enter **Name** and **Value**
4. Click **Add secret**
5. Repeat for all secrets

### Adding Secrets via GitHub CLI

```bash
# Install GitHub CLI if needed: https://cli.github.com/

gh secret set AZURE_CLIENT_ID --body "<value>"
gh secret set AZURE_CLIENT_SECRET --body "<value>"
gh secret set AZURE_SUBSCRIPTION_ID --body "<value>"
gh secret set AZURE_TENANT_ID --body "<value>"
gh secret set TF_BACKEND_RESOURCE_GROUP --body "rg-terraform-state"
gh secret set TF_BACKEND_STORAGE_ACCOUNT --body "sttfstate<uniqueid>"
gh secret set TF_BACKEND_CONTAINER --body "tfstate"
gh secret set TF_BACKEND_KEY --body "simple-ipaas-dev.tfstate"
```

---

## Step 4: Configure GitHub Environments (Optional but Recommended)

Set up environment protection rules for deployment approval:

1. Go to **Repository → Settings → Environments**
2. Create environments:
   - `dev` (for development deployments)
   - `prd` (for production deployments)
   - `dev-destroy` (for dev destruction approval)
   - `prd-destroy` (for prod destruction approval)

### Environment Configuration

For **prd** and **prd-destroy** environments:
- Enable **Required reviewers**: Add team members who must approve deployments
- Enable **Wait timer**: Optional delay before deployment (e.g., 5 minutes)
- Configure **Deployment branches**: Limit to `main` branch only

---

## Step 5: Prepare Terraform Variables

### Development Environment

1. Copy example files:
   ```bash
   cd env/dev
   cp backend.tfvars.example backend.tfvars
   cp dev.tfvars.example dev.tfvars
   ```

2. Update `dev.tfvars` with your values:
   ```hcl
   environment   = "dev"
   organization  = "cellenza"     # Your organization name
   project_name  = "simpleipaas"
   location      = "francecentral" # Azure region
   
   owner        = "platform-team@example.com"
   cost_center  = "IT-INTEGRATION"
   
   # Service configurations
   servicebus_sku        = "Standard"
   servicebus_queue_name = "inbound"
   
   keyvault_sku                        = "standard"
   keyvault_soft_delete_retention_days = 7
   keyvault_purge_protection           = false
   
   storage_account_tier     = "Standard"
   storage_replication_type = "LRS"
   storage_containers       = ["config", "workflows"]
   
   logic_app_sku = "WS1"
   ```

3. Commit and push:
   ```bash
   git add env/dev/dev.tfvars
   git commit -m "Configure dev environment variables"
   git push
   ```

> **Note**: Do NOT commit `backend.tfvars` or actual secrets. Use GitHub Secrets for sensitive values.

---

## Workflows Overview

### 1. `terraform-ci.yaml` - PR Validation

**Triggers:** Pull requests to `main` or `develop`

**Actions:**
- ✅ Terraform format check (`terraform fmt`)
- ✅ Terraform validation (`terraform validate`)
- ✅ Terraform plan (creates plan artifact)
- ✅ Security scanning (TFLint + Checkov)
- ✅ PR comment with plan summary

**Usage:**
1. Create a feature branch
2. Make Terraform changes
3. Open a pull request
4. Workflow runs automatically and posts plan to PR

---

### 2. `deploy.yaml` - Infrastructure Deployment

**Triggers:**
- Push to `main` branch
- Manual trigger via `workflow_dispatch`

**Actions:**
- 🚀 Terraform init with remote backend
- 📋 Terraform plan
- ✅ Terraform apply (if changes detected)
- 📊 Outputs saved as artifacts

**Usage:**

**Automatic (on merge to main):**
```bash
git checkout main
git merge feature-branch
git push
# Workflow runs automatically
```

**Manual deployment:**
1. Go to **Actions → Deploy Infrastructure**
2. Click **Run workflow**
3. Select environment (`dev` or `prd`)
4. Click **Run workflow**

---

### 3. `destroy.yaml` - Infrastructure Teardown

**Triggers:** Manual only (`workflow_dispatch`)

**Actions:**
- ⚠️ Confirmation validation (must type "destroy")
- 📋 Terraform plan -destroy
- ⏸️ Manual approval gate (environment protection)
- 🔥 Terraform destroy

**Usage:**
1. Go to **Actions → Destroy Infrastructure**
2. Click **Run workflow**
3. Select environment to destroy
4. Type `destroy` in confirmation field
5. Click **Run workflow**
6. Wait for approval (if configured)
7. Infrastructure destroyed after approval

---

## Initial Deployment

### First-Time Setup

1. **Push workflows to repository:**
   ```bash
   git add .github/workflows/
   git commit -m "Add GitHub Actions CI/CD workflows"
   git push
   ```

2. **Manual deployment (recommended for first deployment):**
   - Go to **Actions → Deploy Infrastructure**
   - Select `dev` environment
   - Click **Run workflow**
   - Monitor execution in GitHub Actions UI

3. **Verify deployment:**
   - Check workflow logs for successful apply
   - Download artifacts to view outputs
   - Verify resources in Azure Portal

---

## Workflow Best Practices

### State Management
- ✅ Remote state stored in Azure Storage
- ✅ State locking enabled automatically
- ✅ State file encrypted at rest

### Security
- ✅ Secrets masked in workflow logs
- ✅ Service Principal with least privilege
- ✅ Security scanning on every PR
- ✅ Manual approval for production

### Concurrency
- ✅ Only one deployment per environment at a time
- ✅ Prevent race conditions with state locking
- ✅ Cancel pending runs when new changes pushed (CI only)

### Artifacts
- ✅ Terraform plans saved for 30 days (CI)
- ✅ Outputs saved for 90 days (Deploy)
- ✅ Destroy plans saved for 7 days

---

## Troubleshooting

### Workflow Fails with "Backend Initialization Error"

**Solution:** Verify backend secrets are correct:
```bash
az storage account show \
  --name <TF_BACKEND_STORAGE_ACCOUNT> \
  --resource-group <TF_BACKEND_RESOURCE_GROUP>
```

### "Authentication Failed" Errors

**Solution:** Verify Service Principal credentials:
```bash
az login --service-principal \
  --username <AZURE_CLIENT_ID> \
  --password <AZURE_CLIENT_SECRET> \
  --tenant <AZURE_TENANT_ID>

az account show
```

### "State Lock" Errors

**Solution:** Release the state lock:
```bash
cd env/dev
terraform init -backend-config=backend.tfvars
terraform force-unlock <lock-id>
```

### Plan Shows Unexpected Changes

**Solution:** Check for drift:
```bash
cd env/dev
terraform init -backend-config=backend.tfvars
terraform plan -var-file=dev.tfvars
```

---

## Multi-Environment Deployment

### Adding Production Environment

1. **Create production tfvars:**
   ```bash
   cd env/prd
   cp prd.tfvars.example prd.tfvars
   # Edit prd.tfvars with production values
   ```

2. **Add production state key secret:**
   ```bash
   gh secret set TF_BACKEND_KEY_PRD --body "simple-ipaas-prd.tfstate"
   ```

3. **Deploy to production:**
   - Go to **Actions → Deploy Infrastructure**
   - Select `prd` environment
   - Approve deployment (if environment protection enabled)

---

## Monitoring and Notifications

### Adding Slack Notifications (Optional)

Add to each workflow job:

```yaml
- name: Notify Slack
  if: always()
  uses: 8398a7/action-slack@v3
  with:
    status: ${{ job.status }}
    webhook_url: ${{ secrets.SLACK_WEBHOOK_URL }}
```

### Viewing Deployment History

- **GitHub UI:** Actions → All workflows → Select workflow run
- **Terraform Outputs:** Actions → Workflow run → Artifacts → Download

---

## Security Considerations

### Secrets Rotation

Rotate Service Principal credentials regularly:

```bash
# Generate new credentials
az ad sp credential reset --name sp-github-simple-ipaas

# Update GitHub secrets with new values
gh secret set AZURE_CLIENT_SECRET --body "<new-secret>"
```

### Audit Trail

All deployments are logged:
- GitHub Actions run history (90 days retention)
- Azure Activity Log (90 days retention)
- Terraform state file history (versioned in storage)

---

## Cost Optimization

### Resource Cleanup

**Development environment:** Destroy when not in use:
```bash
# Via GitHub Actions
Actions → Destroy Infrastructure → Select 'dev' → Type 'destroy'
```

**Estimated monthly cost (dev):**
- Service Bus Standard: ~$10/month
- Logic App WS1: ~$200/month
- Storage Account: ~$5/month
- Key Vault: ~$0.03/month
- **Total: ~$215/month**

---

## Next Steps

- [ ] Set up branch protection rules on `main`
- [ ] Configure environment protection for `prd`
- [ ] Enable Dependabot for Terraform provider updates
- [ ] Set up cost alerts in Azure
- [ ] Configure drift detection schedule (optional)
- [ ] Add custom Terraform modules as needed

---

## Support

For issues or questions:
- Review workflow logs in GitHub Actions
- Check Terraform state in Azure Storage
- Consult [env/dev/RUNBOOK.md](env/dev/RUNBOOK.md) for manual operations

---

**Version:** 1.0  
**Last Updated:** November 12, 2025  
**Terraform Version:** >= 1.5.0  
**GitHub Actions:** Latest
