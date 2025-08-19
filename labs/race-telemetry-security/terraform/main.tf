#############################################
# main.tf - Core Azure resources
# Secure Race Telemetry ingestion pipeline
# with secrets pulled from Azure Key Vault
#############################################

provider "azurerm" {
  features {}
}

# Resource Group
resource "azurerm_resource_group" "rg" {
  name     = var.resource_group_name
  location = var.location
  tags     = var.tags
}

# Virtual Network
resource "azurerm_virtual_network" "vnet" {
  name                = "telemetry-vnet"
  address_space       = ["10.0.0.0/16"]
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
}

# Subnet for telemetry ingestion
resource "azurerm_subnet" "telemetry_subnet" {
  name                 = "telemetry-subnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.1.0/24"]
}

# Event Hub Namespace
resource "azurerm_eventhub_namespace" "eh_namespace" {
  name                = "telemetry-namespace"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
  sku                 = "Standard"
  capacity            = 2
}

# Event Hub
resource "azurerm_eventhub" "eh" {
  name                = "race-telemetry"
  namespace_name      = azurerm_eventhub_namespace.eh_namespace.name
  resource_group_name = azurerm_resource_group.rg.name
  partition_count     = 2
  message_retention   = 1
}

# Cosmos DB Account
resource "azurerm_cosmosdb_account" "cosmos" {
  name                = "telemetrycosmosacct"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
  offer_type          = "Standard"
  kind                = "GlobalDocumentDB"

  consistency_policy {
    consistency_level       = "Session"
    max_interval_in_seconds = 5
    max_staleness_prefix    = 100
  }

  geo_location {
    location          = var.location
    failover_priority = 0
  }
}

# SQL Server
resource "azurerm_sql_server" "sql" {
  name                         = "telemetry-sqlserver"
  resource_group_name          = azurerm_resource_group.rg.name
  location                     = var.location
  version                      = "12.0"
  administrator_login          = var.sql_admin_user

  # Password retrieved securely from Key Vault
  administrator_login_password = data.azurerm_key_vault_secret.sql_admin_password.value
}

resource "azurerm_sql_database" "sqldb" {
  name                = "TelemetryDB"
  resource_group_name = azurerm_resource_group.rg.name
  location            = var.location
  server_name         = azurerm_sql_server.sql.name
  sku_name            = "S0"
}

# Key Vault for secrets
resource "azurerm_key_vault" "kv" {
  name                = "telemetry-kv"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
  tenant_id           = var.tenant_id
  sku_name            = "standard"

  access_policy {
    tenant_id = var.tenant_id
    object_id = var.admin_object_id  # your Azure AD object ID
    secret_permissions = ["get", "list", "set"]
  }
}

# Secret for SQL admin password
resource "azurerm_key_vault_secret" "sql_password" {
  name         = "sql-admin-password"
  value        = var.sql_admin_password
  key_vault_id = azurerm_key_vault.kv.id
}

# Data source to fetch secret securely
data "azurerm_key_vault_secret" "sql_admin_password" {
  name         = azurerm_key_vault_secret.sql_password.name
  key_vault_id = azurerm_key_vault.kv.id
}
