output "group" {
  value = azuread_group.group
}

output "display_name" {
  value = azuread_group.group.display_name
}


output "role_assignments" {
  value = azurerm_role_assignment.roles
}

output "object_id" {
  value = azuread_group.group.object_id
}

