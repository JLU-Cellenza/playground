# GitHub Actions Setup for Terraform Workflows

## Prerequisites

Before running any workflows, you must set up GitHub secrets and verify Azure infrastructure.

### 1. Create Azure Service Principal

```bash
# Replace with your actual subscription ID
$subscriptionId = "YOUR-SUBSCRIPTION-ID"

# Create service principal with Contributor role
az ad sp create-for-rbac `
  --name "sp-github-playground-terraform" `
  --role Contributor `
  --scopes /subscriptions/$subscriptionId `
  --sdk-auth
```

This will output JSON that looks like:
```json
{
  "clientId": "00000000-0000-0000-0000-000000000000",
  "clientSecret": "your-secret-here",
  "subscriptionId": "00000000-0000-0000-0000-000000000000",
  "tenantId": "00000000-0000-0000-0000-000000000000",
  "activeDirectoryEndpointUrl": "https://login.microsoftonline.com",
  "resourceManagerEndpointUrl": "https://management.azure.com/",
  "activeDirectoryGraphResourceId": "https://graph.windows.net/",
  "sqlManagementEndpointUrl": "https://management.core.windows.net:8443/",
  "galleryEndpointUrl": "https://gallery.azure.com/",
  "managementEndpointUrl": "https://management.core.windows.net/"
}
```

### 2. Set Up GitHub Secrets

Go to: **GitHub Repository → Settings → Secrets and variables → Actions**

Create these secrets:

#### Required Secrets:

**`AZURE_CREDENTIALS`** - Paste the entire JSON from step 1

**`TERRAFORM_APPLY`** - Set to `true` to allow terraform apply in workflows
```
true
```

**`TERRAFORM_DESTROY`** - Set to `true` to allow terraform destroy workflows
```
true
```

### 3. Set Up Azure Infrastructure for Terraform State

```bash
# Variables
$resourceGroupName = "rg-common-iac-01"
$storageAccountName = "stocommoniac01"
$location = "francecentral"
$containerName = "terraform"

# Create resource group
az group create -n $resourceGroupName -l $location

# Create storage account
az storage account create `
  -n $storageAccountName `
  -g $resourceGroupName `
  -l $location `
  --sku Standard_LRS

# Create container for state files
az storage container create `
  -n $containerName `
  --account-name $storageAccountName
```

### 4. Verify Project Environments

Each project needs environment directories with tfvars files:

**project-simple-ipaas:**
- ✅ `env/dev/` - Development environment
  - `dev.tfvars` - Variables for dev
  - `backend.tfvars` - Backend configuration

**project-demo-ipaas-by-ai:**
- ✅ `env/dev/` - Development environment
  - `dev.tfvars` - Variables for dev
  - `backend.tfvars` - Backend configuration
- ✅ `env/prd/` - Production environment
  - `prd.tfvars` - Variables for prod
  - `backend.tfvars` - Backend configuration

---

## Running Workflows

### Via GitHub Actions UI

1. Go to **Actions** tab
2. Select workflow (Terraform CI, Terraform Deploy, or Terraform Destroy)
3. Click **Run workflow**
4. Select parameters:
   - **Project**: Choose project (project-simple-ipaas or project-demo-ipaas-by-ai)
   - **Environment**: Choose environment (dev, prd)
   - **Confirm**: For deploy/destroy, type required text

### Terraform CI Workflow

**Purpose**: Validate and plan Terraform changes

**Trigger**: Manual dispatch or PR to main

**Parameters**:
- `project_name` - Which project to validate
- `environment` - Which environment (dev/prd)

**Output**: Plan artifact uploaded for review

### Terraform Deploy Workflow

**Purpose**: Apply Terraform changes

**Trigger**: Manual dispatch only

**Parameters**:
- `project_name` - Which project to deploy
- `environment` - Which environment (dev/prd)
- `confirm` - Type "YES" to confirm

**Requirements**:
- `TERRAFORM_APPLY` secret must be `true`

### Terraform Destroy Workflow

**Purpose**: Destroy infrastructure (IRREVERSIBLE)

**Trigger**: Manual dispatch only

**Parameters**:
- `project_name` - Which project to destroy
- `environment` - Which environment (dev/prd)
- `confirm` - Type "DESTROY" to confirm

**Requirements**:
- `TERRAFORM_DESTROY` secret must be `true`
- Shows destruction plan before confirming

---

## Troubleshooting

### Workflow fails with: "Project directory does not exist"

**Cause**: Trying to deploy to prd environment that doesn't exist

**Fix**: For `project-simple-ipaas`, only `dev` environment exists.
Create `env/prd/` directory with tfvars if needed:

```bash
mkdir -p project-simple-ipaas/env/prd
cp project-simple-ipaas/env/dev/dev.tfvars project-simple-ipaas/env/prd/prd.tfvars
cp project-simple-ipaas/env/dev/backend.tfvars project-simple-ipaas/env/prd/backend.tfvars
# Then edit prd.tfvars for production settings
```

### Workflow fails with: "Authentication failed"

**Cause**: `AZURE_CREDENTIALS` secret not set or invalid

**Fix**: 
1. Go to GitHub Settings → Secrets and variables → Actions
2. Create `AZURE_CREDENTIALS` secret with JSON from `az ad sp create-for-rbac`
3. Re-run workflow

### Workflow fails with: "Failed to initialize backend"

**Cause**: Azure storage account for state doesn't exist

**Fix**: Run Azure infrastructure setup commands (see section 3 above)

### Workflow stuck in "Plan" step

**Cause**: May need additional variables or backend initialization

**Fix**: Check GitHub Actions logs for detailed error messages

---

## Security Best Practices

1. **Limit Service Principal Scope**
   - Consider restricting to specific resource groups instead of entire subscription
   - Use resource group scope: `--scopes /subscriptions/$subscriptionId/resourceGroups/rg-my-app`

2. **Enable Managed Identity** (future enhancement)
   - Use GitHub OIDC federation instead of storing credentials
   - More secure than storing secrets

3. **Backend Security**
   - Enable private endpoints on storage account
   - Restrict network access
   - Enable encryption at rest and in transit
   - Use SAS token with expiration dates if manual access needed

4. **Secret Rotation**
   - Regularly rotate service principal credentials
   - Monitor GitHub secret access logs

5. **Approval Gates**
   - Deploy/Destroy workflows require explicit confirmation
   - Never use auto-apply in production

