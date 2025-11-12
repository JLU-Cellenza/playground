# Logic App Standard Module

## Overview

Creates an Azure Logic App Standard with App Service Plan for workflow orchestration.

## Features

- App Service Plan with configurable SKU
- Logic App Standard (workflow engine)
- System-assigned Managed Identity
- Integration with Storage Account (required dependency)

## Usage

```hcl
module "logicapp" {
  source = "../../modules/logicapp"

  service_plan_name          = "asp-dev-org-simpleipaas-01"
  logic_app_name             = "loa-dev-org-simpleipaas-01"
  location                   = "francecentral"
  resource_group_name        = "rg-simpleipaas-dev"
  sku_name                   = "WS1"
  
  storage_account_name       = module.storage.storage_account_name
  storage_account_access_key = module.storage.primary_access_key

  tags = {
    environment = "dev"
    project     = "simple-ipaas"
  }
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| service_plan_name | Name of the App Service Plan | string | n/a | yes |
| logic_app_name | Name of the Logic App | string | n/a | yes |
| location | Azure region | string | n/a | yes |
| resource_group_name | Resource group name | string | n/a | yes |
| sku_name | App Service Plan SKU (WS1, WS2, WS3) | string | "WS1" | no |
| storage_account_name | Storage account name for Logic App runtime | string | n/a | yes |
| storage_account_access_key | Storage account access key | string | n/a | yes |
| tags | Resource tags | map(string) | {} | no |

## Outputs

| Name | Description | Sensitive |
|------|-------------|-----------|
| service_plan_id | App Service Plan resource ID | no |
| logic_app_id | Logic App resource ID | no |
| logic_app_name | Logic App name | no |
| identity_principal_id | Managed Identity principal ID | no |

## Dependencies

- Requires a Storage Account (created separately)
- Storage account name and access key must be provided

## Security

- System-assigned Managed Identity enabled
- Use Managed Identity for Service Bus and Key Vault access
- Storage account access key is sensitive (store in Key Vault)

## SKU Recommendations

- **WS1**: Development and testing
- **WS2**: Light production workloads
- **WS3**: Production workloads with high throughput
