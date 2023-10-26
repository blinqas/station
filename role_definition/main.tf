resource "azurerm_role_definition" "example" {
  role_definition_id = var.role_definition.role_definition_id
  name               = var.role_definition.name
  description        = var.role_definition.description
  scope              = var.role_definition.scope
  assignable_scopes  = var.role_definition.assignable_scopes

  dynamic "permissions" {
    for_each = var.role_definition.permissions == null ? [0] : [1]

    content {
      actions          = var.role_definition.permissions.actions
      not_actions      = var.role_definition.permissions.not_actions
      data_actions     = var.role_definition.permissions.data_actions
      not_data_actions = var.role_definition.permissions.not_data_actions
    }
  }
}

