module "ad_groups" {
  for_each      = var.groups
  source        = "./group"
  azuread_group = each.value
  owners = concat(
    each.value.owners == null ? [] : each.value.owners,
    [azuread_service_principal.workload.object_id]
  )
}
