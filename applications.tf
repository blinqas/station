module "caf_applications" {
  for_each = var.applications
  source   = "aztfmod/caf/azurerm//modules/azuread/applications_v1"
  version  = "5.7.0-preview0"

  client_config = data.azurerm_client_config.current
  user_type     = each.value.user_type

  // Hard-specify passthrough = false as the applications_v1 module checks, we are not using caf
  // so it is uneccessary to configure anything else.
  global_settings = {
    passthrough = false
  }

  // The caller of this module is unable to set their workload identity as owner, therefore we must merge.
  // A future improvement could be a bool check for `add_workload_service_principal_to_owners = bool`
  settings = merge(each.value.settings, {
    owners = [azuread_service_principal.workload.object_id]
  })

  azuread_api_permissions = can(each.value.azuread_api_permissions) ? each.value.azuread_api_permissions : []
}
