// -----------------------------
// Provider + Resource Group
// -----------------------------
provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "ztns" {
  name     = var.resource_group_name
  location = var.location
  tags     = var.tags
}

// -----------------------------
// Virtual Network + Subnets
// -----------------------------
resource "azurerm_virtual_network" "ztns" {
  name                = "${var.prefix}-vnet"
  address_space       = ["10.10.0.0/16"]
  location            = azurerm_resource_group.ztns.location
  resource_group_name = azurerm_resource_group.ztns.name
  tags                = var.tags
}

resource "azurerm_subnet" "hub" {
  name                 = "hub-subnet"
  resource_group_name  = azurerm_resource_group.ztns.name
  virtual_network_name = azurerm_virtual_network.ztns.name
  address_prefixes     = ["10.10.0.0/24"]
}

resource "azurerm_subnet" "workload" {
  name                 = "workload-subnet"
  resource_group_name  = azurerm_resource_group.ztns.name
  virtual_network_name = azurerm_virtual_network.ztns.name
  address_prefixes     = ["10.10.1.0/24"]
  service_endpoints    = ["Microsoft.Storage", "Microsoft.Sql"]
}

// -----------------------------
// Network Security Groups
// -----------------------------
resource "azurerm_network_security_group" "workload" {
  name                = "nsg-workload"
  location            = azurerm_resource_group.ztns.location
  resource_group_name = azurerm_resource_group.ztns.name

  security_rule {
    name                       = "Deny-All-Inbound"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Deny"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Allow-AzureFirewall"
    priority                   = 200
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "10.10.0.0/24" // Hub subnet
    destination_address_prefix = "*"
  }
}

resource "azurerm_subnet_network_security_group_association" "workload" {
  subnet_id                 = azurerm_subnet.workload.id
  network_security_group_id = azurerm_network_security_group.workload.id
}

// -----------------------------
// Azure Firewall
// -----------------------------
resource "azurerm_public_ip" "firewall" {
  name                = "firewall-pip"
  location            = azurerm_resource_group.ztns.location
  resource_group_name = azurerm_resource_group.ztns.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_firewall" "ztns" {
  name                = "ztns-firewall"
  location            = azurerm_resource_group.ztns.location
  resource_group_name = azurerm_resource_group.ztns.name
  sku_name            = "AZFW_VNet"
  sku_tier            = "Standard"

  ip_configuration {
    name                 = "configuration"
    subnet_id            = azurerm_subnet.hub.id
    public_ip_address_id = azurerm_public_ip.firewall.id
  }

  tags = var.tags
}

// -----------------------------
// Private Endpoints
// -----------------------------
resource "azurerm_private_endpoint" "storage" {
  name                = "pe-storage"
  location            = azurerm_resource_group.ztns.location
  resource_group_name = azurerm_resource_group.ztns.name
  subnet_id           = azurerm_subnet.workload.id

  private_service_connection {
    name                           = "pe-storage-connection"
    private_connection_resource_id = var.storage_account_id
    subresource_names              = ["blob"]
    is_manual_connection           = false
  }

  tags = var.tags
}

resource "azurerm_private_endpoint" "sql" {
  name                = "pe-sql"
  location            = azurerm_resource_group.ztns.location
  resource_group_name = azurerm_resource_group.ztns.name
  subnet_id           = azurerm_subnet.workload.id

  private_service_connection {
    name                           = "pe-sql-connection"
    private_connection_resource_id = var.sql_server_id
    subresource_names              = ["sqlServer"]
    is_manual_connection           = false
  }

  tags = var.tags
}
