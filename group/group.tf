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
