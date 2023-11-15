output "project_name" {
  value = data.tfe_project.workload.name
}

output "workspace" {
  value = tfe_workspace.workload
}

output "workspace_variables" {
  value = local.tfc_variables
}