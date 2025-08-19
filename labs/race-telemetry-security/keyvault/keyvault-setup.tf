############################################################
# Azure Key Vault Setup for Race Telemetry Security Lab
# This module provisions a Key Vault, configures RBAC, and
# stores critical secrets (SQL password, Cosmos DB key, etc.)
############################################################

provider "azurerm" {
  features {}
}

# Use variables for reusability
variable "resource_group_name" {
  description = "Resource Group where Key Vault will be created"
  type        = string
}

variable "location" {
  description = "Azure region"
  type        = string
}

variable "keyvault_name" {
  description = "Unique Key Vault name"
  type        = string
}

variable "sql_admin_password" {
  description = "SQL Admin password stored securely"
  type        = string
  sensitive   = true
}

variable "cosmos_primary_key" {
  description = "Cosmos DB primary key stored securely"
  type        = string
  sensitive   = true
}

############################################################
# Key Vault Creation
############################################################
resource "azurerm_key_vault" "kv" {
  name                        = var.keyvault_name
  location                    = var.location
  resource_group_name         = var.resource_group_name
  enabled_for_disk_encryption = true
  tenant_id                   = data.azurerm_client_config.current.tenant_id
  sku_name                    = "standard"

  soft_delete_retention_days  = 7

  purge_protection_enabled    = true # Prevents accidental deletions
}

# Ensure we get client context
data "azurerm_client_config" "current" {}

############################################################
# Access Policy (Terraform identity)
# This grants the deploying identity permission to set secrets
############################################################
resource "azurerm_key_vault_access_policy" "terraform_access" {
  key_vault_id = azurerm_key_vault.kv.id
  tenant_id    = data.azurerm_client_config.current.tenant_id
  object_id    = data.azurerm_client_config.current.object_id

  secret_permissions = ["get", "set", "list", "delete"]
}

############################################################
# Secrets - SQL password & Cosmos DB key
############################################################
resource "azurerm_key_vault_secret" "sql_password" {
  name         = "sql-admin-password"
  value        = var.sql_admin_password
  key_vault_id = azurerm_key_vault.kv.id
}

resource "azurerm_key_vault_secret" "cosmos_key" {
  name         = "cosmos-primary-key"
  value        = var.cosmos_primary_key
  key_vault_id = azurerm_key_vault.kv.id
}
