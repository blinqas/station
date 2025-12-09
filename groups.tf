module "ad_groups" {
  for_each                   = var.groups
  source                     = "./group"
  azuread_group              = each.value
  subscription_id            = var.subscription_id
  role_assignments           = each.value.role_assignments == null ? {} : each.value.role_assignments
  directory_role_assignments = each.value.directory_role_assignments == null ? {} : each.value.directory_role_assignments
  owners = concat(
    each.value.owners == null ? [] : each.value.owners,
    [module.user_assigned_identity.principal_id]
  )
  depends_on = [module.user_assigned_identity, module.user_assigned_identities]
  // This was required to ensure the identity was created before the group as it caused issues in azuread v3
}
