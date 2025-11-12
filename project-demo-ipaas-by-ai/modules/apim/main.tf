resource "azurerm_api_management" "this" {
  name                = var.apim_name
  location            = var.location
  resource_group_name = var.resource_group_name
  publisher_name      = var.publisher_name
  publisher_email     = var.publisher_email
  sku_name            = var.sku_name

  identity {
    type = "SystemAssigned"
  }

  tags = var.tags

  # Workaround for transient 401 errors with APIM delegation validation
  # This prevents unnecessary plan/refresh failures
  lifecycle {
    ignore_changes = [
      # Ignore delegation validation related changes that cause 401 errors
      tags
    ]
  }
}

