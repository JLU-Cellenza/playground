output "namespace_id" {
  description = "The ID of the Service Bus namespace"
  value       = azurerm_servicebus_namespace.this.id
}

output "namespace_name" {
  description = "The name of the Service Bus namespace"
  value       = azurerm_servicebus_namespace.this.name
}

output "primary_connection_string" {
  description = "The primary connection string"
  value       = azurerm_servicebus_namespace.this.default_primary_connection_string
  sensitive   = true
}

output "queue_ids" {
  description = "Map of queue names to IDs"
  value       = { for q in azurerm_servicebus_queue.queues : q.name => q.id }
}
