// https://github.com/hashicorp/go-azure-sdk/blob/main/sdk/environments/application_ids.go
data "azuread_application_published_app_ids" "well_known" {}

data "azuread_service_principal" "msgraph" {
  client_id = data.azuread_application_published_app_ids.well_known.result.MicrosoftGraph
}

