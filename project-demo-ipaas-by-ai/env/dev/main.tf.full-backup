# env/dev/main.tf

terraform {
  required_version = ">= 1.5.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }

  backend "azurerm" {
    # Backend configuration to be provided via backend config file or CLI
    # resource_group_name  = "rg-terraform-state"
    # storage_account_name = "stterraformstate"
    # container_name       = "tfstate"
    # key                  = "mvp-ipaas-dev.tfstate"
  }
}

provider "azurerm" {
  features {
    key_vault {
      purge_soft_delete_on_destroy = true
    }
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
  }
}

# Data source for current Azure configuration
data "azurerm_client_config" "current" {}

# Resource Group
resource "azurerm_resource_group" "this" {
  name     = var.resource_group_name
  location = var.location

  tags = local.common_tags
}

# Log Analytics Workspace
module "log_analytics" {
  source = "../../modules/log_analytics"

  workspace_name      = "la-${var.environment}-${var.organization}-${var.project}-01"
  location            = var.location
  resource_group_name = azurerm_resource_group.this.name
  retention_in_days   = var.log_retention_days

  tags = local.common_tags
}

# Application Insights
module "app_insights" {
  source = "../../modules/app_insights"

  app_insights_name   = "appi-${var.environment}-${var.organization}-${var.project}-01"
  location            = var.location
  resource_group_name = azurerm_resource_group.this.name
  workspace_id        = module.log_analytics.workspace_id
  retention_in_days   = var.log_retention_days

  tags = local.common_tags
}

# Storage Account for Function App
module "storage_functions" {
  source = "../../modules/storage"

  storage_account_name       = "stfndev${var.project}01"
  location                   = var.location
  resource_group_name        = azurerm_resource_group.this.name
  account_tier               = "Standard"
  replication_type           = "LRS"
  containers                 = []
  log_analytics_workspace_id = module.log_analytics.workspace_id

  tags = local.common_tags
}

# Storage Account for Logic Apps (Workflow 1)
module "storage_logicapp_01" {
  source = "../../modules/storage"

  storage_account_name       = "stladev${var.project}01"
  location                   = var.location
  resource_group_name        = azurerm_resource_group.this.name
  account_tier               = "Standard"
  replication_type           = "LRS"
  containers                 = []
  log_analytics_workspace_id = module.log_analytics.workspace_id

  tags = local.common_tags
}

# Storage Account for Logic Apps (Workflow 2)
# Temporarily commented out along with Logic App 02
# module "storage_logicapp_02" {
#   source = "../../modules/storage"
#
#   storage_account_name       = "stladev${var.project}02"
#   location                   = var.location
#   resource_group_name        = azurerm_resource_group.this.name
#   account_tier               = "Standard"
#   replication_type           = "LRS"
#   containers                 = []
#   log_analytics_workspace_id = module.log_analytics.workspace_id
#
#   tags = local.common_tags
# }

# Storage Account for Platform Configurations
module "storage_platform" {
  source = "../../modules/storage"

  storage_account_name       = "stpldev${var.project}01"
  location                   = var.location
  resource_group_name        = azurerm_resource_group.this.name
  account_tier               = "Standard"
  replication_type           = "LRS"
  containers                 = ["configurations", "templates", "schemas"]
  log_analytics_workspace_id = module.log_analytics.workspace_id

  tags = local.common_tags
}

# Service Bus Namespace
module "servicebus" {
  source = "../../modules/servicebus"

  namespace_name             = "sb-${var.environment}-${var.organization}-${var.project}-01"
  location                   = var.location
  resource_group_name        = azurerm_resource_group.this.name
  sku                        = "Standard"
  queue_names                = ["inbound"]
  log_analytics_workspace_id = module.log_analytics.workspace_id

  tags = local.common_tags
}

# Function App
module "function_app" {
  source = "../../modules/function_app"

  function_app_name                = "func-${var.environment}-${var.organization}-${var.project}-helpers-01"
  service_plan_name                = "asp-${var.environment}-${var.organization}-${var.project}-func-01"
  location                         = var.location
  resource_group_name              = azurerm_resource_group.this.name
  sku_name                         = "Y1"
  storage_account_name             = module.storage_functions.name
  storage_account_access_key       = module.storage_functions.primary_access_key
  app_insights_connection_string   = module.app_insights.connection_string
  app_insights_instrumentation_key = module.app_insights.instrumentation_key
  servicebus_namespace_fqdn        = "${module.servicebus.namespace_name}.servicebus.windows.net"
  log_analytics_workspace_id       = module.log_analytics.workspace_id

  tags = local.common_tags
}

# Logic App Standard 01 (Workflow 1)
module "logicapp_01" {
  source = "../../modules/logicapp"

