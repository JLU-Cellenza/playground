# modules/logicapp/main.tf

resource "azurerm_logic_app_standard" "this" {
  name                       = var.logic_app_name
  location                   = var.location
  resource_group_name        = var.resource_group_name
  app_service_plan_id        = var.app_service_plan_id
  storage_account_name       = var.storage_account_name
  storage_account_access_key = var.storage_account_access_key
  version                    = "~4"
  https_only                 = true

  app_settings = merge(
    {
      "FUNCTIONS_WORKER_RUNTIME"     = "node"
      "WEBSITE_NODE_DEFAULT_VERSION" = "~18"
    },
    var.servicebus_namespace_fqdn != null ? {
      "SERVICEBUS_NAMESPACE_FQDN" = var.servicebus_namespace_fqdn
    } : {},
    var.app_insights_connection_string != null ? {
      "APPLICATIONINSIGHTS_CONNECTION_STRING" = var.app_insights_connection_string
    } : {},
    var.additional_app_settings
  )

  identity {
    type = "SystemAssigned"
  }

  tags = var.tags
}

# Diagnostic Settings
resource "azurerm_monitor_diagnostic_setting" "logicapp" {
  count                      = var.log_analytics_workspace_id != null ? 1 : 0
  name                       = "diag-${var.logic_app_name}"
  target_resource_id         = azurerm_logic_app_standard.this.id
  log_analytics_workspace_id = var.log_analytics_workspace_id

  enabled_log {
    category = "WorkflowRuntime"
  }

  enabled_log {
    category = "FunctionAppLogs"
  }

  metric {
    category = "AllMetrics"
    enabled  = true
  }
}
