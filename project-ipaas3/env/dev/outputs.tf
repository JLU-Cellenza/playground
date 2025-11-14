# env/dev/outputs.tf

# Resource Group
output "resource_group_name" {
  description = "The name of the resource group"
  value       = azurerm_resource_group.this.name
}

output "resource_group_id" {
  description = "The ID of the resource group"
  value       = azurerm_resource_group.this.id
}

# Log Analytics
output "log_analytics_workspace_id" {
  description = "The ID of the Log Analytics Workspace"
  value       = module.log_analytics.workspace_id
}

output "log_analytics_workspace_name" {
  description = "The name of the Log Analytics Workspace"
  value       = module.log_analytics.workspace_name
}

# Application Insights
output "app_insights_id" {
  description = "The ID of Application Insights"
  value       = module.app_insights.id
}

output "app_insights_instrumentation_key" {
  description = "Application Insights instrumentation key"
  value       = module.app_insights.instrumentation_key
  sensitive   = true
}

output "app_insights_connection_string" {
  description = "Application Insights connection string"
  value       = module.app_insights.connection_string
  sensitive   = true
}

# Key Vault
output "keyvault_id" {
  description = "The ID of the Key Vault"
  value       = module.keyvault.vault_id
}

output "keyvault_uri" {
  description = "The URI of the Key Vault"
  value       = module.keyvault.vault_uri
}

output "keyvault_name" {
  description = "The name of the Key Vault"
  value       = module.keyvault.vault_name
}

# Service Bus
output "servicebus_namespace_id" {
  description = "The ID of the Service Bus namespace"
  value       = module.servicebus.namespace_id
}

output "servicebus_namespace_name" {
  description = "The name of the Service Bus namespace"
  value       = module.servicebus.namespace_name
}

output "servicebus_namespace_fqdn" {
  description = "The FQDN of the Service Bus namespace"
  value       = module.servicebus.namespace_fqdn
}

# Storage Config
output "storage_config_name" {
  description = "The name of the platform config storage account"
  value       = module.storage_config.name
}

output "storage_config_primary_blob_endpoint" {
  description = "The primary blob endpoint for config storage"
  value       = module.storage_config.primary_blob_endpoint
}

# Logic Apps
output "logicapp_01_name" {
  description = "The name of Logic App 01"
  value       = module.logicapp_01.logic_app_name
}

output "logicapp_02_name" {
  description = "The name of Logic App 02"
  value       = module.logicapp_02.logic_app_name
}

output "logicapp_03_name" {
  description = "The name of Logic App 03"
  value       = module.logicapp_03.logic_app_name
}

output "logicapp_04_name" {
  description = "The name of Logic App 04"
  value       = module.logicapp_04.logic_app_name
}

output "logicapp_05_name" {
  description = "The name of Logic App 05"
  value       = module.logicapp_05.logic_app_name
}

output "logicapp_01_identity_principal_id" {
  description = "Managed identity principal ID for Logic App 01"
  value       = module.logicapp_01.identity_principal_id
}

output "logicapp_02_identity_principal_id" {
  description = "Managed identity principal ID for Logic App 02"
  value       = module.logicapp_02.identity_principal_id
}

output "logicapp_03_identity_principal_id" {
  description = "Managed identity principal ID for Logic App 03"
  value       = module.logicapp_03.identity_principal_id
}

output "logicapp_04_identity_principal_id" {
  description = "Managed identity principal ID for Logic App 04"
  value       = module.logicapp_04.identity_principal_id
}

output "logicapp_05_identity_principal_id" {
  description = "Managed identity principal ID for Logic App 05"
  value       = module.logicapp_05.identity_principal_id
}
