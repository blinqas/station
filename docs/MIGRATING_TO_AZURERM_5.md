# Migrating Station to AzureRM 5

Station requires AzureRM 5.x. This guide covers the AzureRM 5 changes that affect resources managed by Station and the actions required in consuming root modules.

## Required consumer changes

Update the AzureRM constraint in the root module that calls Station, then refresh its dependency lock file:

```hcl
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 5.0"
    }
  }
}
```

```shell
terraform init -upgrade
terraform plan
```

Review the first plan before applying it. AzureRM 5 changed the subnet service endpoint state shape, so existing subnets with service endpoints can show an in-place update.

### Resource provider registration

AzureRM 5 changed `resource_provider_registrations` from `legacy` to `none` by default. Station is a reusable module and does not configure providers, so registration remains the responsibility of the consuming root module and must be handled for every subscription used by a provider configuration.

The default Station provider can use these resource providers:

- `Microsoft.Authorization`
- `Microsoft.ManagedIdentity`
- `Microsoft.Network`
- `Microsoft.Resources`

The `azurerm.connectivity` alias can use `Microsoft.Network` in its configured connectivity subscription.

Prefer pre-registering the required providers or explicitly registering only the required namespaces:

```hcl
provider "azurerm" {
  subscription_id = var.subscription_id
  resource_providers_to_register = [
    "Microsoft.Authorization",
    "Microsoft.ManagedIdentity",
    "Microsoft.Network",
    "Microsoft.Resources",
  ]

  features {}
}

provider "azurerm" {
  alias           = "connectivity"
  subscription_id = var.connectivity_subscription_id
  resource_providers_to_register = [
    "Microsoft.Network",
  ]

  features {}
}
```

To temporarily retain the AzureRM 4 registration set instead, set `resource_provider_registrations = "legacy"`. This requires the caller to have permission to register those providers and can register more namespaces than Station needs.

### Other provider configuration changes

AzureRM 5 removed `skip_provider_registration`. Replace `skip_provider_registration = true` with `resource_provider_registrations = "none"`.

The top-level `enhanced_validation` block moved inside `features`, and location and resource-provider validation now default to disabled. Callers that relied on AzureRM 4 plan-time validation can retain it with:

```hcl
provider "azurerm" {
  features {
    enhanced_validation {
      locations          = true
      resource_providers = true
    }
  }
}
```

The combined `ARM_PROVIDER_ENHANCED_VALIDATION` environment variable was removed. Use the corresponding `ARM_PROVIDER_ENHANCED_VALIDATION_LOCATIONS` and `ARM_PROVIDER_ENHANCED_VALIDATION_RESOURCE_PROVIDERS` variables if provider configuration is managed through the environment.

## Station compatibility changes

AzureRM 5 removed `azurerm_subnet.service_endpoints` and replaced it with repeatable `service_endpoint` blocks. Station keeps its existing consumer-facing `service_endpoints = set(string)` input and translates it internally, so Station callers do not need to change their connectivity objects.

Station also preserves `service_endpoints` on its `subnets` module output and generated Terraform Cloud `subnets` variable. The AzureRM 5 `service_endpoint` block remains available alongside that compatibility attribute.

The deprecated `azurerm_federated_identity_credential.parent_id` argument was also removed. Station uses `user_assigned_identity_id`, which is the AzureRM 5 argument.

The remaining AzureRM resources and data sources used by Station have no breaking schema changes listed in the AzureRM 5 upgrade guide. Their v4.81.0 and v5.0.1 schemas were also compared during this upgrade.

## Known AzureRM 5.0.1 subnet issue

AzureRM 5.0.1 models `service_endpoint` as an ordered list, while Azure does not guarantee response ordering. Configurations with multiple service endpoints can therefore show a persistent in-place diff even after apply. This is an upstream provider regression, not a difference Station can safely suppress.

As of 7 August 2026, the provider issue and fix are still open:

- [Service endpoint removal without prior deprecation](https://github.com/hashicorp/terraform-provider-azurerm/issues/32909)
- [Subnet service endpoint ordering regression](https://github.com/hashicorp/terraform-provider-azurerm/issues/32951)
- [Pending provider fix changing the nested block to an unordered set](https://github.com/hashicorp/terraform-provider-azurerm/pull/32968)

If a deployment uses multiple endpoints, inspect the plan carefully and upgrade to the first AzureRM release containing the provider fix when it becomes available. Station's `~> 5.0` constraint permits that update.

## Primary references

- [AzureRM 5.0 upgrade guide](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/guides/5.0-upgrade-guide)
- [AzureRM provider configuration and resource provider registration](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs)
- [AzureRM 5.0.1 release notes](https://github.com/hashicorp/terraform-provider-azurerm/releases/tag/v5.0.1)
- [AzureRM 5 subnet documentation](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/subnet)
