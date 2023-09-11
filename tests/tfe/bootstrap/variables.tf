variable "state_resource_group_name" {
  type        = string
  description = "The name of the resource group to deploy State Storage Accounts in"
  default     = "rg-terraform-backend"
}
variable "tfc_organization_name" {
  type        = string
  description = "The name of the organization you have created in Terraform Cloud"
}
variable "tfc_project_name" {
  type        = string
  description = "The name of the project you have created in Terraform Cloud"
}
variable "tfc_workspace_name" {
  type        = string
  description = "The name of the workspace you have created in Terraform Cloud."
}
variable "station_repo_url" {
  type        = string
  description = "URL to the repository of the sation codebase"
}