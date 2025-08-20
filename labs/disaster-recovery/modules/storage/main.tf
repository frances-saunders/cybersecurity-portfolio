// Module: Geo-Redundant Storage
resource "azurerm_storage_account" "this" {
  name                     = var.storage_name
  resource_group_name      = var.resource_group_name
  location                 = var.location
  account_tier             = "Standard"
  account_replication_type = "GRS"
}

output "storage_endpoint" {
  value = azurerm_storage_account.this.primary_blob_endpoint
}
