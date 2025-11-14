# Log Analytics Workspace Module

This module creates an Azure Log Analytics Workspace for centralized logging and monitoring.

## Resources Created

- `azurerm_log_analytics_workspace` - Log Analytics workspace for platform observability

## Usage

```hcl
module "log_analytics" {
  source = "../../modules/log_analytics"

  workspace_name      = "la-dev-clz-ipaas3-01"
  location            = "francecentral"
  resource_group_name = azurerm_resource_group.this.name
  retention_in_days   = 30

  tags = {
    environment = "dev"
    project     = "ipaas3"
  }
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| workspace_name | The name of the Log Analytics Workspace | string | n/a | yes |
| location | The Azure region | string | n/a | yes |
| resource_group_name | The resource group name | string | n/a | yes |
| sku | The SKU of the workspace | string | "PerGB2018" | no |
| retention_in_days | Data retention in days | number | 30 | no |
| tags | Tags to assign | map(string) | {} | no |

## Outputs

| Name | Description |
|------|-------------|
| workspace_id | The ID of the Log Analytics Workspace |
| workspace_customer_id | The Workspace (Customer) ID |
| primary_shared_key | The primary shared key (sensitive) |
| workspace_name | The name of the workspace |
