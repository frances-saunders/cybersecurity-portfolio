terraform {
  required_version = ">= 1.6.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3.112.0"
    }
  }
}

provider "azurerm" {
  features {}
}

# Resource Group
resource "azurerm_resource_group" "rg" {
  name     = "${var.prefix}-rg"
  location = var.location
}

# Key Vault (no secrets defined in code; secrets are set by scripts later)
resource "azurerm_key_vault" "kv" {
  name                       = var.kv_name
  location                   = azurerm_resource_group.rg.location
  resource_group_name        = azurerm_resource_group.rg.name
  tenant_id                  = data.azurerm_client_config.current.tenant_id
  sku_name                   = "standard"
  purge_protection_enabled   = true
  soft_delete_retention_days = 30
  enable_rbac_authorization  = true
}

data "azurerm_client_config" "current" {}

# Cosmos DB Account with AAD-only (no keys/connection strings)
resource "azurerm_cosmosdb_account" "cdb" {
  name                = "${var.prefix}-cosmos"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  offer_type          = "Standard"
  kind                = "GlobalDocumentDB"

  consistency_policy {
    consistency_level = "Session"
  }

  geo_location {
    location          = azurerm_resource_group.rg.location
    failover_priority = 0
  }

  capabilities {
    name = "EnableServerless"
  }

  # Enforce AAD auth only – prevents classic keys usage (no plaintext secrets).
  disable_local_authentication = true
}

resource "azurerm_cosmosdb_sql_database" "db" {
  name                = var.cosmos_db_name
  resource_group_name = azurerm_resource_group.rg.name
  account_name        = azurerm_cosmosdb_account.cdb.name
}

resource "azurerm_cosmosdb_sql_container" "container" {
  name                = var.cosmos_container_name
  resource_group_name = azurerm_resource_group.rg.name
  account_name        = azurerm_cosmosdb_account.cdb.name
  database_name       = azurerm_cosmosdb_sql_database.db.name
  partition_key_path  = var.cosmos_partition_key
}

# Container Instance to run lab jobs (uses managed identity to access Key Vault and Cosmos)
resource "azurerm_container_group" "jobs" {
  name                = "${var.prefix}-jobs"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  ip_address_type     = "None"
  os_type             = "Linux"

  identity {
    type = "SystemAssigned"
  }

  container {
    name   = "runner"
    image  = var.container_image
    cpu    = 1
    memory = 1.5

    environment_variables = {
      # Non-secret hints only; secrets resolved at runtime via Key Vault and AAD.
      AZURE_KEY_VAULT_URI = "https://${var.kv_name}.vault.azure.net/"
      TARGET_BACKEND      = "cosmos"
    }

    commands = ["/bin/sh", "-c", "echo ready"]
  }
}

# Role assignment so the container's identity can read Key Vault secrets at runtime
data "azurerm_role_definition" "kv_secrets_user" {
  name = "Key Vault Secrets User"
  scope = azurerm_key_vault.kv.id
}

resource "azurerm_role_assignment" "jobs_kv_read" {
  scope              = azurerm_key_vault.kv.id
  role_definition_id = data.azurerm_role_definition.kv_secrets_user.role_definition_resource_id
  principal_id       = azurerm_container_group.jobs.identity[0].principal_id
}

output "resource_group" {
  value = azurerm_resource_group.rg.name
}

output "key_vault_uri" {
  value = "https://${var.kv_name}.vault.azure.net/"
}

output "cosmos_endpoint" {
  value = azurerm_cosmosdb_account.cdb.endpoint
}

output "container_group_name" {
  value = azurerm_container_group.jobs.name
}
