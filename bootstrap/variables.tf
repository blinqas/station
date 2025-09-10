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
