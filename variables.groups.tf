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
}
