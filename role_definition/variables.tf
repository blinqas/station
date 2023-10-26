variable "role_definition" {
  type        = any
  description = <<EOF
    The configuration for the role_definition to create.

    See Station's role_definitions variable type constraint on how to structure this object. Type constraint has not been set internally at this point to ensure Stations "DRY"-ness.
  EOF
}
