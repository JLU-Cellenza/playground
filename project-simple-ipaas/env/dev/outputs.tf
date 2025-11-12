output "resource_group_name" {
  description = "Name of the resource group"
  value       = azurerm_resource_group.this.name
}

output "servicebus_namespace_name" {
  description = "Name of the Service Bus namespace"
  value       = module.servicebus.namespace_name
}

output "servicebus_queue_name" {
  description = "Name of the Service Bus inbound queue"
  value       = module.servicebus.inbound_queue_name
}

output "keyvault_name" {
  description = "Name of the Key Vault"
  value       = module.keyvault.vault_name
}

output "keyvault_uri" {
  description = "URI of the Key Vault"
  value       = module.keyvault.vault_uri
}

output "storage_account_name" {
  description = "Name of the storage account"
  value       = module.storage.storage_account_name
}

output "logic_app_name" {
  description = "Name of the Logic App"
  value       = module.logicapp.logic_app_name
}

output "logic_app_identity_principal_id" {
  description = "Principal ID of the Logic App's managed identity"
  value       = module.logicapp.identity_principal_id
}
