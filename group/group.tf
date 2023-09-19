resource "azuread_group" "group" {
  display_name     = var.settings.display_name
  owners           = var.owners
  security_enabled = try(var.settings.security_enabled, true)
  types            = try(var.settings.types, null) != null ? var.settings.types : []

  dynamic "dynamic_membership" {
    for_each = try(var.settings.dynamic_membership, {})

    content {
      enabled = dynamic_membership.value.enabled
      rule    = dynamic_membership.value.rule
    }
  }
}

resource "azuread_group_member" "members" {
  for_each         = try(var.settings.members, null) != null ? toset(var.settings.members) : toset([])
  group_object_id  = azuread_group.group.object_id
  member_object_id = each.key
}

