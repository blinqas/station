resource "azurerm_role_assignment" "roles" {
  
  for_each = { for key, value in var.role_assignments : key => value if value.scope != null }
  name                                   = each.value.name
  scope                                  = each.value.scope
  role_definition_id                     = each.value.role_definition_id
  role_definition_name                   = each.value.role_definition_name
  principal_id                           = azurerm_user_assigned_identity.identity.principal_id
  condition                              = each.value.condition
  condition_version                      = each.value.condition_version
  delegated_managed_identity_resource_id = each.value.delegated_managed_identity_resource_id
  description                            = each.value.description
  skip_service_principal_aad_check       = each.value.skip_service_principal_aad_check == null ? false : each.value.skip_service_principal_aad_check
}


# This takes all role assigmnets where the scope is not defined and creates a role assignment for each resource group passed to the module.
# This is useful when you want to assign a role to the workload identity on the default and custom resource groups created in the main module.
locals {
  role_assignment_combinations = merge([
    for ra_key, ra_value in var.role_assignments : {
      for rg_id in var.resource_group_ids : "${ra_key}-${rg_id}" => {
        role_definition_name = ra_value.role_definition_name
        role_definition_id   = ra_value.role_definition_id
        scope                = rg_id
        condition            = ra_value.condition
        condition_version    = ra_value.condition_version
        description          = ra_value.description
        skip_service_principal_aad_check = ra_value.skip_service_principal_aad_check
      }
    } if ra_value.scope == null
  ]...)
}


resource "azurerm_role_assignment" "workload_roles" {
  for_each = local.role_assignment_combinations

  scope                  = each.value.scope
  role_definition_name   = each.value.role_definition_name
  role_definition_id     = each.value.role_definition_id
  principal_id           = azurerm_user_assigned_identity.identity.principal_id
  condition              = each.value.condition
  condition_version      = each.value.condition_version
  description            = each.value.description
  skip_service_principal_aad_check = each.value.skip_service_principal_aad_check
}


