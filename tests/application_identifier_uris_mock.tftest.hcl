mock_provider "azurerm" {
  mock_resource "azurerm_resource_group" {
    defaults = {
      id = "/subscriptions/11111111-1111-1111-1111-111111111111/resourceGroups/rg-workload"
    }
  }
  mock_resource "azurerm_user_assigned_identity" {
    defaults = {
      id           = "/subscriptions/11111111-1111-1111-1111-111111111111/resourceGroups/rg-workload/providers/Microsoft.ManagedIdentity/userAssignedIdentities/mock"
      principal_id = "33333333-3333-3333-3333-333333333333"
    }
  }
}
mock_provider "azurerm" {
  alias = "connectivity"
}
mock_provider "azuread" {
  mock_data "azuread_application_published_app_ids" {
    defaults = {
      result = { MicrosoftGraph = "00000003-0000-0000-c000-000000000000" }
    }
  }
  mock_data "azuread_service_principal" {
    defaults = {
      object_id = "44444444-4444-4444-4444-444444444444"
      app_role_ids = {
        "Application.ReadWrite.OwnedBy" = "18a4783c-866b-4cc7-a460-3d5e5662c884"
        "Group.Read.All"                = "5b567255-7703-4780-807c-7be8301ae99b"
        "User.ReadBasic.All"            = "97235f07-e226-4f63-ace3-39588e11d3a1"
      }
    }
  }
  mock_resource "azuread_service_principal" {
    defaults = {
      object_id = "66666666-6666-6666-6666-666666666666"
    }
  }
  mock_resource "azuread_group" {
    defaults = {
      object_id = "77777777-7777-7777-7777-777777777777"
    }
  }
}
mock_provider "msgraph" {}
mock_provider "random" {}
mock_provider "tfe" {}
mock_provider "time" {}

override_resource {
  target = module.applications["generated"].azuread_application.this
  values = {
    id        = "/applications/55555555-5555-5555-5555-555555555555"
    client_id = "cccccccc-cccc-cccc-cccc-cccccccccccc"
  }
}

override_module {
  target = module.station-tfe
  outputs = {
    workspace           = {}
    workspace_variables = {}
    workspace_settings  = {}
  }
}

variables {
  tenant_id       = "22222222-2222-2222-2222-222222222222"
  subscription_id = "11111111-1111-1111-1111-111111111111"
  tfe = {
    organization_name     = "mock-only"
    project               = { id = "prj-mock", name = "mock" }
    workspace_name        = "application-uri-mock"
    workspace_description = "Mocked application identifier URI tests"
  }
  groups = {
    vpn_users = { display_name = "VPN Users" }
  }
  applications = {
    unchanged = {
      display_name = "No identifier URI"
    }
    existing = {
      display_name    = "Existing application"
      identifier_uris = ["api://existing", "api://other"]
    }
    generated = {
      display_name               = "Generated URI"
      use_default_identifier_uri = true
      api = {
        oauth2_permission_scope = [
          {
            id                         = "88888888-8888-8888-8888-888888888888"
            value                      = "user_impersonation"
            admin_consent_description  = "Access the VPN."
            admin_consent_display_name = "Access the VPN"
          },
          {
            id                         = "99999999-9999-9999-9999-999999999999"
            value                      = "diagnostics"
            admin_consent_description  = "Read VPN diagnostics."
            admin_consent_display_name = "Read VPN diagnostics"
          }
        ]
      }
      preauthorized_clients = {
        vpn = {
          client_id    = "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa"
          scope_values = ["user_impersonation"]
        }
        support = {
          client_id    = "bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb"
          scope_values = ["user_impersonation", "diagnostics"]
        }
      }
      service_principal = {
        app_role_assignment_required = true
        group_assignments = {
          vpn_access = { group_key = "vpn_users" }
        }
      }
    }
  }
}

