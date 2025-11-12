output "service_plan_id" {
  description = "The ID of the App Service Plan"
  value       = azurerm_service_plan.this.id
}

output "logic_app_id" {
  description = "The ID of the Logic App"
  value       = azurerm_logic_app_standard.this.id
}

output "logic_app_name" {
  description = "The name of the Logic App"
  value       = azurerm_logic_app_standard.this.name
}

output "identity_principal_id" {
  description = "The principal ID of the Logic App's managed identity"
  value       = azurerm_logic_app_standard.this.identity[0].principal_id
}
