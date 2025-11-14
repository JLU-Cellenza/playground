# Storage Account Module

This module creates an Azure Storage Account with optional containers and tables.

## Resources Created

- `azurerm_storage_account` - Storage account
- `azurerm_storage_container` - Blob containers (optional)
- `azurerm_storage_table` - Storage tables (optional)

## Usage

```hcl
module "storage_config" {
  source = "../../modules/storage"

  storage_account_name       = "stcfgdevclzipaas301"
  location                   = "francecentral"
  resource_group_name        = azurerm_resource_group.this.name
  account_tier               = "Standard"
  replication_type           = "LRS"
  containers                 = ["workflows", "data"]
  tables                     = ["config", "metadata"]
  log_analytics_workspace_id = module.log_analytics.workspace_id

  tags = {
    environment = "dev"
    project     = "ipaas3"
  }
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| storage_account_name | Storage account name (3-24 chars, lowercase alphanumeric, 2-digit suffix) | string | n/a | yes |
| location | The Azure region | string | n/a | yes |
| resource_group_name | The resource group name | string | n/a | yes |
| account_tier | Storage account tier | string | "Standard" | no |
| replication_type | Replication type | string | "LRS" | no |
| account_kind | Storage account kind | string | "StorageV2" | no |
| access_tier | Access tier | string | "Hot" | no |
| containers | List of container names | list(string) | [] | no |
| tables | List of table names | list(string) | [] | no |
| log_analytics_workspace_id | Log Analytics workspace ID for diagnostics | string | n/a | yes |
| tags | Tags to assign | map(string) | {} | no |

## Outputs

| Name | Description |
|------|-------------|
| id | Storage account ID |
| name | Storage account name |
| primary_connection_string | Primary connection string (sensitive) |
| primary_access_key | Primary access key (sensitive) |
| primary_blob_endpoint | Primary blob endpoint |
| primary_queue_endpoint | Primary queue endpoint |
| primary_table_endpoint | Primary table endpoint |
