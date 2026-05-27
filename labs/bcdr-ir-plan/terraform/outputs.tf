output "vault_tier1_id" {
  description = "Resource ID of the Tier 1 (mission-critical) Recovery Services Vault."
  value       = azurerm_recovery_services_vault.tier1.id
}

output "vault_tier2_id" {
  description = "Resource ID of the Tier 2 (business-important) Recovery Services Vault."
  value       = azurerm_recovery_services_vault.tier2.id
}

output "vault_tier3_id" {
  description = "Resource ID of the Tier 3 (operational) Recovery Services Vault."
  value       = azurerm_recovery_services_vault.tier3.id
}

output "vault_tier1_name" {
  description = "Name of the Tier 1 Recovery Services Vault — used in backup enrollment commands."
  value       = azurerm_recovery_services_vault.tier1.name
}

output "primary_resource_group" {
  description = "Name of the primary BCDR resource group."
  value       = azurerm_resource_group.bcdr.name
}

output "recovery_resource_group" {
  description = "Name of the recovery region resource group (ASR target)."
  value       = azurerm_resource_group.bcdr_recovery.name
}

output "alert_action_group_id" {
  description = "Resource ID of the BCDR alert action group."
  value       = azurerm_monitor_action_group.bcdr_alerts.id
}
