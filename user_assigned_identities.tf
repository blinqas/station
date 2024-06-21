module "user_assigned_identity" {
  source                    = "./user_assigned_identity"
  name                      = try(var.identity.name, "mi-${var.tfe.workspace_name}-${var.environment_name}")
  resource_group_name       = azurerm_resource_group.workload.name
  location                  = azurerm_resource_group.workload.location
  tags                      = local.tags
  role_assignments          = try(var.identity.role_assignments, {})
  app_role_assignments      = try(var.identity.app_role_assignments, [])
  group_memberships         = try(var.identity.group_memberships, {})
  directory_role_assignment = try(var.identity.directory_role_assignment, {})
  resource_group_ids = concat(
    [azurerm_resource_group.workload.id],
    values(azurerm_resource_group.user_specified)[*].id
  )
}

module "user_assigned_identities" {
  for_each                  = var.user_assigned_identities
  source                    = "./user_assigned_identity/"
  name                      = each.value.name
  resource_group_name       = each.value.resource_group_name == null ? azurerm_resource_group.workload.name : each.value.resource_group_name
  location                  = each.value.location == null ? azurerm_resource_group.workload.location : each.value.location
  tags                      = local.tags
  role_assignments          = each.value.role_assignments == null ? {} : each.value.role_assignments
  app_role_assignments      = each.value.app_role_assignments == null ? [] : each.value.app_role_assignments
  group_memberships         = each.value.group_memberships == null ? {} : each.value.group_memberships
  directory_role_assignment = each.value.directory_role_assignment == null ? {} : each.value.directory_role_assignment
}
