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
  force_delete = true # Enable successful destroy operations
}

// We wish to only use HCP Terraform for state storage for the bootstrap config
resource "tfe_workspace_settings" "bootstrap" {
  workspace_id   = tfe_workspace.bootstrap.id
  execution_mode = "local"
}

module "station" {
  source              = "../."
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

    # Azure RBAC: Owner on subscription for managing Azure resources
    role_assignments = {
      owner_lz = {
        scope                = "/subscriptions/${var.config.subscription_id}"
        role_definition_name = "Owner"
      }
    }

    # Microsoft Graph API Permissions (Application)
    # These replace Global Administrator with least-privilege permissions
    # See: https://learn.microsoft.com/en-us/graph/permissions-reference
    app_role_assignments = {
      # Manage applications where this identity is an owner
      # https://learn.microsoft.com/en-us/graph/permissions-reference#applicationreadwriteownedby
      "Application.ReadWrite.OwnedBy" = {
        app_role_id        = data.azuread_service_principal.msgraph.app_role_ids["Application.ReadWrite.OwnedBy"]
        resource_object_id = data.azuread_service_principal.msgraph.object_id
      }
      # Create and manage security groups
      # https://learn.microsoft.com/en-us/graph/permissions-reference#groupreadwriteall
      "Group.ReadWrite.All" = {
        app_role_id        = data.azuread_service_principal.msgraph.app_role_ids["Group.ReadWrite.All"]
        resource_object_id = data.azuread_service_principal.msgraph.object_id
      }
      # Add/remove members from groups
      # https://learn.microsoft.com/en-us/graph/permissions-reference#groupmemberreadwriteall
      "GroupMember.ReadWrite.All" = {
        app_role_id        = data.azuread_service_principal.msgraph.app_role_ids["GroupMember.ReadWrite.All"]
        resource_object_id = data.azuread_service_principal.msgraph.object_id
      }
      # Read user profiles (required for group member validation)
      # https://learn.microsoft.com/en-us/graph/permissions-reference#userreadall
      "User.Read.All" = {
        app_role_id        = data.azuread_service_principal.msgraph.app_role_ids["User.Read.All"]
        resource_object_id = data.azuread_service_principal.msgraph.object_id
      }
      # Grant API permissions (app roles) to service principals
      # https://learn.microsoft.com/en-us/graph/permissions-reference#approleassignmentreadwriteall
      "AppRoleAssignment.ReadWrite.All" = {
        app_role_id        = data.azuread_service_principal.msgraph.app_role_ids["AppRoleAssignment.ReadWrite.All"]
        resource_object_id = data.azuread_service_principal.msgraph.object_id
      }
    }

    # Entra ID Directory Role (Optional)
    # Only granted if var.enable_privileged_role_administrator is true
    # https://learn.microsoft.com/en-us/entra/identity/role-based-access-control/permissions-reference#privileged-role-administrator
    directory_role_assignments = var.enable_privileged_role_administrator ? {
      "Privileged Role Administrator" = {
        role_name = "Privileged Role Administrator"
      }
    } : {}
  }
  providers = {
    azurerm              = azurerm
    azurerm.connectivity = azurerm.connectivity
  }
  depends_on = [github_repository_file.alz_applications]
}

# Microsoft Graph service principal - used to reference app role IDs
# https://learn.microsoft.com/en-us/graph/permissions-reference
data "azuread_application_published_app_ids" "well_known" {}

data "azuread_service_principal" "msgraph" {
  client_id = data.azuread_application_published_app_ids.well_known.result.MicrosoftGraph
}

