locals {
  tfe_project = var.create_project ? tfe_project.workload : data.tfe_project.workload
}

resource "tfe_project" "workload" {
  # Create resource if create_project is true
  count = var.create_project ? 1 : 0
  name  = var.project_name
  # prevent_destroy has been set to true because once created it must not be deleted in case we have multiple
  # environments that depend on this project.
  # This setting is unfortunate, but Terraform does not support creation of resource only if it does not exist.
  lifecycle {
    prevent_destroy = true
  }
}

data "tfe_project" "workload" {
  # Create data resource if create_project is false; this means the project already exists.
  count = var.create_project ? 0 : 1
  name  = var.project_name
}

