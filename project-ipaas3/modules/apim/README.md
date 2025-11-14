# API Management Module

This module creates an Azure API Management instance.

## Resources Created

- `azurerm_api_management` - API Management instance

## Usage

```hcl
module "apim" {
  source = "../../modules/apim"

  apim_name               = "apim-dev-clz-ipaas3-01"
  location                = "francecentral"
  resource_group_name     = data.azurerm_resource_group.this.name
  publisher_name          = "Cellenza"
  publisher_email         = "admin@cellenza.com"
  sku_name                = "StandardV2_1"
  log_analytics_workspace_id = data.azurerm_log_analytics_workspace.this.id

  tags = {
    environment = "dev"
    project     = "ipaas3"
  }
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| apim_name | The name of the API Management instance | string | n/a | yes |
| location | The Azure region | string | n/a | yes |
| resource_group_name | The resource group name | string | n/a | yes |
| publisher_name | The publisher name | string | n/a | yes |
| publisher_email | The publisher email | string | n/a | yes |
| sku_name | SKU (format: {Tier}_{Capacity}, e.g., StandardV2_1) | string | "Developer_1" | no |
| log_analytics_workspace_id | Log Analytics workspace ID | string | n/a | yes |
| tags | Tags to assign | map(string) | {} | no |

## Outputs

| Name | Description |
|------|-------------|
| apim_id | API Management ID |
| apim_name | API Management name |
| gateway_url | Gateway URL |
| developer_portal_url | Developer portal URL |
| management_api_url | Management API URL |
| identity_principal_id | Managed identity Principal ID |

## Deployment Notes

⚠️ **CRITICAL:** APIM must be deployed in a separate Terraform configuration from the main platform:
- Main platform: `env/dev/` (all services except APIM)
- APIM: `apim/` (separate folder with own state file)
- Deployment time: 25-30 minutes
- Reason: Azure provider bug with managed identity propagation delays

## SKU Options

| SKU | Capacity | Use Case |
|-----|----------|----------|
| Developer_1 | 1 | Development/testing (no SLA) |
| Basic_1-2 | 1-2 | Small workloads |
| Standard_1-4 | 1-4 | Production workloads |
| StandardV2_1-10 | 1-10 | V2 platform, better performance |
| Premium_1-12 | 1-12 | Multi-region, VNet, high availability |
