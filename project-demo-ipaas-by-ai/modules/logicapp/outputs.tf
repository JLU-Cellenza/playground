output "logic_app_id" {
  description = "The ID of the Logic App"
  value       = azurerm_logic_app_standard.this.id
}

output "logic_app_name" {
  description = "The name of the Logic App"
  value       = azurerm_logic_app_standard.this.name
}

output "default_hostname" {
  description = "The default hostname of the Logic App"
  value       = azurerm_logic_app_standard.this.default_hostname
}

output "identity_principal_id" {
  description = "The Principal ID of the managed identity"
  value       = azurerm_logic_app_standard.this.identity[0].principal_id
}

output "identity_tenant_id" {
  description = "The Tenant ID of the managed identity"
  value       = azurerm_logic_app_standard.this.identity[0].tenant_id
}
