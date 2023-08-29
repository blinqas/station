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

variable "workspace_description" {
  description = "Description of the Terraform Cloud workspace"
  type        = string
}

variable "env_vars" {
  description = "Map of environment variables to provision on the workspace in Terraform Cloud"
  type = map(object({
    value       = string
    category    = string
    description = string
  }))
  default = {}
}

variable "create_project" {
  description = "Determines if a Terraform Cloud Project is created. You may set this to false if it already exists. This variable exists since Terraform does not support checking if a resource already exists, and you may want to put your workspace in an existsing workspace."
  default     = false
}
