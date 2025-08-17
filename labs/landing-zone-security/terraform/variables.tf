// Variables for Landing Zone Baseline Lab
variable "location" {
  description = "Azure region for resource deployment"
  type        = string
  default     = "eastus"
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default = {
    Owner       = "LandingZoneDemo"
    Environment = "Lab"
    CostCenter  = "0000"
  }
}

variable "initiative_id" {
  description = "Resource ID of the Landing Zone Baseline initiative"
  type        = string
}

variable "name_pattern" {
  description = "Regex pattern for naming convention"
  type        = string
  default     = "^[a-z]{2,5}-[a-z0-9]{2,8}-[a-z]{2,5}$"
}

variable "required_tags" {
  description = "List of required tags"
  type        = list(string)
  default     = ["Owner", "Environment", "CostCenter"]
}

variable "allowed_skus" {
  description = "List of allowed VM SKUs"
  type        = list(string)
  default     = ["Standard_B1s", "Standard_B2s", "Standard_D2s_v3"]
}
