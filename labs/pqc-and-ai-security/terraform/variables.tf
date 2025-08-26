variable "prefix" {
  description = "Name prefix for resources"
  type        = string
}

variable "location" {
  description = "Azure location"
  type        = string
  default     = "eastus"
}

variable "kv_name" {
  description = "Existing or to-create Key Vault name (no secrets in TF code)"
  type        = string
}

variable "cosmos_db_name" {
  description = "Cosmos SQL database name"
  type        = string
  default     = "pqcai"
}

variable "cosmos_container_name" {
  description = "Cosmos SQL container name"
  type        = string
  default     = "http_logs"
}

variable "cosmos_partition_key" {
  description = "Partition key path for Cosmos container"
  type        = string
  default     = "/ip"
}

variable "container_image" {
  description = "Container image for scheduled jobs (build from repo without secrets)"
  type        = string
  default     = "ghcr.io/example/pqc-ai-lab:latest"
}
