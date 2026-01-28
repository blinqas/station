variable "policy_exemptions" {
  description = <<EOF
  Map of Azure Policy exemptions to create at the resource group level.
  
  Policy exemptions allow you to exempt specific resource groups from Azure Policy assignments.
  This is useful when working with Azure Landing Zones that have policies restricting provisioning.

  Example:
  policy_exemptions = {
    subnet_nsg = {
      name                 = "subnet-nsg-exemption"
      policy_assignment_id = "/providers/Microsoft.Management/managementGroups/mg-landingzones/providers/Microsoft.Authorization/policyAssignments/Deny-Subnet-Without-Nsg"
      exemption_category   = "Waiver"
      display_name         = "Subnet NSG Exemption"
      description          = "Terraform module configures subnet and NSG association as separate resources. Azure Policy evaluates during subnet creation before the NSG attachment completes, causing deployment failure."
      expires_on           = "2028-01-11T00:00:00Z"
      resource_group_name  = null # Defaults to the main resource group (azurerm_resource_group.workload)
    }
  }
  EOF
  default     = {}
  type = map(object({
    name                            = string
    policy_assignment_id            = string
    exemption_category              = string
    display_name                    = optional(string)
    description                     = string
    expires_on                      = optional(string)
    resource_group_name             = optional(string)
    policy_definition_reference_ids = optional(list(string))
    metadata                        = optional(string)
  }))

  validation {
    condition = alltrue([
      for k, v in var.policy_exemptions : contains(["Waiver", "Mitigated"], v.exemption_category)
    ])
    error_message = "policy_exemptions[*].exemption_category: Must be either 'Waiver' or 'Mitigated'."
  }

  validation {
    condition = alltrue([
      for k, v in var.policy_exemptions : v.description != null && v.description != ""
    ])
    error_message = "policy_exemptions[*].description: Description is required and cannot be empty. Always provide a reason for the policy exemption."
  }

  validation {
    condition = alltrue([
      for k, v in var.policy_exemptions : v.name != null && v.name != ""
    ])
    error_message = "policy_exemptions[*].name: Name is required and cannot be empty."
  }

  validation {
    condition = alltrue([
      for k, v in var.policy_exemptions : v.policy_assignment_id != null && v.policy_assignment_id != ""
    ])
    error_message = "policy_exemptions[*].policy_assignment_id: Policy assignment ID is required and cannot be empty."
  }

  validation {
    condition = alltrue([
      for k, v in var.policy_exemptions : v.expires_on == null || can(regex("^\\d{4}-\\d{2}-\\d{2}T\\d{2}:\\d{2}:\\d{2}Z$", v.expires_on))
    ])
    error_message = "policy_exemptions[*].expires_on: Must be in ISO 8601 format (e.g., '2028-01-11T00:00:00Z') or null."
  }
}
