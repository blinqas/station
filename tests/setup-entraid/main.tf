variable "groups" {
  type        = map(string)
  default     = {}
  description = "Map of group keys to Entra ID group display names to be created. Keys are arbitrary identifiers, values are the group names."
}

data "azuread_client_config" "current" {}

resource "azuread_group" "this" {
  for_each         = var.groups
  display_name     = each.value
  security_enabled = true
  owners           = [data.azuread_client_config.current.object_id]
}

output "groups" {
  value = azuread_group.this
}
