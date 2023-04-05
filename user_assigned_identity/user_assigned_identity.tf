resource "azurerm_user_assigned_identity" "identity" {
  location            = var.location
  name                = var.name
  resource_group_name = var.resource_group_name
  tags                = var.tags
}
