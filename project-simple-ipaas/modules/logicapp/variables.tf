variable "service_plan_name" {
  description = "Name of the App Service Plan"
  type        = string
}

variable "logic_app_name" {
  description = "Name of the Logic App Standard"
  type        = string
}

variable "location" {
  description = "Azure region where resources will be created"
  type        = string
}

variable "resource_group_name" {
  description = "Name of the resource group where resources will be created"
  type        = string
}

variable "sku_name" {
  description = "SKU name for the App Service Plan (WS1, WS2, WS3 for Logic App Standard)"
  type        = string
  default     = "WS1"

  validation {
    condition     = contains(["WS1", "WS2", "WS3"], var.sku_name)
    error_message = "sku_name must be one of: WS1, WS2, WS3"
  }
}

variable "storage_account_name" {
  description = "Name of the storage account for Logic App runtime storage"
  type        = string
}

variable "storage_account_access_key" {
  description = "Access key for the storage account"
  type        = string
  sensitive   = true
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}
