output "group" {
  value = merge(azuread_group.group, { members = values(azuread_group_member.members)[*].member_object_id })
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

output "directory_role_assignments" {
  value = azuread_directory_role_assignment.this
}
