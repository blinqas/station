data "tfe_organization" "test" {
  name = var.organization_name
}

resource "tfe_project" "test" {
  name = var.project_name
}
