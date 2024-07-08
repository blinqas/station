variable "azuread_application" {
  type        = any
  description = <<EOF
  The configuration for the azuread_application to create.

  See Station's applications variable type constraint on how to structure this object. Type constraint has not been set internally at this point to ensure Stations "DRY"-ness.
  EOF
}

variable "azuread_service_principal" {
  type = any
  description = <<EOF
  The configuration for the azuread_service_principal to create. See Station's applications variable on how to configure the service principal block. 
  EOF
}
variable "owners" {
  type        = set(string)
  default     = null
  description = <<EOF
  (Optional) A set of object IDs of principals that will be granted ownership of the application. Supported object types are users or service principals. By default, no owners are assigned.
  - https://registry.terraform.io/providers/hashicorp/azuread/latest/docs/resources/application#owners
  EOF
}

