// labs/siem/terraform/outputs.tf
output "resource_group_name" {
  value       = azurerm_resource_group.siem.name
  description = "Resource group for SIEM lab"
}

output "log_analytics_workspace_id" {
  value       = azurerm_log_analytics_workspace.siem.id
  description = "ID of the Log Analytics Workspace"
}

output "log_analytics_workspace_name" {
  value       = azurerm_log_analytics_workspace.siem.name
  description = "Name of the Log Analytics Workspace"
}

output "sentinel_workspace_status" {
  value       = azurerm_sentinel_log_analytics_workspace_onboarding.sentinel.workspace_id
  description = "Sentinel onboarding status"
}
