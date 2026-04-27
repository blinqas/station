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

variable "resource_group_name" {
  description = <<EOF
    The name of the workload resource group. The final name is prefixed with `rg-`.

    If a value is not provided, Station will set the name to `rg-var.tfe.workspace_name`
  EOF
  default     = null
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

variable "tags" {
  description = <<EOF
    Tags to merge with the default tags configured by Station.

    Station configures the following map in tags.tf:
    {
      "station-id"  = random_id.workload.hex
    }
  EOF
  default     = {}
  type        = map(string)
}

variable "groups" {
  description = <<-EOF
    (Optional) Map of Entra ID (Azure AD) groups to create
    Note: The workload identity is automatically assigned the App Role "User.ReadBasic.All" and "Group.Read.All"
          because being "Owner" of the group is not sufficient to add principals and then list them after an add or delete operation.
  EOF
  default     = {}
  type = map(object({
    display_name       = string
    description        = optional(string)
    owners             = optional(list(string))
    members            = optional(set(string))
    security_enabled   = optional(bool, true)
    mail_enabled       = optional(bool)
    assignable_to_role = optional(bool)
    types              = optional(set(string))
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
      pim = optional(object({
        member_type   = optional(string, "Eligible")
        justification = optional(string)
        ticket = optional(object({
          number = optional(string)
          system = optional(string)
        }))
        schedule = optional(object({
          start_date_time = optional(string)
          expiration = optional(object({
            duration_days  = optional(number)
            duration_hours = optional(number)
            end_date_time  = optional(string)
          }))
        }))
      }))
    })))
    directory_role_assignments = optional(map(object({
      role_name          = optional(string)
      role_id            = optional(string)
      app_scope_id       = optional(string)
      directory_scope_id = optional(string)
    })), {})
  }))

  validation {
    condition     = alltrue(flatten([for k, v in var.groups : [for dk, dv in v.directory_role_assignments == null ? {} : v.directory_role_assignments : !(dv.app_scope_id != null && dv.directory_scope_id != null)]]))
    error_message = "groups[*].directory_role_assignments: `app_scope_id` cannot be used with `directory_scope_id`."
  }

  validation {
    condition     = alltrue(flatten([for k, v in var.groups : [for dk, dv in v.directory_role_assignments == null ? {} : v.directory_role_assignments : !(dv.role_name != null && dv.role_id != null)]]))
    error_message = "groups[*].directory_role_assignments: `role_name` cannot be used with `role_id`."
  }

  validation {
    condition     = alltrue(flatten([for k, v in var.groups : [for dk, dv in v.directory_role_assignments == null ? {} : v.directory_role_assignments : (dv.role_name != null || dv.role_id != null)]]))
    error_message = "groups[*].directory_role_assignments: Either `role_name` or `role_id` must be provided."
  }

  validation {
    condition     = alltrue([for k, v in var.groups : length(v.directory_role_assignments == null ? {} : v.directory_role_assignments) == 0 || v.assignable_to_role == true])
    error_message = "groups[*].assignable_to_role: Must be set to `true` when `directory_role_assignments` is configured. Groups without the assignable_to_role property set cannot be assigned to directory roles."
  }

  validation {
    condition = alltrue(flatten([
      for k, v in var.groups : [
        for rk, rv in(v.role_assignments == null ? {} : v.role_assignments) : (
          try(rv.pim, null) == null || contains(["Eligible", "Active"], try(rv.pim.member_type, "Eligible"))
        )
      ]
    ]))
    error_message = "groups[*].role_assignments[*].pim.member_type: Must be either `Eligible` or `Active` when configured."
  }

  validation {
    condition = alltrue(flatten([
      for k, v in var.groups : [
        for rk, rv in(v.role_assignments == null ? {} : v.role_assignments) : (
          try(rv.pim, null) == null ||
          length(compact([
            try(rv.pim.schedule.expiration.duration_days, null) == null ? "" : "duration_days",
            try(rv.pim.schedule.expiration.duration_hours, null) == null ? "" : "duration_hours",
            try(rv.pim.schedule.expiration.end_date_time, null) == null ? "" : "end_date_time"
          ])) <= 1
        )
      ]
    ]))
    error_message = "groups[*].role_assignments[*].pim.schedule.expiration: Configure at most one of `duration_days`, `duration_hours`, or `end_date_time`."
  }

  validation {
    condition = alltrue(flatten([
      for k, v in var.groups : [
        for rk, rv in(v.role_assignments == null ? {} : v.role_assignments) : (
          try(rv.pim, null) == null || rv.role_definition_id != null || rv.role_definition_name != null
        )
      ]
    ]))
    error_message = "groups[*].role_assignments[*]: `role_definition_id` or `role_definition_name` must be provided when `pim` is configured."
  }

  validation {
    condition = alltrue(flatten([
      for k, v in var.groups : [
        for rk, rv in(v.role_assignments == null ? {} : v.role_assignments) : (
          try(rv.pim.member_type, "Eligible") != "Active" || (rv.condition == null && rv.condition_version == null)
        )
      ]
    ]))
    error_message = "groups[*].role_assignments[*]: `condition` and `condition_version` are not supported when `pim.member_type` is `Active`."
  }
}

