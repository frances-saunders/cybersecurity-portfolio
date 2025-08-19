#############################################
# variables.tf - Input variables
# No plaintext secrets stored here
#############################################

variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
}

variable "location" {
  description = "Azure region to deploy resources"
  type        = string
  default     = "eastus"
}

variable "tags" {
  description = "Resource tags"
  type        = map(string)
  default     = {
    environment = "lab"
    project     = "race-telemetry"
  }
}

variable "sql_admin_user" {
  description = "SQL Server administrator username"
  type        = string
  default     = "telemetryadmin"
}

variable "sql_admin_password" {
  description = "SQL Server administrator password (will be stored securely in Key Vault)"
  type        = string
  sensitive   = true
}

variable "tenant_id" {
  description = "Azure Active Directory tenant ID"
  type        = string
}

variable "admin_object_id" {
  description = "Azure AD Object ID for admin to manage Key Vault access"
  type        = string
}
