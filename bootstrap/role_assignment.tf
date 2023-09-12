data "azurerm_subscription" "deployment" {
  subscription_id = data.azurerm_client_config.current.subscription_id
}

resource "azurerm_role_assignment" "station_subscription_owner" {
  scope                = data.azurerm_subscription.deployment.id
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

