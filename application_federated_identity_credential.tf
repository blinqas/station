resource "azuread_application_federated_identity_credential" "oidc" {
  for_each              = var.federated_identity_credential_config
  application_object_id = azuread_application.workload.object_id
  display_name          = each.value.display_name
  description           = try(each.value.description, null)
  audiences             = each.value.audiences
  issuer                = each.value.issuer
  subject               = each.value.subject
}

locals {
  oidc_tfe = {
    plan = {
      phase = "plan"
    },
    apply = {
      phase = "apply"
    },
  }
}

resource "azuread_application_federated_identity_credential" "oidc-tfe" {
  for_each              = can(var.tfe.create_federated_identity_credential) ? local.oidc_tfe : {}
  application_object_id = azuread_application.workload.object_id
  display_name          = "ficc-station-proj-id-${random_id.workload.hex}-tfc-${each.value.phase}"
  description           = "Terraform Cloud OIDC Station Project ${random_id.workload.hex} (${each.value.phase} phase)"
  audiences             = ["api://AzureADTokenExchange"]
  issuer                = "https://app.terraform.io"
  subject               = "organization:${var.tfe.organization_name}:project:${var.tfe.project_name}:workspace:${var.tfe.workspace_name}:run_phase:${each.value.phase}"
}
