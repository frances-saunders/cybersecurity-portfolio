variable "prefix" {
  description = "Prefix applied to all resource names."
  type        = string
  default     = "bcdr"
}

variable "resource_group_name" {
  description = "Name of the primary resource group."
  type        = string
}

variable "primary_location" {
  description = "Primary Azure region for BCDR vaults and backup policies."
  type        = string
}

variable "recovery_location" {
  description = "Secondary Azure region for ASR replication and cross-region restore."
  type        = string
}

variable "alert_email" {
  description = "Email address for backup failure and replication health alert notifications."
  type        = string
  sensitive   = true
}

variable "tags" {
  description = "Tags applied to all resources."
  type        = map(string)
  default = {
    environment = "production"
    owner       = "security"
    project     = "bcdr-ir-plan"
  }
}
