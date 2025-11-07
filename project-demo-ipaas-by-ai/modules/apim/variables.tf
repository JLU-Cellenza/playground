variable "apim_name" {
  description = "The name of the API Management instance"
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

variable "publisher_name" {
  description = "The publisher name"
  type        = string
}

variable "publisher_email" {
  description = "The publisher email"
  type        = string
}

variable "sku_name" {
  description = "The SKU name (e.g., Developer_1, StandardV2_1)"
  type        = string
  default     = "Developer_1"
}

variable "log_analytics_workspace_id" {
  description = "The ID of the Log Analytics Workspace"
  type        = string
}

variable "tags" {
  description = "A mapping of tags to assign to the resource"
  type        = map(string)
  default     = {}
}
