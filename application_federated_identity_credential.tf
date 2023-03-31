resource "azuread_application_federated_identity_credential" "oidc" {
  for_each              = var.federated_identity_credential_config
  application_object_id = azuread_application.workload.object_id
  display_name          = each.value.display_name
  description           = try(each.value.description, null)
  audiences             = each.value.audiences
  issuer                = each.value.issuer
  subject               = each.value.subject
}
