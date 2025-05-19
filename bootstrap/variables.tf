variable "config" {
  type        = any
  description = "(Required) Input variables for the bootstrap module. See `application-landing-zone.auto.tfvars` for values."
}

variable "tfe_token" {
  description = "(Required) HCP Terraform User API token for \"Service Account\" user. Must be member of the `owners` team."
  sensitive   = true
  type        = string
}

variable "github_app_pem_file" {
  description = "(Required) Base64 encoded private key for the Station Landing Zones Github app."
  sensitive   = true
  type        = string
}

