# env/dev/variables.tf

variable "environment" {
  description = "The environment name"
  type        = string
  default     = "prd"
}

variable "organization" {
  description = "The organization name"
  type        = string
  default     = "cellenza"
}

variable "project" {
  description = "The project name"
  type        = string
  default     = "mvpipaas"
}

variable "location" {
  description = "The Azure region"
  type        = string
  default     = "francecentral"
}

variable "resource_group_name" {
  description = "The name of the resource group"
  type        = string
}

variable "log_retention_days" {
  description = "Log retention in days"
  type        = number
  default     = 30
}

variable "apim_publisher_name" {
  description = "API Management publisher name"
  type        = string
}

variable "apim_publisher_email" {
  description = "API Management publisher email"
  type        = string
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
