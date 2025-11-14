# env/dev/locals.tf

locals {
  common_tags = {
    environment = var.environment
    project     = var.project
    organization = var.organization
    cost_center = var.cost_center
    owner       = var.owner
    managed_by  = "terraform"
  }
}
