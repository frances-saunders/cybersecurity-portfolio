variable "resource_group_name" {
  description = "Resource group name for monitoring lab"
  type        = string
}

variable "location" {
  description = "Azure region"
  type        = string
}

variable "log_analytics_workspace_name" {
  description = "Name of Log Analytics Workspace"
  type        = string
}

variable "aks_cluster_id" {
  description = "Resource ID of the AKS cluster"
  type        = string
}

variable "tags" {
  description = "Resource tags"
  type        = map(string)
}
