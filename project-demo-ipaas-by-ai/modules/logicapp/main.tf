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
  https_only                 = true
  client_affinity_enabled    = false

  app_settings = merge(
    {
      "FUNCTIONS_WORKER_RUNTIME"                       = "node"
      "WEBSITE_NODE_DEFAULT_VERSION"                   = "~18"
      "WEBSITE_RUN_FROM_PACKAGE"                       = "1"
      "AzureWebJobsStorage"                            = var.storage_connection_string
      "APPINSIGHTS_INSTRUMENTATIONKEY"                 = var.app_insights_instrumentation_key
      "APPLICATIONINSIGHTS_CONNECTION_STRING"          = var.app_insights_connection_string
      "SERVICEBUS_CONNECTION__fullyQualifiedNamespace" = var.servicebus_namespace_fqdn
    },
    var.additional_app_settings
  )

  site_config {
    always_on = false
    use_32_bit_worker_process = false
  }

  identity {
    type = "SystemAssigned"
  }

  tags = var.tags

  lifecycle {
    ignore_changes = [
      app_settings["WEBSITE_CONTENTAZUREFILECONNECTIONSTRING"],
      app_settings["WEBSITE_CONTENTSHARE"]
    ]
  }
}

resource "azurerm_monitor_diagnostic_setting" "this" {
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
