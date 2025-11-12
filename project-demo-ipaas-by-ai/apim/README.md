# API Management (APIM) - Standalone Deployment

## Overview

This directory contains a **separate Terraform configuration** for deploying Azure API Management (APIM). APIM has been isolated from the main platform deployment due to persistent Azure provider issues with managed identity propagation.

## Why Separate Deployment?

### Problem
Azure provider has a known issue where it attempts to read APIM delegation validation keys immediately after resource creation, but the managed identity hasn't fully propagated yet. This causes persistent 401 errors:

```
Error: listing APIs/products after creation... unexpected status 401 (401 Unauthorized)
```

### Solution
By deploying APIM separately:
- Main platform deploys quickly (5-10 minutes) without APIM blocking
- APIM can be deployed independently after platform is stable
- Managed identity propagation issues are isolated
- Faster iteration on platform changes
- Independent lifecycle management

## Architecture

```
┌──────────────────────────────────────┐
│  Main Platform (env/dev/)            │
│  - Resource Group                    │
│  - Log Analytics                     │
│  - Storage Account                   │
│  - Service Bus                       │
│  - Function App                      │
│  - Logic Apps                        │
└──────────────────────────────────────┘
                  ↓
          (Deployed First)
                  ↓
┌──────────────────────────────────────┐
│  APIM Standalone (apim/)             │
│  - API Management                    │
│  - Uses existing RG & Log Analytics  │
└──────────────────────────────────────┘
```

## State Management

APIM uses a **separate state file** to ensure complete isolation:

- **Main Platform State:** `mvp-ipaas-dev.tfstate`
- **APIM State:** `mvp-ipaas-dev-apim.tfstate`

Both stored in the same Azure Storage backend but as distinct state files.

## Deployment Order

### 1. Deploy Main Platform First
```bash
# Via GitHub Actions: terraform-deploy.yml workflow
# Or locally from env/dev/:
cd ../env/dev
terraform init -backend-config=backend.tfvars
terraform plan -var-file=dev.tfvars
terraform apply -var-file=dev.tfvars
```

### 2. Deploy APIM Second
```bash
# Via GitHub Actions: terraform-apim-deploy.yml workflow
# Or locally from apim/:
cd apim
terraform init -backend-config=backend.tfvars
terraform plan -var-file=dev.tfvars
terraform apply -var-file=dev.tfvars
```

⏱️ **Expected Duration:** 25-30 minutes for APIM creation

## Configuration Files

| File | Purpose |
|------|---------|
| `main.tf` | APIM module instantiation with data sources for existing RG and Log Analytics |
| `variables.tf` | Input variables for APIM configuration |
| `outputs.tf` | Outputs for gateway URL, portal URL, resource ID |
| `backend.tfvars` | Backend state configuration (separate state file) |
| `dev.tfvars` | DEV environment configuration |
| `terraform.tf` | Provider and Terraform version constraints |

## GitHub Actions Workflows

### Deploy APIM
**Workflow:** `.github/workflows/terraform-apim-deploy.yml`

**Trigger:** Manual (`workflow_dispatch`)

**Inputs:**
- `environment`: dev or prd
- `confirm`: Type `DEPLOY-APIM` to proceed

**Duration:** 25-30 minutes

**Secrets Required:**
- `AZURE_CREDENTIALS`
- `TERRAFORM_APPLY` (must be "true")

### Destroy APIM
**Workflow:** `.github/workflows/terraform-apim-destroy.yml`

**Trigger:** Manual (`workflow_dispatch`)

**Inputs:**
- `environment`: dev or prd
- `confirm`: Type `DESTROY-APIM` to proceed

**Duration:** 3-5 minutes

**Secrets Required:**
- `AZURE_CREDENTIALS`
- `TERRAFORM_DESTROY` (must be "true")

## Variables

### Required Variables (`dev.tfvars`)

