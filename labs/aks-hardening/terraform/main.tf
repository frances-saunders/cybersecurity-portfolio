// -----------------------------
// Provider & Resource Group
// -----------------------------
provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "rg" {
  name     = var.resource_group_name
  location = var.location
  tags     = var.tags
}

// -----------------------------
// AKS Cluster
// -----------------------------
resource "azurerm_kubernetes_cluster" "aks" {
  name                = var.cluster_name
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  dns_prefix          = var.dns_prefix

  default_node_pool {
    name       = "default"
    node_count = var.node_count
    vm_size    = var.vm_size
    vnet_subnet_id = var.subnet_id
  }

  identity {
    type = "SystemAssigned"
  }

  api_server_authorized_ip_ranges = var.api_server_authorized_ip_ranges

  oms_agent {
    log_analytics_workspace_id = var.log_analytics_workspace_id
  }

  tags = var.tags
}

// -----------------------------
// AKS Security Baseline Initiative
// -----------------------------
// NOTE: Policy definition JSONC lives in policies/definitions
// Terraform references it so governance stays IaC-driven.

resource "azurerm_policy_set_definition" "aks_security_baseline" {
  name         = "aks-security-baseline-initiative"
  policy_type  = "Custom"
  display_name = "AKS Security Baseline Initiative"
  description  = "Bundles AKS controls for privileged containers, registries, and network policies"

  // Import initiative definition from file
  policy_definitions = file("${path.module}/../policies/initiatives/aks-security-baseline-initiative.jsonc")
}

// -----------------------------
// Policy Assignment
// -----------------------------
// Assigns the AKS Security Baseline Initiative at the RG scope

resource "azurerm_policy_assignment" "aks_security_baseline" {
  name                 = "aks-security-baseline-assignment"
  scope                = azurerm_resource_group.rg.id
  policy_definition_id = azurerm_policy_set_definition.aks_security_baseline.id
  display_name         = "AKS Security Baseline Assignment"

  // Example parameterization
  parameters = jsonencode({
    privilegedEffect = {
      value = "Deny"
    }
    registryEffect = {
      value = "Deny"
    }
    approvedRegistries = {
      value = ["myregistry.azurecr.io"]
    }
    netpolEffect = {
      value = "Audit"
    }
  })

  identity {
    type = "SystemAssigned"
  }
}
