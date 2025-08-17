// variables.tf - Input variables for Sentinel lab

variable "resource_group_name" {
  description = "Name of the resource group for Sentinel lab"
  type        = string
}

variable "location" {
  description = "Azure region for deployment"
  type        = string
  default     = "eastus"
}

variable "law_name" {
  description = "Log Analytics Workspace name"
  type        = string
}

variable "tags" {
  description = "Resource tags"
  type        = map(string)
  default = {
    owner       = "portfolio"
    environment = "lab"
    project     = "sentinel-ir"
  }
}
