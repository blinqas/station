module "applications" {
  for_each            = var.applications
  source              = "./application/"
  azuread_application = each.value
  # Add workload identity service principal to the list of owners
  owners = concat(
    each.value.owners == null ? [] : each.value.owners,
    [module.user_assigned_identity.principal_id]
  )
}

