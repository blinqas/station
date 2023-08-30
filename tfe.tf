module "station-tfe" {
  count  = var.tfe == null ? 0 : 1
  source = "./hashicorp/tfe/"

  project_name   = var.tfe.project_name
  workspace_name        = var.tfe.workspace_name
  workspace_description = var.tfe.workspace_description
  env_vars = merge(try(var.tfe.env_vars, {}), {
    station_id = {
      value       = random_id.workload.hex
      category    = "terraform"
      description = "Station ID"
    },
  })
  # TODO: vcs_repo configuration
}
