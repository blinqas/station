variable "azuread_application" {
  type        = any
  description = <<EOF
  The configuration for the azuread_application to create.

  See Station's applications variable type constraint on how to structure this object. Type constraint has not been set internally at this point to ensure Stations "DRY"-ness.
  EOF
}

variable "azuread_service_principal" {
  type        = optional(object({
      account_enabled                = optional(bool, true)
      alternative_names              = optional(list(string))
      app_role_assignment_required   = optional(bool, false)
      description                    = optional(string)
      login_url                      = optional(string)
      notes                          = optional(string)
      notification_email_addresses   = optional(list(string))
      owners                         = optional(list(string))
      preferred_single_sign_on_mode  = optional(string)
      tags                           = optional(list(string))
      use_existing                   = optional(bool, false)

      feature_tags = optional(object({
        custom_single_sign_on = optional(bool, false)
        enterprise            = optional(bool, false)
        gallery               = optional(bool, false)
        hide                  = optional(bool, false)
      }))

      saml_single_sign_on = optional(object({
        relay_state = optional(string)
      }))
    }))
  description = <<EOF
  The configuration for the azuread_service_principal to create.
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

