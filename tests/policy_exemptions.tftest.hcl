provider "tfe" {}

provider "azurerm" {
  features {}
}

provider "azurerm" {
  alias = "connectivity"
  features {}
}

provider "azuread" {}

test {
  parallel = true
}

run "bootstrap_create_tfc_test_project" {
  variables {
    tfc_project_name = "tests_policy_exemptions"
  }

  module {
    source = "./tests/setup-tfe-project"
  }
}

variables {
  tfe = {
    project = {
      id   = "# Overridden"
      name = "tests_policy_exemptions"
    }
    organization_name     = "blinq-west-lab"
    workspace_name        = "policy_exemptions_test"
    workspace_description = "Station Tests for var.policy_exemptions"
  }

  resource_group_name = "policy-exemptions"

  resource_groups = {
    alternate = {
      name = "policy-exemptions-alt"
    }
  }

  policy_exemptions = {
    minimum = {
      name                 = "minimum-policy-exemption"
      policy_assignment_id = "/subscriptions/00000000-0000-0000-0000-000000000000/providers/Microsoft.Authorization/policyAssignments/11111111-1111-1111-1111-111111111111"
      exemption_category   = "Waiver"
      description          = "Temporary exemption while workload migration is completed."
    }

    maximum = {
      name                 = "maximum-policy-exemption"
      policy_assignment_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-policy-exemptions/providers/Microsoft.Authorization/policyAssignments/22222222-2222-2222-2222-222222222222"
      exemption_category   = "Mitigated"
      display_name         = "Maximum policy exemption"
      description          = "Mitigated by compensating controls at the workload level."
      expires_on           = "2028-01-11T00:00:00Z"
      resource_group_key   = "alternate"
      policy_definition_reference_ids = [
        "Deny-Subnet-Without-Nsg"
      ]
    }
  }
}

run "policy_exemptions_plan" {
  command = plan

  variables {
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
    condition     = azurerm_resource_group_policy_exemption.this["minimum"].name == var.policy_exemptions.minimum.name
    error_message = "Minimum policy exemption name does not match var.policy_exemptions.minimum.name"
  }

  assert {
    condition     = azurerm_resource_group_policy_exemption.this["maximum"].policy_assignment_id == var.policy_exemptions.maximum.policy_assignment_id
    error_message = "Maximum policy exemption policy_assignment_id does not match input"
  }

  assert {
    condition     = azurerm_resource_group_policy_exemption.this["maximum"].exemption_category == var.policy_exemptions.maximum.exemption_category
    error_message = "Maximum policy exemption exemption_category does not match input"
  }

  assert {
    condition     = azurerm_resource_group_policy_exemption.this["maximum"].display_name == var.policy_exemptions.maximum.display_name
    error_message = "Maximum policy exemption display_name does not match input"
  }

  assert {
    condition     = azurerm_resource_group_policy_exemption.this["maximum"].expires_on == var.policy_exemptions.maximum.expires_on
    error_message = "Maximum policy exemption expires_on does not match input"
  }

  assert {
    condition     = toset(azurerm_resource_group_policy_exemption.this["maximum"].policy_definition_reference_ids) == toset(var.policy_exemptions.maximum.policy_definition_reference_ids)
    error_message = "Maximum policy exemption policy_definition_reference_ids does not match input"
  }
}

run "policy_exemptions_validation_description_required" {
  command = plan

  variables {
    tfe = merge(var.tfe, {
      project = merge(var.tfe.project, {
        id = run.bootstrap_create_tfc_test_project.id
      })
    })

    policy_exemptions = {
      invalid = {
        name                 = "invalid-empty-description"
        policy_assignment_id = "/subscriptions/00000000-0000-0000-0000-000000000000/providers/Microsoft.Authorization/policyAssignments/33333333-3333-3333-3333-333333333333"
        exemption_category   = "Waiver"
        description          = "  "
      }
    }
  }

  expect_failures = [
    var.policy_exemptions
  ]
}

run "policy_exemptions_validation_exemption_category" {
  command = plan

  variables {
    tfe = merge(var.tfe, {
      project = merge(var.tfe.project, {
        id = run.bootstrap_create_tfc_test_project.id
      })
    })

    policy_exemptions = {
      invalid = {
        name                 = "invalid-category"
        policy_assignment_id = "/subscriptions/00000000-0000-0000-0000-000000000000/providers/Microsoft.Authorization/policyAssignments/44444444-4444-4444-4444-444444444444"
        exemption_category   = "InvalidCategory"
        description          = "Description is required but category is invalid"
      }
    }
  }

  expect_failures = [
    var.policy_exemptions
  ]
}

run "policy_exemptions_validation_resource_group_key" {
  command = plan

  variables {
    tfe = merge(var.tfe, {
      project = merge(var.tfe.project, {
        id = run.bootstrap_create_tfc_test_project.id
      })
    })

    policy_exemptions = {
      invalid = {
        name                 = "invalid-rg-key"
        policy_assignment_id = "/subscriptions/00000000-0000-0000-0000-000000000000/providers/Microsoft.Authorization/policyAssignments/55555555-5555-5555-5555-555555555555"
        exemption_category   = "Waiver"
        description          = "Description is present but resource_group_key is invalid"
        resource_group_key   = "missing"
      }
    }
  }

  expect_failures = [
    var.policy_exemptions
  ]
}
