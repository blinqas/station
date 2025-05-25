data "tfe_project" "alz" {
  name = "Azure Application Landing Zones"
}

data "azurerm_client_config" "current" {}