# Quick Start Guide - Project iPaaS 3

Get your Azure Integration Services platform running in 30 minutes (excluding APIM deployment).

## Prerequisites Checklist

- [ ] Azure CLI installed (`az --version`)
- [ ] Terraform 1.5.0+ installed (`terraform version`)
- [ ] Azure account authenticated (`az login`)
- [ ] Contributor access to Azure subscription
- [ ] Backend storage exists: `stocommoniac01` in `rg-common-iac-01`

## 🚀 Fast Track Deployment

### Step 1: Clone and Navigate (30 seconds)

```powershell
cd c:\Workspace\playground\project-ipaas3
```

### Step 2: Deploy Main Platform (10 minutes)

```powershell
# Navigate to dev environment
cd env\dev

# Initialize Terraform
terraform init -backend-config=backend.tfvars

# Review what will be created
terraform plan -var-file=dev.tfvars

# Deploy
terraform apply -var-file=dev.tfvars -auto-approve
```

**What gets deployed:**
- ✅ Resource Group
- ✅ Log Analytics + App Insights
- ✅ Key Vault (with RBAC)
- ✅ Service Bus (with `inbound-queue`)
- ✅ 6 Storage Accounts (1 config + 5 Logic Apps)
- ✅ 2 App Service Plans (WS1)
- ✅ 5 Logic Apps Standard
- ✅ RBAC role assignments
- ✅ Key Vault secrets

**Time:** 8-12 minutes

### Step 3: Verify Main Platform (1 minute)

```powershell
# List all deployed resources
az resource list --resource-group rg-dev-clz-ipaas3-01 --output table

# Check Service Bus queue
az servicebus queue show `
  --resource-group rg-dev-clz-ipaas3-01 `
  --namespace-name sb-dev-clz-ipaas3-01 `
  --name inbound-queue

# Check Key Vault secrets
az keyvault secret list --vault-name kv-dev-clz-ipaas3-01 --output table
```

### Step 4: Deploy APIM (30 minutes)

```powershell
# Navigate to APIM directory
cd ..\..\apim

# Initialize
terraform init -backend-config=backend.tfvars

# Review
terraform plan -var-file=dev.tfvars

# Deploy (this takes 25-30 minutes - go get coffee ☕)
terraform apply -var-file=dev.tfvars -auto-approve
```

**What gets deployed:**
- ✅ API Management (StandardV2_1)

**Time:** 25-30 minutes

### Step 5: Verify APIM (1 minute)

```powershell
# Check APIM status
az apim show `
  --name apim-dev-clz-ipaas3-01 `
  --resource-group rg-dev-clz-ipaas3-01 `
  --query "{Name:name, Status:provisioningState, Gateway:gatewayUrl}" `
  --output table

# Get all important URLs
terraform output
```

## 🎯 What You Now Have

### Integration Platform
- **API Gateway**: `https://apim-dev-clz-ipaas3-01.azure-api.net`
- **Developer Portal**: Available via APIM outputs
- **Service Bus**: Central message broker with managed identity access
- **5 Logic Apps**: Ready for workflow deployment

### Secure Configuration
- **Key Vault**: `kv-dev-clz-ipaas3-01` (all secrets centralized)
- **Managed Identities**: Enabled on all Logic Apps
- **RBAC**: Automatic role assignments for secure access

### Monitoring
- **Log Analytics**: `la-dev-clz-ipaas3-01`
- **Application Insights**: Integrated with all Logic Apps

## 🧪 Test Your Platform

### Test 1: Send Message to Service Bus

```powershell
# Send a test message
az servicebus queue send `
  --resource-group rg-dev-clz-ipaas3-01 `
  --namespace-name sb-dev-clz-ipaas3-01 `
  --name inbound-queue `
  --body "Test message from Quick Start"

# Peek at the message
az servicebus queue peek `
  --resource-group rg-dev-clz-ipaas3-01 `
  --namespace-name sb-dev-clz-ipaas3-01 `
  --name inbound-queue
```

### Test 2: Verify Logic App Status

```powershell
# List all Logic Apps
az logicapp list `
  --resource-group rg-dev-clz-ipaas3-01 `
  --query "[].{Name:name, State:state, HostName:defaultHostName}" `
  --output table
```

### Test 3: Check Key Vault Access

```powershell
# Retrieve a secret (Terraform service principal has access)
az keyvault secret show `
  --vault-name kv-dev-clz-ipaas3-01 `
  --name servicebus-connection-string `
  --query "value" `
  --output tsv
```

### Test 4: Access APIM Developer Portal