```hcl
resource_group_name         = "rg-dev-cellenza-mvpipaas-01"  # Must exist (from main platform)
log_analytics_workspace_name = "la-dev-cellenza-mvpipaas-01" # Must exist (from main platform)
apim_name                   = "apim-dev-cellenza-mvpipaas-01"
publisher_name              = "Cellenza"
publisher_email             = "admin@cellenza.com"
sku_name                    = "Developer_1"                    # Developer for DEV, Premium for PRD
tags = {
  project     = "mvp-ipaas"
  environment = "dev"
  owner       = "platform-team"
  cost_center = "engineering"
  created_by  = "terraform"
}
```

## Outputs

After successful deployment:

```hcl
apim_gateway_url      = "https://apim-dev-cellenza-mvpipaas-01.azure-api.net"
apim_portal_url       = "https://apim-dev-cellenza-mvpipaas-01.developer.azure-api.net"
apim_resource_id      = "/subscriptions/.../apim-dev-cellenza-mvpipaas-01"
apim_identity_principal_id = "..."
```

## Troubleshooting

### Issue: Data Source Can't Find Resource Group
**Error:** `Resource group not found`

**Solution:** Ensure main platform is deployed first. Check that `resource_group_name` in `dev.tfvars` matches the actual deployed RG name.

### Issue: Data Source Can't Find Log Analytics
**Error:** `Log Analytics workspace not found`

**Solution:** Verify main platform deployed successfully. Check `log_analytics_workspace_name` in `dev.tfvars`.

### Issue: 401 Errors During Apply
**Error:** `unexpected status 401 (401 Unauthorized)`

**Solution:** This is expected during/after APIM creation. The provider will retry. If it persists after 5 minutes, wait 10-15 minutes and re-run `terraform apply`. The managed identity needs time to propagate.

### Issue: APIM Already Exists
**Error:** `resource already exists`

**Solution:** Import existing APIM:
```bash
terraform import module.apim.azurerm_api_management.this /subscriptions/{sub-id}/resourceGroups/{rg-name}/providers/Microsoft.ApiManagement/service/{apim-name}
```

## Local Development

### Prerequisites
- Azure CLI logged in (`az login`)
- Terraform 1.5.0+
- Access to Azure subscription
- Main platform already deployed

### Initialize
```bash
cd project-demo-ipaas-by-ai/apim
terraform init -backend-config=backend.tfvars
```

### Plan
```bash
terraform plan -var-file=dev.tfvars
```

### Apply
```bash
terraform apply -var-file=dev.tfvars
```

### Destroy
```bash
terraform destroy -var-file=dev.tfvars
```

## Security Considerations

- APIM uses system-assigned managed identity (no service principals)
- Diagnostic settings send logs to Log Analytics workspace
- Developer SKU used for DEV (no SLA, cost-optimized)
- Premium SKU recommended for PRD (multi-region, VNet injection, higher SLA)

## Cost Estimates

| Environment | SKU | Monthly Cost (approx) |
|-------------|-----|----------------------|
| DEV | Developer_1 | ~$50 USD |
| PRD | Premium_1 | ~$2,800 USD |

## Related Documentation

- [Main Platform Deployment](../env/dev/RUNBOOK.md)
- [APIM Module](../modules/apim/README.md)
- [Deployment Checklist](../DEPLOYMENT-CHECKLIST.md)
- [Azure APIM Documentation](https://learn.microsoft.com/en-us/azure/api-management/)

## Known Limitations

- **No VNet Integration:** Current deployment uses external access mode
- **Developer SKU:** No SLA in DEV environment
- **Single Region:** No multi-region deployment configured
- **No Custom Domain:** Uses default `.azure-api.net` domain

## Future Enhancements

- [ ] Add custom domain support
- [ ] Configure VNet integration for PRD
- [ ] Add API policies and products via Terraform
- [ ] Integrate with Application Gateway for WAF
- [ ] Configure multi-region deployment for PRD
- [ ] Add Azure Monitor alerts for APIM metrics

---

**Last Updated:** 2024  
**Maintained By:** Platform Team  
**Terraform Version:** 1.5.0  
**Azure Provider:** ~> 4.0
