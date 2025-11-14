# Deployment Runbook - Project iPaaS 3 (Dev Environment)

This runbook provides step-by-step instructions for deploying the iPaaS 3 platform to the dev environment.

## Prerequisites

1. **Azure CLI** installed and authenticated
2. **Terraform** v1.5.0 or later installed
3. **Azure Subscription** access (subscription ID configured in GitHub Actions)
4. **Backend Storage** account exists: `stocommoniac01` in `rg-common-iac-01`

## Architecture Overview

The platform consists of:
- **1 API Management** (StandardV2) - Separate deployment
- **1 Service Bus** (Standard) with `inbound-queue`
- **5 Logic Apps Standard** on 2 App Service Plans (WS1)
  - Plan 1: Logic Apps 01, 02, 03
  - Plan 2: Logic Apps 04, 05
- **1 Key Vault** (shared secrets)
- **1 Storage Account** (platform config tables)
- **5 Storage Accounts** (one per Logic App)
- **Log Analytics + Application Insights** (observability)

## Deployment Order

⚠️ **CRITICAL:** Deploy in this exact order:

1. **Main Platform** (env/dev/) - Creates RG, all services except APIM
2. **APIM** (apim/) - Deploys APIM in existing RG (25-30 min)

---

## Step 1: Deploy Main Platform

### 1.1 Initialize Terraform Backend

```powershell
cd project-ipaas3/env/dev
terraform init -backend-config=backend.tfvars
```

**Expected output:**
```
Initializing the backend...
Successfully configured the backend "azurerm"!
```

### 1.2 Validate Configuration

```powershell
terraform validate
```

**Expected output:**
```
Success! The configuration is valid.
```

### 1.3 Format Code

```powershell
terraform fmt -recursive
```

### 1.4 Plan Deployment

```powershell
# Set Azure credentials (GitHub Actions does this automatically)
$env:ARM_SUBSCRIPTION_ID = "3314da4a-7f83-4380-9d92-7b96c6fa78c6"
$env:ARM_CLIENT_ID = "<service-principal-client-id>"
$env:ARM_CLIENT_SECRET = "<service-principal-secret>"
$env:ARM_TENANT_ID = "<tenant-id>"

terraform plan -var-file=dev.tfvars -out=plan.tfplan
```

**Review the plan carefully:**
- ✅ 1 Resource Group
- ✅ 1 Log Analytics Workspace
- ✅ 1 Application Insights
- ✅ 1 Key Vault
- ✅ 1 Service Bus Namespace + 1 Queue
- ✅ 6 Storage Accounts (1 config + 5 Logic Apps)
- ✅ 2 App Service Plans
- ✅ 5 Logic Apps Standard
- ✅ RBAC role assignments (Service Bus, Key Vault)
- ✅ 2 Key Vault secrets

**Total expected resources:** ~40-50 resources

### 1.5 Apply Configuration

```powershell
terraform apply plan.tfplan
```

**Estimated time:** 8-12 minutes

**Monitor deployment:**
- Service Bus: 2-3 minutes
- Storage Accounts: 2-3 minutes
- Logic Apps: 5-8 minutes
- Key Vault: 1-2 minutes

### 1.6 Verify Deployment

```powershell
# List all resources in the resource group
az resource list --resource-group rg-dev-clz-ipaas3-01 --output table

# Verify Service Bus queue exists
az servicebus queue show --resource-group rg-dev-clz-ipaas3-01 `
  --namespace-name sb-dev-clz-ipaas3-01 `
  --name inbound-queue

# Verify Key Vault secrets
az keyvault secret list --vault-name kv-dev-clz-ipaas3-01 --output table
```

---

## Step 2: Deploy APIM (Separate Deployment)

⚠️ **IMPORTANT:** Deploy main platform FIRST. APIM requires existing RG and Log Analytics.

### 2.1 Navigate to APIM Directory

```powershell
cd ../../apim
```

### 2.2 Initialize APIM Backend

```powershell
terraform init -backend-config=backend.tfvars
```

**Note:** Uses same backend storage but different state file (`project-ipaas3-dev-apim.tfstate`)

### 2.3 Plan APIM Deployment

```powershell
terraform plan -var-file=dev.tfvars -out=plan.tfplan
```

**Review:**
- ✅ 1 API Management (StandardV2_1)
- ✅ Data sources for existing RG and Log Analytics

### 2.4 Apply APIM Configuration

```powershell
terraform apply plan.tfplan
```

**⏱️ Estimated time:** 25-30 minutes (APIM provisioning is slow)

**Monitor progress:**
```powershell
# Check APIM provisioning state
az apim show --name apim-dev-clz-ipaas3-01 `
  --resource-group rg-dev-clz-ipaas3-01 `
  --query provisioningState -o tsv
```

**Provisioning states:**
- `Creating` → APIM is being created
- `Succeeded` → APIM is ready

### 2.5 Verify APIM Deployment

```powershell
# Get APIM details
az apim show --name apim-dev-clz-ipaas3-01 `
  --resource-group rg-dev-clz-ipaas3-01

# Test gateway URL
$gateway = az apim show --name apim-dev-clz-ipaas3-01 `
  --resource-group rg-dev-clz-ipaas3-01 `
  --query gatewayUrl -o tsv
Write-Host "Gateway URL: $gateway"

