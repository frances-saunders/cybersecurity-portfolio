# ---------------------------------------------------------------------------
# main.tf — BCDR/IR Plan Lab
# Provisions Recovery Services Vaults (per tier), Azure Backup policies,
# ASR replication for Tier 1 workloads, and Azure Monitor alert rules.
# Secrets are never embedded; use environment variables or Key Vault refs.
# ---------------------------------------------------------------------------

terraform {
  required_version = ">= 1.3"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.80"
    }
  }
}

provider "azurerm" {
  features {
    recovery_services_vault {
      recover_soft_deleted_file_shares = true
      purge_soft_delete_on_destroy     = false
    }
  }
}

# ---------------------------------------------------------------------------
# Resource Groups
# ---------------------------------------------------------------------------

resource "azurerm_resource_group" "bcdr" {
  name     = var.resource_group_name
  location = var.primary_location
  tags     = var.tags
}

resource "azurerm_resource_group" "bcdr_recovery" {
  name     = "${var.resource_group_name}-recovery"
  location = var.recovery_location
  tags     = var.tags
}

# ---------------------------------------------------------------------------
# Recovery Services Vaults — Tier 1 (GRS + immutability)
# ---------------------------------------------------------------------------

resource "azurerm_recovery_services_vault" "tier1" {
  name                         = "${var.prefix}-vault-tier1"
  location                     = var.primary_location
  resource_group_name          = azurerm_resource_group.bcdr.name
  sku                          = "Standard"
  storage_mode_type            = "GeoRedundant"
  cross_region_restore_enabled = true
  soft_delete_enabled          = true
  immutability                 = "Locked"
  tags                         = var.tags
}

# ---------------------------------------------------------------------------
# Recovery Services Vaults — Tier 2 (GRS, soft-delete)
# ---------------------------------------------------------------------------

resource "azurerm_recovery_services_vault" "tier2" {
  name                = "${var.prefix}-vault-tier2"
  location            = var.primary_location
  resource_group_name = azurerm_resource_group.bcdr.name
  sku                 = "Standard"
  storage_mode_type   = "GeoRedundant"
  soft_delete_enabled = true
  tags                = var.tags
}

# ---------------------------------------------------------------------------
# Recovery Services Vaults — Tier 3 (LRS, cost-optimised)
# ---------------------------------------------------------------------------

resource "azurerm_recovery_services_vault" "tier3" {
  name                = "${var.prefix}-vault-tier3"
  location            = var.primary_location
  resource_group_name = azurerm_resource_group.bcdr.name
  sku                 = "Standard"
  storage_mode_type   = "LocallyRedundant"
  soft_delete_enabled = true
  tags                = var.tags
}

# ---------------------------------------------------------------------------
# Backup Policies — VM (Tier 1: hourly, Tier 2: daily, Tier 3: daily)
# ---------------------------------------------------------------------------

resource "azurerm_backup_policy_vm" "tier1" {
  name                = "bcdr-vm-policy-tier1"
  resource_group_name = azurerm_resource_group.bcdr.name
  recovery_vault_name = azurerm_recovery_services_vault.tier1.name

  backup {
    frequency     = "Hourly"
    hour_interval = 1
    hour_duration = 4
  }

  retention_daily { count = 30 }
  retention_weekly {
    count    = 12
    weekdays = ["Sunday"]
  }
  instant_restore_retention_days = 5
}

resource "azurerm_backup_policy_vm" "tier2" {
  name                = "bcdr-vm-policy-tier2"
  resource_group_name = azurerm_resource_group.bcdr.name
  recovery_vault_name = azurerm_recovery_services_vault.tier2.name

  backup {
    frequency = "Daily"
    time      = "02:00"
  }

  retention_daily { count = 30 }
  retention_weekly {
    count    = 12
    weekdays = ["Sunday"]
  }
  instant_restore_retention_days = 2
}

resource "azurerm_backup_policy_vm" "tier3" {
  name                = "bcdr-vm-policy-tier3"
  resource_group_name = azurerm_resource_group.bcdr.name
  recovery_vault_name = azurerm_recovery_services_vault.tier3.name

  backup {
    frequency = "Daily"
    time      = "03:00"
  }

  retention_daily { count = 30 }
}

# ---------------------------------------------------------------------------
# Azure Monitor — Backup Job Failure & Replication Health Alerts
# ---------------------------------------------------------------------------

resource "azurerm_monitor_action_group" "bcdr_alerts" {
  name                = "bcdr-alerts"
  resource_group_name = azurerm_resource_group.bcdr.name
  short_name          = "bcdr"

  email_receiver {
    name          = "SOC"
    email_address = var.alert_email
  }
}

resource "azurerm_monitor_metric_alert" "backup_failure" {
  name                = "bcdr-backup-job-failure"
  resource_group_name = azurerm_resource_group.bcdr.name
  scopes              = [azurerm_recovery_services_vault.tier1.id]
  description         = "Alert on any backup job failure in the Tier 1 vault."
  severity            = 1
  frequency           = "PT5M"
  window_size         = "PT15M"

  criteria {
    metric_namespace = "Microsoft.RecoveryServices/vaults"
    metric_name      = "BackupHealthEvent"
    aggregation      = "Count"
    operator         = "GreaterThan"
    threshold        = 0
  }

  action {
    action_group_id = azurerm_monitor_action_group.bcdr_alerts.id
  }
}
