# env/dev/outputs.tf

output "resource_group_name" {
  description = "The name of the resource group"
  value       = azurerm_resource_group.this.name
}

output "log_analytics_workspace_id" {
  description = "Log Analytics Workspace ID"
  value       = module.log_analytics.workspace_id
}

output "app_insights_instrumentation_key" {
  description = "Application Insights instrumentation key"
  value       = module.app_insights.instrumentation_key
  sensitive   = true
}

output "servicebus_namespace_name" {
  description = "Service Bus namespace name"
  value       = module.servicebus.namespace_name
}

output "servicebus_connection_string" {
  description = "Service Bus connection string"
  value       = module.servicebus.primary_connection_string
  sensitive   = true
}

output "function_app_name" {
  description = "Function App name"
  value       = module.function_app.function_app_name
}

output "function_app_url" {
  description = "Function App URL"
  value       = "https://${module.function_app.default_hostname}"
}

output "logicapp_01_name" {
  description = "Logic App 01 name"
  value       = module.logicapp_01.logic_app_name
}

output "logicapp_01_url" {
  description = "Logic App 01 URL"
  value       = "https://${module.logicapp_01.default_hostname}"
}

output "logicapp_02_name" {
  description = "Logic App 02 name"
  value       = module.logicapp_02.logic_app_name
}

output "logicapp_02_url" {
  description = "Logic App 02 URL"
  value       = "https://${module.logicapp_02.default_hostname}"
}

# Temporarily commented out while APIM module is disabled
/*
output "apim_gateway_url" {
  description = "API Management gateway URL"
  value       = module.apim.gateway_url
}

output "apim_developer_portal_url" {
  description = "API Management developer portal URL"
  value       = module.apim.developer_portal_url
}
*/

output "storage_platform_name" {
  description = "Platform storage account name"
  value       = module.storage_platform.name
}

output "storage_platform_blob_endpoint" {
  description = "Platform storage blob endpoint"
  value       = module.storage_platform.primary_blob_endpoint
}
