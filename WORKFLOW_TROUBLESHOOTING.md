# Workflow Troubleshooting Guide

## Common Issues & Fixes

### Issue 1: Authentication Failures
**Error**: `Error: AZURERM_CLIENT_ID or ARM_CLIENT_ID environment variable is not set.`

**Cause**: Missing GitHub Secrets

**Fix**: Set these secrets in GitHub Settings → Secrets and variables → Actions:
- `AZURE_CREDENTIALS` - JSON output from `az ad sp create-for-rbac --sdk-auth`

```bash
# Generate service principal credentials
az ad sp create-for-rbac \
  --name "sp-github-playground-ci" \
  --role Contributor \
  --scopes /subscriptions/<YOUR-SUBSCRIPTION-ID> \
  --sdk-auth
```

Store the entire JSON output as `AZURE_CREDENTIALS` secret.

---

### Issue 2: Backend State Initialization Fails
**Error**: `Error: Failed to get existing workspaces: InvalidResourceGroupName`

**Cause**: Azure storage account for state doesn't exist or credentials can't access it

**Fix**: Ensure Azure storage account exists:
```bash
# Create resource group
az group create -n rg-common-iac-01 -l francecentral

# Create storage account
az storage account create \
  -n stocommoniac01 \
  -g rg-common-iac-01 \
  -l francecentral \
  --sku Standard_LRS

# Create container
az storage container create \
  -n terraform \
  --account-name stocommoniac01
```

---

### Issue 3: Workflow Validation Fails - Project Not Found
**Error**: `Error: Project directory project-simple-ipaas/env/dev does not exist`

**Cause**: Wrong project name selected or incorrect directory structure

**Fix**: Verify project exists:
```bash
ls -la project-simple-ipaas/env/dev/
# Should show: backend.tfvars, dev.tfvars, main.tf, terraform.tf, variables.tf, etc.
```

---

### Issue 4: Terraform Plan Fails - Variable Missing
**Error**: `Error: Missing required variable "X"`

**Cause**: `.tfvars` file missing required variable definition

**Fix**: Check `project-simple-ipaas/env/dev/dev.tfvars` has all required variables

---

### Issue 5: Module Source Not Found
**Error**: `Module not installed: This module is not yet installed`

**Cause**: Running terraform validate without `terraform init` (expected in CI)
This is normal - the workflow runs `terraform init` before validation

---

## Testing Locally

To test workflows locally before pushing:

```bash
# Navigate to project environment
cd project-simple-ipaas/env/dev

# Initialize (requires Azure auth)
terraform init -backend-config=backend.tfvars

# Format check
terraform fmt -check -recursive

# Validate
terraform validate

# Plan
terraform plan -var-file=dev.tfvars
```

---

## Workflow Execution Flow

1. **Validate Project Directory** - Checks if `{PROJECT_NAME}/env/{ENVIRONMENT}` exists
2. **Setup Terraform** - Installs Terraform 1.5.0
3. **Azure Login** - Authenticates using `AZURE_CREDENTIALS` secret
4. **Get Subscription ID** - Retrieves Azure subscription from authenticated session
5. **Terraform Init** - Initializes backend using `backend.tfvars` and Azure auth
6. **Terraform Validate** - Checks syntax and configuration
7. **Terraform Plan** - Creates deployment plan using `{ENVIRONMENT}.tfvars`
8. **Upload Artifact** - Saves plan file for review

---

## Required Files per Project

For `project-simple-ipaas/env/dev/`:
- ✅ `backend.tfvars` - Backend configuration (resource group, storage account, container, key)
- ✅ `dev.tfvars` - Environment variables (organization, project_name, location, etc.)
- ✅ `terraform.tf` - Provider and backend configuration
- ✅ `variables.tf` - Variable definitions
- ✅ `main.tf` - Resource definitions
- ✅ `locals.tf` - Local values
- ✅ `outputs.tf` - Output definitions
- ✅ Modules in `../../modules/` (storage, keyvault, servicebus, logicapp)

---

## Next Steps

1. **Set up GitHub Secrets** (see Issue 1 above)
2. **Verify Azure infrastructure** (see Issue 2 above)
3. **Run workflow manually** via Actions → Select workflow → Run workflow
4. **Monitor execution** and check logs for specific errors
5. **Share error message** if still failing

