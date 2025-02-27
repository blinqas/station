provider "tfe" {}

provider "azuread" {}

provider "azurerm" {
  features {}
}

run "bootstrap_create_tfc_test_project" {
  variables {
    tfc_project_name = "tests_application"
  }
  module {
    source = "./tests/setup-tfe-project"
  }
}

run "bootstrap_application" {
  //This fetches the objectid of the current user
  module {
    source = "./tests/setup-application"
  }
}


variables {
  tfe = {
    project = {
      id   = "# Overridden"
      name = "tests_group"
    }
    organization_name     = "blinq-west-lab"
    workspace_name        = "application_test"
    workspace_description = "Workspace description"
    workspace_settings = {
      execution_mode = "remote"
    }
  }

  applications = {
    minimum = {
      display_name = "Station test: minimum"
    },
    maximum = {
      display_name                   = "Station test: maximum"
      owners                         = ["This has to be overriden with the current objectid"]
      sign_in_audience               = "AzureADMyOrg"
      identifier_uris                = ["api://station-test"]
      group_membership_claims        = ["All"]
      prevent_duplicate_names        = true
      fallback_public_client_enabled = true
      notes                          = "This is a test application created by Station"
      logo_image                     = "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"

      single_page_application = {
        redirect_uris = ["https://station-test.example/spa"]
      }

      api = {
        mapped_claims_enabled          = true
        requested_access_token_version = 2

        oauth2_permission_scope = [
          {
            admin_consent_description  = "Station Test Maximum"
            admin_consent_display_name = "Station Test Maximum"
            id                         = "f6ac482d-4b5e-4ee4-959b-e002ce75c71f"
            enabled                    = true
            value                      = "user_impersonation"
          },
          {
            admin_consent_description  = "Station Test Maximum 2"
            admin_consent_display_name = "Station Test Maximum 2"
            id                         = "fab51497-eb77-4110-82be-3a15465ce94e"
            enabled                    = true
            value                      = "default"
          }
        ]
      }

      required_resource_access = {
        graph = {
          resource_app_id = "00000003-0000-0000-c000-000000000000" //MicrosoftGraph
          resource_access = {
            application_group_read_all = {
              id   = "5b567255-7703-4780-807c-7be8301ae99b"
              type = "Role"
            },
            application_user_read_all = {
              id   = "df021288-bdef-4463-88db-98f22de89214"
              type = "Role"
            }
            delegated_user_read = {
              id   = "e1fe6dd8-ba31-4d61-89e7-88639da4683d"
              type = "Scope"
            },
          }
        },
        exchange_online = {
          admin_consent = true //This should ensure that the app role assigment is not created automatcaly and needs admin consent
          resource_app_id = "00000002-0000-0ff1-ce00-000000000000" //office_365_exchange_online
          resource_access = {
            delegated_ews_accessasuser_all = {
              id   = "3b5f3d61-589b-4a3c-a359-5dd4b5ee5bd5"
              type = "Scope"
            },
            application_ews_accessasuser_all = {
              id   = "dc890d15-9560-4a4c-9b7f-a736ec74ec40"
              type = "Role"
            }
          }
        }
      }



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
        app_role_assignment_required  = true
        description                   = "Service Principal for Station Test: Maximum"
        login_url                     = "http://localhost/login"
        notes                         = "Notes for Service Principal"
        notification_email_addresses  = ["admin@example.com"]
        owners                        = ["This has to be overriden with the current objectid"]
        preferred_single_sign_on_mode = "saml"
        use_existing                  = false

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

run "application-main" {

  variables {
    applications = merge(var.applications, {
      maximum = merge(var.applications.maximum, {
        owners = [run.bootstrap_application.current.object_id],
        service_principal = merge(var.applications.maximum.service_principal, {
          owners = [run.bootstrap_application.current.object_id]
        })
      })
    })

    tfe = merge(var.tfe, {
      project = merge(var.tfe.project, {
        id = run.bootstrap_create_tfc_test_project.id
      })
    })
  }

  module {
    source = "./"
  }

  # Validate that the Azure AD applications are created correctly
  assert {
    condition = alltrue([
      module.applications["minimum"].application.display_name == var.applications.minimum.display_name,
      module.applications["maximum"].application.display_name == var.applications.maximum.display_name
    ])
    error_message = "The display_name did not match the input."
  }

  assert {
    condition = alltrue([
      module.applications["minimum"].application.owners == toset([module.user_assigned_identity.principal_id]),
      module.applications["maximum"].application.owners == toset(concat(var.applications.maximum.owners, [module.user_assigned_identity.principal_id]))
    ])
    error_message = "The var.applications.appName.owners does not match owners assigned to the application."
  }

  assert {
    condition = alltrue([
      module.applications["minimum"].application.sign_in_audience == "AzureADMyOrg", //Default value when nothing is provided
      module.applications["maximum"].application.sign_in_audience == var.applications.maximum.sign_in_audience
    ])
    error_message = "The var.applications.appName.sign_in_audience does not match the sign in audience of the application."
  }
  assert {
    condition = alltrue([
      module.applications["minimum"].application.identifier_uris == null, //Default value when nothing is provided
      module.applications["maximum"].application.identifier_uris == toset(var.applications.maximum.identifier_uris)
    ])
    error_message = "The var.applications.appName.identifier_uris identifier_uris does not match the identifier uris of the application."
  }
  assert {
    condition = alltrue([
      module.applications["minimum"].application.group_membership_claims == null, //Default value when nothing is provided
      module.applications["maximum"].application.group_membership_claims == toset(var.applications.maximum.group_membership_claims)
    ])
    error_message = "The var.applications.appName.group_membership_claims does not match the group membership claims of the application."
  }
  assert {
    condition = alltrue([
      module.applications["minimum"].application.prevent_duplicate_names == false, //Default value
      module.applications["maximum"].application.prevent_duplicate_names == var.applications.maximum.prevent_duplicate_names
    ])
    error_message = "The var.applications.appName.prevent_duplicate_names does not match the prevent_duplicate_names of the application"
  }
  assert {
    condition = alltrue([
      module.applications["minimum"].application.fallback_public_client_enabled == false,
      module.applications["maximum"].application.fallback_public_client_enabled == var.applications.maximum.fallback_public_client_enabled
    ])
    error_message = "The var.applications.appName.fallback_public_client_enabled did not match the input"
  }
  assert {
    condition = alltrue([
      module.applications["minimum"].application.notes == "", //Defaults to "" instead of null for some reason
      module.applications["maximum"].application.notes == var.applications.maximum.notes
    ])
    error_message = "The var.applications.appName.notes does not match the notes of the application"
  }

}

run "application-single_page_application" {

  variables {
    applications = merge(var.applications, {
      maximum = merge(var.applications.maximum, {
        owners = [run.bootstrap_application.current.object_id],
        service_principal = merge(var.applications.maximum.service_principal, {
          owners = [run.bootstrap_application.current.object_id]
        })
      })
    })

    tfe = merge(var.tfe, {
      project = merge(var.tfe.project, {
        id = run.bootstrap_create_tfc_test_project.id
      })
    })
  }

  module {
    source = "./"
  }

  assert {
    condition = alltrue([
      length(module.applications["minimum"].application.single_page_application[0].redirect_uris) == 0,
      module.applications["maximum"].application.single_page_application[0].redirect_uris == toset(var.applications.maximum.single_page_application.redirect_uris)

    ])
    error_message = "The var.applications.appName.single_page_application does not match the single_page_application of the application"
  }
}

run "application-api" {

  variables {
    applications = merge(var.applications, {
      maximum = merge(var.applications.maximum, {
        owners = [run.bootstrap_application.current.object_id],
        service_principal = merge(var.applications.maximum.service_principal, {
          owners = [run.bootstrap_application.current.object_id]
        })
      })
    })


    tfe = merge(var.tfe, {
      project = merge(var.tfe.project, {
        id = run.bootstrap_create_tfc_test_project.id
      })
    })
  }

  module {
    source = "./"
  }

  assert {
    condition = alltrue([
      module.applications["maximum"].application.api[0].mapped_claims_enabled == var.applications.maximum.api.mapped_claims_enabled,
      module.applications["maximum"].application.api[0].requested_access_token_version == var.applications.maximum.api.requested_access_token_version
    ])
    error_message = "The var.applications.maximum.api configuration does not match the api configuration of the application"
  }

  assert {
    condition = alltrue([
      module.applications["minimum"].application.api[0].mapped_claims_enabled == false,     //Defaults to false when no value is provided,
      module.applications["minimum"].application.api[0].requested_access_token_version == 1 //Defaults to false when no value is provided
    ])
    error_message = "The var.applications.minimum.api configuration does not match the api configuration of the application"
  }

  assert {
    condition = alltrue([
      length(module.applications["maximum"].application.api[0].oauth2_permission_scope) == length(var.applications.maximum.api.oauth2_permission_scope),
      alltrue([
        for expected in var.applications.maximum.api.oauth2_permission_scope :
        anytrue([
          for actual in module.applications["maximum"].application.api[0].oauth2_permission_scope :
          alltrue([
            actual.admin_consent_description == expected.admin_consent_description,
            actual.admin_consent_display_name == expected.admin_consent_display_name,
            actual.id == expected.id,
            actual.enabled == expected.enabled,
            actual.value == expected.value
          ])
        ])
      ])
    ])
    error_message = "The var.applications.maximum.api.oauth2_permission_scope configuration does not match the API configuration of the application."
  }
}

run "application-required_resource_access" {

  variables {
    applications = merge(var.applications, {
      maximum = merge(var.applications.maximum, {
        owners = [run.bootstrap_application.current.object_id],
        service_principal = merge(var.applications.maximum.service_principal, {
          owners = [run.bootstrap_application.current.object_id]
        })
      })
    })


    tfe = merge(var.tfe, {
      project = merge(var.tfe.project, {
        id = run.bootstrap_create_tfc_test_project.id
      })
    })
  }

  module {
    source = "./"
  }

  assert {
    condition     = try(length(module.applications["minimum"].required_resource_access), 0) == 0
    error_message = "required_resource_access should not be configured when no config is provided."
  }

  # Assert that the number of required_resource_access entries match
  assert {
    condition     = length(module.applications["maximum"].application.required_resource_access) == length(var.applications.maximum.required_resource_access)
    error_message = "The number of required_resource_access entries does not match whats provided in var.applications.maximum.required_resource_access."
  }

  # Assert that each resource_app_id in expected exists in actual
  assert {
    condition = alltrue([
      for expected in var.applications.maximum.required_resource_access :
      contains([
        for actual in module.applications["maximum"].application.required_resource_access :
        actual.resource_app_id
      ], expected.resource_app_id)
    ])
    error_message = "One or more var.applications.maximum.required_resource_access.resource_app_id values in required_resource_access are missing."
  }

  # Assert that each required_resource_access entry has the correct number of resource_access entries
  assert {
    condition = alltrue([
      for expected in var.applications.maximum.required_resource_access :
      anytrue([
        for actual in module.applications["maximum"].application.required_resource_access :
        actual.resource_app_id == expected.resource_app_id &&
        length(actual.resource_access) == length(expected.resource_access)
      ])
    ])
    error_message = "The number of resource_access entries does not match for one or more required_resource_access entries."
  }

  # Assert that each resource_access entry has the correct id and type
  assert {
    condition = alltrue([
      for expected in var.applications.maximum.required_resource_access :
      anytrue([
        for actual in module.applications["maximum"].application.required_resource_access :
        actual.resource_app_id == expected.resource_app_id &&
        alltrue([
          for expected_access in expected.resource_access :
          anytrue([
            for actual_access in actual.resource_access :
            alltrue([
              actual_access.id == expected_access.id,
              actual_access.type == expected_access.type
            ])
          ])
        ])
      ])
    ])
    error_message = "One or more resource_access entries do not match in id or type."
  }
  #Verify that the resource_access that is if type "Application/Role" has been assigned to the service principal and is approved when admin_consent is false
  assert {
    condition     = module.applications["maximum"].app_role_assignments["${var.applications.maximum.required_resource_access["graph"].resource_app_id}-${var.applications.maximum.required_resource_access["graph"].resource_access["application_group_read_all"].id}"].app_role_id == var.applications.maximum.required_resource_access["graph"].resource_access["application_group_read_all"].id
    error_message = "The required_resource_access for the Role permission has not been assiged to the service principal"
  }

  assert {
    condition     = module.applications["maximum"].app_role_assignments["${var.applications.maximum.required_resource_access["graph"].resource_app_id}-${var.applications.maximum.required_resource_access["graph"].resource_access["application_user_read_all"].id}"].app_role_id == var.applications.maximum.required_resource_access["graph"].resource_access["application_user_read_all"].id
    error_message = "The required_resource_access for application_user_read_all Role permission has not been assigned to the service principal"
  }

  # Verify that the app role has not been assigned when "admin_consent" is true
    assert {
    condition     = !can(module.applications["maximum"].app_role_assignments["${var.applications.maximum.required_resource_access["exchange_online"].resource_app_id}-${var.applications.maximum.required_resource_access["exchange_online"].resource_access["application_ews_accessasuser_all"].id}"])
    error_message = "The app role has been assigned to the service principal when admin_consent is true. "
  }
}
run "application-optional_claims" {

  variables {
    applications = merge(var.applications, {
      maximum = merge(var.applications.maximum, {
        owners = [run.bootstrap_application.current.object_id],
        service_principal = merge(var.applications.maximum.service_principal, {
          owners = [run.bootstrap_application.current.object_id]
        })
      })
    })


    tfe = merge(var.tfe, {
      project = merge(var.tfe.project, {
        id = run.bootstrap_create_tfc_test_project.id
      })
    })
  }

  module {
    source = "./"
  }

  assert {
    condition     = try(length(module.applications["minimum"].optional_claims), 0) == 0
    error_message = "Public_client should not be configured when no config is provided"
  }

  # Assert that the `optional_claims` block exists
  assert {
    condition     = length(module.applications["maximum"].application.optional_claims) > 0
    error_message = "The optional_claims block is missing."
  }

  # Assert that all expected keys exist in optional_claims
  assert {
    condition = alltrue([
      contains(keys(module.applications["maximum"].application.optional_claims[0]), "access_token"),
      contains(keys(module.applications["maximum"].application.optional_claims[0]), "id_token"),
      contains(keys(module.applications["maximum"].application.optional_claims[0]), "saml2_token")
    ])
    error_message = "One or more expected keys (access_token, id_token, saml2_token) are missing in optional_claims."
  }

  # Assert that the number of claims for each key matches
  assert {
    condition = alltrue([
      length(module.applications["maximum"].application.optional_claims[0].access_token) == length(var.applications.maximum.optional_claims.access_token),
      length(module.applications["maximum"].application.optional_claims[0].id_token) == length(var.applications.maximum.optional_claims.id_token),
      length(module.applications["maximum"].application.optional_claims[0].saml2_token) == length(var.applications.maximum.optional_claims.saml2_token)
    ])
    error_message = "The number of optional claims does not match for one or more token types."
  }

  # Assert that each optional claim has the correct name
  assert {
    condition = alltrue([
      alltrue([
        for expected in var.applications.maximum.optional_claims.access_token :
        anytrue([
          for actual in module.applications["maximum"].application.optional_claims[0].access_token :
          actual.name == expected.name
        ])
      ]),
      alltrue([
        for expected in var.applications.maximum.optional_claims.id_token :
        anytrue([
          for actual in module.applications["maximum"].application.optional_claims[0].id_token :
          actual.name == expected.name
        ])
      ]),
      alltrue([
        for expected in var.applications.maximum.optional_claims.saml2_token :
        anytrue([
          for actual in module.applications["maximum"].application.optional_claims[0].saml2_token :
          actual.name == expected.name
        ])
      ])
    ])
    error_message = "One or more optional claims do not match the expected values."
  }

}

run "application-public_client" {

  variables {
    applications = merge(var.applications, {
      maximum = merge(var.applications.maximum, {
        owners = [run.bootstrap_application.current.object_id],
        service_principal = merge(var.applications.maximum.service_principal, {
          owners = [run.bootstrap_application.current.object_id]
        })
      })
    })
    tfe = merge(var.tfe, {
      project = merge(var.tfe.project, {
        id = run.bootstrap_create_tfc_test_project.id
      })
    })
  }

  module {
    source = "./"
  }

  assert {
    condition     = try(length(module.applications["minimum"].public_client), 0) == 0
    error_message = "Public_client should not be configured when no config is provided"
  }

  assert {
    condition = module.applications["maximum"].application.public_client[0].redirect_uris == toset(var.applications.maximum.public_client.redirect_uris)


    error_message = "The var.applications.maximum.public_client.redirect_uris does not match the redirect_uris of the application"
  }

  assert {
    condition     = length(module.applications["minimum"].application.public_client[0].redirect_uris) == 0
    error_message = "The var.applications.minimum.public_client.redirect_uris are not empty. This should be empty by default."
  }

}

run "application-web" {

  variables {
    applications = merge(var.applications, {
      maximum = merge(var.applications.maximum, {
        owners = [run.bootstrap_application.current.object_id],
        service_principal = merge(var.applications.maximum.service_principal, {
          owners = [run.bootstrap_application.current.object_id]
        })
      })
    })
    tfe = merge(var.tfe, {
      project = merge(var.tfe.project, {
        id = run.bootstrap_create_tfc_test_project.id
      })
    })
  }

  module {
    source = "./"
  }

  assert {
    condition     = try(length(module.applications["minimum"].web), 0) == 0
    error_message = "Web should not be configured when no config is provided"
  }

  assert {
    condition     = module.applications["maximum"].application.web[0].homepage_url == var.applications.maximum.web.homepage_url
    error_message = "homepage_url does not match the expected value."
  }

  assert {
    condition     = module.applications["maximum"].application.web[0].logout_url == var.applications.maximum.web.logout_url
    error_message = "logout_url does not match the expected value."
  }

  assert {
    condition     = module.applications["maximum"].application.web[0].redirect_uris == toset(var.applications.maximum.web.redirect_uris)
    error_message = "redirect_uris do not match the expected values."
  }

  assert {
    condition     = module.applications["maximum"].application.web[0].implicit_grant[0].access_token_issuance_enabled == var.applications.maximum.web.implicit_grant.access_token_issuance_enabled
    error_message = "implicit_grant.access_token_issuance_enabled should be true."
  }
}

run "application-service_principal" {

  variables {
    applications = merge(var.applications, {
      maximum = merge(var.applications.maximum, {
        owners = [run.bootstrap_application.current.object_id],
        service_principal = merge(var.applications.maximum.service_principal, {
          owners = [run.bootstrap_application.current.object_id]
        })
      })
    })
    tfe = merge(var.tfe, {
      project = merge(var.tfe.project, {
        id = run.bootstrap_create_tfc_test_project.id
      })
    })
  }

  module {
    source = "./"
  }

  assert {
    condition     = try(length(module.applications["minimum"].service_principal), 0) == 0
    error_message = "Service principal should not be created when no config is provided"
  }

  assert {
    condition = alltrue([
      module.applications["maximum"].service_principal[0].account_enabled == var.applications.maximum.service_principal.account_enabled,
      module.applications["maximum"].service_principal[0].alternative_names == toset(var.applications.maximum.service_principal.alternative_names),
      module.applications["maximum"].service_principal[0].app_role_assignment_required == var.applications.maximum.service_principal.app_role_assignment_required,
      module.applications["maximum"].service_principal[0].description == var.applications.maximum.service_principal.description,
      module.applications["maximum"].service_principal[0].login_url == var.applications.maximum.service_principal.login_url,
      module.applications["maximum"].service_principal[0].notes == var.applications.maximum.service_principal.notes,
      module.applications["maximum"].service_principal[0].notification_email_addresses == toset(var.applications.maximum.service_principal.notification_email_addresses),
      module.applications["maximum"].service_principal[0].preferred_single_sign_on_mode == var.applications.maximum.service_principal.preferred_single_sign_on_mode,
      module.applications["maximum"].service_principal[0].use_existing == var.applications.maximum.service_principal.use_existing,
    ])
    error_message = "Service principal settings do not match expected configuration."
  }

  assert {
    condition = alltrue([
      module.applications["maximum"].service_principal[0].feature_tags[0].custom_single_sign_on == var.applications.maximum.service_principal.feature_tags.custom_single_sign_on,
      module.applications["maximum"].service_principal[0].feature_tags[0].enterprise == var.applications.maximum.service_principal.feature_tags.enterprise,
      module.applications["maximum"].service_principal[0].feature_tags[0].gallery == var.applications.maximum.service_principal.feature_tags.gallery,
      module.applications["maximum"].service_principal[0].feature_tags[0].hide == var.applications.maximum.service_principal.feature_tags.hide,
    ])
    error_message = "Service principal feature_tags settings do not match expected configuration."
  }

  assert {
    condition     = module.applications["maximum"].service_principal[0].saml_single_sign_on[0].relay_state == var.applications.maximum.service_principal.saml_single_sign_on.relay_state
    error_message = "Service principal saml_single_sign_on settings do not match expected configuration."
  }
}
