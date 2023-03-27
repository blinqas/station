resource "azurerm_storage_account" "state" {
  name                     = "sa${random_id.workload.hex}"
  resource_group_name      = var.station_resource_group_name
  location                 = "norwayeast"
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

resource "azurerm_storage_container" "state" {
  name                 = "sc-remote-state-${random_id.workload.hex}-${var.environment_name}"
  storage_account_name = azurerm_storage_account.state.name
}

# TODO: Does this actually work?
resource "azurerm_role_assignment" "sc_state_owner" {
  scope                = azurerm_storage_container.state.resource_manager_id
  principal_id         = azuread_service_principal.workload.object_id
  role_definition_name = "Contributor"
}
