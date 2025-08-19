// -----------------------------
// General Settings
// -----------------------------
variable "resource_group_name" {
  description = "Name of the resource group to deploy AKS into"
  type        = string
}

variable "location" {
  description = "Azure region for resource deployment"
  type        = string
  default     = "eastus"
}

variable "cluster_name" {
  description = "Name of the AKS cluster"
  type        = string
}

variable "dns_prefix" {
  description = "DNS prefix for the AKS API server"
  type        = string
}

variable "tags" {
  description = "Resource tags"
  type        = map(string)
  default     = {}
}

// -----------------------------
// Node Pool Settings
// -----------------------------
variable "node_count" {
  description = "Number of nodes in the default node pool"
  type        = number
  default     = 2
}

variable "vm_size" {
  description = "VM size for AKS worker nodes"
  type        = string
  default     = "Standard_DS2_v2"
}

variable "subnet_id" {
  description = "Resource ID of the subnet for AKS nodes"
  type        = string
}

// -----------------------------
// Security Settings
// -----------------------------
variable "api_server_authorized_ip_ranges" {
  description = "List of authorized IP ranges for the AKS API server"
  type        = list(string)
  default     = []
}

variable "log_analytics_workspace_id" {
  description = "Resource ID of the Log Analytics workspace"
  type        = string
}

// -----------------------------
// Authentication
// -----------------------------
variable "admin_username" {
  description = "Admin username for AKS nodes"
  type        = string
}

variable "ssh_public_key" {
  description = "SSH public key for AKS admin access"
  type        = string
}

variable "aks_admin_password" {
  description = "Admin password for AKS nodes (stored securely in Key Vault)"
  type        = string
  sensitive   = true
}

// -----------------------------
// Policy Parameters
// -----------------------------
variable "privileged_effect" {
  description = "Effect for blocking privileged containers (Audit, Deny, Disabled)"
  type        = string
  default     = "Deny"
}

variable "registry_effect" {
  description = "Effect for restricting to approved registries (Audit, Deny, Disabled)"
  type        = string
  default     = "Deny"
}

variable "approved_registries" {
  description = "List of approved container registries"
  type        = list(string)
  default     = []
}

variable "netpol_effect" {
  description = "Effect for enforcing NetworkPolicy (Audit, Deny, Disabled)"
  type        = string
  default     = "Audit"
}

variable "resource_limit_effect" {
  description = "Effect for enforcing resource limits/quotas (Audit, Deny, Disabled)"
  type        = string
  default     = "Audit"
}

variable "namespace_effect" {
  description = "Effect for restricting namespace creation (Audit, Deny, Disabled)"
  type        = string
  default     = "Deny"
}

variable "keyvault_effect" {
  description = "Effect for requiring secrets from Azure Key Vault (Audit, Deny, Disabled)"
  type        = string
  default     = "Audit"
}
