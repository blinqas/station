locals {
  tfe_projects = {
    tfe_tests = {
      project_name = "Station TFE Development"
    }
  }
}

resource "tfe_project" "projects" {
  for_each = local.tfe_projects
  name     = each.value.project_name
}

