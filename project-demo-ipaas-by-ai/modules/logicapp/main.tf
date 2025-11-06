resource "azurerm_service_plan" "this" {
  name                = var.service_plan_name
  location            = var.location
  resource_group_name = var.resource_group_name
  os_type             = "Windows"
  sku_name            = var.sku_name

  tags = var.tags
}

resource "azurerm_logic_app_standard" "this" {
  name                       = var.logic_app_name
  location                   = var.location
  resource_group_name        = var.resource_group_name
  app_service_plan_id        = azurerm_service_plan.this.id
  storage_account_name       = var.storage_account_name
  storage_account_access_key = var.storage_account_access_key
  version                    = "~4"

  app_settings = merge(
    {
      "FUNCTIONS_WORKER_RUNTIME"     = "node"
      "WEBSITE_NODE_DEFAULT_VERSION" = "~18"
      "WEBSITE_RUN_FROM_PACKAGE"     = "1"
      "AzureWebJobsStorage"          = var.storage_connection_string
      "APPINSIGHTS_INSTRUMENTATIONKEY" = var.app_insights_instrumentation_key
      "APPLICATIONINSIGHTS_CONNECTION_STRING" = var.app_insights_connection_string
      "SERVICEBUS_CONNECTION__fullyQualifiedNamespace" = var.servicebus_namespace_fqdn
    },
    var.additional_app_settings
  )

  identity {
    type = "SystemAssigned"
  }

  tags = var.tags
}

resource "azurerm_monitor_diagnostic_setting" "this" {
  count                      = var.log_analytics_workspace_id != null ? 1 : 0
  name                       = "diag-${var.logic_app_name}"
  target_resource_id         = azurerm_logic_app_standard.this.id
  log_analytics_workspace_id = var.log_analytics_workspace_id

  enabled_log {
    category = "WorkflowRuntime"
  }

  metric {
    category = "AllMetrics"
    enabled  = true
  }
}
