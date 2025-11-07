# env/dev/locals.tf

locals {
  common_tags = {
    project         = var.project
    environment     = var.environment
    owner           = var.owner
    cost_center     = var.cost_center
    created_by      = "terraform"
    managed_by      = "terraform"
    deployment_date = formatdate("YYYY-MM-DD", timestamp())
  }
}
