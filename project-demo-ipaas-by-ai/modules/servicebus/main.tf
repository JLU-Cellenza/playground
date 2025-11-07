resource "azurerm_servicebus_namespace" "this" {
  name                = var.namespace_name
  location            = var.location
  resource_group_name = var.resource_group_name
  sku                 = var.sku
  capacity            = var.capacity

  tags = var.tags
}

resource "azurerm_servicebus_queue" "queues" {
  for_each     = toset(var.queue_names)
  name         = each.value
  namespace_id = azurerm_servicebus_namespace.this.id

  max_delivery_count                   = var.max_delivery_count
  lock_duration                        = var.lock_duration
  default_message_ttl                  = var.default_message_ttl
  dead_lettering_on_message_expiration = true
}

resource "azurerm_monitor_diagnostic_setting" "this" {
  name                       = "diag-${var.namespace_name}"
  target_resource_id         = azurerm_servicebus_namespace.this.id
  log_analytics_workspace_id = var.log_analytics_workspace_id

  enabled_log {
    category = "OperationalLogs"
  }

  metric {
    category = "AllMetrics"
    enabled  = true
  }
}
