mock_provider "azurerm" {}

mock_provider "azurerm" {
  alias = "connectivity"
}

mock_provider "azuread" {
  mock_data "azuread_application_published_app_ids" {
    defaults = {
      result = { MicrosoftGraph = "00000003-0000-0000-c000-000000000000" }
    }
  }

  mock_data "azuread_service_principal" {
    defaults = {
      object_id = "11111111-1111-1111-1111-111111111111"
      app_role_ids = {
        "Application.ReadWrite.OwnedBy"   = "11111111-1111-1111-1111-111111111111"
        "Group.ReadWrite.All"             = "11111111-1111-1111-1111-111111111111"
        "GroupMember.ReadWrite.All"       = "11111111-1111-1111-1111-111111111111"
        "User.Read.All"                   = "11111111-1111-1111-1111-111111111111"
        "AppRoleAssignment.ReadWrite.All" = "11111111-1111-1111-1111-111111111111"
      }
    }
  }
}

mock_provider "github" {
  alias = "mocked"

  mock_resource "github_repository" {
    defaults = {
      full_name = "example-org/landing-zones"
    }
  }
}

mock_provider "gitlab" {
  alias = "mocked"

  mock_data "gitlab_group" {
    defaults = { id = "12345" }
  }

  mock_resource "gitlab_project" {
    defaults = {
      id                  = "12345"
      path_with_namespace = "example-group/landing-zones"
    }
  }
}

mock_provider "tfe" {}
mock_provider "local" {}
mock_provider "random" {}
mock_provider "time" {}

override_resource {
  target          = github_repository.this[0]
  override_during = plan
  values = {
    full_name = "example-org/landing-zones"
  }
}

override_resource {
  target          = gitlab_project.this[0]
  override_during = plan
  values = {
    id                  = "12345"
    path_with_namespace = "example-group/landing-zones"
  }
}

override_resource {
  target          = gitlab_project.bootstrap[0]
  override_during = plan
  values = {
    id = "67890"
  }
}

variables {
  tfe_token = "test-only-placeholder"
  config = {
    tenant_id           = "00000000-0000-0000-0000-000000000001"
    subscription_id     = "00000000-0000-0000-0000-000000000002"
    resource_group_name = "test-landing-zones"
    identity_name       = "test-landing-zones"
    tags                = { environment = "test" }

    terraform_cloud = {
      organization_name               = "test-only-organization"
      workspace_name                  = "test-landing-zones"
      workspace_description           = "Local bootstrap test"
      bootstrap_workspace_name        = "test-bootstrap"
      bootstrap_workspace_description = "Local bootstrap test"
      project = {
        name        = "Local bootstrap test"
        description = "Local bootstrap test"
      }
    }
  }
}

run "github" {
  command = plan

  providers = {
    azurerm              = azurerm
    azurerm.connectivity = azurerm.connectivity
    azuread              = azuread
    github               = github.mocked
    tfe                  = tfe
    local                = local
    random               = random
    time                 = time
  }

  variables {
    github_app_pem_file = base64encode("test-only-placeholder")
    config = merge(var.config, {
      terraform_cloud = merge(var.config.terraform_cloud, {
        vcs_repo_github_app_installation_id = "98765"
      })
      github = {
        owner                 = "example-org"
        repository            = "landing-zones"
        description           = "Landing zones"
        branch                = "main"
        bootstrap_repository  = "landing-zones-bootstrap"
        bootstrap_description = "Bootstrap"
        bootstrap_branch      = "main"
        provider = {
          id              = "12345"
          installation_id = "54321"
        }
      }
    })
  }

  assert {
    condition     = length(github_repository.this) == 1 && length(github_repository.bootstrap) == 1 && length(gitlab_project.this) == 0 && length(gitlab_project.bootstrap) == 0 && length(data.gitlab_group.this) == 0
    error_message = "GitHub bootstrap must create only GitHub repositories and skip the GitLab group lookup."
  }

  assert {
    condition     = length(github_repository_file.bootstrap) == 15 && length(github_repository_file.alz) == 2 && contains(keys(github_repository_file.bootstrap), "gitlab.tf") && contains(keys(github_repository_file.bootstrap), "files/providers.gitlab.tf") && contains(keys(github_repository_file.bootstrap), "PERMISSIONS.md") && github_repository_file.bootstrap["main.tf"].repository == github_repository.bootstrap[0].name && github_repository_file.alz["providers.tf"].repository == github_repository.this[0].name && github_repository_file.alz["providers.tf"].content == file("${path.root}/files/providers.tf") && length(gitlab_repository_file.bootstrap) == 0 && length(gitlab_repository_file.alz) == 0
    error_message = "GitHub bootstrap must upload bootstrap files and the GitHub landing-zone provider template only."
  }

  assert {
    condition     = local.vcs_repo.github_app_installation_id == "98765" && try(local.vcs_repo.oauth_token_id, null) == null && local.vcs_repo.branch == "main" && local.vcs_repo.identifier == github_repository.this[0].full_name
    error_message = "The GitHub workspace must use the GitHub App connection and selected branch."
  }

  assert {
    condition     = contains(keys(local.workspace_env_vars), "github_owner") && contains(keys(local.workspace_env_vars), "github_app_id") && contains(keys(local.workspace_env_vars), "github_app_pem_file") && contains(keys(local.workspace_env_vars), "TFE_TOKEN") && !contains(keys(local.workspace_env_vars), "GITLAB_TOKEN")
    error_message = "GitHub bootstrap must populate GitHub and common workspace variables but no GitLab token."
  }

  assert {
    condition     = local.workspace_env_vars["github_owner"].value == "example-org" && local.workspace_env_vars["github_app_pem_file"].sensitive && local.workspace_env_vars["TFE_TOKEN"].sensitive && local.workspace_env_vars["github_app_pem_file"].category == "terraform"
    error_message = "GitHub workspace variables must include the owner and protect credentials."
  }
}

