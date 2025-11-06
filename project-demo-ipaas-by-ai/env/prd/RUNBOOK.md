# Azure iPaaS Platform - prdelopment Environment Runbook

## Overview

This runbook provides step-by-step instructions for deploying and managing the iPaaS platform in the prdelopment environment.

## Prerequisites

- [ ] Azure CLI installed (`az --version`)
- [ ] Terraform >= 1.5.0 installed (`terraform version`)
- [ ] Azure subscription with Owner or Contributor + User Access Administrator roles
- [ ] PowerShell 5.1 or higher

## Pre-Deployment Checklist

- [ ] Confirm Azure subscription ID
- [ ] Validate resource naming conventions
- [ ] Ensure no resource name conflicts in target region
- [ ] Verify sufficient Azure quotas (especially APIM, Service Bus)

## Deployment Steps

### 1. Set Azure Subscription

```powershell
# Login to Azure
az login

# Set subscription (replace with your subscription ID)
$env:ARM_SUBSCRIPTION_ID = "YOUR-SUBSCRIPTION-ID-HERE"

# Verify correct subscription
az account show --query "{SubscriptionId:id, Name:name, TenantId:tenantId}"
```

### 2. Create Resource Group (if not exists)

```powershell
az group create `
  --name rg-prd-cellenza-mvpipaas-01 `
  --location francecentral `
  --tags project=mvp-ipaas environment=prd owner=cellenza created_by=terraform
```

### 3. Initialize Terraform

```powershell
cd env/prd

# Initialize Terraform (downloads providers and modules)
terraform init

# Verify initialization
terraform validate
```

### 4. Create tfvars File

```powershell
# Copy example file
cp prd.tfvars.example prd.tfvars

# Edit prd.tfvars with your values
# IMPORTANT: Replace placeholder values
notepad prd.tfvars
```

**Required changes in `prd.tfvars`:**
- Update `apim_publisher_email` with a valid email address
- Confirm `resource_group_name` matches the RG created in step 2

### 5. Plan Deployment

```powershell
# Generate execution plan
terraform plan -var-file=prd.tfvars -out=plan.tfplan

# Review the plan carefully:
# - Check resource names follow naming convention
# - Verify SKUs are cost-appropriate (prdeloper, Standard, Consumption)
# - Confirm no unexpected resources will be created/destroyed
```

**Expected resources (approximately 30+):**
- 1x Resource Group
- 1x Log Analytics Workspace
- 1x Application Insights
- 4x Storage Accounts (Function, 2x Logic Apps, Platform)
- 1x Service Bus Namespace + 1 Queue
- 1x Function App + App Service Plan
- 2x Logic Apps + 2x App Service Plans
- 1x API Management
- ~15x RBAC Role Assignments
- ~10x Diagnostic Settings

### 6. Apply Deployment

```powershell
# Apply the plan
terraform apply plan.tfplan

# IMPORTANT: APIM deployment takes 30-45 minutes
# Monitor progress in Azure Portal or via CLI
```

### 7. Post-Deployment Validation

```powershell
# Verify all resources exist
az resource list --resource-group rg-prd-cellenza-mvpipaas-01 --output table

# Check Service Bus queue
az servicebus queue show `
  --namespace-name (terraform output -raw servicebus_namespace_name) `
  --name inbound `
  --resource-group rg-prd-cellenza-mvpipaas-01

# Test Function App (should return HTTP 200)
$functionUrl = terraform output -raw function_app_url
Invoke-WebRequest -Uri $functionUrl -UseBasicParsing

# Check APIM gateway
$apimUrl = terraform output -raw apim_gateway_url
Write-Host "APIM Gateway: $apimUrl"
Write-Host "prdeloper Portal: $(terraform output -raw apim_prdeloper_portal_url)"

# Verify diagnostic logs are flowing to Log Analytics
az monitor diagnostic-settings list `
  --resource (terraform output -raw servicebus_namespace_name) `
  --resource-group rg-prd-cellenza-mvpipaas-01 `
  --resource-type Microsoft.ServiceBus/namespaces
```

### 8. Retrieve Outputs

```powershell
# Get all outputs
terraform output

# Get specific output
terraform output function_app_url
terraform output apim_gateway_url