variable "user_assigned_identities" {
  description = <<EOF
  User Assigned Identities to create.

  Example:

  user_assigned_identities = {
    my_app = {
      name                = "uai-my-identity"
      resource_group_name = "rg-name"
      location            = "norwayeast"
      app_role_assignments = {
        Application.ReadWrite.OwnedBy = {
          app_role_id        = "18a4783c-866b-4cc7-a460-3d5e5662c884"
          resource_object_id = "microsoft-graph-enterprise-app-object-id"
        }
      }
      group_memberships = {
        "Kubernetes Administrators" = azuread_group.k8s_admins.object_id
      }
      directory_role_assignments = {
        role_name                      = "Application Administrator"
      }
    }
  }
  EOF
  default     = {}
  type = map(object({
    name                = string
    resource_group_name = optional(string)
    location            = optional(string)
    app_role_assignments = optional(map(object({
      app_role_id        = string
      resource_object_id = string
    })), {})
    role_assignments = optional(map(object({
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
      pim = optional(object({
        member_type   = optional(string, "Eligible")
        justification = optional(string)
        ticket = optional(object({
          number = optional(string)
          system = optional(string)
        }))
        schedule = optional(object({
          start_date_time = optional(string)
          expiration = optional(object({
            duration_days  = optional(number)
            duration_hours = optional(number)
            end_date_time  = optional(string)
          }))
        }))
      }))
    })), {})
    group_memberships = optional(map(string), {})
    directory_role_assignments = optional(map(object({
      role_name          = optional(string)
      app_scope_id       = optional(string)
      directory_scope_id = optional(string)
    })), {})
  }))

  validation {
    condition = alltrue(flatten([
      for k, v in var.user_assigned_identities : [
        for rk, rv in(v.role_assignments == null ? {} : v.role_assignments) : (
          try(rv.pim, null) == null || contains(["Eligible", "Active"], try(rv.pim.member_type, "Eligible"))
        )
      ]
    ]))
    error_message = "user_assigned_identities[*].role_assignments[*].pim.member_type: Must be either `Eligible` or `Active` when configured."
  }

  validation {
    condition = alltrue(flatten([
      for k, v in var.user_assigned_identities : [
        for rk, rv in(v.role_assignments == null ? {} : v.role_assignments) : (
          try(rv.pim, null) == null ||
          length(compact([
            try(rv.pim.schedule.expiration.duration_days, null) == null ? "" : "duration_days",
            try(rv.pim.schedule.expiration.duration_hours, null) == null ? "" : "duration_hours",
            try(rv.pim.schedule.expiration.end_date_time, null) == null ? "" : "end_date_time"
          ])) <= 1
        )
      ]
    ]))
    error_message = "user_assigned_identities[*].role_assignments[*].pim.schedule.expiration: Configure at most one of `duration_days`, `duration_hours`, or `end_date_time`."
  }

  validation {
    condition = alltrue(flatten([
      for k, v in var.user_assigned_identities : [
        for rk, rv in(v.role_assignments == null ? {} : v.role_assignments) : (
          try(rv.pim, null) == null || rv.role_definition_id != null || rv.role_definition_name != null
        )
      ]
    ]))
    error_message = "user_assigned_identities[*].role_assignments[*]: `role_definition_id` or `role_definition_name` must be provided when `pim` is configured."
  }

  validation {
    condition = alltrue(flatten([
      for k, v in var.user_assigned_identities : [
        for rk, rv in(v.role_assignments == null ? {} : v.role_assignments) : (
          try(rv.pim.member_type, "Eligible") != "Active" || (rv.condition == null && rv.condition_version == null)
        )
      ]
    ]))
    error_message = "user_assigned_identities[*].role_assignments[*]: `condition` and `condition_version` are not supported when `pim.member_type` is `Active`."
  }
}

