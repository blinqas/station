resource "azuread_application" "app" {
  display_name                   = var.azuread_application.display_name
  owners                         = var.owners
  sign_in_audience               = var.azuread_application.sign_in_audience
  group_membership_claims        = var.azuread_application.group_membership_claims
  identifier_uris                = var.azuread_application.identifier_uris
  prevent_duplicate_names        = var.azuread_application.prevent_duplicate_names
  fallback_public_client_enabled = var.azuread_application.fallback_public_client_enabled
  notes                          = var.azuread_application.notes

  dynamic "single_page_application" {
    for_each = var.azuread_application.single_page_application == null ? [] : [1]

    content {
      redirect_uris = var.azuread_application.single_page_application.redirect_uris
    }
  }

  dynamic "api" {
    for_each = var.azuread_application.api == null ? [] : [1]

    content {
      known_client_applications      = var.azuread_application.api.known_client_applications
      mapped_claims_enabled          = var.azuread_application.api.mapped_claims_enabled
      requested_access_token_version = var.azuread_application.api.requested_access_token_version

      dynamic "oauth2_permission_scope" {
        for_each = var.azuread_application.api.oauth2_permission_scope == null ? [] : var.azuread_application.api.oauth2_permission_scope
        content {
          admin_consent_description  = oauth2_permission_scope.value.admin_consent_description
          admin_consent_display_name = oauth2_permission_scope.value.admin_consent_display_name
          id                         = oauth2_permission_scope.value.id
          enabled                    = oauth2_permission_scope.value.enabled
          type                       = oauth2_permission_scope.value.type
          user_consent_description   = oauth2_permission_scope.value.user_consent_description
          user_consent_display_name  = oauth2_permission_scope.value.user_consent_display_name
          value                      = oauth2_permission_scope.value.value
        }
      }
    }
  }

  dynamic "required_resource_access" {
    for_each = var.azuread_application.required_resource_access == null ? [] : var.azuread_application.required_resource_access

    content {
      resource_app_id = required_resource_access.value.resource_app_id

      dynamic "resource_access" {
        for_each = {
          for key, resource in required_resource_access.value.resource_access : key => resource
        }

        content {
          id   = resource_access.value.id
          type = resource_access.value.type
        }
      }
    }
  }

  dynamic "optional_claims" {
    for_each = var.azuread_application.optional_claims == null ? [] : [var.azuread_application.optional_claims]

    content {
      dynamic "access_token" {
        for_each = var.azuread_application.optional_claims.access_token == null ? [] : var.azuread_application.optional_claims.access_token
        content {
          name                  = access_token.value.name
          source                = access_token.value.source
          essential             = access_token.value.essential
          additional_properties = access_token.value.additional_properties
        }
      }

      dynamic "id_token" {
        for_each = var.azuread_application.optional_claims.id_token == null ? [] : var.azuread_application.optional_claims.id_token
        content {
          name                  = id_token.value.name
          source                = id_token.value.source
          essential             = id_token.value.essential
          additional_properties = id_token.value.additional_properties
        }
      }

      dynamic "saml2_token" {
        for_each = var.azuread_application.optional_claims.saml2_token == null ? [] : var.azuread_application.optional_claims.saml2_token
        content {
          name                  = saml2_token.value.name
          source                = saml2_token.value.source
          essential             = saml2_token.value.essential
          additional_properties = saml2_token.value.additional_properties
        }
      }
    }
  }

  dynamic "web" {
    for_each = var.azuread_application.web == null ? [] : [var.azuread_application.web]

    content {
      homepage_url  = web.value.homepage_url
      logout_url    = web.value.logout_url
      redirect_uris = web.value.redirect_uris

      dynamic "implicit_grant" {
        for_each = web.value.implicit_grant == null ? [] : [web.value.implicit_grant]

        content {
          access_token_issuance_enabled = implicit_grant.value.access_token_issuance_enabled
          id_token_issuance_enabled     = implicit_grant.value.id_token_issuance_enabled
        }
      }
    }
  }
}
