variable "group_display_name" {
  description = "The display name of the group"
  type        = string
}

resource "azuread_group" "test_uai" {
  display_name     = var.group_display_name
  security_enabled = true
}

output "azuread_group" {
  value = azuread_group.test_uai
}

data "azuread_client_config" "current" {}

output "current_client" {
  value = data.azuread_client_config.current
}

data "azurerm_subscription" "current" {
}

output "current_subscription" {
  value = data.azurerm_subscription.current
}
