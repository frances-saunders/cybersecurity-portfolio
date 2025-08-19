#############################################################
# AKS Hardening Lab - Terraform Main Configuration
# Secure version with Azure Key Vault integration
#############################################################

provider "azurerm" {
  features {}
}

# Data block to get current tenant
data "azurerm_client_config" "current" {}

# Resource Group
resource "azurerm_resource_group" "aks_rg" {
  name     = var.resource_group_name
  location = var.location
}

# Key Vault
resource "azurerm_key_vault" "aks_kv" {
  name                        = "${var.prefix}-kv"
  location                    = azurerm_resource_group.aks_rg.location
  resource_group_name         = azurerm_resource_group.aks_rg.name
  tenant_id                   = data.azurerm_client_config.current.tenant_id
  sku_name                    = "standard"
  soft_delete_retention_days  = 7
  purge_protection_enabled    = true
}

# Store AKS Admin Password in Key Vault (if required)
resource "azurerm_key_vault_secret" "aks_admin_password" {
  name         = "aks-admin-password"
  value        = var.aks_admin_password   # Sensitive variable, no default
  key_vault_id = azurerm_key_vault.aks_kv.id
}

# Allow AKS identity to access Key Vault
resource "azurerm_key_vault_access_policy" "aks_policy" {
  key_vault_id = azurerm_key_vault.aks_kv.id
  tenant_id    = data.azurerm_client_config.current.tenant_id
  object_id    = azurerm_kubernetes_cluster.aks.kubelet_identity[0].object_id

  secret_permissions = ["Get", "List"]
}

# Retrieve password securely from Key Vault (if required)
data "azurerm_key_vault_secret" "aks_admin_password" {
  name         = azurerm_key_vault_secret.aks_admin_password.name
  key_vault_id = azurerm_key_vault.aks_kv.id
}

# AKS Cluster
resource "azurerm_kubernetes_cluster" "aks" {
  name                = "${var.prefix}-aks"
  location            = azurerm_resource_group.aks_rg.location
  resource_group_name = azurerm_resource_group.aks_rg.name
  dns_prefix          = "${var.prefix}-dns"

  default_node_pool {
    name       = "system"
    node_count = 2
    vm_size    = "Standard_DS2_v2"
  }

  identity {
    type = "SystemAssigned"
  }

  linux_profile {
    admin_username = var.admin_username
    ssh_key {
      key_data = var.ssh_public_key
    }
    # Uncomment only if password login is required
    # password = data.azurerm_key_vault_secret.aks_admin_password.value
  }
}
