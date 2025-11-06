variable "namespace_name" {
  description = "The name of the Service Bus namespace"
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

variable "sku" {
  description = "The SKU of the Service Bus namespace"
  type        = string
  default     = "Standard"
}

variable "capacity" {
  description = "The capacity of the Service Bus namespace"
  type        = number
  default     = 0
}

variable "queue_names" {
  description = "List of queue names to create"
  type        = list(string)
  default     = []
}

variable "max_delivery_count" {
  description = "Maximum delivery count before message is dead-lettered"
  type        = number
  default     = 10
}

variable "lock_duration" {
  description = "Lock duration for messages"
  type        = string
  default     = "PT5M"
}

variable "default_message_ttl" {
  description = "Default message time to live"
  type        = string
  default     = "P14D"
}

variable "log_analytics_workspace_id" {
  description = "The ID of the Log Analytics Workspace"
  type        = string
  default     = null
}

variable "tags" {
  description = "A mapping of tags to assign to the resource"
  type        = map(string)
  default     = {}
}
