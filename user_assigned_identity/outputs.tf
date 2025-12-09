output "name" {
  value = azurerm_user_assigned_identity.identity.name
}

output "id" {
  value = azurerm_user_assigned_identity.identity.id
}

output "client_id" {
  value = azurerm_user_assigned_identity.identity.client_id
}

output "principal_id" {
  value = azurerm_user_assigned_identity.identity.principal_id
}

output "tenant_id" {
  value = azurerm_user_assigned_identity.identity.tenant_id
}

output "group_memberships" {
  value = azuread_group_member.uai
}

output "directory_role_assignments" {
  value = azuread_directory_role_assignment.this
}

output "location" {
  value = azurerm_user_assigned_identity.identity.location
}

output "role_assignments" {
  value = azurerm_role_assignment.this
}

output "app_role_assignments" {
  value = azuread_app_role_assignment.this
}

