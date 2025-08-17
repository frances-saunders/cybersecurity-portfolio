# -----------------------------
# General Settings
# -----------------------------
resource_group_name = "rg-aks-hardening-lab"
location            = "eastus"
cluster_name        = "aks-hardening-lab"
dns_prefix          = "akslab"

tags = {
  owner       = "portfolio"
  environment = "lab"
  project     = "aks-hardening"
}

# -----------------------------
# Node Pool Settings
# -----------------------------
node_count = 2
vm_size    = "Standard_DS2_v2"

# Replace this with a valid subnet resource ID from your lab VNet
subnet_id = "/subscriptions/<sub_id>/resourceGroups/<rg_name>/providers/Microsoft.Network/virtualNetworks/<vnet_name>/subnets/<subnet_name>"

# -----------------------------
# Security Settings
# -----------------------------
api_server_authorized_ip_ranges = [
  "203.0.113.25/32",   # Example: corporate office IP
  "198.51.100.42/32"   # Example: home IP
]

# Replace this with your Log Analytics Workspace resource ID
log_analytics_workspace_id = "/subscriptions/<sub_id>/resourceGroups/<rg_name>/providers/Microsoft.OperationalInsights/workspaces/<law_name>"
