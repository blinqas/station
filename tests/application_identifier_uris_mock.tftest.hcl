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
      }
    }
  }
}
mock_provider "msgraph" {}
mock_provider "random" {}
mock_provider "tfe" {}
mock_provider "time" {}

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
  applications = {
    unchanged = {
      display_name = "No identifier URI"
    }
    existing = {
      display_name    = "Existing application"
      identifier_uris = ["api://existing"]
    }
    generated = {
      display_name               = "Generated URI"
      use_default_identifier_uri = true
    }
  }
}

run "initial_apply" {
  assert {
    condition = (
      length(output.applications["unchanged"].application.identifier_uris) == 0 &&
      output.applications["existing"].application.identifier_uris == toset(["api://existing"]) &&
      output.applications["generated"].application.identifier_uris == toset(["api://${output.applications["generated"].application.client_id}"])
    )
    error_message = "Applications must have their omitted, explicit or generated identifier URIs after the first apply."
  }
}

run "enable_on_existing_application" {
  variables {
    applications = merge(var.applications, {
      existing = merge(var.applications.existing, {
        identifier_uris            = []
        use_default_identifier_uri = true
      })
    })
  }

  assert {
    condition = (
      output.applications["existing"].application.id == run.initial_apply.applications["existing"].application.id &&
      output.applications["existing"].application.client_id == run.initial_apply.applications["existing"].application.client_id &&
      output.applications["existing"].application.identifier_uris == toset(["api://${run.initial_apply.applications["existing"].application.client_id}"])
    )
    error_message = "Enabling the generated URI must update the existing application without replacing it."
  }
}

run "unchanged_plan" {
  command = plan

  variables {
    applications = merge(var.applications, {
      existing = merge(var.applications.existing, {
        identifier_uris            = []
        use_default_identifier_uri = true
      })
    })
  }

  assert {
    condition     = output.applications["existing"].application.identifier_uris == run.enable_on_existing_application.applications["existing"].application.identifier_uris
    error_message = "A subsequent plan must retain the generated URI."
  }
}

run "conflicting_identifier_uris" {
  command = plan

  variables {
    applications = {
      conflict = {
        display_name               = "Conflicting URI settings"
        identifier_uris            = ["api://explicit"]
        use_default_identifier_uri = true
      }
    }
  }

  expect_failures = [var.applications]
}
