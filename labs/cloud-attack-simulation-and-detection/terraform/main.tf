// =======================================================
// Cloud Attack Simulation & Detection Lab (Terraform)
// -------------------------------------------------------
// This lab provisions a secure environment to simulate
// attacks (impossible travel, brute-force, malicious containers)
// and validate detections with Sentinel + automation.
// =======================================================

provider "azurerm" {
  features {}
}

data "azurerm_client_config" "current" {}


// =======================================================
// Resource Group
// =======================================================
resource "azurerm_resource_group" "lab" {
  name     = var.resource_group_name
  location = var.location
  tags     = var.tags
}


// =======================================================
// Networking (Hub + Spokes)
// =======================================================

resource "azurerm_virtual_network" "lab_vnet" {
  name                = "${var.prefix}-vnet"
  address_space       = ["10.20.0.0/16"]
  location            = azurerm_resource_group.lab.location
  resource_group_name = azurerm_resource_group.lab.name
  tags                = var.tags
}

// Attacker subnet – simulates external adversary foothold
resource "azurerm_subnet" "attacker_subnet" {
  name                 = "attacker-subnet"
  resource_group_name  = azurerm_resource_group.lab.name
  virtual_network_name = azurerm_virtual_network.lab_vnet.name
  address_prefixes     = ["10.20.1.0/24"]
}

// Victim subnet – workloads and PaaS services
resource "azurerm_subnet" "victim_subnet" {
  name                 = "victim-subnet"
  resource_group_name  = azurerm_resource_group.lab.name
  virtual_network_name = azurerm_virtual_network.lab_vnet.name
  address_prefixes     = ["10.20.2.0/24"]
  service_endpoints    = ["Microsoft.Storage", "Microsoft.Sql"]
}


// =======================================================
// NSGs (Zero Trust enforcement)
// =======================================================

resource "azurerm_network_security_group" "attacker_nsg" {
  name                = "${var.prefix}-attacker-nsg"
  location            = azurerm_resource_group.lab.location
  resource_group_name = azurerm_resource_group.lab.name
  tags                = var.tags
}

resource "azurerm_network_security_group" "victim_nsg" {
  name                = "${var.prefix}-victim-nsg"
  location            = azurerm_resource_group.lab.location
  resource_group_name = azurerm_resource_group.lab.name
  tags                = var.tags
}

// Default deny-all rules: explicitly forcing Zero Trust
resource "azurerm_network_security_rule" "deny_inbound" {
  name                        = "Deny-All-Inbound"
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Deny"
  protocol                    = "*"
  source_port_range           = "*"
  destination_port_range      = "*"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.lab.name
  network_security_group_name = azurerm_network_security_group.victim_nsg.name
}

resource "azurerm_network_security_rule" "deny_outbound" {
  name                        = "Deny-All-Outbound"
  priority                    = 100
  direction                   = "Outbound"
  access                      = "Deny"
  protocol                    = "*"
  source_port_range           = "*"
  destination_port_range      = "*"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.lab.name
  network_security_group_name = azurerm_network_security_group.victim_nsg.name
}


// =======================================================
// Azure Firewall (DNAT/SNAT for controlled attack flows)
// =======================================================

resource "azurerm_firewall" "lab_fw" {
  name                = "${var.prefix}-fw"
  location            = azurerm_resource_group.lab.location
  resource_group_name = azurerm_resource_group.lab.name
  sku_name            = "AZFW_VNet"
  sku_tier            = "Standard"

  ip_configuration {
    name                 = "configuration"
    subnet_id            = azurerm_subnet.victim_subnet.id
    public_ip_address_id = azurerm_public_ip.fw_pip.id
  }

  tags = var.tags
}

resource "azurerm_public_ip" "fw_pip" {
  name                = "${var.prefix}-fw-pip"
  location            = azurerm_resource_group.lab.location
  resource_group_name = azurerm_resource_group.lab.name
  allocation_method   = "Static"
  sku                 = "Standard"
  tags                = var.tags
}


// =======================================================
// Sensitive Services (Exfiltration targets)
// =======================================================

resource "azurerm_storage_account" "lab_storage" {
  name                     = "${var.prefix}stgacct"
  resource_group_name      = azurerm_resource_group.lab.name
  location                 = azurerm_resource_group.lab.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  min_tls_version          = "TLS1_2"

  tags = var.tags
}

resource "azurerm_key_vault" "lab_kv" {
  name                        = "${var.prefix}-kv"
  location                    = azurerm_resource_group.lab.location
  resource_group_name         = azurerm_resource_group.lab.name
  tenant_id                   = data.azurerm_client_config.current.tenant_id
  sku_name                    = "standard"
  soft_delete_retention_days  = 7
  purge_protection_enabled    = true

  tags = var.tags
}


// =======================================================
// Monitoring: Log Analytics + Sentinel
// =======================================================

resource "azurerm_log_analytics_workspace" "lab_law" {
  name                = "${var.prefix}-law"
  location            = azurerm_resource_group.lab.location
  resource_group_name = azurerm_resource_group.lab.name
  sku                 = "PerGB2018"
  retention_in_days   = 30
  tags                = var.tags
}

resource "azurerm_sentinel_log_analytics_workspace_onboarding" "lab_sentinel" {
  workspace_id = azurerm_log_analytics_workspace.lab_law.id
}
