moved {
  from = azuread_app_role_assignment.app_workload_roles
  to   = azuread_app_role_assignment.this
}

resource "azuread_app_role_assignment" "this" {
  for_each            = var.app_role_assignments
  app_role_id         = each.value.app_role_id
  principal_object_id = azurerm_user_assigned_identity.identity.principal_id
  resource_object_id  = each.value.resource_object_id
}


