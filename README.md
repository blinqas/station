> NOTE! The following has been generated by ChatGPT.

# Station Terraform Module

The "Station" Terraform module is designed to simplify the setup of various resources related to Azure deployments and access management. It provides a streamlined way to define and configure applications, identity assignments, resource groups, and more.

## Table of Contents

- [Prerequisites](#prerequisites)
- [Environment variables](#environment-variables)
- [Usage](#usage)
  - [Module Configuration](#module-configuration)
  - [Output Values](#output-values)
- [Contributing](#contributing)
- [License](#license)
- [Contact](#contact)

## Prerequisites

Before using this module, ensure you have the following prerequisites:

- [Terraform](https://www.terraform.io/) installed on your local machine.
- An [Azure account](https://azure.com) and valid credentials for resource provisioning.

### Environment Variables

| Name | Description | Comment |
| ---- | ----------- | ------- |
| TFE_ORGANIZATION | The default organization that resources should belong to. If provided, it's usually possible to omit resource-specific organization arguments. Ensure that the organization already exists prior to using this argument | N/A |
| TFE_TOKEN | Token to use for authentication with the tfe provider | https://registry.terraform.io/providers/hashicorp/tfe/latest/docs#authentication

### To run in Terraform Cloud you need the following enviornment variables

| Name | Description | Comment |
| ---- | ----------- | ------- |
| ARM_SUBSCRIPTION_ID | The default organization that resources should belong to. If provided, it's usually possible to omit resource-specific organization arguments. Ensure that the organization already exists prior to using this argument | N/A |
| ARM_TENANT_ID | Token to use for authentication with the tfe provider | https://registry.terraform.io/providers/hashicorp/tfe/latest/docs#authentication
| TFC_AZURE_PROVIDER_AUTH | true/false if authenticating using OIDC | When bootstrapping with the provided bootstrap folder, set to true | 
| TFC_AZURE_RUN_CLIENT_ID | Client ID of the identity to execute with |


## Usage


### Module Configuration

To use the "Station" module, you need to include it in your Terraform configuration. Here's an example snippet of how you can configure the module:

```hcl
module "station" {
  source = "path/to/module"

  # Customize module settings here
}
```

#### Configuration Parameters

- `environment_name`: The name of the environment (e.g., "dev").
- `role_definition_name_on_workload_rg`: The role definition name for the workload resource group.
- `user_assigned_identities`: Define user-assigned identities and their associated role assignments.
- `resource_groups`: Configure resource groups and their locations.
- `federated_identity_credential_config`: Configuration for federated identity credentials.
- `tags`: Tags to be applied to resources.
- `groups`: Configure security groups and their settings.
- `applications`: Configure applications, their settings, and permissions.
- `tfe`: Configure Terraform Cloud

### Output Values

- `client_id`: The Client ID of the workload Azure AD service principal.
- `workload_service_principal_object_id`: The Object ID of the workload Azure AD service principal.
- `tenant_id`: The Azure AD Tenant ID.
- `subscription_id`: The Azure Subscription ID.
- `workload_resource_group_name`: The name of the resource group where workload resources are located.
- `applications`: A map of configured applications, their settings, and permissions.
- `groups`: A map of configured security groups and their settings.
- `user_assigned_identities`: A map of configured user-assigned identities and their associated role assignments.
- `tfe`: Terraform Cloud configration. Create workspaces, link project and set up vcs connections.

## Contributing

We welcome contributions from the community! If you'd like to contribute to this module, please follow our [contribution guidelines](CONTRIBUTING.md).

## License

This project is licensed under the [MIT License](LICENSE).

## Contact

For questions, support, or collaboration, feel free to contact the owner of this repository: Kim

