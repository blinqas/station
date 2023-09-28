module "user_assigned_identity" {
  source              = "./user_assigned_identity"
  name                = "mi-workload-identity"
  resource_group_name = azurerm_resource_group.workload.name
  location            = azurerm_resource_group.workload.location
  tags                = local.tags
  role_assignments    = []
  group_memberships   = []
}

module "user_assigned_identities" {
  for_each            = var.user_assigned_identities
  source              = "./user_assigned_identity/"
  name                = each.value.name
  resource_group_name = each.value.resource_group_name == null ? azurerm_resource_group.workload.name : each.value.resource_group_name
  location            = each.value.location == null ? azurerm_resource_group.workload.location : each.value.location
  tags                = local.tags
  role_assignments    = each.value.role_assignments == null ? [] : each.value.role_assignments
  group_memberships   = each.value.group_memberships == null ? [] : each.value.group_memberships
}
