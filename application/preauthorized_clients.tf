locals {
  permission_scopes = coalesce(try(var.azuread_application.api.oauth2_permission_scope, null), [])
}

resource "azuread_application_pre_authorized" "this" {
  for_each = try(var.azuread_application.preauthorized_clients, {})

  application_id       = azuread_application.this.id
  authorized_client_id = each.value.client_id
  permission_ids = [
    for scope in local.permission_scopes : scope.id
    if contains(each.value.scope_values, scope.value) && coalesce(scope.enabled, true)
  ]

  # Both resources update the same application in Microsoft Graph.
  depends_on = [msgraph_update_resource.this]
}