run "initial_apply" {
  assert {
    condition = (
      length(output.applications["unchanged"].application.identifier_uris) == 0 &&
      output.applications["existing"].application.identifier_uris == toset(["api://existing", "api://other"]) &&
      output.applications["generated"].application.identifier_uris == toset(["api://${output.applications["generated"].application.client_id}"])
    )
    error_message = "Applications must have their omitted, explicit or generated identifier URIs after the first apply."
  }

  assert {
    condition = (
      length(output.applications["unchanged"].preauthorized_clients) == 0 &&
      length(output.applications["unchanged"].group_assignments) == 0
    )
    error_message = "Applications must not create preauthorizations or group assignments by default."
  }

  assert {
    condition = (
      output.applications["generated"].preauthorized_clients["vpn"].application_id == output.applications["generated"].application.id &&
      output.applications["generated"].preauthorized_clients["vpn"].authorized_client_id == var.applications.generated.preauthorized_clients.vpn.client_id &&
      output.applications["generated"].preauthorized_clients["vpn"].permission_ids == toset(["88888888-8888-8888-8888-888888888888"]) &&
      output.applications["generated"].preauthorized_clients["support"].permission_ids == toset(["88888888-8888-8888-8888-888888888888", "99999999-9999-9999-9999-999999999999"])
    )
    error_message = "Each client must be preauthorized for exactly its selected scopes on the target application."
  }

  assert {
    condition = (
      output.applications["generated"].group_assignments["vpn_access"].app_role_id == "00000000-0000-0000-0000-000000000000" &&
      output.applications["generated"].group_assignments["vpn_access"].principal_object_id == output.groups["vpn_users"].object_id &&
      output.applications["generated"].group_assignments["vpn_access"].resource_object_id == output.applications["generated"].service_principal[0].object_id
    )
    error_message = "The group must receive Default Access on the target service principal."
  }
}

run "enable_on_existing_application" {
  variables {
    applications = merge(var.applications, {
      existing = merge(var.applications.existing, {
        use_default_identifier_uri = true
      })
    })
  }

  assert {
    condition = (
      output.applications["existing"].application.id == run.initial_apply.applications["existing"].application.id &&
      output.applications["existing"].application.client_id == run.initial_apply.applications["existing"].application.client_id &&
      output.applications["existing"].application.identifier_uris == toset(["api://existing", "api://other", "api://${run.initial_apply.applications["existing"].application.client_id}"])
    )
    error_message = "Enabling the generated URI must preserve the existing application and its custom URIs."
  }
}

run "unchanged_plan" {
  command = plan

  variables {
    applications = merge(var.applications, {
      existing = merge(var.applications.existing, {
        use_default_identifier_uri = true
      })
    })
  }

  assert {
    condition     = output.applications["existing"].application.identifier_uris == run.enable_on_existing_application.applications["existing"].application.identifier_uris
    error_message = "A subsequent plan must retain the generated URI."
  }

  assert {
    condition = (
      output.applications["generated"].preauthorized_clients == run.enable_on_existing_application.applications["generated"].preauthorized_clients &&
      output.applications["generated"].group_assignments == run.enable_on_existing_application.applications["generated"].group_assignments
    )
    error_message = "A subsequent plan must retain the existing preauthorizations and group assignments."
  }
}

run "deduplicate_identifier_uris" {
  variables {
    applications = merge(var.applications, {
      existing = merge(var.applications.existing, {
        identifier_uris            = ["api://existing", "api://other", "api://${run.initial_apply.applications["existing"].application.client_id}"]
        use_default_identifier_uri = true
      })
    })
  }

  assert {
    condition     = output.applications["existing"].application.identifier_uris == run.enable_on_existing_application.applications["existing"].application.identifier_uris
    error_message = "An explicitly listed default URI must not be duplicated."
  }
}

run "unknown_scope_value" {
  command = plan

  variables {
    applications = {
      invalid = {
        display_name = "Invalid scope reference"
        preauthorized_clients = {
          vpn = {
            client_id    = "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa"
            scope_values = ["missing"]
          }
        }
      }
    }
  }

  expect_failures = [var.applications]
}

run "unknown_group_key" {
  command = plan

  variables {
    applications = {
      invalid = {
        display_name = "Invalid group reference"
        service_principal = {
          group_assignments = {
            vpn_access = { group_key = "missing" }
          }
        }
      }
    }
  }

  expect_failures = [var.applications]
}
