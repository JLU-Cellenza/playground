# Service Bus Module

This module creates an Azure Service Bus namespace with queues.

## Resources Created

- `azurerm_servicebus_namespace` - Service Bus namespace
- `azurerm_servicebus_queue` - Service Bus queues

## Usage

```hcl
module "servicebus" {
  source = "../../modules/servicebus"

  namespace_name      = "sb-dev-clz-ipaas3-01"
  location            = "francecentral"
  resource_group_name = azurerm_resource_group.this.name
  sku                 = "Standard"
  queue_names         = ["inbound-queue"]
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
| namespace_name | The name of the Service Bus namespace | string | n/a | yes |
| location | The Azure region | string | n/a | yes |
| resource_group_name | The resource group name | string | n/a | yes |
| sku | The SKU (Basic, Standard, Premium) | string | "Standard" | no |
| capacity | Capacity for Premium SKU (1, 2, 4, 8, 16) | number | 0 | no |
| queue_names | List of queue names to create | list(string) | [] | no |
| max_delivery_count | Max delivery count before dead-letter | number | 10 | no |
| lock_duration | Lock duration (ISO 8601) | string | "PT5M" | no |
| default_message_ttl | Default message TTL (ISO 8601) | string | "P14D" | no |
| log_analytics_workspace_id | Log Analytics workspace ID | string | n/a | yes |
| tags | Tags to assign | map(string) | {} | no |

## Outputs

| Name | Description |
|------|-------------|
| namespace_id | Service Bus namespace ID |
| namespace_name | Service Bus namespace name |
| namespace_fqdn | Fully qualified domain name |
| primary_connection_string | Primary connection string (sensitive) |
| queue_ids | Map of queue names to IDs |
