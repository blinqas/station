module "applications" {
  for_each            = var.applications
  source              = "./application/"
  azuread_application = each.value
  # Add workload identity service principal to the list of owners
  owners = concat(
    each.value.owners == null ? [] : each.value.owners,
    [module.user_assigned_identity.principal_id]
  )
  azuread_service_principal = try(each.value.service_principal, {})

  # This ensures that the workload identity has the correct permissions before it can be used as owner for the applications
  depends_on = [azuread_app_role_assignment.app_workload_roles]
}