  logic_app_name                   = "loa-${var.environment}-${var.organization}-${var.project}-workflow-01"
  service_plan_name                = "asp-${var.environment}-${var.organization}-${var.project}-loa-01"
  location                         = var.location
  resource_group_name              = azurerm_resource_group.this.name
  sku_name                         = "WS1"
  storage_account_name             = module.storage_logicapp_01.name
  storage_account_access_key       = module.storage_logicapp_01.primary_access_key
  storage_connection_string        = module.storage_logicapp_01.primary_connection_string
  app_insights_connection_string   = module.app_insights.connection_string
  app_insights_instrumentation_key = module.app_insights.instrumentation_key
  servicebus_namespace_fqdn        = "${module.servicebus.namespace_name}.servicebus.windows.net"
  log_analytics_workspace_id       = module.log_analytics.workspace_id

  tags = local.common_tags

  depends_on = [
    module.storage_logicapp_01,
    module.app_insights,
    module.servicebus
  ]
}

# Logic App Standard 02 (Workflow 2)
# Temporarily commented out to simplify testing - deploy one Logic App at a time
# module "logicapp_02" {
#   source = "../../modules/logicapp"
#
#   logic_app_name                   = "loa-${var.environment}-${var.organization}-${var.project}-workflow-02"
#   service_plan_name                = "asp-${var.environment}-${var.organization}-${var.project}-loa-02"
#   location                         = var.location
#   resource_group_name              = azurerm_resource_group.this.name
#   sku_name                         = "WS1"
#   storage_account_name             = module.storage_logicapp_02.name
#   storage_account_access_key       = module.storage_logicapp_02.primary_access_key
#   storage_connection_string        = module.storage_logicapp_02.primary_connection_string
#   app_insights_connection_string   = module.app_insights.connection_string
#   app_insights_instrumentation_key = module.app_insights.instrumentation_key
#   servicebus_namespace_fqdn        = "${module.servicebus.namespace_name}.servicebus.windows.net"
#   log_analytics_workspace_id       = module.log_analytics.workspace_id
#
#   tags = local.common_tags
#
#   depends_on = [
#     module.storage_logicapp_02,
#     module.app_insights,
#     module.servicebus,
#     module.logicapp_01  # Create Logic App 02 after Logic App 01 to avoid simultaneous API calls
#   ]
# }

# API Management
# Temporarily commented out to speed up testing - APIM takes 25+ minutes to deploy
# module "apim" {
#   source = "../../modules/apim"
#
#   apim_name                  = "apim-${var.environment}-${var.organization}-${var.project}-01"
#   location                   = var.location
#   resource_group_name        = azurerm_resource_group.this.name
#   publisher_name             = var.apim_publisher_name
#   publisher_email            = var.apim_publisher_email
#   sku_name                   = "Developer_1"
#   log_analytics_workspace_id = module.log_analytics.workspace_id
#
#   tags = local.common_tags
# }

# RBAC Assignments for Service Bus
resource "azurerm_role_assignment" "function_app_servicebus_sender" {
  scope                = module.servicebus.namespace_id
  role_definition_name = "Azure Service Bus Data Sender"
  principal_id         = module.function_app.identity_principal_id
}

resource "azurerm_role_assignment" "function_app_servicebus_receiver" {
  scope                = module.servicebus.namespace_id
  role_definition_name = "Azure Service Bus Data Receiver"
  principal_id         = module.function_app.identity_principal_id
}

resource "azurerm_role_assignment" "logicapp_01_servicebus_sender" {
  scope                = module.servicebus.namespace_id
  role_definition_name = "Azure Service Bus Data Sender"
  principal_id         = module.logicapp_01.identity_principal_id
}

resource "azurerm_role_assignment" "logicapp_01_servicebus_receiver" {
  scope                = module.servicebus.namespace_id
  role_definition_name = "Azure Service Bus Data Receiver"
  principal_id         = module.logicapp_01.identity_principal_id
}

# Temporarily commented out along with Logic App 02
# resource "azurerm_role_assignment" "logicapp_02_servicebus_sender" {
#   scope                = module.servicebus.namespace_id
#   role_definition_name = "Azure Service Bus Data Sender"
#   principal_id         = module.logicapp_02.identity_principal_id
# }
#
# resource "azurerm_role_assignment" "logicapp_02_servicebus_receiver" {
#   scope                = module.servicebus.namespace_id
#   role_definition_name = "Azure Service Bus Data Receiver"
#   principal_id         = module.logicapp_02.identity_principal_id
# }

# RBAC Assignments for Storage (Platform)
resource "azurerm_role_assignment" "function_app_storage_blob_contributor" {
  scope                = module.storage_platform.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = module.function_app.identity_principal_id
}

resource "azurerm_role_assignment" "logicapp_01_storage_blob_contributor" {
  scope                = module.storage_platform.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = module.logicapp_01.identity_principal_id
}

# Temporarily commented out along with Logic App 02
# resource "azurerm_role_assignment" "logicapp_02_storage_blob_contributor" {
#   scope                = module.storage_platform.id
#   role_definition_name = "Storage Blob Data Contributor"
#   principal_id         = module.logicapp_02.identity_principal_id
# }
