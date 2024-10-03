data "azuread_application_published_app_ids" "well_known" {}

resource "azuread_service_principal" "msgraph" {
  client_id    = data.azuread_application_published_app_ids.well_known.result.MicrosoftGraph
  use_existing = true
}

# Assign the workload identity the `Application.ReadWrite.OwnedBy` role so it can interact with the applications they own however they desire
resource "azuread_app_role_assignment" "app_workload_roles" {
  app_role_id         = azuread_service_principal.msgraph.app_role_ids["Application.ReadWrite.OwnedBy"]
  principal_object_id = module.user_assigned_identity.principal_id
  resource_object_id  = azuread_service_principal.msgraph.object_id
}


