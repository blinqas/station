variable "config" {
  type        = any
  description = "(Required) Input variables for the bootstrap module. See `application-landing-zone.auto.tfvars` for values."
}

variable "tfe_token" {
  description = "(Required) HCP Terraform User API token for \"Service Account\" user. Must be member of the `owners` team."
  sensitive   = true
  type        = string
  default     = "value"
}

variable "enable_privileged_role_administrator" {
  description = <<-EOT
    (Optional) Whether to grant the Station identity the "Privileged Role Administrator" directory role.
    
    Default: false
    
    When DISABLED (default):
      • Station uses only Microsoft Graph API permissions (least-privilege)
      • Landing zones CANNOT be assigned Entra ID directory roles
      • Landing zones CAN still receive Graph API permissions (e.g., User.Read.All)
      • This is the recommended setting for most deployments
    
    When ENABLED:
      • Station can assign ANY directory role to landing zone identities
      • Including Global Administrator (privilege escalation risk)
      • Only enable if landing zones genuinely require directory roles
      • Ensure strict repository access controls are in place
    
    See PERMISSIONS.md for detailed security implications.
    Reference: https://learn.microsoft.com/en-us/entra/identity/role-based-access-control/permissions-reference#privileged-role-administrator
  EOT
  type        = bool
  default     = false
}
