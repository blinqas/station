resource "tfe_project" "projects" {
  for_each = var.projects
  name     = each.value.project_name
}

