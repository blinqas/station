variable "provider_configuration" {
  description = "See the official docs: https://registry.terraform.io/providers/hashicorp/tfe/latest/docs"
  type = object({
    organization = optional(string)
  })
  default = {}
}

variable "project_name" {
  description = "Name of the project to provision in Terraform Cloud"
  type        = string
}

variable "workspace_name" {
  description = "Name of the workspace to provision in Terraform Cloud"
  type        = string
}

variable "env_vars" {
  description = "Map of environment variables to provision on the workspace in Terraform Cloud"
  type        = map(string)
}

