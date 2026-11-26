resource "msgraph_update_resource" "this" {
  url = "applications/${azuread_application.this.object_id}"
  body = {
    identifierUris = toset(concat(
      coalesce(var.azuread_application.identifier_uris, []),
      try(var.azuread_application.use_default_identifier_uri == true, false) ? ["api://${azuread_application.this.client_id}"] : []
    ))
  }

  read_query_parameters = {
    "$select" = ["identifierUris"]
  }
  ignore_missing_property = false
}
