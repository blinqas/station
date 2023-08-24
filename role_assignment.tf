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

