# Application Insights Module

This module creates an Azure Application Insights instance for application monitoring and telemetry.

## Resources Created

- `azurerm_application_insights` - Application Insights for monitoring

## Usage

```hcl
module "app_insights" {
  source = "../../modules/app_insights"

  app_insights_name   = "appi-dev-clz-ipaas3-01"
  location            = "francecentral"
  resource_group_name = azurerm_resource_group.this.name
  workspace_id        = module.log_analytics.workspace_id
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
| app_insights_name | The name of the Application Insights instance | string | n/a | yes |
| location | The Azure region | string | n/a | yes |
| resource_group_name | The resource group name | string | n/a | yes |
| workspace_id | The Log Analytics Workspace ID | string | n/a | yes |
| application_type | The application type | string | "web" | no |
| retention_in_days | Data retention in days | number | 30 | no |
| tags | Tags to assign | map(string) | {} | no |

## Outputs

| Name | Description |
|------|-------------|
| id | Application Insights ID |
| instrumentation_key | Instrumentation key (sensitive) |
| connection_string | Connection string (sensitive) |
| app_id | Application ID |
| name | Application Insights name |
