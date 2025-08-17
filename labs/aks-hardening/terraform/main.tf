// Terraform main configuration for AKS Hardening Lab

provider "azurerm" {
  features {}
}

data "azurerm_subscription" "current" {}

resource "azurerm_resource_group" "aks" {
  name     = var.resource_group_name
  location = var.location
}

// AKS Cluster
resource "azurerm_kubernetes_cluster" "aks" {
  name                = var.cluster_name
  location            = azurerm_resource_group.aks.location
  resource_group_name = azurerm_resource_group.aks.name
  dns_prefix          = var.dns_prefix

  default_node_pool {
    name       = "systempool"
    node_count = var.node_count
    vm_size    = var.node_vm_size
  }

  identity {
    type = "SystemAssigned"
  }

  network_profile {
    network_plugin = "azure"
    network_policy = "azure"
  }

  role_based_access_control_enabled = true
}

// Policy Initiative (from definition JSONC)
resource "azurerm_policy_set_definition" "aks_security_baseline" {
  name         = "aks-security-baseline-initiative"
  policy_type  = "Custom"
  display_name = "AKS Security Baseline Initiative"

  // Reference your JSONC file
  metadata = jsonencode({
    category = "Kubernetes"
  })

  policy_definitions = file("${path.module}/../policies/initiatives/aks-security-baseline-initiative.jsonc")
}

// Policy Assignment
resource "azurerm_policy_assignment" "aks_security_baseline" {
  name                 = "aks-security-baseline-assignment"
  display_name         = "AKS Security Baseline Assignment"
  scope                = azurerm_resource_group.aks.id
  policy_definition_id = azurerm_policy_set_definition.aks_security_baseline.id
  description          = "Assignment of AKS security baseline initiative to enforce hardened standards"

  parameters = jsonencode({
    privilegedEffect    = { value = var.privileged_effect }
    registryEffect      = { value = var.registry_effect }
    approvedRegistries  = { value = var.approved_registries }
    netpolEffect        = { value = var.netpol_effect }
    resourceLimitEffect = { value = var.resource_limit_effect }
    namespaceEffect     = { value = var.namespace_effect }
    keyVaultEffect      = { value = var.keyvault_effect }
  })

  identity {
    type = "SystemAssigned"
  }
}
