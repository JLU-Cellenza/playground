# Deployment Runbook - Simple iPaaS Platform (Development)

## Overview

This runbook provides step-by-step instructions for deploying the Simple iPaaS platform to the development environment.

## Prerequisites

### Required Tools
- Azure CLI (latest version)
- Terraform >= 1.5.0
- PowerShell or Bash terminal

### Required Permissions
- Azure subscription contributor access
- Ability to create resource groups
- Ability to create service principals (for CI/CD)

### Required Information
- Azure Subscription ID
- Target Azure region (e.g., francecentral, westeurope)
- Organization name
- Project name
- Owner email
- Cost center code

## Pre-Flight Checklist

Before running Terraform, complete these checks:

### 1. Azure Authentication
```powershell
# Login to Azure
az login

# Set the correct subscription
az account set --subscription "<your-subscription-id>"

# Verify current subscription
az account show
```

### 2. Create Terraform State Storage (One-Time Setup)

If you don't have a storage account for Terraform state:

```powershell
# Create resource group for Terraform state
az group create --name "rg-terraform-state" --location "francecentral"

# Create storage account (name must be globally unique)
az storage account create `
  --name "sttfstatemyorg01" `
  --resource-group "rg-terraform-state" `
  --location "francecentral" `
  --sku "Standard_LRS" `
  --encryption-services blob

# Create blob container
az storage container create `
  --name "tfstate" `
  --account-name "sttfstatemyorg01"
```

### 3. Configure Backend

Copy the example backend configuration and update with your values:

```powershell
cd env/dev
cp backend.tfvars.example backend.tfvars

# Edit backend.tfvars with your actual storage account details
# DO NOT commit backend.tfvars to git
```

### 4. Configure Environment Variables

Copy the example tfvars and customize:

```powershell
cp dev.tfvars.example dev.tfvars

# Edit dev.tfvars with your values:
# - organization
# - project_name
# - location
# - owner
# - cost_center
```

**Important:** Add `*.tfvars` (except `*.tfvars.example`) to `.gitignore`

### 5. Set Subscription ID Environment Variable

```powershell
# PowerShell
$env:ARM_SUBSCRIPTION_ID = "<your-subscription-id>"

# Linux/Mac
export ARM_SUBSCRIPTION_ID="<your-subscription-id>"
```

### 6. Verify Naming Conventions

Before proceeding, verify that resource names will be globally unique:

```powershell
# Check if Key Vault name is available (max 24 chars, alphanumeric + hyphens)
az keyvault list --query "[?name=='kv-dev-myorg-simpleipaas-01']"

# Check if Storage Account name is available (max 24 chars, lowercase alphanumeric only)
az storage account check-name --name "stdevmyorgsimpleipaas01"
```

**Note:** Adjust the `organization` and `project_name` values in `dev.tfvars` if names are taken.

For this setup, using `cellenza` as organization, the resource names will be:
- Key Vault: `kv-dev-cellenza-simpleipaas-01`
- Storage Account: `stdevcellenzasimpleipaas01`

## Deployment Steps

### Step 1: Initialize Terraform

```powershell
cd env/dev

# Initialize with backend configuration
terraform init -backend-config=backend.tfvars
```

Expected output: "Terraform has been successfully initialized!"

### Step 2: Format and Validate

```powershell
# Format code
terraform fmt -recursive

# Validate configuration
terraform validate
```

### Step 3: Plan Deployment

```powershell
# Generate execution plan
terraform plan -var-file=dev.tfvars -out=dev.tfplan

# Review the plan output carefully
# Verify:
# - Resource names follow naming convention
# - All tags are present
# - No unexpected changes
# - Costs are within budget
```

**Review Checklist:**
- [ ] Resource names are globally unique
- [ ] All resources have correct tags (environment, project, owner, cost_center, created_by)
- [ ] Security settings are appropriate (soft delete, HTTPS-only, etc.)
- [ ] No sensitive values in plan output (should be marked as sensitive)

### Step 4: Apply Configuration

```powershell
# Apply the plan
terraform apply dev.tfplan
```

This will create:
- Resource group
- Storage Account with containers
- Key Vault with RBAC
- Service Bus namespace with inbound queue
- Logic App Standard with App Service Plan
- RBAC role assignments
- Key Vault secrets (connection strings)

Expected duration: 5-10 minutes

### Step 5: Verify Deployment

```powershell
# List created resources
az resource list --resource-group "rg-dev-cellenza-simpleipaas" --output table

