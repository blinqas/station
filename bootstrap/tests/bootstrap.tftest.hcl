provider "azurerm" {
  features {
  }
  # You will need to set the following environment variables:
  # - ARM_CLIENT_ID
  # - ARM_CLIENT_SECRET
  # - ARM_SUBSCRIPTION_ID
  # - ARM_TENANT_ID
}

provider "tfe" {
}

provider "github" {
  # You will need to set the following environment variables:
  # - GITHUB_TOKEN
  # - GITHUB_OWNER
}

# You will also have to define some sensitive variables in the environment before running the tests:
# - TF_VAR_tfc_organization_name ""                                        # The name of the Terraform Cloud organization where the workspaces will be created.
# - (Optonal) TF_VAR_vcs_repo_github_app_installation_id ghain-yourKey     # ID for GitHub app installation in TFC. Use either this or the bellow. Ensure GitHub Terraform app is pre-installed: https://app.terraform.io/api/v2/github-app/installations.
# - (Optonal) TF_VAR_vcs_repo_oauth_token_id "ot-yourTokenId"              # Alternative to GitHub app installation ID. Use either this or the above. This can be found at https://app.terraform.io/app/your-org-name/settings/version-control
# - TF_VAR_subscription_ids "[\"subscription_1\"]"                         # Azure Subscriptions where Station should have owner permissions. Fetch using: az account list --query "[?tenantId=='yourTenantID'].{Name:name, ID:id}" --output table
# - TF_VAR_vcs_repo_PAT "ghp_yourPAThere"                                  # Personal Access Token (PAT) for TFC to create repositories. Documentation: https://docs.github.com/en/enterprise-server@3.6/authentication/keeping-your-account-and-data-secure/managing-your-personal-access-tokens
# - TF_VAR_tfc_token "Team_or_org_token"                                   # Token for the Terraform Cloud organization where the workspaces will be created. 

variables {
  bootstrap_tfc_workspace_name   = "test-station-bootstrap-workspace"
  tfc_project_name               = "test-station-bootstrap-project"
  deployments_tfc_workspace_name = "test-station-deployments"
  vcs_repo_name                  = "test-station-deployments"
  vcs_repo_branch                = null
}


run "test_tfc" {

  assert {
    condition     = tfe_workspace.deployments.name == var.deployments_tfc_workspace_name
    error_message = "The deployment workspace name does NOT match the input"
  }

  assert {
    condition     = tfe_workspace.bootstrap.name == var.bootstrap_tfc_workspace_name
    error_message = "The bootstrap workspace name does NOT match the input"
  }

  assert {
    condition     = tfe_project.station.name == var.tfc_project_name
    error_message = "The TFC project name does NOT match the input"
  }
}

run "test_github_repo" {
  variables {
    vcs_repo_branch = "test"
  }

  assert {
    condition     = github_repository.deployments.name == var.vcs_repo_name
    error_message = "The deployment repository name does NOT match the input"
  }

  assert {
    condition     = github_branch.deployments.branch == var.vcs_repo_branch
    error_message = "The deployment repository branch does NOT match the input"
  }

  assert {
    condition     = github_repository.deployments.visibility == "private"
    error_message = "The deployment repository visibility is not private"
  }
}

run "test_github_repo_default_branch_name" {

  assert {
    condition     = github_branch.deployments.branch == "trunk"
    error_message = "The deployment repository branch does NOT match the default value when not setting the 'vcs_repo_branch' variable"
  }
}

run "test_azure_app_registration" {

  assert {
    condition     = azuread_application.workload.display_name == "app-station-bootstrap"
    error_message = "The app registration name does NOT match the default value"
  }
}

run "test_azure_subscription" {

  assert {
    condition     = length(data.azurerm_subscription.deployment) == length(var.subscription_ids)
    error_message = "The number of subscriptions does NOT match the input"
  }
}
run "test_azure_service_principal" {

  assert {
    condition     = azuread_application.workload.display_name == "app-station-bootstrap"
    error_message = "The app registration name does NOT match the default value"
  }
}