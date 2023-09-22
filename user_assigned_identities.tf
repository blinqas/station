module "user_assigned_identities" {
  for_each            = var.user_assigned_identities
  source              = "./user_assigned_identity/"
  name                = each.value.name
  resource_group_name = each.value.resource_group_name != null ? each.value.resource_group_name : azurerm_resource_group.workload.name
  location            = each.value.location != null ? each.value.location : azurerm_resource_group.workload.location
  tags                = local.tags
  role_assignments    = each.value.role_assignments != null ? each.value.role_assignment : []
  group_membership    = each.value.group_membership != null ? each.value.group_membership : toset([])
}
