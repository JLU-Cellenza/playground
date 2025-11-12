output "apim_gateway_url" {
  description = "API Management gateway URL"
  value       = module.apim.gateway_url
}

output "apim_developer_portal_url" {
  description = "API Management developer portal URL"
  value       = module.apim.developer_portal_url
}

output "apim_id" {
  description = "API Management resource ID"
  value       = module.apim.apim_id
}

output "apim_principal_id" {
  description = "API Management managed identity principal ID"
  value       = module.apim.identity_principal_id
}
