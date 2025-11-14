# apim/main.tf

terraform {
  required_version = ">= 1.5.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
  }

  backend "azurerm" {
    # Backend configuration to be provided via backend.tfvars
    # resource_group_name  = "rg-common-iac-01"
    # storage_account_name = "stocommoniac01"
    # container_name       = "terraform"
    # key                  = "project-ipaas3-dev-apim.tfstate"
  }
}

provider "azurerm" {
  features {
    api_management {
      purge_soft_delete_on_destroy = true
      recover_soft_deleted         = true
    }
  }
}

# Data sources for existing resources (created by main platform)
data "azurerm_resource_group" "this" {
  name = var.resource_group_name
}

data "azurerm_log_analytics_workspace" "this" {
  name                = var.log_analytics_workspace_name
  resource_group_name = var.resource_group_name
}

# Data source for Key Vault (created by main platform)
data "azurerm_key_vault" "this" {
  name                = "kv-${var.environment}-${var.organization}-${var.project}-01"
  resource_group_name = var.resource_group_name
}

# Data source for Service Bus (created by main platform)
data "azurerm_servicebus_namespace" "this" {
  name                = "sb-${var.environment}-${var.organization}-${var.project}-01"
  resource_group_name = var.resource_group_name
}

# API Management
module "apim" {
  source = "../modules/apim"

  apim_name                  = "apim-${var.environment}-${var.organization}-${var.project}-01"
  location                   = var.location
  resource_group_name        = data.azurerm_resource_group.this.name
  publisher_name             = var.apim_publisher_name
  publisher_email            = var.apim_publisher_email
  sku_name                   = var.apim_sku_name
  log_analytics_workspace_id = data.azurerm_log_analytics_workspace.this.id

  tags = {
    environment  = var.environment
    project      = var.project
    organization = var.organization
    cost_center  = var.cost_center
    owner        = var.owner
    managed_by   = "terraform"
  }
}

# RBAC: Grant APIM access to Key Vault secrets
resource "azurerm_role_assignment" "apim_keyvault" {
  scope                = data.azurerm_key_vault.this.id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = module.apim.identity_principal_id
}

# RBAC: Grant APIM access to Service Bus (if needed for backend integration)
resource "azurerm_role_assignment" "apim_servicebus" {
  scope                = data.azurerm_servicebus_namespace.this.id
  role_definition_name = "Azure Service Bus Data Sender"
  principal_id         = module.apim.identity_principal_id
}