run "gitlab" {
  command = plan

  providers = {
    azurerm              = azurerm
    azurerm.connectivity = azurerm.connectivity
    azuread              = azuread
    gitlab               = gitlab.mocked
    tfe                  = tfe
    local                = local
    random               = random
    time                 = time
  }

  variables {
    gitlab_token = "test-only-placeholder"
    config = merge(var.config, {
      terraform_cloud = merge(var.config.terraform_cloud, {
        vcs_repo_oauth_token_id = "ot-12345"
      })
      gitlab = {
        group                 = "example-group"
        repository            = "landing-zones"
        description           = "Landing zones"
        branch                = "main"
        bootstrap_repository  = "landing-zones-bootstrap"
        bootstrap_description = "Bootstrap"
        bootstrap_branch      = "main"
      }
    })
  }

  assert {
    condition     = length(gitlab_project.this) == 1 && length(gitlab_project.bootstrap) == 1 && length(data.gitlab_group.this) == 1 && gitlab_project.this[0].namespace_id == 12345 && length(github_repository.this) == 0 && length(github_repository.bootstrap) == 0
    error_message = "GitLab bootstrap must create only GitLab projects in the selected group."
  }

  assert {
    condition     = length(gitlab_repository_file.bootstrap) == 15 && length(gitlab_repository_file.alz) == 2 && contains(keys(gitlab_repository_file.bootstrap), "github.tf") && contains(keys(gitlab_repository_file.bootstrap), "files/providers.gitlab.tf") && contains(keys(gitlab_repository_file.bootstrap), "PERMISSIONS.md") && gitlab_repository_file.bootstrap["main.tf"].project == gitlab_project.bootstrap[0].id && gitlab_repository_file.alz["providers.tf"].project == gitlab_project.this[0].id && gitlab_repository_file.alz["providers.tf"].content == file("${path.root}/files/providers.gitlab.tf") && gitlab_repository_file.alz["variables.tf"].content == file("${path.root}/files/variables.gitlab.tf") && gitlab_repository_file.alz["providers.tf"].branch == "main" && length(github_repository_file.bootstrap) == 0 && length(github_repository_file.alz) == 0
    error_message = "GitLab bootstrap must upload bootstrap files and GitLab landing-zone templates only."
  }

  assert {
    condition     = local.vcs_repo.oauth_token_id == "ot-12345" && try(local.vcs_repo.github_app_installation_id, null) == null && local.vcs_repo.branch == "main" && local.vcs_repo.identifier == gitlab_project.this[0].path_with_namespace
    error_message = "The GitLab workspace must use the OAuth connection and selected branch."
  }

  assert {
    condition     = contains(keys(local.workspace_env_vars), "GITLAB_TOKEN") && contains(keys(local.workspace_env_vars), "TFE_TOKEN") && !contains(keys(local.workspace_env_vars), "github_owner") && !contains(keys(local.workspace_env_vars), "github_app_pem_file") && local.workspace_env_vars["GITLAB_TOKEN"].category == "env" && local.workspace_env_vars["GITLAB_TOKEN"].sensitive
    error_message = "GitLab bootstrap must inject a sensitive GitLab token and common variables, without GitHub variables."
  }
}

run "neither_vcs" {
  command = plan

  expect_failures = [var.config]
}

run "both_vcs" {
  command = plan

  variables {
    github_app_pem_file = base64encode("test-only-placeholder")
    config = merge(var.config, {
      github = {
        owner                 = "example-org"
        repository            = "landing-zones"
        description           = "Landing zones"
        branch                = "main"
        bootstrap_repository  = "landing-zones-bootstrap"
        bootstrap_description = "Bootstrap"
        provider = {
          id              = "12345"
          installation_id = "54321"
        }
      }
      gitlab = {
        group                 = "example-group"
        repository            = "landing-zones"
        description           = "Landing zones"
        branch                = "main"
        bootstrap_repository  = "landing-zones-bootstrap"
        bootstrap_description = "Bootstrap"
        bootstrap_branch      = "main"
      }
    })
  }

  expect_failures = [var.config]
}
