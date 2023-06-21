module "station-basic" {
  source = "../"
  environment_name                    = "dev"
  role_definition_name_on_workload_rg = "Owner"
  station_resource_group_name         = "rg-terraform-station"
}
