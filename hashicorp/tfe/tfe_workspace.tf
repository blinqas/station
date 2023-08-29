resource "tfe_workspace" "workload" {
  name        = var.workspace_name
  description = var.workspace_description
}

