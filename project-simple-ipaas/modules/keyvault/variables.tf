variable "key_vault_name" {
  description = "Name of the Key Vault (must be globally unique, 3-24 characters, alphanumeric and hyphens only)"
  type        = string

  validation {
    condition     = can(regex("^[a-zA-Z0-9-]{3,24}$", var.key_vault_name))
    error_message = "Key Vault name must be 3-24 characters, alphanumeric and hyphens only"
  }
}

variable "location" {
  description = "Azure region where the Key Vault will be created"
  type        = string
}

variable "resource_group_name" {
  description = "Name of the resource group where the Key Vault will be created"
  type        = string
}

variable "sku" {
  description = "SKU of the Key Vault (standard or premium)"
  type        = string
  default     = "standard"

  validation {
    condition     = contains(["standard", "premium"], var.sku)
    error_message = "SKU must be either standard or premium"
  }
}

variable "soft_delete_retention_days" {
  description = "Number of days to retain soft-deleted Key Vault (7-90 days)"
  type        = number
  default     = 7

  validation {
    condition     = var.soft_delete_retention_days >= 7 && var.soft_delete_retention_days <= 90
    error_message = "soft_delete_retention_days must be between 7 and 90"
  }
}

variable "purge_protection_enabled" {
  description = "Enable purge protection (recommended for production)"
  type        = bool
  default     = false
}

variable "public_network_access_enabled" {
  description = "Enable public network access to the Key Vault"
  type        = bool
  default     = true
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}
