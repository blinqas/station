# Assign the workload service principal a role on the workload resource group
resource "azurerm_role_assignment" "rg_workload_owner" {
  scope                = azurerm_resource_group.workload.id
  principal_id         = azuread_service_principal.workload.object_id
  role_definition_name = var.role_definition_name_on_workload_rg
}

# Assign the workload service principal a role on the user specified resource groups
resource "azurerm_role_assignment" "rg_user_specified" {
  for_each             = azurerm_resource_group.user_specified
  scope                = each.value.id
  principal_id         = azuread_service_principal.workload.object_id
  role_definition_name = var.role_definition_name_on_workload_rg
}

resource "azurerm_role_assignment" "user_input" {
  for_each                               = var.role_assignment
  name                                   = each.value.name
  scope                                  = each.value.scope
  role_definition_id                     = each.value.role_definition_id
  role_definition_name                   = each.value.role_definition_name
  principal_id                           = each.value.assign_to_workload_principal == true ? azuread_service_principal.workload.object_id : each.value.principal_id
  condition                              = each.value.condition
  condition_version                      = each.value.condition_version
  delegated_managed_identity_resource_id = each.value.delegated_managed_identity_resource_id
  description                            = each.value.description
  skip_service_principal_aad_check       = each.value.skip_service_principal_aad_check == null ? false : each.value.skip_service_principal_aad_check
}
