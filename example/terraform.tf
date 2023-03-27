module "station" {
  source = "../"

  environment_name                    = "dev"
  role_definition_name_on_workload_rg = "Owner"
  station_resource_group_name         = "rg-terraform-remote-state"
  federated_identity_credential_config = {
    create = false
    audiences = ["api://AzureADTokenExchange"]
    issuer    = "https://token.actions.githubusercontent.com"
    subject   = "repo:kimfy/station:environment:dev"
  }
}
