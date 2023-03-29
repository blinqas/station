resource "azuread_group" "group" {
  display_name     = var.settings.display_name
  owners           = var.settings.owners
  security_enabled = can(var.settings.security_enabled) != null ? var.settings.security_enabled : true
  types            = can(var.settings.types) != null ? var.settings.types : []

  dynamic "dynamic_membership" {
    for_each = try(var.settings.dynamic_membership, {})

    content {
      enabled = dynamic_membership.value.enabled
      rule    = dynamic_membership.value.rule
    }
  }
}

