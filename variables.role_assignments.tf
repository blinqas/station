variable "role_assignments" {
  description = <<-EOT
    A map of role assignments to create at the subscription or management group level.

    - `scope` - (Required) The scope at which the role assignment applies. This can be a subscription ID, resource group ID, or resource ID.
    - `role_definition_id` - (Optional) The ID of the role definition to assign. Cannot be used together with `role_definition_name`.
    - `role_definition_name` - (Optional) The name of the role definition to assign. Cannot be used together with `role_definition_id`.
    - `principal_id` - (Required) The ID of the principal to assign the role to.
  EOT
  type = map(object({
    scope                = string
    role_definition_id   = optional(string)
    role_definition_name = optional(string)
    principal_id         = string
  }))
  default = {}

  validation {
    condition = alltrue([
      for k, v in var.role_assignments : (
        (v.role_definition_id != null && v.role_definition_name == null) ||
        (v.role_definition_id == null && v.role_definition_name != null)
      )
    ])
    error_message = "Each role assignment must specify exactly one of 'role_definition_id' or 'role_definition_name', not both."
  }
}
