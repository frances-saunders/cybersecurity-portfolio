# -----------------------------
# General Settings
# -----------------------------
resource_group_name          = "rg-logging-monitoring-lab"
location                     = "eastus"
log_analytics_workspace_name = "law-logging-monitoring-lab"

tags = {
  owner       = "portfolio"
  environment = "lab"
  project     = "logging-monitoring"
}

# -----------------------------
# AKS Cluster Integration
# -----------------------------
aks_cluster_id = "/subscriptions/<sub_id>/resourceGroups/<rg_name>/providers/Microsoft.ContainerService/managedClusters/<aks_name>"
