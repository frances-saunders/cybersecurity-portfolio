variable "sql_server_name" {
  description = "SQL Server name"
  type        = string
}

variable "db_name" {
  description = "Primary SQL database name"
  type        = string
}

variable "sku_name" {
  description = "SKU for SQL Database"
  type        = string
}

variable "resource_group_name" {
  description = "Resource group where resources are deployed"
  type        = string
}

variable "location" {
  description = "Azure region"
  type        = string
}

variable "admin_user" {
  description = "SQL Server administrator username"
  type        = string
}

variable "key_vault_id" {
  description = "Resource ID of the Key Vault storing secrets"
  type        = string
}

variable "sql_admin_password_secret_name" {
  description = "Name of the Key Vault secret containing SQL admin password"
  type        = string
}

variable "secondary_sql_server_id" {
  description = "Resource ID of secondary SQL server for geo-replication"
  type        = string
}
