resource "azuread_directory_role_assignment" "roles" {
  for_each            = var.directory_role_assignment
  app_scope_id        = each.value.app_scope_id
  directory_scope_id  = each.value.directory_scope_id
  role_id             = azuread_directory_role.roles[each.key].template_id
  principal_object_id = azurerm_user_assigned_identity.identity.principal_id
}

resource "azuread_directory_role" "roles" {
  for_each     = var.directory_role_assignment
  display_name = each.value.role_name
}