# Get sensitive outputs (connection strings)
terraform output -raw servicebus_connection_string
```

## Service URLs & Endpoints

After deployment, note these URLs:

| Service | URL/Endpoint |
|---------|--------------|
| Function App | https://func-prd-cellenza-mvpipaas-helpers-01.azurewebsites.net |
| Logic App 01 | https://loa-prd-cellenza-mvpipaas-workflow-01.azurewebsites.net |
| Logic App 02 | https://loa-prd-cellenza-mvpipaas-workflow-02.azurewebsites.net |
| APIM Gateway | https://apim-prd-cellenza-mvpipaas-01.azure-api.net |
| APIM Portal | https://apim-prd-cellenza-mvpipaas-01.prdeloper.azure-api.net |
| Service Bus | sb-prd-cellenza-mvpipaas-01.servicebus.windows.net |
| Platform Storage | https://stplprdcellenzamvpipaas01.blob.core.windows.net |

## RBAC Assignments

The following Managed Identity role assignments are configured:

| Service | Role | Target |
|---------|------|--------|
| Function App | Service Bus Data Sender/Receiver | Service Bus Namespace |
| Function App | Storage Blob Data Contributor | Platform Storage |
| Logic App 01 | Service Bus Data Sender/Receiver | Service Bus Namespace |
| Logic App 01 | Storage Blob Data Contributor | Platform Storage |
| Logic App 02 | Service Bus Data Sender/Receiver | Service Bus Namespace |
| Logic App 02 | Storage Blob Data Contributor | Platform Storage |

## Troubleshooting

### APIM Deployment Fails
- **Cause**: Name conflict, quota limit, or region unavailable
- **Solution**: Check `az apim check-name-availability --name <name>` and verify quotas

### Storage Account Name Too Long
- **Cause**: Storage names limited to 24 characters
- **Solution**: Shorten project name in `prd.tfvars`

### Service Bus Connection Fails
- **Cause**: Managed Identity RBAC assignment not propagated
- **Solution**: Wait 5-10 minutes for Azure AD propagation, then restart app

### Terraform State Lock
- **Cause**: Previous apply interrupted
- **Solution**: Release lock via Azure Portal (Storage Account > Container > Lease)

### Logs Not Appearing in Log Analytics
- **Cause**: Diagnostic settings not enabled or logs not generated yet
- **Solution**: Verify diagnostic settings exist, generate test traffic, wait 10-15 minutes

## Updates & Changes

### To Update Existing Resources

```powershell
# Make changes to .tf files or tfvars
terraform plan -var-file=prd.tfvars -out=plan.tfplan

# Review changes carefully
terraform apply plan.tfplan
```

### To Add a New Queue

```powershell
# Edit env/prd/main.tf
# Update module "servicebus" queue_names = ["inbound", "outbound"]
terraform plan -var-file=prd.tfvars -out=plan.tfplan
terraform apply plan.tfplan
```

## Rollback

### Rollback to Previous State

```powershell
# Revert to previous commit
git revert HEAD

# Re-apply
terraform plan -var-file=prd.tfvars -out=plan.tfplan
terraform apply plan.tfplan
```

## Destroy Environment

⚠️ **WARNING: This will DELETE all resources**

```powershell
cd env/prd

# Plan destroy
terraform plan -destroy -var-file=prd.tfvars -out=destroy.tfplan

# Review what will be destroyed
terraform show destroy.tfplan

# Execute destroy (requires confirmation)
terraform apply destroy.tfplan
```

## Monitoring & Logs

### View Logs in Log Analytics

```powershell
# Get workspace ID
$workspaceId = terraform output -raw log_analytics_workspace_id

# Open in Azure Portal
az monitor log-analytics workspace show --ids $workspaceId --query "id"
```

### Common Kusto Queries

```kusto
// Function App logs (last 1 hour)
FunctionAppLogs
| where TimeGenerated > ago(1h)
| project TimeGenerated, FunctionName, Message, Level

// Service Bus operational logs
AzureDiagnostics
| where ResourceProvider == "MICROSOFT.SERVICEBUS"
| where TimeGenerated > ago(1h)
| project TimeGenerated, OperationName, Status, CallerIpAddress

// APIM gateway logs
AzureDiagnostics
| where ResourceProvider == "MICROSOFT.APIMANAGEMENT"
| where Category == "GatewayLogs"
| project TimeGenerated, OperationName, Method, Url, ResponseCode
```

## Support & Escalation

- **Terraform Issues**: Check `terraform.log` (set `TF_LOG=DEBUG`)
- **Azure Issues**: Review Activity Log in Azure Portal
- **Networking**: Verify NSGs, firewall rules (demo uses public access)
- **RBAC**: Confirm role assignments via `az role assignment list`

## Maintenance Schedule

- **Terraform State Backup**: Weekly (automated via backend)
- **Cost Review**: Monthly
- **SKU Review**: Quarterly (upgrade to prod SKUs for production)
- **Security Audit**: Quarterly (implement Private Endpoints, disable public access)

---

**Last Updated**: 2025-11-06  
**Maintained By**: Cellenza Integration Team  
**Environment**: prdelopment  
**Terraform Version**: >= 1.5.0  
**AzureRM Provider**: ~> 3.0
