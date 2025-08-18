// =======================================================
// Outputs for Cloud Attack Simulation & Detection Lab
// =======================================================

output "resource_group_name" {
  description = "Deployed Resource Group"
  value       = azurerm_resource_group.lab.name
}

output "vnet_name" {
  description = "Virtual Network"
  value       = azurerm_virtual_network.lab_vnet.name
}

output "attacker_subnet_id" {
  description = "Attacker Subnet ID"
  value       = azurerm_subnet.attacker_subnet.id
}

output "victim_subnet_id" {
  description = "Victim Subnet ID"
  value       = azurerm_subnet.victim_subnet.id
}

output "firewall_public_ip" {
  description = "Azure Firewall Public IP"
  value       = azurerm_public_ip.fw_pip.ip_address
}

output "storage_account" {
  description = "Storage account name (exfiltration target)"
  value       = azurerm_storage_account.lab_storage.name
}

output "key_vault" {
  description = "Key Vault name (sensitive secrets target)"
  value       = azurerm_key_vault.lab_kv.name
}

output "log_analytics_workspace_id" {
  description = "Log Analytics Workspace ID"
  value       = azurerm_log_analytics_workspace.lab_law.id
}
