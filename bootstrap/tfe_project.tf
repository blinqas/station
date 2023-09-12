resource "tfe_project" "station" {
  organization = data.tfe_organization.this.name
  name         = var.tfc_project_name
}
