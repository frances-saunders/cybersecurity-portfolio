// Terraform variables for AKS Hardening Lab

variable "resource_group_name" {
  description = "Resource group for AKS deployment"
  type        = string
  default     = "rg-aks-hardening"
}

variable "location" {
  description = "Azure region"
  type        = string
  default     = "eastus"
}

variable "cluster_name" {
  description = "Name of the AKS cluster"
  type        = string
  default     = "aks-hardening-cluster"
}

variable "dns_prefix" {
  description = "DNS prefix for the cluster"
  type        = string
  default     = "akshardening"
}

variable "node_count" {
  description = "Number of AKS worker nodes"
  type        = number
  default     = 2
}

variable "node_vm_size" {
  description = "VM size for worker nodes"
  type        = string
  default     = "Standard_DS2_v2"
}

// Policy Parameters
variable "privileged_effect" {
  description = "Effect for privileged container policy"
  type        = string
  default     = "Deny"
}

variable "registry_effect" {
  description = "Effect for restricting registries"
  type        = string
  default     = "Deny"
}

variable "approved_registries" {
  description = "Approved registries for container images"
  type        = list(string)
  default     = ["mcr.microsoft.com", "mycompany.azurecr.io"]
}

variable "netpol_effect" {
  description = "Effect for network policy enforcement"
  type        = string
  default     = "Audit"
}

variable "resource_limit_effect" {
  description = "Effect for enforcing container resource limits"
  type        = string
  default     = "Audit"
}

variable "namespace_effect" {
  description = "Effect for default namespace restrictions"
  type        = string
  default     = "Deny"
}

variable "keyvault_effect" {
  description = "Effect for Key Vault secret enforcement"
  type        = string
  default     = "Audit"
}
