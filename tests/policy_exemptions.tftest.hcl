provider "tfe" {}

provider "azuread" {}

provider "azurerm" {
  features {}
}

test {
  parallel = true
}

provider "azurerm" {
  alias = "connectivity"
  features {}
}

run "bootstrap_create_tfc_test_project" {
  variables {
    tfc_project_name = "tests_policy_exemptions"
  }
  module {
    source = "./tests/setup-tfe-project"
  }
}

run "setup" {
  module {
    source = "./tests/setup-common"
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
    workspace_description = "Workspace description for var.policy_exemptions"
    workspace_settings = {
      execution_mode = "remote"
    }
  }

  resource_groups = {
    additional = {
      name     = "additional-rg"
      location = "norwayeast"
    }
  }

  policy_exemptions = {
    # Minimum configuration - exemption on default resource group
    minimum = {
      name                 = "minimum-exemption"
      policy_assignment_id = "/providers/Microsoft.Management/managementGroups/mg-example/providers/Microsoft.Authorization/policyAssignments/Deny-Example-Policy"
      exemption_category   = "Waiver"
      description          = "This is a minimum test exemption with required fields only."
    }

    # Maximum configuration - exemption on default resource group with all optional fields
    maximum = {
      name                 = "maximum-exemption"
      policy_assignment_id = "/providers/Microsoft.Management/managementGroups/mg-example/providers/Microsoft.Authorization/policyAssignments/Enforce-Example-Policy"
      exemption_category   = "Mitigated"
      display_name         = "Maximum Test Exemption"
      description          = "This is a maximum test exemption with all optional fields populated."
      expires_on           = "2028-12-31T23:59:59Z"
      metadata             = "{\"requestedBy\": \"Station Testing\", \"approvedBy\": \"Admin\"}"
    }

    # Exemption on user-specified resource group
    additional_rg = {
      name                 = "additional-rg-exemption"
      policy_assignment_id = "/providers/Microsoft.Management/managementGroups/mg-example/providers/Microsoft.Authorization/policyAssignments/Audit-Example-Policy"
      exemption_category   = "Waiver"
      description          = "This exemption is applied to a user-specified resource group."
      resource_group_name  = "additional"
    }
  }
}

run "main" {
  command = plan

  variables {
    tfe = {
      project = {
        id   = run.bootstrap_create_tfc_test_project.project.id
        name = "tests_policy_exemptions"
      }
      organization_name     = "blinq-west-lab"
      workspace_name        = "policy_exemptions_test"
      workspace_description = "Workspace description for var.policy_exemptions"
      workspace_settings = {
        execution_mode = "remote"
      }
    }

    resource_groups = {
      additional = {
        name     = "additional-rg"
        location = "norwayeast"
      }
    }

    policy_exemptions = {
      minimum = {
        name                 = "minimum-exemption"
        policy_assignment_id = "/providers/Microsoft.Management/managementGroups/mg-example/providers/Microsoft.Authorization/policyAssignments/Deny-Example-Policy"
        exemption_category   = "Waiver"
        description          = "This is a minimum test exemption with required fields only."
      }

      maximum = {
        name                 = "maximum-exemption"
        policy_assignment_id = "/providers/Microsoft.Management/managementGroups/mg-example/providers/Microsoft.Authorization/policyAssignments/Enforce-Example-Policy"
        exemption_category   = "Mitigated"
        display_name         = "Maximum Test Exemption"
        description          = "This is a maximum test exemption with all optional fields populated."
        expires_on           = "2028-12-31T23:59:59Z"
        metadata             = "{\"requestedBy\": \"Station Testing\", \"approvedBy\": \"Admin\"}"
      }

      additional_rg = {
        name                 = "additional-rg-exemption"
        policy_assignment_id = "/providers/Microsoft.Management/managementGroups/mg-example/providers/Microsoft.Authorization/policyAssignments/Audit-Example-Policy"
        exemption_category   = "Waiver"
        description          = "This exemption is applied to a user-specified resource group."
        resource_group_name  = "additional"
      }
    }
  }

  # Test that minimum configuration is correctly set
  assert {
    condition     = azurerm_resource_group_policy_exemption.this["minimum"].name == "minimum-exemption"
    error_message = "Minimum exemption name should be 'minimum-exemption'"
  }

  assert {
    condition     = azurerm_resource_group_policy_exemption.this["minimum"].exemption_category == "Waiver"
    error_message = "Minimum exemption category should be 'Waiver'"
  }

  assert {
    condition     = azurerm_resource_group_policy_exemption.this["minimum"].description == "This is a minimum test exemption with required fields only."
    error_message = "Minimum exemption description should match input"
  }

  assert {
    condition     = azurerm_resource_group_policy_exemption.this["minimum"].resource_group_id == azurerm_resource_group.workload.id
    error_message = "Minimum exemption should be applied to the default workload resource group"
  }

  # Test that maximum configuration is correctly set
  assert {
    condition     = azurerm_resource_group_policy_exemption.this["maximum"].name == "maximum-exemption"
    error_message = "Maximum exemption name should be 'maximum-exemption'"
  }

  assert {
    condition     = azurerm_resource_group_policy_exemption.this["maximum"].exemption_category == "Mitigated"
    error_message = "Maximum exemption category should be 'Mitigated'"
  }

  assert {
    condition     = azurerm_resource_group_policy_exemption.this["maximum"].display_name == "Maximum Test Exemption"
    error_message = "Maximum exemption display_name should match input"
  }

  assert {
    condition     = azurerm_resource_group_policy_exemption.this["maximum"].expires_on == "2028-12-31T23:59:59Z"
    error_message = "Maximum exemption expires_on should match input"
  }

  assert {
    condition     = azurerm_resource_group_policy_exemption.this["maximum"].metadata == "{\"requestedBy\": \"Station Testing\", \"approvedBy\": \"Admin\"}"
    error_message = "Maximum exemption metadata should match input"
  }

  # Test that additional resource group exemption is correctly set
  assert {
    condition     = azurerm_resource_group_policy_exemption.this["additional_rg"].name == "additional-rg-exemption"
    error_message = "Additional RG exemption name should be 'additional-rg-exemption'"
  }

  assert {
    condition     = azurerm_resource_group_policy_exemption.this["additional_rg"].resource_group_id == azurerm_resource_group.user_specified["additional"].id
    error_message = "Additional RG exemption should be applied to the user-specified resource group"
  }

  # Test that output is correctly set
  assert {
    condition     = output.policy_exemptions["minimum"].name == "minimum-exemption"
    error_message = "Output should contain the minimum exemption"
  }

  assert {
    condition     = output.policy_exemptions["maximum"].name == "maximum-exemption"
    error_message = "Output should contain the maximum exemption"
  }

  assert {
    condition     = output.policy_exemptions["additional_rg"].name == "additional-rg-exemption"
    error_message = "Output should contain the additional_rg exemption"
  }
}
