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

resource "azurerm_federated_identity_credential" "oidc-tfe" {
  for_each            = local.oidc_tfe
  resource_group_name = azurerm_resource_group.workload.name
  parent_id           = module.user_assigned_identity.id
  name                = "terraform-cloud-run-phase-${each.value.phase}"
  audience            = ["api://AzureADTokenExchange"]
  issuer              = "https://app.terraform.io"
  subject             = "organization:${var.tfe.organization_name}:project:${var.tfe.project.name}:workspace:${var.tfe.workspace_name}:run_phase:${each.value.phase}"
}

