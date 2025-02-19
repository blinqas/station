data "tfe_organization" "test" {
  name = var.tfc_organization_name
}

resource "tfe_project" "test" {
  name = var.tfc_project_name
}

output "id" {
  value = tfe_project.test.id
}

data "azurerm_client_config" "current" {}

resource "azuread_group" "this" {
  for_each         = var.create_ad_group ? { "test" = {} } : {}
  display_name     = "station-test-identity"
  security_enabled = true
  owners           = [data.azurerm_client_config.current.object_id]
}

output "azuread_group" {
  value = azuread_group.this
}

