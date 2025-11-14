# apim/variables.tf

variable "resource_group_name" {
  description = "The name of the existing resource group (created by main platform)"
  type        = string
}

variable "log_analytics_workspace_name" {
  description = "The name of the existing Log Analytics Workspace (created by main platform)"
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

variable "apim_publisher_name" {
  description = "The publisher name for APIM"
  type        = string
}

variable "apim_publisher_email" {
  description = "The publisher email for APIM"
  type        = string
}

variable "apim_sku_name" {
  description = "The SKU name for APIM (e.g., Developer_1, StandardV2_1)"
  type        = string
  default     = "StandardV2_1"
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
