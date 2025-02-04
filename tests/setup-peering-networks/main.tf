resource "azurerm_virtual_network" "this" {
  name                = var.remote_vnet_name
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  address_space       = [var.remote_vnet_address_space]
}

resource "azurerm_resource_group" "this" {
  name     = var.resource_group_name
  location = var.location
}


output "virtual_network_id" {
  value = azurerm_virtual_network.this.id
  
}