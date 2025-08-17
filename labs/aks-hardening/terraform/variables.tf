# -----------------------------
# General Settings
# -----------------------------
variable "resource_group_name" {
  description = "The name of the resource group in which to create the AKS cluster"
  type        = string
}

variable "location" {
  description = "Azure region where resources will be deployed"
  type        = string
  default     = "eastus"
}

variable "cluster_name" {
  description = "The name of the AKS cluster"
  type        = string
}

variable "dns_prefix" {
  description = "DNS prefix for the AKS cluster"
  type        = string
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {
    environment = "lab"
    project     = "aks-hardening"
  }
}

# -----------------------------
# Node Pool Settings
# -----------------------------
variable "node_count" {
  description = "Number of nodes in the default pool"
  type        = number
  default     = 2
}

variable "vm_size" {
  description = "VM size for the default node pool"
  type        = string
  default     = "Standard_DS2_v2"
}

variable "subnet_id" {
  description = "The subnet ID for the AKS node pool"
  type        = string
}

# -----------------------------
# Security Settings
# -----------------------------
variable "api_server_authorized_ip_ranges" {
  description = "List of authorized IP ranges for the AKS API server"
  type        = list(string)
  default     = []
}

variable "log_analytics_workspace_id" {
  description = "Log Analytics Workspace ID for Defender for Containers integration"
  type        = string
}
