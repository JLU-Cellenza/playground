variable "app_insights_name" {
  description = "The name of the Application Insights instance"
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
variable "workspace_id" {
  description = "The Log Analytics Workspace ID"
  type        = string
}
variable "application_type" {
  description = "The application type"
  type        = string
  default     = "web"
}
variable "retention_in_days" {
  description = "Data retention in days"
  type        = number
  default     = 30
}
variable "tags" {
  description = "Tags to assign"
  type        = map(string)
  default     = {}
}
