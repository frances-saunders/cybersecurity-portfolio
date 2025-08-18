# -----------------------------
# General Settings
# -----------------------------
resource_group_name = "rg-zero-trust-segmentation"
location            = "eastus"
prefix              = "ztns"

tags = {
  owner       = "portfolio"
  environment = "lab"
  project     = "zero-trust-network-segmentation"
}

# -----------------------------
# Private Endpoint Targets
# -----------------------------
# Replace with actual resource IDs from your lab environment
storage_account_id = "/subscriptions/<sub_id>/resourceGroups/<rg_name>/providers/Microsoft.Storage/storageAccounts/<storage_name>"
sql_server_id      = "/subscriptions/<sub_id>/resourceGroups/<rg_name>/providers/Microsoft.Sql/servers/<sql_name>"
