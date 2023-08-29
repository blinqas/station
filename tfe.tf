module "station-tfe" {
  source = "./hashicorp/tfe/"

  # How to handle project creation vs existing project?
  project_name = var.tfe.project_name
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
  })
}
