resource "azuread_application_federated_identity_credential" "tfc-plan" {
  application_object_id = azuread_application.workload.object_id
  display_name          = "plan"
  description           = "Authenticate Station tests (tests/tfe) from Terraform Cloud to Azure"
  audiences             = ["api://AzureADTokenExchange"]
  issuer                = "https://app.terraform.io"
  subject               = "organization:managed-devops:project:Station Development:workspace:Test:run_phase:plan"
}

resource "azuread_application_federated_identity_credential" "tfc-apply" {
  application_object_id = azuread_application.workload.object_id
  display_name          = "apply"
  description           = "Authenticate Station tests (tests/tfe) from Terraform Cloud to Azure"
  audiences             = ["api://AzureADTokenExchange"]
  issuer                = "https://app.terraform.io"
  subject               = "organization:managed-devops:project:Station Development:workspace:Test:run_phase:apply"
}

