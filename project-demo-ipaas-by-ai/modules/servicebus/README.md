# Service Bus Module

Creates Azure Service Bus namespace with queues for messaging.

## Resources
- Service Bus Namespace (Standard SKU)
- Service Bus Queues
- Diagnostic Settings

## Inputs
| Name | Type | Default | Description |
|------|------|---------|-------------|
| namespace_name | string | - | Service Bus namespace name |
| location | string | - | Azure region |
| resource_group_name | string | - | Resource group |
| sku | string | "Standard" | Service Bus SKU |
| queue_names | list(string) | [] | Queue names to create |
| log_analytics_workspace_id | string | null | Log Analytics workspace ID |

## Outputs
- namespace_id
- namespace_name
- primary_connection_string (sensitive)
- queue_ids
