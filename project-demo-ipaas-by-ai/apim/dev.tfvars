# APIM Deployment Configuration - DEV Environment

# Resource group created by main platform
resource_group_name = "rg-dev-cellenza-mvpipaas-01"

# Log Analytics workspace created by main platform
log_analytics_workspace_name = "la-dev-cellenza-mvpipaas-01"

# APIM Configuration
apim_name           = "apim-dev-cellenza-mvpipaas-01"
apim_publisher_name = "Cellenza"
apim_publisher_email = "demo@cellenza.com"
apim_sku            = "Developer_1"

# Tags
tags = {
  environment     = "dev"
  project         = "mvpipaas"
  owner           = "cellenza"
  cost_center     = "demo"
  created_by      = "terraform"
  managed_by      = "terraform"
  deployment_date = "2025-11-12"
  component       = "apim"
}
