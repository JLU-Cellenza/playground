# apim/outputs.tf

output "apim_id" {
  description = "The ID of the API Management instance"
  value       = module.apim.apim_id
}

output "apim_name" {
  description = "The name of the API Management instance"
  value       = module.apim.apim_name
}

output "gateway_url" {
  description = "The gateway URL"
  value       = module.apim.gateway_url
}

output "developer_portal_url" {
  description = "The developer portal URL"
  value       = module.apim.developer_portal_url
}

output "management_api_url" {
  description = "The management API URL"
  value       = module.apim.management_api_url
}

output "identity_principal_id" {
  description = "The Principal ID of the APIM managed identity"
  value       = module.apim.identity_principal_id
}
