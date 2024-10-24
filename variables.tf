variable "tenant_id" {
  type        = string
  description = "(Required) The Entra ID tenant ID used by the caller."
}

variable "subscription_id" {
  type        = string
  description = "(Required) The Azure subscription ID used by the caller."
}

variable "default_location" {
  description = "The name of the default location to deploy workload resources to."
  default     = "norwayeast"
  type        = string
}

variable "environment_name" {
  description = "The name of the deployment environment for the workload. Ex: dev/staging/production"
  default     = "dev"
  type        = string
}

variable "resource_group_name" {
  description = <<EOF
    The name of the workload resource group. The final name is prefixed with `rg-`.

    If a value is not provided, Station will set the name to `rg-var.tfe.workspace_name-var.environment_name`
  EOF
  default     = null
  type        = string
}

variable "managed_identity_name" {
  description = <<EOF
    The name of the managed identity (identity provided to the workload) that is created. The final name is prefixed with `mi-`.

    If a value is not provided, Station will set the name to `mi-var.tfe.workspace_name-var.environment_name`
  EOF
  default     = null
  type        = string
}

variable "app_role_assignments" {
  description = <<EOF
    (Optional) A set of azuread_app_role_assignment resources to assign to the workload identity. Only built-in application roles are supported.

    Example:
    ```hcl
    app_role_assignments = [
      "IdentityRiskEvent.ReadWrite.All",
      "IdentityRiskEvent.Read.All"
    ]
    ```
  EOF
  default     = []
  type        = set(string)
}

variable "role_definition_name_on_workload_rg" {
  description = "The name of an in-built role to assign the workload identity on the workload resource group"
  default     = "Owner"
  type        = string
}

variable "resource_groups" {
  description = "Map of resource groups to create"
  default     = {}
  type = map(object({
    name     = string
    location = optional(string)
    tags     = optional(map(string))
  }))
}

variable "federated_identity_credential_config" {
  description = "Map of Federated Credentials to create on the workload identity"
  default     = {}
  type = map(object({
    display_name = string
    description  = optional(string)
    audiences    = list(string)
    issuer       = string
    subject      = string
  }))
}

variable "tags" {
  description = <<EOF
    Tags to merge with the default tags configured by Station.

    Station configures the following map in tags.tf:
    {
      "station-id"  = random_id.workload.hex
      "environment" = var.environment_name
    }
  EOF
  default     = {}
  type        = map(string)
}

variable "applications" {
  description = <<EOT
  Map of applications to create. The body of each object is more or less identical to azuread_application 
  with the exception of map usage instead of blocks (as blocks are impossible to define with HCL)
  EOT
  default     = {}
  type = map(object({
    display_name                   = string
    owners                         = optional(list(string))
    logo_image                     = optional(string) #Base64 encoded image
    sign_in_audience               = optional(string)
    group_membership_claims        = optional(list(string))
    identifier_uris                = optional(list(string))
    prevent_duplicate_names        = optional(bool)
    fallback_public_client_enabled = optional(bool)
    notes                          = optional(string) #This can be used as description for the application. 1024 character limit.

    single_page_application = optional(object({
      redirect_uris = optional(list(string))
    }))

    api = optional(object({
      known_client_applications      = optional(list(string))
      mapped_claims_enabled          = optional(bool)
      requested_access_token_version = optional(number)

      oauth2_permission_scope = optional(list(object({
        admin_consent_description  = string
        admin_consent_display_name = string
        id                         = string
        enabled                    = optional(bool)
        type                       = optional(string)
        user_consent_description   = optional(string)
        user_consent_display_name  = optional(string)
        value                      = string
      })))
    }))

    public_client = optional(object({
      redirect_uris = optional(set(string))
    }))

    required_resource_access = optional(set(object({
      resource_app_id = string
      resource_access = map(object({
        id   = string
        type = string
      }))
    })))

    optional_claims = optional(object({
      access_token = optional(set(object({
        name                  = string
        source                = optional(string)
        essential             = optional(bool)
        additional_properties = optional(list(string))
      })))
      id_token = optional(set(object({
        name                  = string
        source                = optional(string)
        essential             = optional(bool)
        additional_properties = optional(list(string))
      })))
      saml2_token = optional(set(object({
        name                  = string
        source                = optional(string)
        essential             = optional(bool)
        additional_properties = optional(list(string))
      })))
    }))

    web = optional(object({
      homepage_url  = optional(string)
      logout_url    = optional(string)
      redirect_uris = optional(set(string))
      implicit_grant = optional(object({
        access_token_issuance_enabled = optional(bool)
        id_token_issuance_enabled     = optional(bool)
      }))
    }))

    service_principal = optional(object({
      account_enabled               = optional(bool, true)
      alternative_names             = optional(list(string))
      app_role_assignment_required  = optional(bool, false)
      description                   = optional(string)
      login_url                     = optional(string)
      notes                         = optional(string)
      notification_email_addresses  = optional(list(string))
      owners                        = optional(list(string))
      preferred_single_sign_on_mode = optional(string)
      tags                          = optional(list(string))
      use_existing                  = optional(bool, false)

      feature_tags = optional(object({
        custom_single_sign_on = optional(bool, false)
        enterprise            = optional(bool, false)
        gallery               = optional(bool, false)
        hide                  = optional(bool, false)
      }))

      saml_single_sign_on = optional(object({
        relay_state = optional(string)
      }))
    }))
  }))
}

