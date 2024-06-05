variable "azuread_group" {
  type        = any
  description = <<EOF
    The configuration for the azuread_group to create.

    See Station's applications variable type constraint on how to structure this object. Type constraint has not been set internally at this point to ensure Stations "DRY"-ness.
  EOF
}

variable "owners" {
  type        = set(string)
  default     = null
  description = <<EOF
    (Optional) A set of object IDs of principals that will be granted ownership of the group. Supported object types are users or service principals. By default, the principal being used to execute Terraform is assigned as the sole owner. Groups cannot be created with no owners or have all their owners removed.
    - https://registry.terraform.io/providers/hashicorp/azuread/latest/docs/resources/group#owners
  EOF
}

variable "role_assignments" {
  type        = map(any)
  default     = null
  description = <<EOF
    (Optional) A map of role assignments to create for the group.
  EOF
}