# Test developer portal URL
$portal = az apim show --name apim-dev-clz-ipaas3-01 `
  --resource-group rg-dev-clz-ipaas3-01 `
  --query developerPortalUrl -o tsv
Write-Host "Developer Portal: $portal"
```

---

## Step 3: Post-Deployment Validation

### 3.1 Verify All Resources

```powershell
# Count resources in resource group
az resource list --resource-group rg-dev-clz-ipaas3-01 --query "length(@)"

# Expected: ~45-55 resources (main platform + APIM)
```

### 3.2 Test Service Bus Connectivity

```powershell
# Send test message to inbound-queue
az servicebus queue send --resource-group rg-dev-clz-ipaas3-01 `
  --namespace-name sb-dev-clz-ipaas3-01 `
  --name inbound-queue `
  --body "Test message from deployment validation"
```

### 3.3 Verify Logic Apps

```powershell
# List all Logic Apps
az logicapp list --resource-group rg-dev-clz-ipaas3-01 --output table

# Check Logic App runtime status
az logicapp show --name logic-dev-clz-ipaas3-01 `
  --resource-group rg-dev-clz-ipaas3-01 `
  --query state -o tsv
```

### 3.4 Verify Key Vault Access

```powershell
# Test Key Vault secret retrieval
az keyvault secret show --vault-name kv-dev-clz-ipaas3-01 `
  --name servicebus-connection-string `
  --query value -o tsv
```

### 3.5 Check Monitoring

```powershell
# Verify Application Insights is receiving telemetry
az monitor app-insights component show --app appi-dev-clz-ipaas3-01 `
  --resource-group rg-dev-clz-ipaas3-01
```

---

## Rollback Procedures

### Rollback Main Platform

```powershell
cd project-ipaas3/env/dev

# Option 1: Destroy all resources
terraform destroy -var-file=dev.tfvars

# Option 2: Revert to previous state
terraform state pull > backup.tfstate
# Restore from backup if needed
```

### Rollback APIM Only

```powershell
cd project-ipaas3/apim

# Destroy APIM only (leaves main platform intact)
terraform destroy -var-file=dev.tfvars
```

---

## Troubleshooting

### Issue: Backend Storage Not Found

**Error:** `Error: Failed to get existing workspaces: storage account not found`

**Solution:**
```powershell
# Verify backend storage exists
az storage account show --name stocommoniac01 --resource-group rg-common-iac-01

# If missing, create it
az group create --name rg-common-iac-01 --location francecentral
az storage account create --name stocommoniac01 `
  --resource-group rg-common-iac-01 `
  --location francecentral `
  --sku Standard_LRS
az storage container create --name terraform --account-name stocommoniac01
```

### Issue: Key Vault Access Denied (HTTP 403)

**Error:** `StatusCode=403 Forbidden`

**Cause:** Terraform service principal missing "Key Vault Secrets Officer" role

**Solution:** The main.tf already includes automatic RBAC assignment. Wait 60 seconds for role propagation and retry:
```powershell
terraform apply plan.tfplan
```

### Issue: Logic App Name Already Exists

**Error:** `A logic app with the same name already exists`

**Solution:** Delete the existing Logic App or change the instance suffix in dev.tfvars

### Issue: APIM Deployment Times Out

**Symptom:** APIM deployment exceeds 30 minutes

**Solution:**
1. Check Azure Portal for APIM provisioning state
2. If state is "Creating", wait up to 45 minutes
3. If state is "Failed", destroy and redeploy:
   ```powershell
   cd project-ipaas3/apim
   terraform destroy -var-file=dev.tfvars
   terraform apply -var-file=dev.tfvars
   ```

---

## Output Values

After successful deployment, retrieve important values:

```powershell
# Main platform outputs
cd project-ipaas3/env/dev
terraform output

# APIM outputs
cd ../../apim
terraform output
```

**Key outputs:**
- `keyvault_uri` - Key Vault URI for secret references
- `servicebus_namespace_fqdn` - Service Bus FQDN for managed identity connections
- `logicapp_XX_name` - Logic App names for workflow deployment
- `gateway_url` - APIM gateway URL for API calls

---

## Maintenance

### Update Resources

```powershell
# Main platform
cd project-ipaas3/env/dev
terraform plan -var-file=dev.tfvars -out=plan.tfplan
terraform apply plan.tfplan

# APIM
cd ../../apim
terraform plan -var-file=dev.tfvars -out=plan.tfplan
terraform apply plan.tfplan
```

### Add New Logic App

1. Add new storage module in `env/dev/main.tf`
2. Add new Logic App module
3. Add RBAC assignments for Service Bus and Key Vault
4. Update numeric suffix (e.g., `06`, `07`)
5. Run `terraform plan` and `terraform apply`

---

## Security Notes

- **Secrets:** Never commit `.tfvars` files with sensitive data
- **State Files:** Remote state in Azure Storage with access keys
- **RBAC:** All services use managed identities (no service principals)
- **Key Vault:** RBAC-based authorization (no access policies)
- **Service Bus:** Managed identity connections (no connection strings in code)

---

## Support

For issues or questions:
1. Check troubleshooting section above
2. Review Terraform plan output for errors
3. Check Azure Portal for resource provisioning state
4. Review `build-ais-platform.instructions.md` for detailed standards
