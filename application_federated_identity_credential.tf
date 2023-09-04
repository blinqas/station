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
      display_name = "Terraform Cloud OIDC Station Project ${random_id.workload.hex} (plan phase)"
      subject      = "organization:${var.TFE_ORGANIZATION}:project:${var.tfe.project_name}:workspace:${var.tfe.workspace_name}:run_phase:plan"
    },
    apply = {
      display_name = "Terraform Cloud OIDC Station Project ${random_id.workload.hex} (apply phase)"
      subject      = "organization:${var.TFE_ORGANIZATION}:project:${var.tfe.project_name}:workspace:${var.tfe.workspace_name}:run_phase:apply"
    },
  }
}

resource "azuread_application_federated_identity_credential" "oidc-tfe" {
  for_each              = var.tfe.create_federated_identity_credential ? [local.oidc_tfe] : [0]
  application_object_id = azuread_application.workload.object_id
  display_name          = each.value.display_name
  audiences             = ["api://AzureADTokenExchange"]
  issuer                = "https://app.terraform.io"
  subject               = each.value.subject
}
