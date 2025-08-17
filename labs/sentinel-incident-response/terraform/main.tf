// main.tf - Deploys Log Analytics Workspace + Sentinel + Data Connectors

provider "azurerm" {
  features {}
}

// -----------------------------
// Resource Group
// -----------------------------
resource "azurerm_resource_group" "sentinel_rg" {
  name     = var.resource_group_name
  location = var.location
  tags     = var.tags
}

// -----------------------------
// Log Analytics Workspace
// -----------------------------
resource "azurerm_log_analytics_workspace" "law" {
  name                = var.law_name
  location            = azurerm_resource_group.sentinel_rg.location
  resource_group_name = azurerm_resource_group.sentinel_rg.name
  sku                 = "PerGB2018"
  retention_in_days   = 30

  tags = var.tags
}

// -----------------------------
// Microsoft Sentinel (Security Insights)
// -----------------------------
resource "azurerm_sentinel_log_analytics_workspace_onboarding" "sentinel" {
  workspace_id = azurerm_log_analytics_workspace.law.id
}

// -----------------------------
// Data Connectors
// -----------------------------

// Azure Activity Logs
resource "azurerm_sentinel_data_connector_azure_activity_log" "activity" {
  name         = "activity-connector"
  log_analytics_workspace_id = azurerm_log_analytics_workspace.law.id
}

// Azure AD Sign-in Logs
resource "azurerm_sentinel_data_connector_azure_active_directory" "aad" {
  name         = "aad-connector"
  log_analytics_workspace_id = azurerm_log_analytics_workspace.law.id
}

// Microsoft Defender Alerts
resource "azurerm_sentinel_data_connector_microsoft_defender_advanced_threat_protection" "defender" {
  name         = "defender-connector"
  log_analytics_workspace_id = azurerm_log_analytics_workspace.law.id
}
