# Logic App Standard Module

This module creates an Azure Logic App Standard instance. The App Service Plan is created externally to allow multiple Logic Apps to share the same plan.

## Resources Created

- `azurerm_logic_app_standard` - Logic App Standard instance

## Usage

### Shared App Service Plan (Recommended)

```hcl
# Create App Service Plan separately
resource "azurerm_service_plan" "shared_plan" {
  name                = "asp-dev-clz-ipaas3-01"
  location            = "francecentral"
  resource_group_name = azurerm_resource_group.this.name
  os_type             = "Windows"
  sku_name            = "WS1"

  tags = {
    environment = "dev"
    project     = "ipaas3"
  }
}

# Logic App 1 on shared plan
module "logicapp_01" {
  source = "../../modules/logicapp"

  logic_app_name              = "logic-dev-clz-ipaas3-01"
  app_service_plan_id         = azurerm_service_plan.shared_plan.id
  location                    = "francecentral"
  resource_group_name         = azurerm_resource_group.this.name
  storage_account_name        = module.storage_logicapp_01.name
  storage_account_access_key  = module.storage_logicapp_01.primary_access_key
  storage_connection_string   = module.storage_logicapp_01.primary_connection_string
  servicebus_namespace_fqdn   = module.servicebus.namespace_fqdn
  app_insights_connection_string = module.app_insights.connection_string
  log_analytics_workspace_id  = module.log_analytics.workspace_id

  tags = {
    environment = "dev"
    project     = "ipaas3"
  }
}

# Logic App 2 on same shared plan
module "logicapp_02" {
  source = "../../modules/logicapp"

  logic_app_name              = "logic-dev-clz-ipaas3-02"
  app_service_plan_id         = azurerm_service_plan.shared_plan.id  # Same plan
  location                    = "francecentral"
  resource_group_name         = azurerm_resource_group.this.name
  storage_account_name        = module.storage_logicapp_02.name
  storage_account_access_key  = module.storage_logicapp_02.primary_access_key
  storage_connection_string   = module.storage_logicapp_02.primary_connection_string
  servicebus_namespace_fqdn   = module.servicebus.namespace_fqdn
  app_insights_connection_string = module.app_insights.connection_string
  log_analytics_workspace_id  = module.log_analytics.workspace_id

  tags = {
    environment = "dev"
    project     = "ipaas3"
  }
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| logic_app_name | The name of the Logic App Standard | string | n/a | yes |
| app_service_plan_id | ID of existing App Service Plan (can be shared) | string | n/a | yes |
| location | The Azure region | string | n/a | yes |
| resource_group_name | The resource group name | string | n/a | yes |
| storage_account_name | Storage account name for Logic App | string | n/a | yes |
| storage_account_access_key | Storage account access key (sensitive) | string | n/a | yes |
| storage_connection_string | Storage connection string (sensitive) | string | n/a | yes |
| app_insights_connection_string | App Insights connection string (sensitive) | string | null | no |
| servicebus_namespace_fqdn | Service Bus FQDN for managed identity | string | null | no |
| additional_app_settings | Additional app settings | map(string) | {} | no |
| log_analytics_workspace_id | Log Analytics workspace ID | string | null | no |
| tags | Tags to assign | map(string) | {} | no |

## Outputs

| Name | Description |
|------|-------------|
| logic_app_id | Logic App ID |
| logic_app_name | Logic App name |
| default_hostname | Default hostname |
| identity_principal_id | Managed identity Principal ID |
| identity_tenant_id | Managed identity Tenant ID |

## Important Notes

- **App Service Plan:** Must be created separately to enable sharing across multiple Logic Apps
- **Runtime:** Uses Logic App runtime version `~4`
- **Managed Identity:** System-assigned managed identity enabled by default
- **AzureWebJobsStorage:** Automatically configured via storage_account_name and storage_account_access_key
- **Never** manually set AzureWebJobsStorage in app_settings

## App Service Plan Sharing

Multiple Logic Apps can share a single App Service Plan:
- **Benefits:** Cost savings, resource consolidation
- **SKU Requirements:** WS1, WS2, or WS3 (Windows-based)
- **Recommended:** 3-5 Logic Apps per WS1 plan for dev/test
- **Production:** Monitor CPU/memory and scale to WS2/WS3 if needed
