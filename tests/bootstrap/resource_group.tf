resource "azurerm_resource_group" "station_tests_state_storage" {
  name     = var.state_resource_group_name
  location = "norwayeast"
}
