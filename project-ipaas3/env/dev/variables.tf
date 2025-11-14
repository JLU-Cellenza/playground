# env/dev/variables.tf

variable "resource_group_name" {
  description = "The name of the resource group"
  type        = string
}

variable "location" {
  description = "The Azure region where resources will be created"
  type        = string
}

variable "environment" {
  description = "The environment (dev, test, stg, prod)"
  type        = string

  validation {
    condition     = contains(["dev", "test", "stg", "prod"], var.environment)
    error_message = "Environment must be dev, test, stg, or prod"
  }
}

variable "organization" {
  description = "The organization abbreviation (3-6 characters)"
  type        = string

  validation {
    condition     = can(regex("^[a-z]{3,6}$", var.organization))
    error_message = "Organization must be 3-6 lowercase letters"
  }
}

variable "project" {
  description = "The project name (3-8 characters)"
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9]{3,8}$", var.project))
    error_message = "Project must be 3-8 lowercase alphanumeric characters"
  }
}

variable "log_retention_days" {
  description = "Log Analytics and Application Insights retention in days"
  type        = number
  default     = 30

  validation {
    condition     = var.log_retention_days >= 30 && var.log_retention_days <= 730
    error_message = "Log retention must be between 30 and 730 days"
  }
}

variable "cost_center" {
  description = "Cost center for billing"
  type        = string
  default     = "demo"
}

variable "owner" {
  description = "Owner of the resources"
  type        = string
  default     = "cellenza"
}
