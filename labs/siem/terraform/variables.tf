// labs/siem/terraform/variables.tf
variable "resource_group_name" {
  description = "Name of the resource group for SIEM lab"
  type        = string
}

variable "location" {
  description = "Azure region"
  type        = string
  default     = "eastus"
}

variable "prefix" {
  description = "Prefix for resource names"
  type        = string
}

variable "tags" {
  description = "Resource tags"
  type        = map(string)
  default = {
    owner       = "portfolio"
    environment = "lab"
    project     = "siem"
  }
}
