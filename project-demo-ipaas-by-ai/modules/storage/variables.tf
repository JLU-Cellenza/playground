variable "storage_account_name" {
  description = "The name of the storage account"
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

variable "log_analytics_workspace_id" {
  description = "The ID of the Log Analytics Workspace for diagnostics"
  type        = string
}

variable "tags" {
  description = "A mapping of tags to assign to the resource"
  type        = map(string)
  default     = {}
}
