// outputs.tf - Key resource outputs

output "resource_group_name" {
  description = "Resource group for Sentinel lab"
  value       = azurerm_resource_group.sentinel_rg.name
}

output "log_analytics_workspace_id" {
  description = "ID of the Log Analytics Workspace"
  value       = azurerm_log_analytics_workspace.law.id
}

output "log_analytics_workspace_name" {
  description = "Name of the Log Analytics Workspace"
  value       = azurerm_log_analytics_workspace.law.name
}

output "sentinel_workspace_status" {
  description = "Sentinel Onboarding Status"
  value       = azurerm_sentinel_log_analytics_workspace_onboarding.sentinel.workspace_id
}
