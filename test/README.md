# Terraform Station Tests

## Overview

This folder contains all tests for the Terraform Station module. The aim is to simplify the development and testing process for contributors.

## How It Works

1. **Terraform Cloud (TFC) Project Creation**: The process begins by creating a TFC project. This project's name should match the value set in the `TF_VAR_tfc_project_name` environment variable. It's recommended to use a name like `station-tests`.

2. **Workspace and Resource Creation**: For each test (files ending with `_test.tf`), a new workspace is created, and the defined Azure and/or Entra ID resources are provisioned.

## Prerequisites

- Azure CLI installed and configured
- Terraform CLI installed
- Access to a Terraform Cloud account and an Azure subscription

## How to Run Tests

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
   Replace empty strings with appropriate values for your environment.
    ```bash
    export TFE_ORGANIZATION=""
    export TF_VAR_tfc_organization_name=""
    export TF_VAR_tfc_project_name=""
    export TF_VAR_tenant_id=""
    export TF_VAR_subscription_id=""
    ```

4. **Plan and Apply**:
    ```bash
    terraform plan -out=plan.tfplan -input=false
    terraform apply plan.tfplan
    ```

5. **Clean Up**:
   Destroy resources after testing is completed.
    ```bash
    terraform destroy
    ```

6. **Tips**
   You can also test each module separately by running `terraform plan -target module.module_you_want_to_test`

## Testing Approach for New Features in the Station Module

When adding new features to the Station module, it's crucial to validate their functionality. Contributors should create tests that encompass at least two fundamental configurations:

1. **Minimal Configuration**: Focus on the core functionality of the feature by using only the essential parameters. This configuration aims to verify that the feature works with the bare minimum setup.

2. **Maximum Configuration**: Expand the test to include all possible parameters. This approach is designed to showcase the feature's full capabilities and ensures compatibility with a wide range of options and settings.

### Additional Configurations

- **Scenario-Specific Tests**: If the feature includes multiple optional values that cannot all be used simultaneously or has different modes of operation, create additional test configurations to cover these scenarios. 
- **Combination Tests**: For features with parameters that interact in complex ways, design tests that combine these parameters in various forms. This helps in understanding the interactions and dependencies between different options.

### Example Test Case Structure

```hcl
module "station-new-feature" {
  depends_on      = [tfe_project.test]
  source          = "./.."
  tenant_id       = ""
  subscription_id = ""

  tfe = {
    project_name          = tfe_project.test.name
    organization_name     = data.tfe_organization.test.name
    workspace_description = "This workspace contains groups_tests from https://github.com/blinqas/station.git"
    workspace_name        = "station-tests-role_definitions"
  }

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
Use this structure as a template when adding tests for new functionalities to ensure both basic and advanced use cases are covered.
