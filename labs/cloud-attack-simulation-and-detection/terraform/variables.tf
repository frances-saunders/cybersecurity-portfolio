// =======================================================
// Variables for Cloud Attack Simulation & Detection Lab
// =======================================================

variable "resource_group_name" {
  description = "Resource group name"
  type        = string
}

variable "location" {
  description = "Azure region for deployment"
  type        = string
  default     = "eastus"
}

variable "prefix" {
  description = "Prefix used for naming resources"
  type        = string
  default     = "cloudattacklab"
}

variable "tags" {
  description = "Standardized tags for resource tracking"
  type        = map(string)
}
