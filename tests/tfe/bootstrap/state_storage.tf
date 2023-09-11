resource "random_id" "storage_account" {
  byte_length = 8
}

resource "azurerm_storage_account" "state" {
  name                     = "station${random_id.storage_account.hex}"
  resource_group_name      = var.state_resource_group_name
  location                 = "norwayeast"
  account_tier             = "Standard"
  account_replication_type = "LRS"
  tags = {
    "createdBy" = "Manually in ${var.station_repo_url}/tree/trunk/tests/bootstrap"
    "repoUrl"   = var.station_repo_url
  }
}


resource "azurerm_storage_container" "state" {
  name                 = "station-tfe-tests-remote-state"
  storage_account_name = azurerm_storage_account.state.name
}

# TODO: Does this actually work?
resource "azurerm_role_assignment" "sc_state_owner" {
  scope                = azurerm_storage_container.state.resource_manager_id
  principal_id         = azuread_service_principal.workload.object_id
  role_definition_name = "Contributor"
}