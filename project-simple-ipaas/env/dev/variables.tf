variable "environment" {
  description = "Environment name (dev, test, stg, prod)"
  type        = string
  default     = "dev"
}

variable "organization" {
  description = "Organization or company abbreviation"
  type        = string
}

variable "project_name" {
  description = "Project name for resource naming"
  type        = string
}

variable "location" {
  description = "Azure region for all resources"
  type        = string
}

variable "owner" {
  description = "Owner email or team name"
  type        = string
}

variable "cost_center" {
  description = "Cost center or billing code"
  type        = string
}

# Service Bus variables
variable "servicebus_sku" {
  description = "Service Bus SKU (Standard or Premium)"
  type        = string
  default     = "Standard"
}

variable "servicebus_queue_name" {
  description = "Name of the inbound Service Bus queue"
  type        = string
  default     = "inbound"
}

# Key Vault variables
variable "keyvault_sku" {
  description = "Key Vault SKU (standard or premium)"
  type        = string
  default     = "standard"
}

variable "keyvault_soft_delete_retention_days" {
  description = "Soft delete retention period for Key Vault (7-90 days)"
  type        = number
  default     = 7
}

variable "keyvault_purge_protection" {
  description = "Enable purge protection for Key Vault (recommended for production)"
  type        = bool
  default     = false
}

# Storage Account variables
variable "storage_account_tier" {
  description = "Storage account tier (Standard or Premium)"
  type        = string
  default     = "Standard"
}

variable "storage_replication_type" {
  description = "Storage account replication type (LRS, GRS, RAGRS, ZRS)"
  type        = string
  default     = "LRS"
}

variable "storage_containers" {
  description = "List of blob container names to create"
  type        = list(string)
  default     = ["config", "workflows"]
}

# Logic App variables
variable "logic_app_sku" {
  description = "App Service Plan SKU for Logic App (WS1, WS2, WS3)"
  type        = string
  default     = "WS1"
}
