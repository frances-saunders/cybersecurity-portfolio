// -----------------------------
// AKS Cluster Outputs
// -----------------------------

output "resource_group_name" {
  description = "Resource group containing the AKS cluster"
  value       = azurerm_resource_group.aks_rg.name
}

output "aks_cluster_name" {
  description = "Name of the deployed AKS cluster"
  value       = azurerm_kubernetes_cluster.aks.name
}

output "aks_cluster_id" {
  description = "Resource ID of the AKS cluster"
  value       = azurerm_kubernetes_cluster.aks.id
}

output "aks_fqdn" {
  description = "FQDN of the AKS cluster API server"
  value       = azurerm_kubernetes_cluster.aks.fqdn
}

output "aks_kube_config" {
  description = "Kube config for connecting to the cluster"
  value       = azurerm_kubernetes_cluster.aks.kube_config_raw
  sensitive   = true
}

// -----------------------------
// Policy Outputs
// -----------------------------

output "aks_security_baseline_initiative_id" {
  description = "Resource ID of the AKS Security Baseline Initiative"
  value       = azurerm_policy_set_definition.aks_security_baseline.id
}

output "aks_security_baseline_assignment_id" {
  description = "Resource ID of the AKS Security Baseline Assignment"
  value       = azurerm_policy_assignment.aks_security_baseline.id
}
