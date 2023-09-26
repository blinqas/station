module "ad_groups" {
  for_each      = var.groups
  source        = "./group"
  azuread_group = each.value
  owners = concat(
    each.value.owners == null ? [] : each.value.owners,
    [module.user_assigned_identity.principal_id]
  )
}
