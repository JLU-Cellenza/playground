# Storage Account Module

## Overview

Creates an Azure Storage Account for platform configuration storage and Logic App runtime storage.

## Features

- Configurable SKU (Standard LRS for dev, GRS/ZRS for production)
- Blob containers for organized storage
- HTTPS-only access
- Managed Identity support

## Usage

```hcl
module "storage" {
  source = "../../modules/storage"

  storage_account_name = "stdevorgsipaas01"
  location             = "francecentral"
  resource_group_name  = "rg-simpleipaas-dev"
  
  account_tier             = "Standard"
  account_replication_type = "LRS"
  access_tier              = "Hot"

  containers = ["config", "workflows"]

  tags = {
    environment = "dev"
    project     = "simple-ipaas"
  }
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| storage_account_name | Name of the storage account (3-24 lowercase alphanumeric) | string | n/a | yes |
| location | Azure region | string | n/a | yes |
| resource_group_name | Resource group name | string | n/a | yes |
| account_tier | Storage account tier (Standard or Premium) | string | "Standard" | no |
| account_replication_type | Replication type (LRS, GRS, RAGRS, ZRS) | string | "LRS" | no |
| access_tier | Access tier (Hot or Cool) | string | "Hot" | no |
| containers | List of blob container names to create | list(string) | [] | no |
| tags | Resource tags | map(string) | {} | no |

## Outputs

| Name | Description | Sensitive |
|------|-------------|-----------|
| storage_account_id | Storage account resource ID | no |
| storage_account_name | Storage account name | no |
| primary_connection_string | Primary connection string | yes |
| primary_access_key | Primary access key | yes |
| primary_blob_endpoint | Primary blob endpoint | no |

## Security

- Connection strings and keys marked as sensitive
- Store connection string in Key Vault
- HTTPS-only access enforced
- Minimum TLS version 1.2
