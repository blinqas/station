resource "azuread_app_role_assignment" "groups" {
  for_each = var.group_assignments

  app_role_id         = each.value.app_role_id
  principal_object_id = each.value.group_object_id
  resource_object_id  = azuread_service_principal.this[0].object_id
}
