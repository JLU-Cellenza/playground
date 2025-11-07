# Environment: prd
# Azure Subscription ID should be set via ARM_SUBSCRIPTION_ID environment variable

# Resource Group
resource_group_name = "rg-prd-cellenza-mvpipaas-01"

# Location
location = "francecentral"

# Environment
environment  = "prd"
organization = "cellenza"
project      = "mvpipaas"

# Log Analytics
log_retention_days = 90

# API Management
apim_publisher_name  = "Cellenza"
apim_publisher_email = "admin@cellenza.com"

# Tags
cost_center = "production"
owner       = "cellenza"
