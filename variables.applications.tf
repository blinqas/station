variable "applications" {
  description = <<EOT
  Map of applications to create. The body of each object is more or less identical to azuread_application 
  with the exception of map usage instead of blocks (as blocks are impossible to define with HCL)
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

    public_client = optional(object({
      redirect_uris = optional(set(string))
    }))

    required_resource_access = optional(map(object({
      auto_admin_consent = optional(bool)
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
}