# Verify Service Bus queue
az servicebus queue show `
  --resource-group "rg-dev-cellenza-simpleipaas" `
  --namespace-name "svb-dev-cellenza-simpleipaas-01" `
  --name "inbound"

# Verify Key Vault secrets
az keyvault secret list --vault-name "kv-dev-cellenza-simpleipaas-01" --output table

# Verify Logic App identity
az logicapp show `
  --name "loa-dev-cellenza-simpleipaas-01" `
  --resource-group "rg-dev-myorg-simpleipaas" `
  --query "identity.principalId"
```

### Step 6: Retrieve Outputs

```powershell
# View all outputs
terraform output

# Get specific output
terraform output keyvault_uri
terraform output logic_app_name
```

## Post-Deployment Configuration

### Configure Logic App Workflows

1. Open Azure Portal
2. Navigate to Logic App: `loa-dev-myorg-simpleipaas-01`
3. Create workflows using the Logic App Designer
4. Use Managed Identity for Service Bus and Key Vault connections

### Test Service Bus Integration

```powershell
# Send test message to inbound queue
az servicebus queue message send `
  --resource-group "rg-dev-myorg-simpleipaas" `
  --namespace-name "svb-dev-myorg-simpleipaas-01" `
  --queue-name "inbound" `
  --body "Test message from CLI"
```

### Grant Human Access to Key Vault

To access Key Vault secrets from Portal/CLI:

```powershell
# Get your user principal ID
$userPrincipalId = az ad signed-in-user show --query id -o tsv

# Grant Key Vault Secrets Officer role
az role assignment create `
  --role "Key Vault Secrets Officer" `
  --assignee $userPrincipalId `
  --scope "/subscriptions/<subscription-id>/resourceGroups/rg-dev-myorg-simpleipaas/providers/Microsoft.KeyVault/vaults/kv-dev-myorg-simpleipaas-01"
```

## Rollback Procedure

If you need to rollback changes:

```powershell
# Option 1: Destroy specific resources (manual)
terraform destroy -target=module.logicapp -var-file=dev.tfvars

# Option 2: Destroy entire environment
terraform destroy -var-file=dev.tfvars

# Option 3: Revert to previous state (if state is versioned)
az storage blob download `
  --container-name tfstate `
  --name simple-ipaas-dev.tfstate `
  --version-id <previous-version-id> `
  --file terraform.tfstate
```

## Troubleshooting

### Issue: "Name already exists"

**Cause:** Resource name collision (Key Vault, Storage Account, or Service Bus namespace)

**Solution:**
1. Check existing resources: `az resource list --name "<name>"`
2. Update `organization` or `project_name` in `dev.tfvars`
3. Re-run `terraform plan`

### Issue: "Insufficient permissions"

**Cause:** Missing Azure RBAC permissions

**Solution:**
```powershell
# Verify subscription access
az role assignment list --assignee $(az ad signed-in-user show --query id -o tsv) --subscription <subscription-id>
```

Request Contributor role if missing.

### Issue: "Backend initialization failed"

**Cause:** Storage account or container doesn't exist

**Solution:**
1. Verify storage account exists: `az storage account show --name "sttfstatemyorg01"`
2. Verify container exists: `az storage container show --name tfstate --account-name "sttfstatemyorg01"`
3. Create missing resources (see Pre-Flight Checklist)

### Issue: "Key Vault access denied"

**Cause:** User doesn't have RBAC role on Key Vault

**Solution:**
```powershell
# Grant yourself access (see Post-Deployment Configuration)
az role assignment create --role "Key Vault Secrets Officer" --assignee <your-principal-id> --scope <keyvault-id>
```

## Maintenance

### Update Resources

```powershell
# Make changes to tfvars or module code
# Re-run plan and apply
terraform plan -var-file=dev.tfvars -out=dev.tfplan
terraform apply dev.tfplan
```

### View State

```powershell
# List resources in state
terraform state list

# Show specific resource
terraform state show module.servicebus.azurerm_servicebus_namespace.this
```

### Refresh State

```powershell
# Sync state with Azure
terraform refresh -var-file=dev.tfvars
```

## Security Reminders

- [ ] Never commit `*.tfvars` (except examples) to git
- [ ] Never commit `*.tfstate` files to git
- [ ] Never commit `backend.tfvars` to git
- [ ] Rotate Service Bus and Storage connection strings regularly
- [ ] Enable purge protection on Key Vault for production
- [ ] Use GRS or ZRS storage replication for production
- [ ] Use Premium SKUs for production workloads

## Support Contacts

- **Platform Team:** platform-team@example.com
- **Azure Support:** [Azure Portal](https://portal.azure.com) → Help + Support

## Change Log

| Date | Author | Change |
|------|--------|--------|
| 2025-11-12 | AI Assistant | Initial runbook creation |
