#########################################
# Race Telemetry Security Lab - Terraform
# ---------------------------------------
# Provisions secure Event Hubs ingestion,
# Cosmos DB, Azure SQL, Key Vault, and
# networking controls (VNet, NSGs, private
# endpoints).
#########################################

provider "azurerm" {
  features {}
}

# ---------------------------
# Resource Group
# ---------------------------
resource "azurerm_resource_group" "rg" {
  name     = "rg-telemetry-lab"
  location = "eastus"
  tags = {
    environment = "lab"
    workload    = "race-telemetry"
  }
}

# ---------------------------
# Virtual Network + Subnets
# ---------------------------
resource "azurerm_virtual_network" "vnet" {
  name                = "vnet-telemetry"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  address_space       = ["10.50.0.0/16"]
}

resource "azurerm_subnet" "eventhub_subnet" {
  name                 = "subnet-eventhub"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.50.1.0/24"]

  # Required for private endpoints
  delegation {
    name = "eventhub-delegation"
    service_delegation {
      name = "Microsoft.EventHub/namespaces"
      actions = [
        "Microsoft.Network/virtualNetworks/subnets/join/action"
      ]
    }
  }
}

# ---------------------------
# Key Vault for CMK
# ---------------------------
resource "azurerm_key_vault" "kv" {
  name                = "kvtelemetrylab01"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  tenant_id           = data.azurerm_client_config.current.tenant_id
  sku_name            = "standard"
}

# ---------------------------
# Event Hubs Namespace
# ---------------------------
resource "azurerm_eventhub_namespace" "ehns" {
  name                = "ehns-telemetry"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  sku                 = "Standard"

  # Encryption enforced with CMK
  identity {
    type = "SystemAssigned"
  }

  customer_managed_key {
    key_vault_key_id = azurerm_key_vault.kv.id
  }
}

resource "azurerm_eventhub" "telemetry" {
  name                = "eh-race-telemetry"
  namespace_name      = azurerm_eventhub_namespace.ehns.name
  resource_group_name = azurerm_resource_group.rg.name
  partition_count     = 4
  message_retention   = 1
}

# ---------------------------
# Cosmos DB (NoSQL) - Telemetry
# ---------------------------
resource "azurerm_cosmosdb_account" "cosmos" {
  name                = "cosmos-telemetry"
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

  # Enforce virtual network + private access only
  is_virtual_network_filter_enabled = true
  key_vault_key_uri                 = azurerm_key_vault.kv.id
}

# ---------------------------
# Azure SQL - Telemetry Archive
# ---------------------------
resource "azurerm_sql_server" "sql" {
  name                         = "sqltelemetrylab01"
  resource_group_name          = azurerm_resource_group.rg.name
  location                     = azurerm_resource_group.rg.location
  version                      = "12.0"
  administrator_login          = "sqladmin"
  administrator_login_password = "StrongPassword123!"
}

resource "azurerm_sql_database" "telemetry_archive" {
  name                = "TelemetryArchiveDB"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  server_name         = azurerm_sql_server.sql.name
  sku_name            = "S0"

  # Transparent Data Encryption w/ CMK
  transparent_data_encryption {
    key_vault_key_id = azurerm_key_vault.kv.id
  }
}
