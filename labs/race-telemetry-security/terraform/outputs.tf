#############################################
# outputs.tf - Useful deployment outputs
#############################################

output "eventhub_namespace_name" {
  description = "Name of the Event Hub Namespace"
  value       = azurerm_eventhub_namespace.eh_namespace.name
}

output "eventhub_name" {
  description = "Name of the Event Hub"
  value       = azurerm_eventhub.eh.name
}

output "cosmosdb_account_name" {
  description = "Name of the Cosmos DB Account"
  value       = azurerm_cosmosdb_account.cosmos.name
}

output "sql_server_name" {
  description = "Name of the SQL Server"
  value       = azurerm_sql_server.sql.name
}

output "sql_database_name" {
  description = "Name of the SQL Database"
  value       = azurerm_sql_database.sqldb.name
}

output "key_vault_uri" {
  description = "URI of the Key Vault"
  value       = azurerm_key_vault.kv.vault_uri
}
