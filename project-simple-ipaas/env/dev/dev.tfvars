# Environment Configuration
environment  = "dev"
organization = "cellenza"
project_name = "simpleipaas"
location     = "francecentral"

# Ownership and Billing
owner       = "platform-team@example.com"
cost_center = "IT-INTEGRATION"

# Service Bus Configuration
servicebus_sku        = "Standard"
servicebus_queue_name = "inbound"

# Key Vault Configuration
keyvault_sku                        = "standard"
keyvault_soft_delete_retention_days = 7
keyvault_purge_protection           = false # Set to true for production

# Storage Account Configuration
storage_account_tier     = "Standard"
storage_replication_type = "LRS" # Use GRS or ZRS for production
storage_containers       = ["config", "workflows"]

# Logic App Configuration
logic_app_sku = "WS1" # WS2 or WS3 for production
