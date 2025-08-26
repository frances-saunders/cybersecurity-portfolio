output "resource_group" {
  description = "Name of the resource group"
  value       = azurerm_resource_group.rg.name
}

output "key_vault_uri" {
  description = "Key Vault URI (set AZURE_KEY_VAULT_URI to this)"
  value       = "https://${var.kv_name}.vault.azure.net/"
}

output "cosmos_endpoint" {
  description = "Cosmos DB account endpoint (not a secret)"
  value       = azurerm_cosmosdb_account.cdb.endpoint
}

output "container_group_name" {
  description = "Name of the container group runner"
  value       = azurerm_container_group.jobs.name
}
