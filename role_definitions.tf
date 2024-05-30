resource "azurerm_role_definition" "user_created" {
  for_each           = var.role_definitions
  role_definition_id = each.value.role_definition_id
  name               = each.value.name
  description        = each.value.description
  scope              = each.value.scope == null ? "/subscriptions/${var.subscription_id}/resourceGroups/${azurerm_resource_group.workload.name}" : each.value.scope
  assignable_scopes  = each.value.assignable_scopes
  dynamic "permissions" {
    for_each = each.value.permissions == null ? [] : [1]

    content {
      actions          = each.value.permissions.actions
      not_actions      = each.value.permissions.not_actions
      data_actions     = each.value.permissions.data_actions
      not_data_actions = each.value.permissions.not_data_actions
    }
  }
}

