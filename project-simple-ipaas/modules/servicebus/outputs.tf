output "namespace_id" {
  description = "The ID of the Service Bus namespace"
  value       = azurerm_servicebus_namespace.this.id
}

output "namespace_name" {
  description = "The name of the Service Bus namespace"
  value       = azurerm_servicebus_namespace.this.name
}

output "primary_connection_string" {
  description = "The primary connection string for the Service Bus namespace"
  value       = azurerm_servicebus_namespace.this.default_primary_connection_string
  sensitive   = true
}

output "inbound_queue_id" {
  description = "The ID of the inbound queue"
  value       = azurerm_servicebus_queue.inbound.id
}

output "inbound_queue_name" {
  description = "The name of the inbound queue"
  value       = azurerm_servicebus_queue.inbound.name
}
