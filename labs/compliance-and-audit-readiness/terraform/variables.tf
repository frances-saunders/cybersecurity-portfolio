variable "subscription_id" {
  description = "Target Azure subscription ID for provider context."
  type        = string
}

variable "management_group_id" {
  description = "Optional management group ID to create definitions under. Leave empty to use subscription-level."
  type        = string
  default     = ""
}

variable "assignment_scope" {
  description = "Scope at which to assign initiatives. MG, Subscription, or Resource Group scope string."
  type        = string
}

variable "policy_assignment_location" {
  description = "Azure location required for policy assignment (e.g., eastus)."
  type        = string
  default     = "eastus"
}

variable "log_analytics_workspace_id" {
  description = "Resource ID of the Log Analytics workspace used for diagnostics policies."
  type        = string
  default     = ""
}

variable "allowed_locations" {
  description = "List of permitted Azure regions for resource deployment."
  type        = list(string)
  default     = ["eastus", "eastus2", "centralus", "westus3"]
}

variable "owner_tag" {
  description = "Tag value for 'owner'."
  type        = string
}

variable "environment" {
  description = "Environment tag value (e.g., prod, nonprod)."
  type        = string
  default     = "prod"
}

variable "additional_tags" {
  description = "Additional common tags to apply."
  type        = map(string)
  default     = {}
}

# Effects allow you to switch between audit/deny without changing policy bodies
variable "policy_effects" {
  description = "Map of effects per policy control."
  type = object({
    deny_public_ip_on_vm             = string
    require_disk_encryption          = string
    require_secure_transfer_on_storage = string
    require_diagnostics_to_law       = string
    restrict_approved_locations      = string
    require_resource_tags            = string
  })
  default = {
    deny_public_ip_on_vm               = "deny"
    require_disk_encryption            = "auditIfNotExists"
    require_secure_transfer_on_storage = "deny"
    require_diagnostics_to_law         = "audit"
    restrict_approved_locations        = "deny"
    require_resource_tags              = "audit"
  }
}
