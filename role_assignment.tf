resource "azurerm_role_assignment" "rg_workload_owner" {
  scope                = azurerm_resource_group.workload.id
  principal_id         = azuread_service_principal.workload.object_id
  role_definition_name = var.role_definition_name_on_workload_rg
}
