resource "azuread_application_federated_identity_credential" "oidc" {
  count                 = var.federated_identity_credential_config.create ? 1 : 0
  application_object_id = azuread_application.workload.object_id
  display_name          = "deployments-from-${random_id.workload.hex}-${var.environment_name}"
  description           = "Station deployment for workload with ID ${random_id.workload.hex} in environment ${var.environment_name}"
  audiences             = var.federated_identity_credential_config.audiences
  issuer                = var.federated_identity_credential_config.issuer
  subject               = var.federated_identity_credential_config.subject
}
