module "station-tfe" {
  source = "./hashicorp/tfe/"

  project_name   = "Station TFE Development"
  workspace_name = "tests-tfe"
  env_vars = {
    x = {
      value       = "x"
      category    = "env"
      description = "Some description"
    }
  }
}
