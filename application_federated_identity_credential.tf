resource "azuread_application_federated_identity_credential" "oidc" {
  for_each              = var.federated_identity_credential_config
  application_object_id = azuread_application.workload.object_id
  display_name          = "deployments-from-${random_id.workload.hex}-${var.environment_name}"
  description           = "Station deployment for workload with ID ${random_id.workload.hex} in environment ${var.environment_name}"
  audiences             = each.value.audiences
  issuer                = each.value.issuer
  subject               = each.value.subject
}
