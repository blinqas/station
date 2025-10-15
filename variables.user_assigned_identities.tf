variable "user_assigned_identities" {
  description = <<-EOT
    A map of user assigned identities to create. The key is a custom identifier for the identity.

    - `name` - (Required) The name of the user assigned identity.
    - `location` - (Optional) The location of the user assigned identity. Defaults to `var.default_location`.
    - `resource_group_name` - (Optional) The name of the resource group in which to create the user assigned identity. Defaults to `var.resource_group_name`.
    - `role_assignments` - (Optional) A map of role assignments to create for the user assigned identity. For additional information on `role_assignments`, see [role_assignments block](#role_assignments-block).
    - `group_memberships` - (Optional) A set of object IDs of groups that the user assigned identity should be a member of.
    - `app_role_assignments` - (Optional) A map of app role assignments to create for the user assigned identity. For additional information on `app_role_assignments`, see [app_role_assignments block](#app_role_assignments-block).
    - `directory_role_assignments` - (Optional) A map of directory role assignments to create for the user assigned identity. For additional information on `directory_role_assignments`, see [directory_role_assignments block](#directory_role_assignments-block).
  EOT
  type = map(object({
    name                = string
    location            = optional(string)
    resource_group_name = optional(string)
    role_assignments = optional(map(object({
      scope                = string
      role_definition_id   = optional(string)
      role_definition_name = optional(string)
    })), {})
    group_memberships = optional(set(string), [])
    app_role_assignments = optional(map(object({
      resource_object_id = string
      app_role_id        = string
    })), {})
    directory_role_assignments = optional(map(object({
      role_id           = optional(string)
      role_name         = optional(string)
      app_scope_id      = optional(string)
      directory_scope_id = optional(string)
    })), {})
  }))
  default = {}

  validation {
    condition = alltrue(flatten([
      for k, v in var.user_assigned_identities : [
        for rk, rv in v.role_assignments : (
          (rv.role_definition_id != null && rv.role_definition_name == null) ||
          (rv.role_definition_id == null && rv.role_definition_name != null)
        )
      ]
    ]))
    error_message = "Each role assignment must specify exactly one of 'role_definition_id' or 'role_definition_name', not both."
  }

  validation {
    condition = alltrue(flatten([
      for k, v in var.user_assigned_identities : [
        for dk, dv in v.directory_role_assignments : (
          (dv.app_scope_id != null && dv.directory_scope_id == null) ||
          (dv.app_scope_id == null && dv.directory_scope_id != null)
        )
      ]
    ]))
    error_message = "Each directory role assignment must specify exactly one of 'app_scope_id' or 'directory_scope_id', not both."
  }

  validation {
    condition = alltrue(flatten([
      for k, v in var.user_assigned_identities : [
        for ak, av in v.app_role_assignments : can(regex("^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$", av.app_role_id))
      ]
    ]))
    error_message = "All 'app_role_id' values must be valid UUIDs (format: xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx)."
  }
}
