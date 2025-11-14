# modules/storage/variables.tf

variable "storage_account_name" {
  description = "The name of the storage account (3-24 lowercase alphanumeric, must end with 2-digit suffix)"
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9]{3,24}$", var.storage_account_name)) && can(regex("[0-9]{2}$", var.storage_account_name))
    error_message = "Storage account name must be 3-24 lowercase alphanumeric characters with 2-digit suffix (e.g., 01)"
  }
}

variable "location" {
  description = "The Azure region"
  type        = string
}

variable "resource_group_name" {
  description = "The resource group name"
  type        = string
}

variable "account_tier" {
  description = "The storage account tier"
  type        = string
  default     = "Standard"
}

variable "replication_type" {
  description = "The storage replication type"
  type        = string
  default     = "LRS"
}

variable "account_kind" {
  description = "The storage account kind"
  type        = string
  default     = "StorageV2"
}

variable "access_tier" {
  description = "The access tier for the storage account"
  type        = string
  default     = "Hot"
}

variable "containers" {
  description = "List of container names to create"
  type        = list(string)
  default     = []
}

variable "tables" {
  description = "List of table names to create"
  type        = list(string)
  default     = []
}

variable "log_analytics_workspace_id" {
  description = "The ID of the Log Analytics Workspace for diagnostics"
  type        = string
}

variable "tags" {
  description = "A mapping of tags to assign to the resource"
  type        = map(string)
  default     = {}
}
