module "applications" {
  for_each            = var.applications
  source              = "./application/"
  azuread_application = each.value
  # Add workload identity service principal to the list of owners
  owners = concat(
    each.value.owners == null ? [] : each.value.owners,
    [module.user_assigned_identity.principal_id]
  )
  azuread_service_principal = try(each.value.service_principal, null)
  group_assignments = {
    for key, assignment in try(each.value.service_principal.group_assignments, {}) : key => {
      app_role_id     = assignment.app_role_id
      group_object_id = try(module.ad_groups[assignment.group_key].object_id, null)
    }
  }

  # This ensures that the workload identity has the correct permissions before it can be used as owner for the applications
  depends_on = [module.user_assigned_identity]
}
