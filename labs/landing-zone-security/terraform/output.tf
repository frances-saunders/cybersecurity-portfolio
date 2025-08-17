// Outputs for validation
output "resource_group_id" {
  description = "The ID of the Landing Zone Baseline resource group"
  value       = azurerm_resource_group.lz_baseline.id
}

output "policy_assignment_id" {
  description = "The ID of the Landing Zone Baseline policy assignment"
  value       = azurerm_policy_assignment.lz_baseline_assignment.id
}
