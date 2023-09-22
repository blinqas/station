module "user_assigned_identities" {
  for_each            = var.user_assigned_identities
  source              = "./user_assigned_identity/"
  name                = each.value.name
  resource_group_name = each.value.resource_group_name != null ? each.value.resource_group_name : azurerm_resource_group.workload.name
  location            = each.value.location != null ? each.value.location : azurerm_resource_group.workload.location
  tags                = local.tags
  role_assignments    = try(each.value.role_assignments, [])
  group_membership    = try(each.value.group_membership, toset([]))
}
