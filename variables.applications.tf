variable "applications" {
  description = <<EOT
  Map of applications to create. The body of each object is more or less identical to azuread_application 
  with the exception of map usage instead of blocks (as blocks are impossible to define with HCL)

  Set use_default_identifier_uri to true to add api://<client-id> to any URIs
  configured in identifier_uris in the same apply. It defaults to false.

  Use preauthorized_clients to grant clients access to enabled API scopes by scope value.
  Use service_principal.group_assignments to grant groups access by key in the groups input.
  Omit app_role_id for Default Access on applications without app roles.

    Example:
  applications = {
    example_client = {
      display_name                   = "Example app"
      owners                         = local.users["admin_user"]
      sign_in_audience               = "AzureADMyOrg"
      identifier_uris                = ["api://station-test"]
      group_membership_claims        = ["All"]
      prevent_duplicate_names        = true
      fallback_public_client_enabled = true
      notes                          = "This is an example application"
      logo_image                     = filebase64("./assets/application_logos/example.png")

      required_resource_access = {
        graph = {
          resource_app_id    = azuread_service_principal.MicrosoftGraph.client_id
          resource_object_id = azuread_service_principal.MicrosoftGraph.object_id
          resource_access = {
            application_user_read_all = {
              id   = "df021288-bdef-4463-88db-98f22de89214"
              type = "Role" //Application
            }
            delegated_user_read = {
              id   = "e1fe6dd8-ba31-4d61-89e7-88639da4683d"
              type = "Scope" //Delegated
            },
          }
        },
        exchange_online = {
          auto_admin_consent      = true //This will require admin consent after the deployment
          resource_app_id    = azuread_service_principal.Office365ExchangeOnline.client_id
          resource_object_id = azuread_service_principal.Office365ExchangeOnline.object_id
          resource_access = {
            delegated_ews_accessasuser_all = {
              id   = "3b5f3d61-589b-4a3c-a359-5dd4b5ee5bd5"
              type = "Scope" //Application
            },
            application_ews_accessasuser_all = {
              id   = "dc890d15-9560-4a4c-9b7f-a736ec74ec40"
              type = "Role" //Delegated
            }
          }
        }
      }

      web = {
        implicit_grant = {
          access_token_issuance_enabled = true
        }
      }

      service_principal = {
        account_enabled               = true
        app_role_assignment_required  = true
        description                   = "Service Principal for example app"
        owners                        = local.users["admin_user"]
        use_existing                  = false
      }
    }
  EOT
  default     = {}
  type = map(object({
    display_name                   = string
    owners                         = optional(list(string))
    logo_image                     = optional(string) #Base64 encoded image
    sign_in_audience               = optional(string)
    group_membership_claims        = optional(list(string))
    identifier_uris                = optional(list(string))
    use_default_identifier_uri     = optional(bool, false)
    prevent_duplicate_names        = optional(bool)
    fallback_public_client_enabled = optional(bool)
    notes                          = optional(string) #This can be used as description for the application. 1024 character limit.
    use_existing                   = optional(bool)

    single_page_application = optional(object({
      redirect_uris = optional(list(string))
    }))

    api = optional(object({
      known_client_applications      = optional(list(string))
      mapped_claims_enabled          = optional(bool)
      requested_access_token_version = optional(number)

      oauth2_permission_scope = optional(list(object({
        admin_consent_description  = string
        admin_consent_display_name = string
        id                         = string
        enabled                    = optional(bool)
        type                       = optional(string)
        user_consent_description   = optional(string)
        user_consent_display_name  = optional(string)
        value                      = string
      })))
    }))

    preauthorized_clients = optional(map(object({
      client_id    = string
      scope_values = set(string)
    })), {})

    public_client = optional(object({
      redirect_uris = optional(set(string))
    }))

    required_resource_access = optional(map(object({
      auto_admin_consent = optional(bool, true)
      resource_app_id    = string
      resource_object_id = string
      resource_access = map(object({
        id   = string
        type = string
      }))
    })))

    optional_claims = optional(object({
      access_token = optional(set(object({
        name                  = string
        source                = optional(string)
        essential             = optional(bool)
        additional_properties = optional(list(string))
      })))
      id_token = optional(set(object({
        name                  = string
        source                = optional(string)
        essential             = optional(bool)
        additional_properties = optional(list(string))
      })))
      saml2_token = optional(set(object({
        name                  = string
        source                = optional(string)
        essential             = optional(bool)
        additional_properties = optional(list(string))
      })))
    }))

    web = optional(object({
      homepage_url  = optional(string)
      logout_url    = optional(string)
      redirect_uris = optional(set(string))
      implicit_grant = optional(object({
        access_token_issuance_enabled = optional(bool)
        id_token_issuance_enabled     = optional(bool)
      }))
    }))

    service_principal = optional(object({
      account_enabled               = optional(bool, true)
      alternative_names             = optional(list(string))
      app_role_assignment_required  = optional(bool, false)
      description                   = optional(string)
      login_url                     = optional(string)
      notes                         = optional(string)
      notification_email_addresses  = optional(list(string))
      owners                        = optional(list(string))
      preferred_single_sign_on_mode = optional(string)
      tags                          = optional(list(string))
      use_existing                  = optional(bool, false)

      group_assignments = optional(map(object({
        group_key   = string
        app_role_id = optional(string, "00000000-0000-0000-0000-000000000000")
      })), {})

      feature_tags = optional(object({
        custom_single_sign_on = optional(bool, false)
        enterprise            = optional(bool, false)
        gallery               = optional(bool, false)
        hide                  = optional(bool, false)
      }))

      saml_single_sign_on = optional(object({
        relay_state = optional(string)
      }))
    }))
  }))

  validation {
    condition = alltrue(flatten([
      for app in var.applications : [
        for client in app.preauthorized_clients : try(
          length(client.scope_values) > 0 && alltrue([
            for value in client.scope_values : length([
              for scope in coalesce(try(app.api.oauth2_permission_scope, null), []) : scope
              if scope.value == value && coalesce(scope.enabled, true)
            ]) == 1
          ]),
          false
        )
      ]
    ]))
    error_message = "Each applications[*].preauthorized_clients entry must specify at least one scope_values item, and every item must match exactly one enabled api.oauth2_permission_scope value on the same application."
  }

  validation {
    condition = alltrue(flatten([
      for app in var.applications : [
        for assignment in try(app.service_principal.group_assignments, {}) :
        try(contains(keys(var.groups), assignment.group_key), false)
      ]
    ]))
    error_message = "Each applications[*].service_principal.group_assignments entry must specify a group_key that exists in the groups input."
  }
}
