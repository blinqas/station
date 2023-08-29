module "tfe-projects" {
  source   = "./hashicorp/tfe_project/"
  projects = var.projects
}
