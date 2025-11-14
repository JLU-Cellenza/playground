# API Management Deployment

This directory contains the Terraform configuration for deploying API Management (APIM) as a separate component from the main platform.

## ⚠️ Important: Deploy Main Platform First

APIM **must** be deployed **after** the main platform (`env/dev/`) because:
- It requires an existing Resource Group
- It requires an existing Log Analytics Workspace
- Azure provider has a known issue with APIM managed identity propagation

## Architecture

- **SKU:** StandardV2_1 (production-grade)
- **Publisher:** Cellenza
- **Region:** France Central
- **Managed Identity:** System-assigned (enabled by default)
- **Monitoring:** Integrated with Log Analytics from main platform

## Deployment Time

⏱️ **25-30 minutes** (APIM provisioning is slow by design)

## Quick Start

### Prerequisites

1. Main platform deployed successfully (`env/dev/`)
2. Resource Group `rg-dev-clz-ipaas3-01` exists
3. Log Analytics Workspace `la-dev-clz-ipaas3-01` exists

### Deploy APIM

```powershell
# 1. Initialize backend
terraform init -backend-config=backend.tfvars

# 2. Plan deployment
terraform plan -var-file=dev.tfvars -out=plan.tfplan

# 3. Apply (this will take 25-30 minutes)
terraform apply plan.tfplan

# 4. Verify deployment
az apim show --name apim-dev-clz-ipaas3-01 `
  --resource-group rg-dev-clz-ipaas3-01 `
  --query provisioningState -o tsv
```

### Destroy APIM

```powershell
terraform destroy -var-file=dev.tfvars
```

**Note:** Destroying APIM does not affect the main platform.

## Configuration Files

| File | Purpose |
|------|---------|
| `main.tf` | APIM module instantiation + data sources |
| `variables.tf` | Input variable definitions |
| `outputs.tf` | Output values (gateway URL, portal URL, etc.) |
| `dev.tfvars` | Dev environment configuration |
| `backend.tfvars` | Remote state configuration (separate from main) |

## State Management

- **Backend Storage:** `stocommoniac01` (shared with main platform)
- **State File:** `project-ipaas3-dev-apim.tfstate` (separate from main platform)
- **Container:** `terraform`

## Data Sources

APIM deployment uses data sources to reference existing resources:

```hcl
data "azurerm_resource_group" "this" {
  name = "rg-dev-clz-ipaas3-01"
}

data "azurerm_log_analytics_workspace" "this" {
  name                = "la-dev-clz-ipaas3-01"
  resource_group_name = "rg-dev-clz-ipaas3-01"
}
```

## Outputs

After deployment, you can retrieve:

```powershell
terraform output gateway_url          # APIM gateway endpoint
terraform output developer_portal_url # Developer portal URL
terraform output management_api_url   # Management API endpoint
terraform output identity_principal_id # Managed identity ID
```

## Monitoring Progress

During the 25-30 minute deployment, monitor progress:

```powershell
# Check provisioning state (refresh every 2-3 minutes)
az apim show --name apim-dev-clz-ipaas3-01 `
  --resource-group rg-dev-clz-ipaas3-01 `
  --query provisioningState -o tsv

# Provisioning states:
# - Creating   → In progress
# - Succeeded  → Complete
# - Failed     → Error (check logs)
```

## Troubleshooting

### APIM Already Exists

If APIM was previously deployed and soft-deleted:

```powershell
# List soft-deleted APIM instances
az apim deletedservice list --output table

# Purge soft-deleted instance
az apim deletedservice purge --service-name apim-dev-clz-ipaas3-01 --location francecentral
```

### Deployment Timeout

If deployment exceeds 45 minutes:
1. Check Azure Portal for detailed error messages
2. Verify quota limits for APIM in your subscription
3. Try deploying in a different region

### Data Source Not Found

**Error:** `Resource group not found`

**Solution:** Deploy main platform first:
```powershell
cd ../env/dev
terraform apply -var-file=dev.tfvars
```

## GitHub Actions

APIM has dedicated workflows:
- `.github/workflows/terraform-apim-deploy.yml` - Deploy APIM
- `.github/workflows/terraform-apim-destroy.yml` - Destroy APIM

Trigger manually from GitHub Actions with environment selection.

## Next Steps

After APIM is deployed:
1. Configure APIs and backends
2. Set up policies (rate limiting, transformation, etc.)
3. Create products and subscriptions
4. Integrate with Logic Apps backends
5. Configure custom domains (optional)

## References

- [Azure APIM Documentation](https://learn.microsoft.com/en-us/azure/api-management/)
- [APIM SKU Comparison](https://learn.microsoft.com/en-us/azure/api-management/api-management-features)
- Main Platform: `../env/dev/`
- Module Source: `../modules/apim/`
