# Environment: dev
# Azure Subscription ID should be set via ARM_SUBSCRIPTION_ID environment variable

# Existing Resources (created by main platform deployment)
resource_group_name          = "rg-dev-clz-ipaas3-01"
log_analytics_workspace_name = "la-dev-clz-ipaas3-01"

# Location
location = "francecentral"

# Environment
environment  = "dev"
organization = "clz"
project      = "ipaas3"

# API Management
apim_publisher_name  = "Cellenza"
apim_publisher_email = "admin@cellenza.com"
apim_sku_name        = "StandardV2_1"

# Tags
cost_center = "demo"
owner       = "cellenza"