variable "tfe" {
  description = <<EOF
  Terraform Cloud configuration for the workload environment

  - Either of tfe.vcs_repo.(oauth_token_id|github_app_installation_id) must be provided, both can not be used at the same time.
  - tfe.workspace_env_vars lets you configure Environment Variables for the Terraform Cloud runtime environment
  - tfe.workspace_vars lets you configure Terraform variables
    resource into respective Terraform variables on the Terraform Cloud workspace. Useful when you need group object ids
    for the groups Station Deployments provisioned in your workload environment.
  - tfe.workspace_settings lets you configure the workspace settings like agent_pool_id and execution_mode. If agent_pool_id is provided, execution_mode must be set to "agent".
  - tfe.tags lets you configure tags for the workspace. Tags are key-value pairs that can be used to group and filter workspaces.
  EOF
  default     = null
  type = object({
    organization_name = string
    project = object({
      id   = string
      name = string
    })
    workspace_name        = string
    workspace_description = string
    workspace_settings = optional(object({
      agent_pool_id  = optional(string)
      execution_mode = optional(string)
    }))
    file_triggers_enabled = optional(bool)
    tags                  = optional(map(string))
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
  })
}

variable "role_assignments" {
  description = <<EOF
    Map of role_assignments to create. Be careful of who is allowed to provision role_assignments, you might want to 
    consider Sentinel policies in TFC.
  EOF
  default     = {}
  type = map(object({
    name                                   = optional(string)
    scope                                  = string
    role_definition_id                     = optional(string)
    role_definition_name                   = optional(string)
    principal_id                           = optional(string)
    condition                              = optional(string)
    condition_version                      = optional(string)
    delegated_managed_identity_resource_id = optional(string)
    description                            = optional(string)
    skip_service_principal_aad_check       = optional(bool, false)
    pim = optional(object({
      member_type   = optional(string, "Eligible")
      justification = optional(string)
      ticket = optional(object({
        number = optional(string)
        system = optional(string)
      }))
      schedule = optional(object({
        start_date_time = optional(string)
        expiration = optional(object({
          duration_days  = optional(number)
          duration_hours = optional(number)
          end_date_time  = optional(string)
        }))
      }))
    }))
  }))

  validation {
    condition = alltrue([
      for k, v in var.role_assignments : (
        try(v.pim, null) == null || contains(["Eligible", "Active"], try(v.pim.member_type, "Eligible"))
      )
    ])
    error_message = "role_assignments[*].pim.member_type: Must be either `Eligible` or `Active` when configured."
  }

  validation {
    condition = alltrue([
      for k, v in var.role_assignments : (
        try(v.pim, null) == null ||
        length(compact([
          try(v.pim.schedule.expiration.duration_days, null) == null ? "" : "duration_days",
          try(v.pim.schedule.expiration.duration_hours, null) == null ? "" : "duration_hours",
          try(v.pim.schedule.expiration.end_date_time, null) == null ? "" : "end_date_time"
        ])) <= 1
      )
    ])
    error_message = "role_assignments[*].pim.schedule.expiration: Configure at most one of `duration_days`, `duration_hours`, or `end_date_time`."
  }

  validation {
    condition = alltrue([
      for k, v in var.role_assignments : (
        try(v.pim, null) == null || v.role_definition_id != null || v.role_definition_name != null
      )
    ])
    error_message = "role_assignments[*]: `role_definition_id` or `role_definition_name` must be provided when `pim` is configured."
  }

  validation {
    condition = alltrue([
      for k, v in var.role_assignments : (
        try(v.pim.member_type, "Eligible") != "Active" || (v.condition == null && v.condition_version == null)
      )
    ])
    error_message = "role_assignments[*]: `condition` and `condition_version` are not supported when `pim.member_type` is `Active`."
  }
}

