data "tfe_organization" "test" {
  name = var.tfc_organization_name
}

resource "tfe_project" "test" {
  name = var.tfc_project_name
}
