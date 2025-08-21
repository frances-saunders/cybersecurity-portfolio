variable "resource_group_name" {
  description = "Name of the Resource Group"
  type        = string
}

variable "location" {
  description = "Azure region for deployment"
  type        = string
  default     = "eastus"
}

variable "prefix" {
  description = "Prefix for naming resources"
  type        = string
}

variable "tags" {
  description = "Tags for all resources"
  type        = map(string)
  default     = {
    owner       = "portfolio"
    environment = "lab"
    project     = "monitoring-integration"
  }
}
