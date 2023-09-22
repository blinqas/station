resource "azuread_group" "group" {
  display_name     = var.display_name
  owners           = var.owners
  security_enabled = var.security_enabled
  types            = var.types

  dynamic "dynamic_membership" {
    for_each = try(var.dynamic_membership, null) != null ? [var.dynamic_membership] : []

    content {
      enabled = dynamic_membership.value.enabled
      rule    = dynamic_membership.value.rule
    }
  }
}

resource "azuread_group_member" "members" {
  for_each         = try(var.members, null) != null ? var.members : toset([])
  group_object_id  = azuread_group.group.object_id
  member_object_id = each.key
}
