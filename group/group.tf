resource "azuread_group" "group" {
  display_name     = var.azuread_group.display_name
  description      = var.azuread_group.description
  owners           = var.owners
  security_enabled = var.azuread_group.security_enabled
  mail_enabled     = var.azuread_group.mail_enabled
  types            = var.azuread_group.types

  dynamic "dynamic_membership" {
    for_each = var.azuread_group.dynamic_membership == null ? [] : [var.azuread_group.dynamic_membership]

    content {
      enabled = dynamic_membership.value.enabled
      rule    = dynamic_membership.value.rule
    }
  }
}

resource "azuread_group_member" "members" {
  for_each         = var.azuread_group.members == null ? [] : var.azuread_group.members
  group_object_id  = azuread_group.group.object_id
  member_object_id = each.key
}

resource "azurerm_role_assignment" "roles" {
  for_each                               = var.role_assignments
  name                                   = each.value.name
  scope                                  = each.value.scope == null ? "/subscriptions/${data.azurerm_client_config.current.subscription_id}" : each.value.scope
  role_definition_id                     = each.value.role_definition_id
  role_definition_name                   = each.value.role_definition_name
  principal_id                           = azuread_group.group.object_id
  condition                              = each.value.condition
  condition_version                      = each.value.condition_version
  delegated_managed_identity_resource_id = each.value.delegated_managed_identity_resource_id
  description                            = each.value.description
  skip_service_principal_aad_check       = each.value.skip_service_principal_aad_check == null ? false : each.value.skip_service_principal_aad_check
}

data "azurerm_client_config" "current" {}