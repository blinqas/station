module "caf_applications" {
  for_each = var.applications
  source  = "aztfmod/caf/azurerm//modules/azuread/applications_v1"
  version = "5.7.0-preview0"

  client_config = data.azurerm_client_config.current
  user_type = each.value.user_type

  // We are not using CAF
  global_settings = {
    passthrough = false
  }

  settings = merge(each.value.settings, {
    owners = [azuread_service_principal.workload.object_id]
  })

  azuread_api_permissions = can(each.value.azuread_api_permissions) ? each.value.azuread_api_permissions : []
}
