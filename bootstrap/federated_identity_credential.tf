resource "azuread_application_federated_identity_credential" "tfc-plan" {
  application_id = azuread_application.workload.id
  display_name   = "plan"
  description    = "Authenticate Station from Terraform Cloud to Azure"
  audiences      = ["api://AzureADTokenExchange"]
  issuer         = "https://app.terraform.io"
  subject        = "organization:${var.tfc_organization_name}:project:${var.tfc_project_name}:workspace:${var.deployments_tfc_workspace_name}:run_phase:plan"
}

resource "azuread_application_federated_identity_credential" "tfc-apply" {
  application_id = azuread_application.workload.id
  display_name   = "apply"
  description    = "Authenticate Station from Terraform Cloud to Azure"
  audiences      = ["api://AzureADTokenExchange"]
  issuer         = "https://app.terraform.io"
  subject        = "organization:${var.tfc_organization_name}:project:${var.tfc_project_name}:workspace:${var.deployments_tfc_workspace_name}:run_phase:apply"
}
