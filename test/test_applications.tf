module "station-applications" {
  depends_on      = [tfe_project.test]
  source          = "./.."
  tenant_id       = var.tenant_id
  subscription_id = var.subscription_id

  tfe = {
    project_name          = tfe_project.test.name
    organization_name     = data.tfe_organization.test.name
    workspace_description = "This workspace contains application_tests from https://github.com/blinqas/station.git"
    workspace_name        = "station-tests-application_tests"
  }

  applications = {
    # Bare minimum configuration
    minimum = {
      display_name = "Station test: minimum"
    },

    # Maximum configuration
    maximum = {
      display_name                   = "Station test: maximum"
      owners                         = [data.azuread_client_config.current.object_id]
      sign_in_audience               = "AzureADMyOrg"
      identifier_uris                = ["api://station-test"]
      group_membership_claims        = ["All"]
      prevent_duplicate_names        = true
      fallback_public_client_enabled = true
      notes                          = "This is a test application created by Station"

      single_page_application = {
        redirect_uris = ["https://station-test.example/spa"]
      }

      api = {
        oauth2_permission_scope = [
          {
            admin_consent_description  = "Station Test Maximum"
            admin_consent_display_name = "Station Test Maximum"
            id                         = random_uuid.maximum.result
            enabled                    = true
            value                      = "user_impersonation"
          },
          {
            admin_consent_description  = "Station Test Maximum 2"
            admin_consent_display_name = "Station Test Maximum 2"
            id                         = random_uuid.maximum2.result
            enabled                    = true
            value                      = "default"
          }
        ]
      }

      required_resource_access = [
        {
          resource_app_id = data.azuread_application_published_app_ids.well_known.result.Office365Management
          resource_access = {
            x = {
              id   = "c5393580-f805-4401-95e8-94b7a6ef2fc2"
              type = "Role"
            },
            y = {
              id   = "498476ce-e0fe-48b0-b801-37ba7e2685c6"
              type = "Role"
            }
          }
        },
        {
          resource_app_id = data.azuread_application_published_app_ids.well_known.result.MicrosoftGraph
          resource_access = {
            x = {
              id   = azuread_service_principal.msgraph.app_role_ids["User.Read.All"]
              type = "Role"
            }
          }
        }
      ]

      optional_claims = {
        access_token = [{ name = "Test token" }, { name = "Test token 2" }]
        id_token     = [{ name = "Test id token" }, { name = "Test id token 2" }]
        saml2_token  = [{ name = "Test saml2 token" }, { name = "Test saml2 token 2" }]
      }

      public_client = {
        redirect_uris = ["https://localhost/"]
      }

      web = {
        homepage_url  = "http://localhost"
        logout_url    = "http://localhost/logout"
        redirect_uris = ["http://localhost/redirect"]
        implicit_grant = {
          access_token_issuance_enabled = true
        }
      }

      service_principal = {
        account_enabled               = true
        alternative_names             = ["alt_name1", "alt_name2"]
        app_role_assignment_required  = false
        description                   = "Service Principal for Station Test: Maximum"
        login_url                     = "http://localhost/login"
        notes                         = "Notes for Service Principal"
        notification_email_addresses  = ["admin@example.com"]
        owners                        = [data.azuread_client_config.current.object_id]
        preferred_single_sign_on_mode = "saml"
        #tags                          = ["tag1", "tag2"] #This confliencts with the "feature_tags" block below
        use_existing = false

        feature_tags = {
          custom_single_sign_on = true
          enterprise            = true
          gallery               = false
          hide                  = false
        }

        saml_single_sign_on = {
          relay_state = "/relay"
        }
      }
    }

  }
}

resource "random_uuid" "maximum" {
}

resource "random_uuid" "maximum2" {
}

