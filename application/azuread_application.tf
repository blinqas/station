moved {
  from = azuread_application.app
  to   = azuread_application.this
}
resource "azuread_application" "this" {
  display_name                   = var.azuread_application.display_name
  owners                         = var.owners
  sign_in_audience               = var.azuread_application.sign_in_audience
  logo_image                     = var.azuread_application.logo_image
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

  dynamic "public_client" {
    for_each = var.azuread_application.public_client == null ? [] : [1]

    content {
      redirect_uris = var.azuread_application.public_client.redirect_uris
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
    for_each = var.azuread_application.required_resource_access == null ? {} : var.azuread_application.required_resource_access

    content {
      resource_app_id = required_resource_access.value.resource_app_id

      dynamic "resource_access" {
        for_each = required_resource_access.value.resource_access == null ? {} : required_resource_access.value.resource_access

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

moved {
  from = azuread_service_principal.sp
  to   = azuread_service_principal.this
}

resource "azuread_service_principal" "this" {
  count = var.azuread_service_principal == null ? 0 : 1

  client_id                     = azuread_application.this.client_id
  account_enabled               = var.azuread_service_principal.account_enabled
  alternative_names             = var.azuread_service_principal.alternative_names
  app_role_assignment_required  = var.azuread_service_principal.app_role_assignment_required
  description                   = var.azuread_service_principal.description
  login_url                     = var.azuread_service_principal.login_url
  notes                         = var.azuread_service_principal.notes
  notification_email_addresses  = var.azuread_service_principal.notification_email_addresses
  owners                        = var.owners
  preferred_single_sign_on_mode = var.azuread_service_principal.preferred_single_sign_on_mode
  tags                          = var.azuread_service_principal.tags # This conflicts with the "feature_tags" block below
  use_existing                  = var.azuread_service_principal.use_existing

  dynamic "feature_tags" {
    for_each = try(var.azuread_service_principal.feature_tags != null, false) ? [var.azuread_service_principal.feature_tags] : []
    content {
      custom_single_sign_on = try(feature_tags.value.custom_single_sign_on, false)
      enterprise            = try(feature_tags.value.enterprise, false)
      gallery               = try(feature_tags.value.gallery, false)
      hide                  = try(feature_tags.value.hide, false)
    }
  }

  dynamic "saml_single_sign_on" {
    for_each = try(var.azuread_service_principal.saml_single_sign_on != null, false) ? [var.azuread_service_principal.saml_single_sign_on] : []
    content {
      relay_state = try(saml_single_sign_on.value.relay_state, "")
    }
  }
}

/* 
Auto consent application roles by assiging the requested roles to the service principal
*/

locals {
  required_resource_access = var.azuread_application.required_resource_access != null ? flatten([
    for access_key, access in var.azuread_application.required_resource_access : [
      for resource_access_key, resource_access in access.resource_access : {
        id                 = resource_access.id        # Example: "df021288-bdef-4463-88db-98f22de89214" (User.Read.All)
        type               = resource_access.type      # Example: "Role" or "Scope"
        resource_app_id    = access.resource_app_id    # Example: "00000003-0000-0000-c000-000000000000" (Microsoft Graph client/app ID)
        resource_object_id = access.resource_object_id #Example: "38423b0f-3b79-4126-bb05-4f2f123ed55f" (Microsoft Graph objectID for your tenant)
        admin_consent      = access.admin_consent      # Example: true or false
      }
    ] if length(access.resource_access) > 0
  ]) : []

  // Convert the list of objects to a map with a unique key
  required_resource_access_map = {
    for entry in local.required_resource_access :
    "${entry.resource_app_id}-${entry.id}" => entry
  }

  // Filter out scopes and keep only Role-based assignments where `admin_consent` is false
  app_role_to_assign = var.azuread_service_principal != null ? {
    for key, entry in local.required_resource_access_map :
    key => entry
    if entry.type == "Role" && entry.admin_consent != true
  } : {}
}

resource "azuread_app_role_assignment" "this" {
  for_each = local.app_role_to_assign

  app_role_id         = each.value.id
  principal_object_id = azuread_service_principal.this[0].object_id
  resource_object_id  = each.value.resource_object_id
}