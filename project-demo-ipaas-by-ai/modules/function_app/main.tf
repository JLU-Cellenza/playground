resource "azurerm_service_plan" "this" {
  name                = var.service_plan_name
  location            = var.location
  resource_group_name = var.resource_group_name
  os_type             = "Linux"
  sku_name            = var.sku_name

  tags = var.tags
}

resource "azurerm_linux_function_app" "this" {
  name                       = var.function_app_name
  location                   = var.location
  resource_group_name        = var.resource_group_name
  service_plan_id            = azurerm_service_plan.this.id
  storage_account_name       = var.storage_account_name
  storage_account_access_key = var.storage_account_access_key

  site_config {
    application_insights_connection_string = var.app_insights_connection_string
    application_insights_key               = var.app_insights_instrumentation_key

    application_stack {
      dotnet_version = "8.0"
    }
  }

  app_settings = merge(
    {
      "FUNCTIONS_WORKER_RUNTIME"                       = "dotnet-isolated"
      "WEBSITE_RUN_FROM_PACKAGE"                       = "1"
      "SERVICEBUS_CONNECTION__fullyQualifiedNamespace" = var.servicebus_namespace_fqdn
    },
    var.additional_app_settings
  )

  identity {
    type = "SystemAssigned"
  }

  tags = var.tags
}
