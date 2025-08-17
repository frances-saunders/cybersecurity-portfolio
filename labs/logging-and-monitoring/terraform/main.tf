// -----------------------------
// Provider & Setup
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
// Log Analytics Workspace
// -----------------------------
resource "azurerm_log_analytics_workspace" "law" {
  name                = var.log_analytics_workspace_name
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  sku                 = "PerGB2018"
  retention_in_days   = 30
  tags                = var.tags
}

// -----------------------------
// AKS Diagnostics → LAW
// -----------------------------
resource "azurerm_monitor_diagnostic_setting" "aks_diag" {
  name                       = "aks-diagnostics"
  target_resource_id         = var.aks_cluster_id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.law.id

  log {
    category = "kube-audit"
    enabled  = true
  }
  log {
    category = "kube-audit-admin"
    enabled  = true
  }
  log {
    category = "guard"
    enabled  = true
  }
  metric {
    category = "AllMetrics"
    enabled  = true
  }
}

// -----------------------------
// Azure Policy Logs → LAW
// -----------------------------
resource "azurerm_monitor_diagnostic_setting" "policy_diag" {
  name                       = "policy-diagnostics"
  target_resource_id         = "/providers/Microsoft.Authorization/policyAssignments"
  log_analytics_workspace_id = azurerm_log_analytics_workspace.law.id

  log {
    category = "PolicyInsights"
    enabled  = true
  }
}

// -----------------------------
// Defender for Cloud Alerts → LAW
// -----------------------------
resource "azurerm_security_center_workspace" "defender_integration" {
  scope        = azurerm_resource_group.rg.id
  workspace_id = azurerm_log_analytics_workspace.law.id
}
