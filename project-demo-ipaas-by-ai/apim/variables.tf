variable "resource_group_name" {
  description = "Name of the existing resource group"
  type        = string
}

variable "log_analytics_workspace_name" {
  description = "Name of the existing Log Analytics workspace"
  type        = string
}

variable "apim_name" {
  description = "Name of the API Management service"
  type        = string
}

variable "apim_publisher_name" {
  description = "Publisher name for APIM"
  type        = string
}

variable "apim_publisher_email" {
  description = "Publisher email for APIM"
  type        = string
}

variable "apim_sku" {
  description = "SKU for APIM (e.g., Developer_1, Premium_1)"
  type        = string
  default     = "Developer_1"
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}
