data "azuread_client_config" "current" {}

data "azuread_application_published_app_ids" "well_known" {}

data "azuread_service_principal" "msgraph" {
  client_id = data.azuread_application_published_app_ids.well_known.result.MicrosoftGraph
}

output "azuread_client_config" {
  value = {
    current = data.azuread_client_config.current
  }
}

output "azuread_application_published_app_ids" {
  value = {
    well_known = data.azuread_application_published_app_ids.well_known
  }
}

output "azuread_service_principal" {
  value = {
    msgraph = data.azuread_service_principal.msgraph
  }
}

