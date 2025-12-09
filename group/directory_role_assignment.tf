resource "azuread_directory_role_assignment" "this" {
  for_each            = var.directory_role_assignments
  app_scope_id        = each.value.app_scope_id
  directory_scope_id  = each.value.directory_scope_id
  role_id             = each.value.role_id == null ? azuread_directory_role.existing[each.key].template_id : each.value.role_id
  principal_object_id = azuread_group.group.object_id
}

resource "azuread_directory_role" "existing" {
  for_each     = var.directory_role_assignments
  display_name = each.value.role_name
}
