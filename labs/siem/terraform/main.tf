// labs/siem/terraform/main.tf
// Deploys Sentinel + workspace + sample data connectors

provider "azurerm" {
  features {}
}

// Resource group
resource "azurerm_resource_group" "siem" {
  name     = var.resource_group_name
  location = var.location
  tags     = var.tags
}

// Log Analytics Workspace
resource "azurerm_log_analytics_workspace" "siem" {
  name                = "${var.prefix}-law"
  location            = azurerm_resource_group.siem.location
  resource_group_name = azurerm_resource_group.siem.name
  sku                 = "PerGB2018"
  retention_in_days   = 30
  tags                = var.tags
}

// Onboard Sentinel
resource "azurerm_sentinel_log_analytics_workspace_onboarding" "sentinel" {
  workspace_id = azurerm_log_analytics_workspace.siem.id
}

// Sample data connector: Azure AD Sign-in logs
resource "azurerm_sentinel_data_connector_azure_active_directory" "aad" {
  name         = "${var.prefix}-aad-connector"
  log_analytics_workspace_id = azurerm_log_analytics_workspace.siem.id
}

// Sample data connector: Defender ATP alerts
resource "azurerm_sentinel_data_connector_microsoft_defender_advanced_threat_protection" "defender" {
  name         = "${var.prefix}-defender-connector"
  log_analytics_workspace_id = azurerm_log_analytics_workspace.siem.id
}
