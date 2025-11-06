output "function_app_id" {
  description = "The ID of the Function App"
  value       = azurerm_linux_function_app.this.id
}

output "function_app_name" {
  description = "The name of the Function App"
  value       = azurerm_linux_function_app.this.name
}

output "default_hostname" {
  description = "The default hostname of the Function App"
  value       = azurerm_linux_function_app.this.default_hostname
}

output "identity_principal_id" {
  description = "The Principal ID of the managed identity"
  value       = azurerm_linux_function_app.this.identity[0].principal_id
}

output "identity_tenant_id" {
  description = "The Tenant ID of the managed identity"
  value       = azurerm_linux_function_app.this.identity[0].tenant_id
}
