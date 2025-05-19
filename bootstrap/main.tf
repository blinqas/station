// These two resources (local_file and terraform_data) ensure that Terraform uses
// the local backend on the first run of the bootstrap process.
// On the subsequent run, the providers file is replaced with one that configures
// the `cloud` backend (e.g., Terraform Cloud).
// This approach is necessary because the Terraform Cloud workspace is created
// during the first run, and the state is migrated to the cloud on the second run.
resource "local_file" "providers" {
  source     = "${path.root}/providers/providers.cloud.tf"
  filename   = "${path.root}/providers.tf"
  depends_on = [terraform_data.this, github_repository_file.bootstrap]
}

resource "terraform_data" "this" {
  provisioner "local-exec" {
    when    = destroy
    command = "cp ${path.root}/providers/providers.local.tf ${path.root}/providers.tf"
  }
}

resource "tfe_project" "this" {
  name         = var.config.terraform_cloud.project.name
  description  = var.config.terraform_cloud.project.description
  organization = var.config.terraform_cloud.organization_name
}

resource "tfe_workspace" "bootstrap" {
  name         = var.config.terraform_cloud.bootstrap_workspace_name
  description  = var.config.terraform_cloud.bootstrap_workspace_description
  organization = var.config.terraform_cloud.organization_name
  project_id   = tfe_project.this.id
  force_delete = true # Enable successfull destroy operations
}

// We wish to only use HCP Terraform for state storage for the bootstrap config
resource "tfe_workspace_settings" "bootstrap" {
  workspace_id   = tfe_workspace.bootstrap.id
  execution_mode = "local"
}

module "station" {
  source              = "git::https://github.com/blinqas/station.git?ref=trunk"
  tenant_id           = var.config.tenant_id
  subscription_id     = var.config.subscription_id
  resource_group_name = var.config.resource_group_name
  tags                = merge(var.config.tags, { repoUrl = github_repository.this.full_name })
  tfe = merge(
    var.config.terraform_cloud, {
      workspace_vars = local.workspace_env_vars,
      project        = tfe_project.this,
      vcs_repo       = local.vcs_repo
  })

  identity = {
    name = var.config.identity_name
    role_assignments = {
      owner_lz = {
        scope                = "/subscriptions/${var.config.subscription_id}"
        role_definition_name = "Owner"
      }
    }

    app_role_assignments = {
      // The following API permissions are required in order to use `azuread_app_role_assignment`: https://registry.terraform.io/providers/hashicorp/azuread/latest/docs/resources/app_role_assignment
      "AppRoleAssignment.ReadWrite.All" = {
        app_role_id        = data.azuread_service_principal.well_known["Microsoft Graph"].app_role_ids["AppRoleAssignment.ReadWrite.All"]
        resource_object_id = data.azuread_service_principal.well_known["Microsoft Graph"].object_id
      }
      "Directory.Read.All" = {
        app_role_id        = data.azuread_service_principal.well_known["Microsoft Graph"].app_role_ids["Directory.Read.All"]
        resource_object_id = data.azuread_service_principal.well_known["Microsoft Graph"].object_id
      }
    }
  }
  depends_on = [github_repository_file.alz_applications]
}

data "azuread_service_principal" "well_known" {
  for_each     = toset(["Microsoft Graph"])
  display_name = each.value
}

