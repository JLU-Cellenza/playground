variable "namespace_name" {
  description = "Name of the Service Bus namespace"
  type        = string
}

variable "location" {
  description = "Azure region where the Service Bus namespace will be created"
  type        = string
}

variable "resource_group_name" {
  description = "Name of the resource group where the Service Bus namespace will be created"
  type        = string
}

variable "sku" {
  description = "SKU of the Service Bus namespace (Standard or Premium)"
  type        = string
  default     = "Standard"

  validation {
    condition     = contains(["Standard", "Premium"], var.sku)
    error_message = "SKU must be either Standard or Premium"
  }
}

variable "inbound_queue_name" {
  description = "Name of the inbound queue"
  type        = string
  default     = "inbound"
}

variable "max_delivery_count" {
  description = "Maximum number of delivery attempts before message is dead-lettered"
  type        = number
  default     = 10

  validation {
    condition     = var.max_delivery_count > 0 && var.max_delivery_count <= 2000
    error_message = "max_delivery_count must be between 1 and 2000"
  }
}

variable "lock_duration" {
  description = "ISO 8601 duration for message lock (e.g., PT5M for 5 minutes)"
  type        = string
  default     = "PT5M"
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}
