# modules/logicapp/variables.tf

variable "logic_app_name" {
  description = "The name of the Logic App Standard"
  type        = string
}

variable "app_service_plan_id" {
  description = "The ID of an existing App Service Plan (can be shared across multiple Logic Apps)"
  type        = string
}

variable "location" {
  description = "The Azure region"
  type        = string
}

variable "resource_group_name" {
  description = "The resource group name"
  type        = string
}

variable "storage_account_name" {
  description = "The storage account name for the Logic App"
  type        = string
}

variable "storage_account_access_key" {
  description = "The storage account access key"
  type        = string
  sensitive   = true
}

variable "storage_connection_string" {
  description = "The storage account connection string"
  type        = string
  sensitive   = true
}

variable "app_insights_connection_string" {
  description = "Application Insights connection string"
  type        = string
  sensitive   = true
  default     = null
}

variable "app_insights_instrumentation_key" {
  description = "Application Insights instrumentation key"
  type        = string
  sensitive   = true
  default     = null
}

variable "servicebus_namespace_fqdn" {
  description = "Service Bus namespace FQDN for managed identity connection"
  type        = string
  default     = null
}

variable "additional_app_settings" {
  description = "Additional app settings"
  type        = map(string)
  default     = {}
}

variable "log_analytics_workspace_id" {
  description = "The ID of the Log Analytics Workspace for diagnostics"
  type        = string
  default     = null
}

variable "tags" {
  description = "A mapping of tags to assign to the resource"
  type        = map(string)
  default     = {}
}
