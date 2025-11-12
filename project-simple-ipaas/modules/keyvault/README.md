# Key Vault Module

## Overview

Creates an Azure Key Vault with RBAC-based access control for storing secrets, keys, and certificates.

## Features

- RBAC-based access control (recommended over access policies)
- Soft delete and purge protection (configurable per environment)
- Network access restrictions (configurable)
- Diagnostic settings for audit logging

## Usage

```hcl
module "keyvault" {
  source = "../../modules/keyvault"

  key_vault_name      = "kv-dev-org-simpleipaas-01"
  location            = "francecentral"
  resource_group_name = "rg-simpleipaas-dev"
  sku                 = "standard"

  soft_delete_retention_days = 7
  purge_protection_enabled   = false

  tags = {
    environment = "dev"
    project     = "simple-ipaas"
  }
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| key_vault_name | Name of the Key Vault | string | n/a | yes |
| location | Azure region | string | n/a | yes |
| resource_group_name | Resource group name | string | n/a | yes |
| sku | Key Vault SKU (standard or premium) | string | "standard" | no |
| soft_delete_retention_days | Soft delete retention in days (7-90) | number | 7 | no |
| purge_protection_enabled | Enable purge protection | bool | false | no |
| public_network_access_enabled | Enable public network access | bool | true | no |
| tags | Resource tags | map(string) | {} | no |

## Outputs

| Name | Description | Sensitive |
|------|-------------|-----------|
| vault_id | Key Vault resource ID | no |
| vault_uri | Key Vault URI | no |
| vault_name | Key Vault name | no |

## Security

- Uses Azure RBAC for access control
- Soft delete enabled by default
- Purge protection should be enabled for production environments
- Configure private endpoints for production (not included in this module)

## RBAC Roles

To grant access to Key Vault secrets, assign these roles to Managed Identities:
- **Key Vault Secrets User**: Read secrets
- **Key Vault Secrets Officer**: Manage secrets