```powershell
# Get developer portal URL
$portalUrl = az apim show `
  --name apim-dev-clz-ipaas3-01 `
  --resource-group rg-dev-clz-ipaas3-01 `
  --query developerPortalUrl `
  --output tsv

Write-Host "Developer Portal: $portalUrl"
Start-Process $portalUrl
```

## 📋 Next Steps

### 1. Deploy Logic App Workflows

Navigate to Azure Portal → Logic Apps → Choose a Logic App → Workflows → Create new workflow

**Example Workflow: Service Bus Message Processor**
1. Trigger: When messages are received in Service Bus queue
2. Action: Process message
3. Action: Send to another system or log to storage

### 2. Configure APIM APIs

1. Open APIM in Azure Portal: `apim-dev-clz-ipaas3-01`
2. Go to APIs → Add API → HTTP/OpenAPI
3. Configure backend to point to Logic Apps
4. Add policies (rate limiting, transformation)

### 3. Add Secrets to Key Vault

```powershell
# Add a new secret
az keyvault secret set `
  --vault-name kv-dev-clz-ipaas3-01 `
  --name "my-api-key" `
  --value "super-secret-value"

# Reference in Logic App: @Microsoft.KeyVault(SecretUri=https://kv-dev-clz-ipaas3-01.vault.azure.net/secrets/my-api-key/)
```

### 4. Monitor with Log Analytics

```powershell
# Open Log Analytics in Azure Portal
az monitor log-analytics workspace show `
  --resource-group rg-dev-clz-ipaas3-01 `
  --workspace-name la-dev-clz-ipaas3-01 `
  --query id `
  --output tsv
```

**Sample Query (run in Log Analytics):**
```kusto
// View all Logic App executions in the last 24 hours
AzureDiagnostics
| where ResourceProvider == "MICROSOFT.WEB"
| where Category == "FunctionAppLogs"
| where TimeGenerated > ago(24h)
| summarize count() by Resource, Level
```

## 🛠️ Common Tasks

### Update a Resource

```powershell
# Edit dev.tfvars or main.tf
cd env\dev
terraform plan -var-file=dev.tfvars
terraform apply -var-file=dev.tfvars
```

### Add Another Logic App

1. Edit `env/dev/main.tf`
2. Add storage module: `module "storage_logicapp_06" { ... }`
3. Add Logic App module: `module "logicapp_06" { ... }`
4. Add RBAC assignments
5. Run: `terraform apply -var-file=dev.tfvars`

### Destroy Everything

```powershell
# Destroy APIM first (optional)
cd apim
terraform destroy -var-file=dev.tfvars

# Destroy main platform
cd ..\env\dev
terraform destroy -var-file=dev.tfvars
```

## 🚨 Troubleshooting

### Issue: Backend Storage Not Found

```powershell
# Verify backend exists
az storage account show `
  --name stocommoniac01 `
  --resource-group rg-common-iac-01
```

### Issue: Key Vault Access Denied (HTTP 403)

**Solution:** Wait 60 seconds for RBAC propagation, then retry `terraform apply`

### Issue: Resource Name Already Exists

**Solution:** Change the instance number in `dev.tfvars` (e.g., `01` → `02`)

### Issue: APIM Deployment Stuck

**Solution:** Check Azure Portal for APIM status. It can take up to 45 minutes on first deployment.

## 📊 Cost Management

**Current monthly cost:** ~$920 USD

**Save money in dev:**
```powershell
# Stop when not in use (saves ~70%)
cd apim
terraform destroy -var-file=dev.tfvars  # Destroys APIM only

# Start again when needed
terraform apply -var-file=dev.tfvars    # Recreates APIM
```

## 📚 Resources

- **Full Documentation**: `README.md`
- **Detailed Runbook**: `env/dev/RUNBOOK.md`
- **APIM Guide**: `apim/README.md`
- **Module Docs**: `modules/*/README.md`
- **Changelog**: `CHANGELOG.md`

## ✅ Success Checklist

After completing this guide, you should have:

- [x] Main platform deployed (RG, Storage, Service Bus, Logic Apps, Key Vault)
- [x] APIM deployed and accessible
- [x] All resources visible in Azure Portal
- [x] Service Bus queue receiving messages
- [x] Logic Apps in Running state
- [x] Key Vault secrets accessible
- [x] Monitoring enabled (Log Analytics + App Insights)

**Congratulations! Your Azure Integration Services platform is ready! 🎉**

---

**Total Time:** ~40 minutes (10 min platform + 30 min APIM)  
**Next**: Deploy your first Logic App workflow!
