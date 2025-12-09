# Terraform Station Tests

## Overview

This folder contains all tests for the Terraform Station module. The aim is to simplify the development and testing process for contributors.

## How It Works

1. **Terraform Cloud (TFC) Project Creation**: The tests are dependent on an existing TFC project so this should be created using the `setup-fte-project` module. This project's name should match the value set in the `TF_VARtfc_tfc_project_name` environment variable. It's recommended to use a name like `station-tests`.

2. **Workspace and Resource Creation**: For each test (files ending with `tftest.hcl`), a new workspace is created, and the defined Azure and/or Entra ID resources are provisioned.

## Prerequisites

- Azure CLI installed and configured
- Terraform CLI installed
- Access to a Terraform Cloud account and an Azure subscription

## How to Run Tests

### Running Tests Locally

1. **Login to Azure and Terraform**:
    ```bash
    az login --tenant YourTenantIdHere
    terraform login
    ```

2. **Initialize Terraform**:
    ```bash
    terraform init
    ```

3. **Set Environment Variables**:
   Replace empty strings with your TFC organization name.
    ```bash
    export TFE_ORGANIZATION=""
    export TF_VAR_tfc_organization_name=""
    export TF_VAR_tfc_project_name=""
    export TF_VAR_tenant_id=""
    export TF_VAR_subscription_id=""
    export ARM_SUBSCRIPTION_ID=""
    ```

4. **Starting the tests**:
    ```bash
    terraform test #This will run all the tests
    terraform test -filter=tests/tfe.tftest.hcl #This will only run the tests for the tfe block
    ```

### Automated Test Execution in CI/CD

The repository uses **selective test execution** to optimize CI/CD performance and reduce GitHub Actions minutes. Tests are automatically selected based on which files you've changed:

#### How It Works

When you create a pull request, the CI/CD pipeline analyzes your changes and runs only the tests affected by those changes:

- **Application module changes** (`application/**`, `variables.applications.tf`, `applications.tf`) → Runs `application.tftest.hcl`
- **Group module changes** (`group/**`, `groups.tf`) → Runs `group.tftest.hcl`
- **TFE module changes** (`hashicorp/tfe/**`, `tfe.tf`) → Runs `tfe.tftest.hcl`
- **Connectivity changes** (`connectivity.tf`) → Runs `connectivity.tftest.hcl`
- **Identity module changes** (`user_assigned_identity/**`, `variables.identity.tf`) → Runs `identity.tftest.hcl` and `user_assigned_identities.tftest.hcl`
- **Core infrastructure changes** (`variables.tf`, `providers.tf`, `resource_group.tf`, etc.) → Runs **all tests**

For full details on the mapping rules, see [`.github/scripts/README.md`](../.github/scripts/README.md).

#### Manual Full Test Execution

If you need to run all tests on a PR (for example, to verify everything works together), comment on the PR:

```
/test-all
```

or

```
/test all
```

The workflow will acknowledge your request with a 🚀 emoji and run all tests.

## Testing Approach for New Features in the Station Module

When adding new features to the Station module, it's crucial to validate their functionality. Contributors should create tests that encompass at least two fundamental configurations:

1. **Minimal Configuration**: Focus on the core functionality of the feature by using only the essential parameters. This configuration aims to verify that the feature works with the bare minimum setup.

2. **Maximum Configuration**: Expand the test to include all possible parameters. This approach is designed to showcase the feature's full capabilities and ensures compatibility with a wide range of options and settings.

### Additional Configurations

- **Scenario-Specific Tests**: If the feature includes multiple optional values that cannot all be used simultaneously or has different modes of operation, create additional test configurations to cover these scenarios. 
- **Combination Tests**: For features with parameters that interact in complex ways, design tests that combine these parameters in various forms. This helps in understanding the interactions and dependencies between different options.

### Example Test Case Structure

Add your required providers:
```hcl
provider "tfe" {}
provider "azurerm" {
  features {}
}
provider "azuread" {

}
```
Call the module like how you would use it but inside a variables block

```hcl
variables {
  tfe = {
    project_name                         = "name_matching_the_project_in_the_setup_block"
    organization_name                    = "Your_tfc_org_name"
    workspace_name                       = "tfe_test"
    workspace_description                = "Workspace description"
  }

  # Call you new_feature module
  new_feature = {
    # Minimal Configuration Example
    minimal = {
      required_param = "basic_value"
    },

    # Maximum Configuration Example
    maximum = {
      required_param = "value"
      optional_param1 = "advanced_value1"
      optional_param2 = "advanced_value2"
      ...
    },

    # Additional Scenario-Specific Configurations
    scenario_specific = {
      ...
    }
  }
}
```
Call the setup module that will create a test project for us in TFC. Ensure the project name is unique to the test your creating

```hcl
run "setup_create_tfc_test_project" {
  variables {
    project_name      = "tests_new_feature"
    organization_name = "Your_tfc_org_name"
  }
  module {
    source = "./tests/setup-tfe-project"
  }
}
``````
Create multiple `assert` or `expect_failures` blocks to validate that the required resources where created with the values we provided in the variable block.

```hcl
run "test_new_feature" {

  module {
    source = "./"
  }

  assert {
    condition     = module.new_feature.name == "Name you set in the variables block"
    error_message = "Some error message explaining why it failed"
  }

  assert {
    condition     = module.new_feature.someValue == true
    error_message = "Some error message explaining why it failed"
  }
  
}

```
Use this structure as a template when adding tests for new functionalities to ensure both basic and advanced use cases are covered.
