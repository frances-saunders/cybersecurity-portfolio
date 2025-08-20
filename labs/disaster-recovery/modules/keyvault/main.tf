// Key Vault for DR Lab
resource "azurerm_key_vault" "this" {
  name                        = var.keyvault_name
  location                    = var.location
  resource_group_name         = var.resource_group_name
  tenant_id                   = var.tenant_id
  sku_name                    = "standard"
  purge_protection_enabled    = true
  soft_delete_retention_days  = 30

  tags = var.tags
}

// Allow admin/service principal to manage Key Vault
resource "azurerm_key_vault_access_policy" "admin" {
  key_vault_id = azurerm_key_vault.this.id
  tenant_id    = var.tenant_id
  object_id    = var.admin_object_id

  secret_permissions = [
    "Get",
    "List",
    "Set",
    "Delete",
    "Recover",
    "Backup",
    "Restore"
  ]
}

// Example secret (placeholder; rotation handled by scripts)
resource "azurerm_key_vault_secret" "sql_admin_password" {
  name         = "SqlAdminPassword"
  value        = "placeholder" // replaced by automation/scripts/set-sql-password.sh|ps1
  key_vault_id = azurerm_key_vault.this.id
}
