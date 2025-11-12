# Standalone APIM Deployment
# This deploys APIM separately from the main platform to avoid deployment conflicts

# Data source for existing resource group (created by main platform)
data "azurerm_resource_group" "this" {
  name = var.resource_group_name
}

# Data source for existing Log Analytics workspace
data "azurerm_log_analytics_workspace" "this" {
  name                = var.log_analytics_workspace_name
  resource_group_name = var.resource_group_name
}

# API Management
module "apim" {
  source = "../modules/apim"

  apim_name                  = var.apim_name
  location                   = data.azurerm_resource_group.this.location
  resource_group_name        = data.azurerm_resource_group.this.name
  publisher_name             = var.apim_publisher_name
  publisher_email            = var.apim_publisher_email
  sku_name                   = var.apim_sku
  log_analytics_workspace_id = data.azurerm_log_analytics_workspace.this.id

  tags = var.tags
}
