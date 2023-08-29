resource "tfe_workspace" "workload" {
  name        = var.workspace_name
  description = var.workspace_description
  project_id  = tfe_project.workload.id
}

