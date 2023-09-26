data "azuread_application_published_app_ids" "well_known" {}

resource "azuread_service_principal" "msgraph" {
  application_id = data.azuread_application_published_app_ids.well_known.result.MicrosoftGraph
  use_existing   = true
}

resource "azuread_app_role_assignment" "app_workload_roles" {
  for_each            = var.role_assignments
  app_role_id         = azuread_service_principal.msgraph.app_role_ids[each.value]
  principal_object_id = azurerm_user_assigned_identity.identity.principal_id
  resource_object_id  = azuread_service_principal.msgraph.object_id
}


