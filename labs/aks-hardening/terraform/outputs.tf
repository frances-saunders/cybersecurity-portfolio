output "aks_cluster_name" {
  description = "The name of the AKS cluster"
  value       = azurerm_kubernetes_cluster.aks.name
}

output "aks_kube_config" {
  description = "Kubeconfig to authenticate with the AKS cluster"
  value       = azurerm_kubernetes_cluster.aks.kube_config[0].raw_kube_config
  sensitive   = true
}
