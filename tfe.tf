module "station-tfe" {
  count  = var.tfe == null ? 0 : 1
  source = "./hashicorp/tfe/"

  # How to handle project creation vs existing project?
  project_name   = var.tfe.project_name
  create_project = var.tfe.create_project
  # How to handle dev/prod?
  workspace_name        = var.tfe.workspace_name
  workspace_description = var.tfe.workspace_description
  # Which default env vars?
  env_vars = merge(try(var.tfe.env_vars, {}), {
    x = {
      value       = "x"
      category    = "env"
      description = "My env var"
    },
    station_id = {
      value       = random_id.workload.hex
      category    = "terraform"
      description = "Station ID"
    },
  })
  # TODO: vcs_repo configuration
}
