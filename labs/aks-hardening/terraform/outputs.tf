// Terraform outputs for AKS Hardening Lab

output "aks_cluster_name" {
  description = "The name of the AKS cluster"
  value       = azurerm_kubernetes_cluster.aks.name
}

output "aks_kube_config" {
  description = "Kube config for the AKS cluster"
  value       = azurerm_kubernetes_cluster.aks.kube_config_raw
  sensitive   = true
}

output "policy_assignment_id" {
  description = "The ID of the AKS Security Baseline assignment"
  value       = azurerm_policy_assignment.aks_security_baseline.id
}
