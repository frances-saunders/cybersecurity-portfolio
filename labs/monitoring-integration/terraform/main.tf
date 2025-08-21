// main.tf - Monitoring Integration Lab
provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "monitoring" {
  name     = var.resource_group_name
  location = var.location
  tags     = var.tags
}

resource "azurerm_log_analytics_workspace" "law" {
  name                = "${var.prefix}-law"
  location            = azurerm_resource_group.monitoring.location
  resource_group_name = azurerm_resource_group.monitoring.name
  sku                 = "PerGB2018"
  retention_in_days   = 30
  tags                = var.tags
}

resource "azurerm_security_insights_workspace_onboarding" "sentinel" {
  workspace_id = azurerm_log_analytics_workspace.law.id
}

resource "azurerm_eventhub_namespace" "zabbix_ns" {
  name                = "${var.prefix}-ehns"
  location            = azurerm_resource_group.monitoring.location
  resource_group_name = azurerm_resource_group.monitoring.name
  sku                 = "Standard"
  capacity            = 1
  tags                = var.tags
}

resource "azurerm_eventhub" "zabbix" {
  name                = "${var.prefix}-zabbix"
  namespace_name      = azurerm_eventhub_namespace.zabbix_ns.name
  resource_group_name = azurerm_resource_group.monitoring.name
  partition_count     = 2
  message_retention   = 1
}

resource "azurerm_eventhub_authorization_rule" "zabbix_send" {
  name                = "zabbix-send"
  namespace_name      = azurerm_eventhub_namespace.zabbix_ns.name
  eventhub_name       = azurerm_eventhub.zabbix.name
  resource_group_name = azurerm_resource_group.monitoring.name
  send                = true
}

output "eventhub_connection_string" {
  description = "Connection string for Zabbix forwarder"
  value       = azurerm_eventhub_authorization_rule.zabbix_send.primary_connection_string
  sensitive   = true
}

output "law_workspace_id" {
  value       = azurerm_log_analytics_workspace.law.id
  description = "ID of the Log Analytics Workspace"
}
