variable "name" {
  description = "Specifies the name of this User Assigned Identity. Changing this forces a new User Assigned Identity to be created."
  type        = string
}

variable "resource_group_name" {
  description = "Specifies the name of the Resource Group within which this User Assigned Identity should exist. Changing this forces a new User Assigned Identity to be created."
  type        = string
}

variable "location" {
  description = "The Azure Region where the User Assigned Identity should exist. Changing this forces a new User Assigned Identity to be created."
  type        = string
}

variable "tags" {
  description = "A mapping of tags which should be assigned to the User Assigned Identity."
  type        = map(string)
}

variable "role_assignments" {
  description = "Application Roles to assign the Managed Identity"
  type        = list(string)
}

variable "group_membership" {
  description = "List of Object IDs that represent the Azure AD groups to which the assigned user identity should be added as a member"
  type = set(string)
}