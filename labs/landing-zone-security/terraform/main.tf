// Terraform configuration for Landing Zone Baseline governance
terraform {
  required_version = ">=1.5.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~>3.70"
    }
  }
}

provider "azurerm" {
  features {}
}

// Resource Group for Landing Zone demonstration
resource "azurerm_resource_group" "lz_baseline" {
  name     = "rg-landingzone-baseline"
  location = var.location
  tags     = var.tags
}

// Policy Assignment for Landing Zone Baseline
resource "azurerm_policy_assignment" "lz_baseline_assignment" {
  name                 = "landing-zone-baseline-assignment"
  scope                = azurerm_resource_group.lz_baseline.id
  policy_definition_id = var.initiative_id
  display_name         = "Landing Zone Baseline Assignment"
  description          = "Enforces baseline governance policies for landing zones"
  location             = var.location

  parameters = jsonencode({
    location = {
      value = var.location
    }
    namePattern = {
      value = var.name_pattern
    }
    requiredTags = {
      value = var.required_tags
    }
    allowedSkus = {
      value = var.allowed_skus
    }
  })
}
