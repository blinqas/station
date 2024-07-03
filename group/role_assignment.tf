resource "azurerm_role_assignment" "roles" {
  for_each                         = var.role_assignments
  name                             = each.value.name
  scope                            = each.value.scope == null ? "/subscriptions/${var.subscription_id}" : each.value.scope
  role_definition_id               = each.value.role_definition_id
  role_definition_name             = each.value.role_definition_name
  principal_id                     = azuread_group.group.object_id
  condition                        = each.value.condition
  condition_version                = each.value.condition_version
  description                      = each.value.description
  skip_service_principal_aad_check = each.value.skip_service_principal_aad_check == null ? false : each.value.skip_service_principal_aad_check
}