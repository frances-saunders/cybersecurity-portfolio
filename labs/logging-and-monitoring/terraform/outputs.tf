output "log_analytics_workspace_id" {
  value       = azurerm_log_analytics_workspace.law.id
  description = "ID of the Log Analytics Workspace"
}

output "log_analytics_workspace_name" {
  value       = azurerm_log_analytics_workspace.law.name
  description = "Name of the Log Analytics Workspace"
}
