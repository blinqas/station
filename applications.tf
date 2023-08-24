module "applications" {
  for_each = var.applications
  source   = "./application/"

  // The caller of this module is unable to set their workload identity as owner, therefore we must merge.
  // A future improvement could be a bool check for `add_workload_service_principal_to_owners = bool`
  settings = merge(each.value.settings, {
    owners = [azuread_service_principal.workload.object_id]
  })

  azuread_api_permissions = can(each.value.azuread_api_permissions) ? each.value.azuread_api_permissions : []
}
