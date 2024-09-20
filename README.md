# Station Terraform Module

Station is a Terraform module that lets you quickly spin up new workload environments in Azure and Terraform Cloud. Station gives you a high level of automation for workload environment provisioning.

- Station is maintained by the DevOps team at blinQ (https://blinq.no).
- See the [terraform-docs.md]() file for `terraform-docs` generated documentation.
- Check out our Design Decision document [here.](https://github.com/blinqas/station/blob/trunk/DESIGN_DESICIONS.md)

## Why does Station exist?

To quickly enable users to deploy workload environments in Azure. Isolating Entra ID and Azure Subscription interactions from the actual workload environment. Station consists of three parts; bootstrap, deployments and workload environment.

- Bootstrap: setting up a Station for your Azure subscription(s) and tenant. (Administrator with permissions on Subscription and Entra ID/Azure AD)
- Deployments: Where workload environments are defined and deployed. (Application Team/DevOps/SRE/Platform Engineer/Cloud Engineer)
- Workload Environment: The workload environment where infrastructure is deployed to. (Application Team)

Station was designed with isolation in mind. We want our environments to work with least-privilege principle. That's why your workload identity is restricted to permissions inside its own resource group(s). The module is highly flexible and also support Cloud Adoption Framework-like modularization. See our COMING! examples folder for more!

## Who uses Station? 

Station is used primarily in context of application development and hosting; DevOps, GitOps, SRE's or Platform Engineers. There is nothing wrong with using Station in operations; we encourage it!

---

### Requirements

- Terraform Cloud account
    - Permission to create Team Token
- Azure- Tenant and Subscription
    - Global Administrator on Azure AD
    - Owner on Subscription

## Usage

The following example deploys a workload environment for common resources, in this environment we would deploy Container Registries for example.

Consider the following file structure:

```bash
common.tf
github_repositories.tf
tags.tf
variables.tf
```

```terraform
# filename: common.tf
module "common" {
  source              = "git::https://github.com/blinqas/station.git?ref=1.3.0"
  tenant_id           = var.tenant_id
  subscription_id     = var.subscription_id
  environment_name    = "prod"
  resource_group_name = "common"
  tags                = local.tags.common
  tfe = {
    organization_name     = "my-tfc-organization"
    project_name          = "Azure"
    workspace_name        = "common"
    workspace_description = "Common resources which are shared between workloads."
    vcs_repo = {
      identifier     = github_repository.repos["common"].full_name
      branch         = "trunk"
      oauth_token_id = var.vcs_repo_oauth_token_id
    }
  }
}
```

This file would provision the following:

- Resource Group
- Managed Identity
    - Service Principal is assigned Owner on Resource Group
- Federated Credential (OIDC to authenticate Terraform Cloud runners)
- Terraform Cloud (TFC) Workspace
    - Configured to run on commits to trunk branch
    - Configured to authenticate to VCS with token already in Terraform Cloud
- TFC Environment Variables for OIDC authentication with Managed Identity

---

## Contact

- Kim Iversen | [kim.iversen@blinq.no](mailto:kim.iversen@blinq.no)
- Sander Blomvågnes | [sander@blinq.no](mailto:sander@blinq.no)
- Erik Hansen | [erik.hansen@blinq.no](mailto:erik.hansen@blinq.no)

## License

MIT

## terraform-docs

<details>
<summary>Click to view `terraform-docs`</summary>

<!-- BEGIN_TF_DOCS -->
## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_app_role_assignments"></a> [app\_role\_assignments](#input\_app\_role\_assignments) | (Optional) A set of azuread\_app\_role\_assignment resources to assign to the workload identity. Only built-in application roles are supported.<br><br>    Example:<pre>hcl<br>    app_role_assignments = [<br>      "IdentityRiskEvent.ReadWrite.All",<br>      "IdentityRiskEvent.Read.All"<br>    ]</pre> | `set(string)` | `[]` | no |
| <a name="input_applications"></a> [applications](#input\_applications) | Map of applications to create. The body of each object is more or less identical to azuread\_application <br>  with the exception of map usage instead of blocks (as blocks are impossible to define with HCL) | <pre>map(object({<br>    display_name                   = string<br>    owners                         = optional(list(string))<br>    logo_image                     = optional(string) #Base64 encoded image<br>    sign_in_audience               = optional(string)<br>    group_membership_claims        = optional(list(string))<br>    identifier_uris                = optional(list(string))<br>    prevent_duplicate_names        = optional(bool)<br>    fallback_public_client_enabled = optional(bool)<br>    notes                          = optional(string) #This can be used as description for the application. 1024 character limit.<br><br>    single_page_application = optional(object({<br>      redirect_uris = optional(list(string))<br>    }))<br><br>    api = optional(object({<br>      known_client_applications      = optional(list(string))<br>      mapped_claims_enabled          = optional(bool)<br>      requested_access_token_version = optional(number)<br><br>      oauth2_permission_scope = optional(list(object({<br>        admin_consent_description  = string<br>        admin_consent_display_name = string<br>        id                         = string<br>        enabled                    = optional(bool)<br>        type                       = optional(string)<br>        user_consent_description   = optional(string)<br>        user_consent_display_name  = optional(string)<br>        value                      = string<br>      })))<br>    }))<br><br>    public_client = optional(object({<br>      redirect_uris = optional(set(string))<br>    }))<br><br>    required_resource_access = optional(set(object({<br>      resource_app_id = string<br>      resource_access = map(object({<br>        id   = string<br>        type = string<br>      }))<br>    })))<br><br>    optional_claims = optional(object({<br>      access_token = optional(set(object({<br>        name                  = string<br>        source                = optional(string)<br>        essential             = optional(bool)<br>        additional_properties = optional(list(string))<br>      })))<br>      id_token = optional(set(object({<br>        name                  = string<br>        source                = optional(string)<br>        essential             = optional(bool)<br>        additional_properties = optional(list(string))<br>      })))<br>      saml2_token = optional(set(object({<br>        name                  = string<br>        source                = optional(string)<br>        essential             = optional(bool)<br>        additional_properties = optional(list(string))<br>      })))<br>    }))<br><br>    web = optional(object({<br>      homepage_url  = optional(string)<br>      logout_url    = optional(string)<br>      redirect_uris = optional(set(string))<br>      implicit_grant = optional(object({<br>        access_token_issuance_enabled = optional(bool)<br>        id_token_issuance_enabled     = optional(bool)<br>      }))<br>    }))<br><br>    service_principal = optional(object({<br>      account_enabled               = optional(bool, true)<br>      alternative_names             = optional(list(string))<br>      app_role_assignment_required  = optional(bool, false)<br>      description                   = optional(string)<br>      login_url                     = optional(string)<br>      notes                         = optional(string)<br>      notification_email_addresses  = optional(list(string))<br>      owners                        = optional(list(string))<br>      preferred_single_sign_on_mode = optional(string)<br>      tags                          = optional(list(string))<br>      use_existing                  = optional(bool, false)<br><br>      feature_tags = optional(object({<br>        custom_single_sign_on = optional(bool, false)<br>        enterprise            = optional(bool, false)<br>        gallery               = optional(bool, false)<br>        hide                  = optional(bool, false)<br>      }))<br><br>      saml_single_sign_on = optional(object({<br>        relay_state = optional(string)<br>      }))<br>    }))<br>  }))</pre> | `{}` | no |
| <a name="input_default_location"></a> [default\_location](#input\_default\_location) | The name of the default location to deploy workload resources to. | `string` | `"norwayeast"` | no |
| <a name="input_environment_name"></a> [environment\_name](#input\_environment\_name) | The name of the deployment environment for the workload. Ex: dev/staging/production | `string` | `"dev"` | no |
| <a name="input_federated_identity_credential_config"></a> [federated\_identity\_credential\_config](#input\_federated\_identity\_credential\_config) | Map of Federated Credentials to create on the workload identity | <pre>map(object({<br>    display_name = string<br>    description  = optional(string)<br>    audiences    = list(string)<br>    issuer       = string<br>    subject      = string<br>  }))</pre> | `{}` | no |
| <a name="input_group_membership"></a> [group\_membership](#input\_group\_membership) | Map of group object ids the workload identity should be member of.<br><br>  Example:<br><br>  group\_membership = {<br>    "Kubernetes Administrators" = azuread\_group.k8s\_admins.object\_id<br>  } | `map(string)` | `{}` | no |
| <a name="input_groups"></a> [groups](#input\_groups) | (Optional) Map of Entra ID (Azure AD) groups to create<br>Note: The workload identity is automatically assigned the App Role "User.ReadBasic.All"<br>      because being "Owner" of the group is not sufficient to add principals. | <pre>map(object({<br>    display_name     = string<br>    description      = optional(string)<br>    owners           = optional(list(string))<br>    members          = optional(set(string))<br>    security_enabled = optional(bool)<br>    mail_enabled     = optional(bool)<br>    types            = optional(set(string))<br>    dynamic_membership = optional(object({<br>      enabled = bool<br>      rule    = string<br>    }))<br>    role_assignments = optional(map(object({<br>      name                             = optional(string)<br>      scope                            = optional(string)<br>      role_definition_id               = optional(string)<br>      role_definition_name             = optional(string)<br>      condition                        = optional(string)<br>      condition_version                = optional(string)<br>      description                      = optional(string)<br>      skip_service_principal_aad_check = optional(bool)<br>    })))<br>  }))</pre> | `{}` | no |
| <a name="input_managed_identity_name"></a> [managed\_identity\_name](#input\_managed\_identity\_name) | The name of the managed identity (identity provided to the workload) that is created. The final name is prefixed with `mi-`.<br><br>    If a value is not provided, Station will set the name to `mi-var.tfe.workspace_name-var.environment_name` | `string` | `null` | no |
| <a name="input_resource_group_name"></a> [resource\_group\_name](#input\_resource\_group\_name) | The name of the workload resource group. The final name is prefixed with `rg-`.<br><br>    If a value is not provided, Station will set the name to `rg-var.tfe.workspace_name-var.environment_name` | `string` | `null` | no |
| <a name="input_resource_groups"></a> [resource\_groups](#input\_resource\_groups) | Map of resource groups to create | <pre>map(object({<br>    name     = string<br>    location = optional(string)<br>    tags     = optional(map(string))<br>  }))</pre> | `{}` | no |
| <a name="input_role_assignment"></a> [role\_assignment](#input\_role\_assignment) | Map of role\_assignments to create. Be careful of who is allowed to provision role\_assignments, you might want to <br>    consider Sentinel policies in TFC.<br><br>    - assign\_to\_workload\_principal assigns the role to the workload identity. Can not be used with principal\_id. | <pre>map(object({<br>    name                                   = optional(string)<br>    scope                                  = string<br>    role_definition_id                     = optional(string)<br>    role_definition_name                   = optional(string)<br>    principal_id                           = optional(string)<br>    assign_to_workload_principal           = optional(bool)<br>    condition                              = optional(string)<br>    condition_version                      = optional(string)<br>    delegated_managed_identity_resource_id = optional(string)<br>    description                            = optional(string)<br>    skip_service_principal_aad_check       = optional(bool)<br>  }))</pre> | `{}` | no |
| <a name="input_role_definition_name_on_workload_rg"></a> [role\_definition\_name\_on\_workload\_rg](#input\_role\_definition\_name\_on\_workload\_rg) | The name of an in-built role to assign the workload identity on the workload resource group | `string` | `"Owner"` | no |
| <a name="input_role_definitions"></a> [role\_definitions](#input\_role\_definitions) | Map of Role Definitions to create.<br><br>    See https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/role_definition <br>    for documentation. | <pre>map(object({<br>    role_definition_id = optional(string)<br>    name               = string<br>    scope              = optional(string) #Sets scope to current subscription if empty<br>    description        = optional(string)<br>    permissions = optional(object({<br>      actions          = optional(list(string))<br>      data_actions     = optional(list(string))<br>      not_actions      = optional(list(string))<br>      not_data_actions = optional(list(string))<br>    }))<br>    assignable_scopes = optional(list(string))<br>  }))</pre> | `{}` | no |
| <a name="input_subscription_id"></a> [subscription\_id](#input\_subscription\_id) | (Required) The Azure subscription ID used by the caller. | `string` | n/a | yes |
| <a name="input_tags"></a> [tags](#input\_tags) | Tags to merge with the default tags configured by Station.<br><br>    Station configures the following map in tags.tf:<br>    {<br>      "station-id"  = random\_id.workload.hex<br>      "environment" = var.environment\_name<br>    } | `map(string)` | `{}` | no |
| <a name="input_tenant_id"></a> [tenant\_id](#input\_tenant\_id) | (Required) The Entra ID tenant ID used by the caller. | `string` | n/a | yes |
| <a name="input_tfe"></a> [tfe](#input\_tfe) | Terraform Cloud configuration for the workload environment<br><br>  - tfe.create\_federated\_identity\_credential configures Federated Credentials on the workload identity for plan and apply phases.<br>  - Either of tfe.vcs\_repo.(oauth\_token\_id\|github\_app\_installation\_id) must be provided, both can not be used at the same time.<br>  - tfe.workspace\_env\_vars lets you configure Environment Variables for the Terraform Cloud runtime environment<br>  - tfe.workspace\_vars lets you configure Terraform variables<br>  - tfe.module\_outputs\_to\_workspace\_var.(groups\|applications\|user\_assigned\_identities) sets output from the respective <br>    resource into respective Terraform variables on the Terraform Cloud workspace. Useful when you need group object ids<br>    for the groups Station Deployments provisioned in your workload environment. | <pre>object({<br>    organization_name                    = string<br>    project_name                         = string<br>    workspace_name                       = string<br>    workspace_description                = string<br>    create_federated_identity_credential = optional(bool)<br>    file_triggers_enabled                = optional(bool)<br>    vcs_repo = optional(object({<br>      identifier                 = string<br>      branch                     = optional(string)<br>      ingress_submodules         = optional(string)<br>      oauth_token_id             = optional(string)<br>      github_app_installation_id = optional(string)<br>      tags_regex                 = optional(string)<br>    }))<br>    workspace_env_vars = optional(map(object({<br>      value       = string<br>      category    = string<br>      description = string<br>      sensitive   = optional(bool, false)<br>    })))<br>    workspace_vars = optional(map(object({<br>      value       = any<br>      category    = string<br>      description = string<br>      hcl         = optional(bool, false)<br>      sensitive   = optional(bool, false)<br>    })))<br>    module_outputs_to_workspace_var = optional(object({<br>      groups                   = optional(bool)<br>      applications             = optional(bool)<br>      user_assigned_identities = optional(bool)<br>      resource_groups          = optional(bool)<br>      role_definitions         = optional(bool)<br>    }))<br>  })</pre> | `null` | no |
| <a name="input_user_assigned_identities"></a> [user\_assigned\_identities](#input\_user\_assigned\_identities) | User Assigned Identities to create."<br><br>  Example:<br><br>  user\_assigned\_identities = {<br>    my\_app = {<br>      name                = "uai-my-identity"<br>      resource\_group\_name = "rg-name"<br>      location            = "norwayeast"<br>      app\_role\_assignments    = ["IdentityRiskEvent.ReadWrite.All"]<br>      group\_memberships = {<br>        "Kubernetes Administrators" = azuread\_group.k8s\_admins.object\_id<br>      }<br>    }<br>  } | <pre>map(object({<br>    name                 = string<br>    resource_group_name  = optional(string)<br>    location             = optional(string)<br>    app_role_assignments = optional(set(string))<br>    role_assignments = optional(map(object({<br>      name                                   = optional(string)<br>      scope                                  = string<br>      role_definition_id                     = optional(string)<br>      role_definition_name                   = optional(string)<br>      assign_to_workload_principal           = optional(bool)<br>      condition                              = optional(string)<br>      condition_version                      = optional(string)<br>      delegated_managed_identity_resource_id = optional(string)<br>      description                            = optional(string)<br>      skip_service_principal_aad_check       = optional(bool)<br>    })))<br>    group_memberships = optional(map(string))<br>  }))</pre> | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_applications"></a> [applications](#output\_applications) | n/a |
| <a name="output_client_id"></a> [client\_id](#output\_client\_id) | n/a |
| <a name="output_groups"></a> [groups](#output\_groups) | n/a |
| <a name="output_resource_group"></a> [resource\_group](#output\_resource\_group) | n/a |
| <a name="output_resource_groups_user_specified"></a> [resource\_groups\_user\_specified](#output\_resource\_groups\_user\_specified) | n/a |
| <a name="output_role_definitions"></a> [role\_definitions](#output\_role\_definitions) | n/a |
| <a name="output_subscription_id"></a> [subscription\_id](#output\_subscription\_id) | n/a |
| <a name="output_tenant_id"></a> [tenant\_id](#output\_tenant\_id) | n/a |
| <a name="output_tfe"></a> [tfe](#output\_tfe) | n/a |
| <a name="output_user_assigned_identities"></a> [user\_assigned\_identities](#output\_user\_assigned\_identities) | n/a |
| <a name="output_workload_resource_group_name"></a> [workload\_resource\_group\_name](#output\_workload\_resource\_group\_name) | n/a |
| <a name="output_workload_service_principal_object_id"></a> [workload\_service\_principal\_object\_id](#output\_workload\_service\_principal\_object\_id) | n/a |
<!-- END_TF_DOCS -->
</details>
