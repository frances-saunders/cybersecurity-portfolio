output "resource_group_name" {
  value = azurerm_resource_group.ztns.name
}

output "firewall_public_ip" {
  value = azurerm_public_ip.firewall.ip_address
}

output "hub_subnet_id" {
  value = azurerm_subnet.hub.id
}

output "workload_subnet_id" {
  value = azurerm_subnet.workload.id
}

output "shared_subnet_id" {
  value = azurerm_subnet.shared.id
}

output "private_endpoint_storage_id" {
  value = azurerm_private_endpoint.storage.id
}

output "private_endpoint_sql_id" {
  value = azurerm_private_endpoint.sql.id
}
