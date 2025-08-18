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
  description = "Prefix for resource names"
  type        = string
}

variable "tags" {
  description = "Resource tags"
  type        = map(string)
  default     = {}
}

variable "storage_account_id" {
  description = "Resource ID of the Storage Account"
  type        = string
}

variable "sql_server_id" {
  description = "Resource ID of the SQL Server"
  type        = string
}
