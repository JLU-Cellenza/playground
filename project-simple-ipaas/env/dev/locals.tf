locals {
  # Common naming components
  environment = var.environment
  org         = var.organization
  project     = var.project_name
  location    = var.location

  # Common tags applied to all resources
  common_tags = {
    environment = local.environment
    project     = local.project
    owner       = var.owner
    cost_center = var.cost_center
    created_by  = "terraform"
    managed_by  = "terraform"
  }

  # Resource naming following pattern: <svc>-<env>-<org>-<project>-<purpose>-<instance>
  resource_group_name  = "rg-${local.environment}-${local.org}-${local.project}"
  servicebus_name      = "svb-${local.environment}-${local.org}-${local.project}-01"
  keyvault_name        = "kv-${local.environment}-${local.org}-${local.project}-01"
  storage_account_name = "st${local.environment}${local.org}${local.project}01"
  service_plan_name    = "asp-${local.environment}-${local.org}-${local.project}-01"
  logic_app_name       = "loa-${local.environment}-${local.org}-${local.project}-01"
}
