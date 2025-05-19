variable "station_id" {
  type        = string
  description = "The id of the workload deployment"
}

variable "workload_resource_group_name" {
  type        = string
  description = "The name of the resource group for the workload deployment"
}

variable "tags" {
  type        = map(string)
  description = "Tags passed on from Station Deployments"
  default     = {}
}

variable "user_assigned_identities" {
  description = "User Assigned Identities (Managed Identities) provisioned with Station"
  type = map(object({
    id           = string
    client_id    = string
    principal_id = string
  }))
  default = {}
}

variable "groups" {
  description = "Groups provisioned with Station"
  type = map(object({
    display_name = string
    object_id    = string
  }))
  default = {}
}

variable "applications" {
  description = "Applications provisioned with Station"
  type = map(object({
    client_id = string
    object_id = string
  }))
  default = {}
}

variable "resource_groups" {
  description = "User specified resource groups provisioned by Station"
  type = map(object({
    location = string
    name     = string
  }))
  default = {}
}

variable "github_owner" {
  description = "(Required) The name of the GitHub account to manage."
  type        = string
}

variable "github_app_id" {
  description = "(Required) Application ID of the Station Application Landing Zones Github app."
  type        = string
}

variable "github_app_installation_id" {
  description = "(Required) Application Installation ID of the Station Application Landing Zones Github app."
  type        = string
}

variable "github_app_pem_file" {
  description = "(Required) The private key for the Github app `Station Landing Zones (<org>`. Created at https://github.com/organizations/<org>/settings/apps/"
  sensitive   = true
  type        = string
  ephemeral   = true
}

variable "vcs_repo_github_app_installation_id" {
  description = "(Required) Installation ID of the HCP Terraform Github app"
  type        = string
}

