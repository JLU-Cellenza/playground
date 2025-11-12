# Service Bus Module

## Overview

Creates an Azure Service Bus namespace with an inbound queue for message processing.

## Features

- Service Bus namespace (Standard or Premium SKU)
- Inbound queue with configurable settings
- Dead-letter queue support
- Diagnostic settings for monitoring

## Usage

```hcl
module "servicebus" {
  source = "../../modules/servicebus"

  namespace_name      = "svb-dev-org-simpleipaas-01"
  location            = "francecentral"
  resource_group_name = "rg-simpleipaas-dev"
  sku                 = "Standard"

  inbound_queue_name = "inbound"
  max_delivery_count = 10
  lock_duration      = "PT5M"

  tags = {
    environment = "dev"
    project     = "simple-ipaas"
  }
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| namespace_name | Name of the Service Bus namespace | string | n/a | yes |
| location | Azure region | string | n/a | yes |
| resource_group_name | Resource group name | string | n/a | yes |
| sku | Service Bus SKU (Standard or Premium) | string | "Standard" | no |
| inbound_queue_name | Name of the inbound queue | string | "inbound" | no |
| max_delivery_count | Max delivery attempts before dead-lettering | number | 10 | no |
| lock_duration | Message lock duration (ISO 8601) | string | "PT5M" | no |
| tags | Resource tags | map(string) | {} | no |

## Outputs

| Name | Description | Sensitive |
|------|-------------|-----------|
| namespace_id | Service Bus namespace resource ID | no |
| namespace_name | Service Bus namespace name | no |
| primary_connection_string | Primary connection string | yes |
| inbound_queue_id | Inbound queue resource ID | no |
| inbound_queue_name | Inbound queue name | no |

## Security

- Connection strings marked as sensitive
- Store connection string in Key Vault for application access
- Use Managed Identity with "Azure Service Bus Data Sender/Receiver" roles where possible
