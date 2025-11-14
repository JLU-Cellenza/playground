# Create or reference existing resource group
resource "azurerm_resource_group" "this" {
  name     = local.resource_group_name
  location = local.location
  tags     = local.common_tags
}

# Storage Account (must be created before Logic App)
module "storage" {
  source = "../../modules/storage"

  storage_account_name     = local.storage_account_name
  location                 = azurerm_resource_group.this.location
  resource_group_name      = azurerm_resource_group.this.name
  account_tier             = var.storage_account_tier
  account_replication_type = var.storage_replication_type
  containers               = var.storage_containers

  tags = local.common_tags
}

# Key Vault for secrets management
module "keyvault" {
  source = "../../modules/keyvault"

  key_vault_name             = local.keyvault_name
  location                   = azurerm_resource_group.this.location
  resource_group_name        = azurerm_resource_group.this.name
  sku                        = var.keyvault_sku
  soft_delete_retention_days = var.keyvault_soft_delete_retention_days
  purge_protection_enabled   = var.keyvault_purge_protection

  tags = local.common_tags
}

# Service Bus for messaging
module "servicebus" {
  source = "../../modules/servicebus"

  namespace_name      = local.servicebus_name
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  sku                 = var.servicebus_sku
  inbound_queue_name  = var.servicebus_queue_name

  tags = local.common_tags
}

# Logic App Standard for workflows
module "logicapp" {
  source = "../../modules/logicapp"

  service_plan_name          = local.service_plan_name
  logic_app_name             = local.logic_app_name
  location                   = azurerm_resource_group.this.location
  resource_group_name        = azurerm_resource_group.this.name
  sku_name                   = var.logic_app_sku
  storage_account_name       = module.storage.storage_account_name
  storage_account_access_key = module.storage.primary_access_key

  tags = local.common_tags
}

# RBAC: Grant Terraform service principal (GitHub Actions) access to Key Vault secrets
# This is needed for Terraform to create/manage secrets during deployment
data "azurerm_client_config" "current" {}

resource "azurerm_role_assignment" "terraform_keyvault_secrets_officer" {
  scope                = module.keyvault.vault_id
  role_definition_name = "Key Vault Secrets Officer"
  principal_id         = data.azurerm_client_config.current.object_id
}

# RBAC: Grant Logic App Managed Identity access to Key Vault secrets
resource "azurerm_role_assignment" "logicapp_keyvault_secrets_user" {
  scope                = module.keyvault.vault_id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = module.logicapp.identity_principal_id
}

# RBAC: Grant Logic App Managed Identity access to Service Bus (sender/receiver)
resource "azurerm_role_assignment" "logicapp_servicebus_data_owner" {
  scope                = module.servicebus.namespace_id
  role_definition_name = "Azure Service Bus Data Owner"
  principal_id         = module.logicapp.identity_principal_id
}

# Store Service Bus connection string in Key Vault
resource "azurerm_key_vault_secret" "servicebus_connection_string" {
  depends_on = [
    azurerm_role_assignment.logicapp_keyvault_secrets_user,
    azurerm_role_assignment.terraform_keyvault_secrets_officer
  ]

  name         = "servicebus-connection-string"
  value        = module.servicebus.primary_connection_string
  key_vault_id = module.keyvault.vault_id
}

# Store Storage Account connection string in Key Vault
resource "azurerm_key_vault_secret" "storage_connection_string" {
  depends_on = [
    azurerm_role_assignment.logicapp_keyvault_secrets_user,
    azurerm_role_assignment.terraform_keyvault_secrets_officer
  ]

  name         = "storage-connection-string"
  value        = module.storage.primary_connection_string
  key_vault_id = module.keyvault.vault_id
}