variable "groups" {
  description = <<-EOF
    (Optional) Map of Entra ID (Azure AD) groups to create
    Note: The workload identity is automatically assigned the App Role "User.ReadBasic.All" and "Group.Read.All"
          because being "Owner" of the group is not sufficient to add principals and then list them after an add or delete operation.
  EOF
  default     = {}
  type = map(object({
    display_name     = string
    description      = optional(string)
    owners           = optional(list(string))
    members          = optional(set(string))
    security_enabled = optional(bool)
    mail_enabled     = optional(bool)
    types            = optional(set(string))
    dynamic_membership = optional(object({
      enabled = bool
      rule    = string
    }))
    role_assignments = optional(map(object({
      name                             = optional(string)
      scope                            = optional(string)
      role_definition_id               = optional(string)
      role_definition_name             = optional(string)
      condition                        = optional(string)
      condition_version                = optional(string)
      description                      = optional(string)
      skip_service_principal_aad_check = optional(bool)
    })))
  }))
}



variable "user_assigned_identities" {
  description = <<EOF
  User Assigned Identities to create."

  Example:

  user_assigned_identities = {
    my_app = {
      name                = "uai-my-identity"
      resource_group_name = "rg-name"
      location            = "norwayeast"
      app_role_assignments    = ["IdentityRiskEvent.ReadWrite.All"]
      group_memberships = {
        "Kubernetes Administrators" = azuread_group.k8s_admins.object_id
      }
    }
  }
  EOF
  default     = {}
  type = map(object({
    name                 = string
    resource_group_name  = optional(string)
    location             = optional(string)
    app_role_assignments = optional(set(string))
    role_assignments = optional(map(object({
      name                                   = optional(string)
      scope                                  = string
      role_definition_id                     = optional(string)
      role_definition_name                   = optional(string)
      assign_to_workload_principal           = optional(bool)
      condition                              = optional(string)
      condition_version                      = optional(string)
      delegated_managed_identity_resource_id = optional(string)
      description                            = optional(string)
      skip_service_principal_aad_check       = optional(bool)
    })))
    group_memberships = optional(map(string))
  }))
}


variable "tfe" {
  description = <<EOF
  Terraform Cloud configuration for the workload environment

  - tfe.create_federated_identity_credential configures Federated Credentials on the workload identity for plan and apply phases.
  - Either of tfe.vcs_repo.(oauth_token_id|github_app_installation_id) must be provided, both can not be used at the same time.
  - tfe.workspace_env_vars lets you configure Environment Variables for the Terraform Cloud runtime environment
  - tfe.workspace_vars lets you configure Terraform variables
  - tfe.module_outputs_to_workspace_var.(groups|applications|user_assigned_identities) sets output from the respective 
    resource into respective Terraform variables on the Terraform Cloud workspace. Useful when you need group object ids
    for the groups Station Deployments provisioned in your workload environment.
  EOF
  default     = null
  type = object({
    organization_name                    = string
    project_name                         = string
    workspace_name                       = string
    workspace_description                = string
    create_federated_identity_credential = optional(bool)
    file_triggers_enabled                = optional(bool)
    vcs_repo = optional(object({
      identifier                 = string
      branch                     = optional(string)
      ingress_submodules         = optional(string)
      oauth_token_id             = optional(string)
      github_app_installation_id = optional(string)
      tags_regex                 = optional(string)
    }))
    workspace_env_vars = optional(map(object({
      value       = string
      category    = string
      description = string
      sensitive   = optional(bool, false)
    })))
    workspace_vars = optional(map(object({
      value       = any
      category    = string
      description = string
      hcl         = optional(bool, false)
      sensitive   = optional(bool, false)
    })))
    module_outputs_to_workspace_var = optional(object({
      groups                   = optional(bool)
      applications             = optional(bool)
      user_assigned_identities = optional(bool)
      resource_groups          = optional(bool)
      role_definitions         = optional(bool)
    }))
  })
}

variable "group_membership" {
  description = <<EOF
  Map of group object ids the workload identity should be member of.

  Example:

  group_membership = {
    "Kubernetes Administrators" = azuread_group.k8s_admins.object_id
  }
  EOF
  default     = {}
  type        = map(string)
}

variable "role_assignment" {
  description = <<EOF
    Map of role_assignments to create. Be careful of who is allowed to provision role_assignments, you might want to 
    consider Sentinel policies in TFC.

    - assign_to_workload_principal assigns the role to the workload identity. Can not be used with principal_id.
  EOF
  default     = {}
  type = map(object({
    name                                   = optional(string)
    scope                                  = string
    role_definition_id                     = optional(string)
    role_definition_name                   = optional(string)
    principal_id                           = optional(string)
    assign_to_workload_principal           = optional(bool)
    condition                              = optional(string)
    condition_version                      = optional(string)
    delegated_managed_identity_resource_id = optional(string)
    description                            = optional(string)
    skip_service_principal_aad_check       = optional(bool)
  }))
}