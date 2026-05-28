# ---------------------------------------------------------------------------
# asr-replication.tf — BCDR/IR Plan Lab
# Provisions Azure Site Recovery (ASR) replication infrastructure for Tier 1 workloads.
# Includes recovery network pre-staging (VNet, NSGs, private DNS zones) in the
# recovery region — the gap identified during the test failover on 2025-01-20.
# See docs/test-results.md section 1.3 and docs/ir-playbooks/region-outage-tier1-failover.md.
#
# Deliberate design decision: ASR replication is enabled ONLY for Tier 1 workloads.
# See docs/options-analysis-and-architecture-decision.md Decision 2 for full rationale.
# ---------------------------------------------------------------------------

resource "azurerm_resource_group" "asr_recovery" {
  name     = "${var.prefix}-rg-recovery"
  location = var.recovery_location
  tags     = var.tags
}

resource "azurerm_virtual_network" "recovery_vnet" {
  name                = "${var.prefix}-vnet-recovery"
  location            = var.recovery_location
  resource_group_name = azurerm_resource_group.asr_recovery.name
  address_space       = ["10.1.0.0/16"]
  tags                = var.tags
}

resource "azurerm_subnet" "recovery_app_subnet" {
  name                 = "app-subnet"
  resource_group_name  = azurerm_resource_group.asr_recovery.name
  virtual_network_name = azurerm_virtual_network.recovery_vnet.name
  address_prefixes     = ["10.1.1.0/24"]
}

resource "azurerm_subnet" "recovery_data_subnet" {
  name                 = "data-subnet"
  resource_group_name  = azurerm_resource_group.asr_recovery.name
  virtual_network_name = azurerm_virtual_network.recovery_vnet.name
  address_prefixes     = ["10.1.2.0/24"]
}

resource "azurerm_network_security_group" "recovery_nsg" {
  name                = "${var.prefix}-nsg-recovery"
  location            = var.recovery_location
  resource_group_name = azurerm_resource_group.asr_recovery.name
  tags                = var.tags

  security_rule {
    name                       = "deny-all-inbound"
    priority                   = 4096
    direction                  = "Inbound"
    access                     = "Deny"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

resource "azurerm_subnet_network_security_group_association" "recovery_app_nsg" {
  subnet_id                 = azurerm_subnet.recovery_app_subnet.id
  network_security_group_id = azurerm_network_security_group.recovery_nsg.id
}

# ---------------------------------------------------------------------------
# Private DNS Zones — linked to recovery VNet
# CRITICAL: This was the gap identified in test failover 2025-01-20.
# All private endpoint DNS zones used in production MUST be linked here.
# See docs/test-results.md section 1.3.
# ---------------------------------------------------------------------------

locals {
  private_dns_zones = [
    "privatelink.database.windows.net",
    "privatelink.blob.core.windows.net",
    "privatelink.file.core.windows.net",
    "privatelink.vaultcore.azure.net",
    "privatelink.documents.azure.com"
  ]
}

resource "azurerm_private_dns_zone_virtual_network_link" "recovery_dns_links" {
  for_each = toset(local.private_dns_zones)

  name                  = "${replace(each.key, ".", "-")}-recovery-link"
  resource_group_name   = azurerm_resource_group.asr_recovery.name
  private_dns_zone_name = each.key
  virtual_network_id    = azurerm_virtual_network.recovery_vnet.id
  registration_enabled  = false
  tags                  = var.tags
}

# ---------------------------------------------------------------------------
# ASR Replication Fabric, Container, and Policy
# ---------------------------------------------------------------------------

resource "azurerm_site_recovery_fabric" "primary" {
  name                = "asr-fabric-primary"
  resource_group_name = azurerm_resource_group.bcdr.name
  recovery_vault_name = azurerm_recovery_services_vault.tier1.name
  location            = var.primary_location
}

resource "azurerm_site_recovery_fabric" "recovery" {
  name                = "asr-fabric-recovery"
  resource_group_name = azurerm_resource_group.bcdr.name
  recovery_vault_name = azurerm_recovery_services_vault.tier1.name
  location            = var.recovery_location
}

resource "azurerm_site_recovery_protection_container" "primary" {
  name                 = "asr-container-primary"
  resource_group_name  = azurerm_resource_group.bcdr.name
  recovery_vault_name  = azurerm_recovery_services_vault.tier1.name
  recovery_fabric_name = azurerm_site_recovery_fabric.primary.name
}

resource "azurerm_site_recovery_protection_container" "recovery" {
  name                 = "asr-container-recovery"
  resource_group_name  = azurerm_resource_group.bcdr.name
  recovery_vault_name  = azurerm_recovery_services_vault.tier1.name
  recovery_fabric_name = azurerm_site_recovery_fabric.recovery.name
}

resource "azurerm_site_recovery_replication_policy" "tier1" {
  name                                                 = "asr-policy-tier1"
  resource_group_name                                  = azurerm_resource_group.bcdr.name
  recovery_vault_name                                  = azurerm_recovery_services_vault.tier1.name
  recovery_point_retention_in_minutes                  = 24 * 60
  application_consistent_snapshot_frequency_in_minutes = 4 * 60
}

resource "azurerm_site_recovery_protection_container_mapping" "primary_to_recovery" {
  name                                      = "asr-mapping-primary-to-recovery"
  resource_group_name                       = azurerm_resource_group.bcdr.name
  recovery_vault_name                       = azurerm_recovery_services_vault.tier1.name
  recovery_fabric_name                      = azurerm_site_recovery_fabric.primary.name
  recovery_source_protection_container_name = azurerm_site_recovery_protection_container.primary.name
  recovery_target_protection_container_id   = azurerm_site_recovery_protection_container.recovery.id
  recovery_replication_policy_id            = azurerm_site_recovery_replication_policy.tier1.id
}

# ---------------------------------------------------------------------------
# Network Mapping — maps primary VNet to recovery VNet for failover
# ---------------------------------------------------------------------------

resource "azurerm_site_recovery_network_mapping" "primary_to_recovery" {
  name                        = "asr-network-map-primary-to-recovery"
  resource_group_name         = azurerm_resource_group.bcdr.name
  recovery_vault_name         = azurerm_recovery_services_vault.tier1.name
  source_recovery_fabric_name = azurerm_site_recovery_fabric.primary.name
  target_recovery_fabric_name = azurerm_site_recovery_fabric.recovery.name
  source_network_id           = var.primary_vnet_id
  target_network_id           = azurerm_virtual_network.recovery_vnet.id
}
