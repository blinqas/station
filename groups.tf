module "ad_groups" {
  for_each         = var.groups
  source           = "./group"
  azuread_group    = each.value
  subscription_id  = var.subscription_id
  role_assignments = each.value.role_assignments == null ? {} : each.value.role_assignments
  owners = concat(
    each.value.owners == null ? [] : each.value.owners,
    [module.user_assigned_identity.principal_id]
  )
}

module "groups" {
  for_each        = var.groups
  source          = "./group"
  azuread_group   = each.value.name
  subscription_id = var.subscription_id
  role_assignments = {
    scopes = concat(
      azurerm_resource_group.user_specified[*].id,
    )
    assignments = each.value.role_assignments
  }
}
