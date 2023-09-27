resource "azurerm_role_assignment" "station_subscription_owner" {
  for_each             = var.subscription_ids
  scope                = each.value
  principal_id         = azuread_service_principal.workload.object_id
  role_definition_name = "Owner"
}

resource "azuread_directory_role" "global_admin" {
  display_name = "Global Administrator"
}

resource "azuread_directory_role_assignment" "station_aad_admin" {
  role_id             = azuread_directory_role.global_admin.template_id
  principal_object_id = azuread_service_principal.workload.object_id
}

