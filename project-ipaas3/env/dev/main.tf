# env/dev/main.tf

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
    # key                  = "project-ipaas3-dev.tfstate"
  }
}

provider "azurerm" {
  features {
    api_management {
      purge_soft_delete_on_destroy = true
      recover_soft_deleted         = true
    }
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

# Key Vault
module "keyvault" {
  source = "../../modules/keyvault"

  key_vault_name                = "kv-${var.environment}-${var.organization}-${var.project}-01"
  location                      = var.location
  resource_group_name           = azurerm_resource_group.this.name
  sku                           = "standard"
  soft_delete_retention_days    = 7
  purge_protection_enabled      = false
  public_network_access_enabled = true
  log_analytics_workspace_id    = module.log_analytics.workspace_id

  tags = local.common_tags
}

# Grant Terraform service principal "Key Vault Secrets Officer" role
resource "azurerm_role_assignment" "terraform_keyvault_secrets_officer" {
  scope                = module.keyvault.vault_id
  role_definition_name = "Key Vault Secrets Officer"
  principal_id         = data.azurerm_client_config.current.object_id
}

# Service Bus with inbound-queue
module "servicebus" {
  source = "../../modules/servicebus"

  namespace_name             = "sb-${var.environment}-${var.organization}-${var.project}-01"
  location                   = var.location
  resource_group_name        = azurerm_resource_group.this.name
  sku                        = "Standard"
  queue_names                = ["inbound-queue"]
  log_analytics_workspace_id = module.log_analytics.workspace_id

  tags = local.common_tags
}

# Storage Account for Platform Configuration Tables
module "storage_config" {
  source = "../../modules/storage"

  storage_account_name       = "stcfg${var.environment}${var.organization}${var.project}01"
  location                   = var.location
  resource_group_name        = azurerm_resource_group.this.name
  account_tier               = "Standard"
  replication_type           = "LRS"
  containers                 = []
  tables                     = ["platformconfig", "metadata"]
  log_analytics_workspace_id = module.log_analytics.workspace_id

  tags = local.common_tags
}

# Storage Accounts for Logic Apps (5 total)
module "storage_logicapp_01" {
  source = "../../modules/storage"

  storage_account_name       = "stla${var.environment}${var.organization}${var.project}01"
  location                   = var.location
  resource_group_name        = azurerm_resource_group.this.name
  account_tier               = "Standard"
  replication_type           = "LRS"
  containers                 = []
  tables                     = []
  log_analytics_workspace_id = module.log_analytics.workspace_id

  tags = local.common_tags
}

module "storage_logicapp_02" {
  source = "../../modules/storage"

  storage_account_name       = "stla${var.environment}${var.organization}${var.project}02"
  location                   = var.location
  resource_group_name        = azurerm_resource_group.this.name
  account_tier               = "Standard"
  replication_type           = "LRS"
  containers                 = []
  tables                     = []
  log_analytics_workspace_id = module.log_analytics.workspace_id

  tags = local.common_tags
}

module "storage_logicapp_03" {
  source = "../../modules/storage"

  storage_account_name       = "stla${var.environment}${var.organization}${var.project}03"
  location                   = var.location
  resource_group_name        = azurerm_resource_group.this.name
  account_tier               = "Standard"
  replication_type           = "LRS"
  containers                 = []
  tables                     = []
  log_analytics_workspace_id = module.log_analytics.workspace_id

  tags = local.common_tags
}

module "storage_logicapp_04" {
  source = "../../modules/storage"

  storage_account_name       = "stla${var.environment}${var.organization}${var.project}04"
  location                   = var.location
  resource_group_name        = azurerm_resource_group.this.name
  account_tier               = "Standard"
  replication_type           = "LRS"
  containers                 = []
  tables                     = []
  log_analytics_workspace_id = module.log_analytics.workspace_id

  tags = local.common_tags
}

module "storage_logicapp_05" {
  source = "../../modules/storage"

  storage_account_name       = "stla${var.environment}${var.organization}${var.project}05"
  location                   = var.location
  resource_group_name        = azurerm_resource_group.this.name
  account_tier               = "Standard"
  replication_type           = "LRS"
  containers                 = []
  tables                     = []
  log_analytics_workspace_id = module.log_analytics.workspace_id

  tags = local.common_tags
}

# App Service Plans (2 plans for 5 Logic Apps)
resource "azurerm_service_plan" "plan_01" {
  name                = "asp-${var.environment}-${var.organization}-${var.project}-01"
  location            = var.location
  resource_group_name = azurerm_resource_group.this.name
  os_type             = "Windows"
  sku_name            = "WS1"

  tags = local.common_tags
}

resource "azurerm_service_plan" "plan_02" {
  name                = "asp-${var.environment}-${var.organization}-${var.project}-02"
  location            = var.location
  resource_group_name = azurerm_resource_group.this.name
  os_type             = "Windows"
  sku_name            = "WS1"

  tags = local.common_tags
}

# Logic Apps - Plan 1 (3 Logic Apps)
module "logicapp_01" {
  source = "../../modules/logicapp"

  logic_app_name                 = "logic-${var.environment}-${var.organization}-${var.project}-01"
  app_service_plan_id            = azurerm_service_plan.plan_01.id
  location                       = var.location
  resource_group_name            = azurerm_resource_group.this.name
  storage_account_name           = module.storage_logicapp_01.name
  storage_account_access_key     = module.storage_logicapp_01.primary_access_key
  storage_connection_string      = module.storage_logicapp_01.primary_connection_string
  servicebus_namespace_fqdn      = module.servicebus.namespace_fqdn
  app_insights_connection_string = module.app_insights.connection_string
  log_analytics_workspace_id     = module.log_analytics.workspace_id

  tags = local.common_tags
}

module "logicapp_02" {
  source = "../../modules/logicapp"

  logic_app_name                 = "logic-${var.environment}-${var.organization}-${var.project}-02"
  app_service_plan_id            = azurerm_service_plan.plan_01.id
  location                       = var.location
  resource_group_name            = azurerm_resource_group.this.name
  storage_account_name           = module.storage_logicapp_02.name
  storage_account_access_key     = module.storage_logicapp_02.primary_access_key
  storage_connection_string      = module.storage_logicapp_02.primary_connection_string
  servicebus_namespace_fqdn      = module.servicebus.namespace_fqdn
  app_insights_connection_string = module.app_insights.connection_string
  log_analytics_workspace_id     = module.log_analytics.workspace_id

  tags = local.common_tags
}

module "logicapp_03" {
  source = "../../modules/logicapp"

  logic_app_name                 = "logic-${var.environment}-${var.organization}-${var.project}-03"
  app_service_plan_id            = azurerm_service_plan.plan_01.id
  location                       = var.location
  resource_group_name            = azurerm_resource_group.this.name
  storage_account_name           = module.storage_logicapp_03.name
  storage_account_access_key     = module.storage_logicapp_03.primary_access_key
  storage_connection_string      = module.storage_logicapp_03.primary_connection_string
  servicebus_namespace_fqdn      = module.servicebus.namespace_fqdn
  app_insights_connection_string = module.app_insights.connection_string
  log_analytics_workspace_id     = module.log_analytics.workspace_id

  tags = local.common_tags
}

# Logic Apps - Plan 2 (2 Logic Apps)
module "logicapp_04" {
  source = "../../modules/logicapp"

  logic_app_name                 = "logic-${var.environment}-${var.organization}-${var.project}-04"
  app_service_plan_id            = azurerm_service_plan.plan_02.id
  location                       = var.location
  resource_group_name            = azurerm_resource_group.this.name
  storage_account_name           = module.storage_logicapp_04.name
  storage_account_access_key     = module.storage_logicapp_04.primary_access_key
  storage_connection_string      = module.storage_logicapp_04.primary_connection_string
  servicebus_namespace_fqdn      = module.servicebus.namespace_fqdn
  app_insights_connection_string = module.app_insights.connection_string
  log_analytics_workspace_id     = module.log_analytics.workspace_id

  tags = local.common_tags
}

module "logicapp_05" {
  source = "../../modules/logicapp"

  logic_app_name                 = "logic-${var.environment}-${var.organization}-${var.project}-05"
  app_service_plan_id            = azurerm_service_plan.plan_02.id
  location                       = var.location
  resource_group_name            = azurerm_resource_group.this.name
  storage_account_name           = module.storage_logicapp_05.name
  storage_account_access_key     = module.storage_logicapp_05.primary_access_key
  storage_connection_string      = module.storage_logicapp_05.primary_connection_string
  servicebus_namespace_fqdn      = module.servicebus.namespace_fqdn
  app_insights_connection_string = module.app_insights.connection_string
  log_analytics_workspace_id     = module.log_analytics.workspace_id

  tags = local.common_tags
}

# RBAC: Grant Logic Apps access to Service Bus
resource "azurerm_role_assignment" "logicapp_01_servicebus" {
  scope                = module.servicebus.namespace_id
  role_definition_name = "Azure Service Bus Data Receiver"
  principal_id         = module.logicapp_01.identity_principal_id
}

resource "azurerm_role_assignment" "logicapp_02_servicebus" {
  scope                = module.servicebus.namespace_id
  role_definition_name = "Azure Service Bus Data Receiver"
  principal_id         = module.logicapp_02.identity_principal_id
}

resource "azurerm_role_assignment" "logicapp_03_servicebus" {
  scope                = module.servicebus.namespace_id
  role_definition_name = "Azure Service Bus Data Receiver"
  principal_id         = module.logicapp_03.identity_principal_id
}

resource "azurerm_role_assignment" "logicapp_04_servicebus" {
  scope                = module.servicebus.namespace_id
  role_definition_name = "Azure Service Bus Data Receiver"
  principal_id         = module.logicapp_04.identity_principal_id
}

resource "azurerm_role_assignment" "logicapp_05_servicebus" {
  scope                = module.servicebus.namespace_id
  role_definition_name = "Azure Service Bus Data Receiver"
  principal_id         = module.logicapp_05.identity_principal_id
}

# RBAC: Grant Logic Apps access to Key Vault secrets
resource "azurerm_role_assignment" "logicapp_01_keyvault" {
  scope                = module.keyvault.vault_id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = module.logicapp_01.identity_principal_id
}

resource "azurerm_role_assignment" "logicapp_02_keyvault" {
  scope                = module.keyvault.vault_id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = module.logicapp_02.identity_principal_id
}

resource "azurerm_role_assignment" "logicapp_03_keyvault" {
  scope                = module.keyvault.vault_id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = module.logicapp_03.identity_principal_id
}

resource "azurerm_role_assignment" "logicapp_04_keyvault" {
  scope                = module.keyvault.vault_id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = module.logicapp_04.identity_principal_id
}

resource "azurerm_role_assignment" "logicapp_05_keyvault" {
  scope                = module.keyvault.vault_id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = module.logicapp_05.identity_principal_id
}

# RBAC: Grant Logic Apps access to their Storage Accounts (for workflow state management)
resource "azurerm_role_assignment" "logicapp_01_storage" {
  scope                = module.storage_logicapp_01.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = module.logicapp_01.identity_principal_id
}

resource "azurerm_role_assignment" "logicapp_02_storage" {
  scope                = module.storage_logicapp_02.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = module.logicapp_02.identity_principal_id
}

resource "azurerm_role_assignment" "logicapp_03_storage" {
  scope                = module.storage_logicapp_03.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = module.logicapp_03.identity_principal_id
}

resource "azurerm_role_assignment" "logicapp_04_storage" {
  scope                = module.storage_logicapp_04.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = module.logicapp_04.identity_principal_id
}

resource "azurerm_role_assignment" "logicapp_05_storage" {
  scope                = module.storage_logicapp_05.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = module.logicapp_05.identity_principal_id
}

# RBAC: Grant Logic Apps access to Config Storage Account (for table access)
resource "azurerm_role_assignment" "logicapp_01_storage_config" {
  scope                = module.storage_config.id
  role_definition_name = "Storage Table Data Contributor"
  principal_id         = module.logicapp_01.identity_principal_id
}

resource "azurerm_role_assignment" "logicapp_02_storage_config" {
  scope                = module.storage_config.id
  role_definition_name = "Storage Table Data Contributor"
  principal_id         = module.logicapp_02.identity_principal_id
}

resource "azurerm_role_assignment" "logicapp_03_storage_config" {
  scope                = module.storage_config.id
  role_definition_name = "Storage Table Data Contributor"
  principal_id         = module.logicapp_03.identity_principal_id
}

resource "azurerm_role_assignment" "logicapp_04_storage_config" {
  scope                = module.storage_config.id
  role_definition_name = "Storage Table Data Contributor"
  principal_id         = module.logicapp_04.identity_principal_id
}

resource "azurerm_role_assignment" "logicapp_05_storage_config" {
  scope                = module.storage_config.id
  role_definition_name = "Storage Table Data Contributor"
  principal_id         = module.logicapp_05.identity_principal_id
}

# Store Service Bus connection string in Key Vault
resource "azurerm_key_vault_secret" "servicebus_connection" {
  depends_on = [azurerm_role_assignment.terraform_keyvault_secrets_officer]

  name         = "servicebus-connection-string"
  value        = module.servicebus.primary_connection_string
  key_vault_id = module.keyvault.vault_id
}

# Store Storage Config connection string in Key Vault
resource "azurerm_key_vault_secret" "storage_config_connection" {
  depends_on = [azurerm_role_assignment.terraform_keyvault_secrets_officer]

  name         = "storage-config-connection-string"
  value        = module.storage_config.primary_connection_string
  key_vault_id = module.keyvault.vault_id
}
