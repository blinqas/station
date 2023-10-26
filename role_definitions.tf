resource "azurerm_role_definition" "user_created" {
  for_each           = var.role_definitions
  role_definition_id = each.value.role_definition_id
  name               = each.value.name
  description        = each.value.description
  scope              = each.value.scope
  assignable_scopes  = each.value.assignable_scopes
  dynamic "permissions" {
    for_each = var.role_definitions.permissions == null ? [0] : [1]

    content {
      actions          = var.role_definitions.permissions.actions
      not_actions      = var.role_definitions.permissions.not_actions
      data_actions     = var.role_definitions.permissions.data_actions
      not_data_actions = var.role_definitions.permissions.not_data_actions
    }
  }
}

