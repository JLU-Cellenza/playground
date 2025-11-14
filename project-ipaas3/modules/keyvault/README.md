# Key Vault Module

This module creates an Azure Key Vault with RBAC-based authorization for secure secrets management.

## Resources Created

- `azurerm_key_vault` - Key Vault for storing secrets, keys, and certificates

## Usage

```hcl
module "keyvault" {
  source = "../../modules/keyvault"

  key_vault_name      = "kv-dev-clz-ipaas3-01"
  location            = "francecentral"
  resource_group_name = azurerm_resource_group.this.name
  sku                 = "standard"
  purge_protection_enabled = false
  public_network_access_enabled = true

  tags = {
    environment = "dev"
    project     = "ipaas3"
  }
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| key_vault_name | Key Vault name (3-24 chars, alphanumeric/hyphens, 2-digit suffix) | string | n/a | yes |
| location | The Azure region | string | n/a | yes |
| resource_group_name | The resource group name | string | n/a | yes |
| sku | SKU (standard or premium) | string | "standard" | no |
| soft_delete_retention_days | Soft-delete retention (7-90 days) | number | 7 | no |
| purge_protection_enabled | Enable purge protection | bool | false | no |
| public_network_access_enabled | Enable public network access | bool | true | no |
| tags | Tags to assign | map(string) | {} | no |

## Outputs

| Name | Description |
|------|-------------|
| vault_id | Key Vault ID |
| vault_uri | Key Vault URI |
| vault_name | Key Vault name |

## Security Notes

- RBAC authorization is enabled by default
- Terraform service principal needs "Key Vault Secrets Officer" role to manage secrets
- Application identities need "Key Vault Secrets User" role to read secrets
- Soft delete enabled with configurable retention
- Purge protection recommended for production
