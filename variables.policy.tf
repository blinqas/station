variable "policy_exemptions" {
  description = <<EOF
    Map of policy exemptions to create at resource group scope.

    Exemptions default to the workload resource group created by Station.
    Set `resource_group_key` to target one of the resource groups from `var.resource_groups`.
  EOF
  default     = {}
  type = map(object({
    name                            = string
    policy_assignment_id            = string
    exemption_category              = string
    description                     = string
    display_name                    = optional(string)
    expires_on                      = optional(string)
    policy_definition_reference_ids = optional(set(string))
    resource_group_key              = optional(string)
  }))

  validation {
    condition     = alltrue([for k, v in var.policy_exemptions : trimspace(v.name) != ""])
    error_message = "policy_exemptions[*].name: Value must not be empty."
  }

  validation {
    condition     = alltrue([for k, v in var.policy_exemptions : trimspace(v.description) != ""])
    error_message = "policy_exemptions[*].description: Value must not be empty."
  }

  validation {
    condition     = alltrue([for k, v in var.policy_exemptions : contains(["Waiver", "Mitigated"], v.exemption_category)])
    error_message = "policy_exemptions[*].exemption_category: Value must be one of [\"Waiver\", \"Mitigated\"]."
  }

  validation {
    condition     = alltrue([for k, v in var.policy_exemptions : trimspace(v.policy_assignment_id) != "" && strcontains(lower(v.policy_assignment_id), "/providers/microsoft.authorization/policyassignments/")])
    error_message = "policy_exemptions[*].policy_assignment_id: Value must be a valid Azure Policy Assignment resource ID."
  }

  validation {
    condition     = alltrue([for k, v in var.policy_exemptions : v.expires_on == null ? true : can(formatdate("", v.expires_on))])
    error_message = "policy_exemptions[*].expires_on: Value must be a valid RFC3339 timestamp (for example 2028-01-11T00:00:00Z)."
  }

  validation {
    condition     = alltrue([for k, v in var.policy_exemptions : v.resource_group_key == null ? true : contains(keys(var.resource_groups), v.resource_group_key)])
    error_message = "policy_exemptions[*].resource_group_key: Value must reference an existing key in var.resource_groups."
  }
}
