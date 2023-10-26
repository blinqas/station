resource "azurerm_role_definition" "user_created" {
  for_each           = var.role_definitions
  role_definition_id = each.value.role_definition_id
  name               = each.value.name
  description        = each.value.description
  scope              = each.value.scope
  assignable_scopes  = each.value.assignable_scopes
}

