module "ad_groups" {
  for_each = var.groups
  source   = "./group"
  settings = each.value.settings
  ##owners = try(each.value.settings.add_workload_sp_to_owners, true) ? merge(try(each.value.settings.owners, []), [azuread_service_principal.workload.object_id]) : each.value.settings.owners
  owners = try(each.value.settings.add_workload_sp_to_owners, true) ? concat(each.value.settings.owners, [azuread_service_principal.workload.object_id]) : each.value.settings.owners
}

