data "azuread_client_config" "current" {}

output "current" {
  value = data.azuread_client_config.current
}

resource "random_uuid" "min" {
}

output "uuid_min" {
  value = random_uuid.min
}

resource "random_uuid" "max" {
}


output "uuid_max" {
  value = random_uuid.max
}

data "azuread_application_published_app_ids" "well_known" {}


data "azuread_service_principal" "MicrosoftGraph" {
  client_id = data.azuread_application_published_app_ids.well_known.result.MicrosoftGraph
}

data "azuread_service_principal" "Office365ExchangeOnline" {
  client_id = data.azuread_application_published_app_ids.well_known.result.Office365ExchangeOnline
}

output "MicrosoftGraph" {
  value = data.azuread_service_principal.MicrosoftGraph
}

output "Office365ExchangeOnline" {

  value = data.azuread_service_principal.Office365ExchangeOnline
}

