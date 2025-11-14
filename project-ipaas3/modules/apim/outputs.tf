# modules/apim/outputs.tf

output "apim_id" {
  description = "The ID of the API Management instance"
  value       = azurerm_api_management.this.id
}

output "apim_name" {
  description = "The name of the API Management instance"
  value       = azurerm_api_management.this.name
}

output "gateway_url" {
  description = "The gateway URL"
  value       = azurerm_api_management.this.gateway_url
}

output "developer_portal_url" {
  description = "The developer portal URL"
  value       = azurerm_api_management.this.developer_portal_url
}

output "management_api_url" {
  description = "The management API URL"
  value       = azurerm_api_management.this.management_api_url
}

output "identity_principal_id" {
  description = "The Principal ID of the managed identity"
  value       = azurerm_api_management.this.identity[0].principal_id
}
