output "resource_group_name" {
  value       = azurerm_resource_group.monitoring.name
  description = "Resource group for monitoring integration"
}

output "sentinel_workspace_name" {
  value       = azurerm_log_analytics_workspace.law.name
  description = "Log Analytics Workspace with Sentinel enabled"
}

output "eventhub_name" {
  value       = azurerm_eventhub.zabbix.name
  description = "Event Hub name used for Zabbix ingestion"
}
