output "custom_policy_definition_ids" {
  description = "IDs of all custom policy definitions."
  value       = { for k, v in azurerm_policy_definition.custom : k => v.id }
}

output "initiative_ids" {
  description = "IDs of the created initiatives."
  value       = { for k, v in azurerm_policy_set_definition.initiative : k => v.id }
}

output "assignment_ids" {
  description = "IDs of the policy assignments per framework."
  value       = { for k, v in azurerm_policy_assignment.assign_initiatives : k => v.id }
}
