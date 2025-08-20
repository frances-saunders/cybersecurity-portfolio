// -----------------------------
// Module: SQL Server + Database with Geo-Replication
// -----------------------------
// NOTE: Admin password is retrieved securely from Key Vault
//       instead of being passed/stored in plaintext
// -----------------------------

// Retrieve SQL password from Key Vault
data "azurerm_key_vault_secret" "sql_admin_password" {
  name         = var.sql_admin_password_secret_name
  key_vault_id = var.key_vault_id
}

resource "azurerm_sql_server" "this" {
  name                         = var.sql_server_name
  resource_group_name          = var.resource_group_name
  location                     = var.location
  version                      = "12.0"
  administrator_login          = var.admin_user
  administrator_login_password = data.azurerm_key_vault_secret.sql_admin_password.value
}

resource "azurerm_sql_database" "primary" {
  name                = var.db_name
  resource_group_name = var.resource_group_name
  location            = var.location
  server_name         = azurerm_sql_server.this.name
  sku_name            = var.sku_name
}

resource "azurerm_sql_failover_group" "this" {
  name                = "${var.db_name}-fog"
  resource_group_name = var.resource_group_name
  server_name         = azurerm_sql_server.this.name

  partner_servers {
    id = var.secondary_sql_server_id
  }

  databases = [azurerm_sql_database.primary.id]
}

output "primary_db_name" {
  value = azurerm_sql_database.primary.name
}
