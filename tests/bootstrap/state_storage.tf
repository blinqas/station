resource "azurerm_storage_account" "state" {
  name                     = "sastationtests"
  resource_group_name      = azurerm_resource_group.station_tests_state_storage.name
  location                 = azurerm_resource_group.station_tests_state_storage.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  tags = {
    "createdBy" = "Manually in https://github.com/kimfy/station - under dir 'tests/bootstrap'"
    "repoUrl"   = "https://github.com/kimfy/station.git"
  }
}

resource "azurerm_storage_container" "state" {
  name                 = "station-tests-remote-state"
  storage_account_name = azurerm_storage_account.state.name
}

# TODO: Does this actually work?
resource "azurerm_role_assignment" "sc_state_owner" {
  scope                = azurerm_storage_container.state.resource_manager_id
  principal_id         = azuread_service_principal.workload.object_id
  role_definition_name = "Owner"
}
