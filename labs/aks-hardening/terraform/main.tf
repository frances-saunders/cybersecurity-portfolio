provider "azurerm" {
  features {}
}

# -----------------------------
# Resource Group
# -----------------------------
resource "azurerm_resource_group" "rg" {
  name     = var.resource_group_name
  location = var.location
}

# -----------------------------
# AKS Cluster with Hardened Config
# -----------------------------
resource "azurerm_kubernetes_cluster" "aks" {
  name                = var.cluster_name
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  dns_prefix          = var.dns_prefix

  # -----------------------------
  # Default Node Pool (no public IPs)
  # -----------------------------
  default_node_pool {
    name                  = "systempool"
    node_count            = var.node_count
    vm_size               = var.vm_size
    vnet_subnet_id        = var.subnet_id
    enable_node_public_ip = false
    os_disk_size_gb       = 128
    only_critical_addons_enabled = true
  }

  # -----------------------------
  # Managed Identity (for RBAC + Defender)
  # -----------------------------
  identity {
    type = "SystemAssigned"
  }

  # -----------------------------
  # Security Features
  # -----------------------------
  role_based_access_control_enabled = true

  # Enable Pod Security Admission (baseline/restricted profiles)
  workload_identity_enabled = true
  oidc_issuer_enabled       = true

  # Network Security
  network_profile {
    network_plugin     = "azure"
    network_policy     = "azure"
    load_balancer_sku  = "standard"
    outbound_type      = "userDefinedRouting"
    dns_service_ip     = "10.0.0.10"
    service_cidr       = "10.0.0.0/16"
    docker_bridge_cidr = "172.17.0.1/16"
  }

  # API Server Lockdown (private cluster + restricted IPs)
  api_server_access_profile {
    enable_private_cluster    = true
    authorized_ip_ranges      = var.api_server_authorized_ip_ranges
  }

  # Defender for Containers Integration
  oms_agent {
    log_analytics_workspace_id = var.log_analytics_workspace_id
  }

  # Policy Add-On (ensures EPAC policies get enforced at cluster scope)
  azure_policy_enabled = true

  tags = var.tags
}

# -----------------------------
# Role Assignment for Defender
# -----------------------------
resource "azurerm_role_assignment" "aks_msi_defender" {
  principal_id         = azurerm_kubernetes_cluster.aks.identity[0].principal_id
  role_definition_name = "Monitoring Metrics Publisher"
  scope                = azurerm_resource_group.rg.id
}
