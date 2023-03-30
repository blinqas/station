resource "azuread_group" "group" {
  display_name     = var.settings.display_name
  owners           = var.owners
  security_enabled = can(var.settings.security_enabled) != null ? var.settings.security_enabled : true
  types            = try(var.settings.types, null) != null ? var.settings.types : []
  members =    try(var.settings.members, null)

  dynamic "dynamic_membership" {
    for_each = try(var.settings.dynamic_membership, {})

    content {
      enabled = dynamic_membership.value.enabled
      rule    = dynamic_membership.value.rule
    }
  }
}

