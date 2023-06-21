resource "azuread_application_federated_identity_credential" "github" {
  application_object_id = azuread_application.workload.object_id
  display_name          = "deployments-from-station-tests"
  description           = "Used to authenticate GitHub in kimfy/station"
  audiences             = ["api://AzureADTokenExchange"]
  issuer                = "https://token.actions.githubusercontent.com"
  subject               = "repo:kimfy/station:environment:Tests"
}

