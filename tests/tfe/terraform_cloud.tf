terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.71.0"
    }

    azuread = {
      source  = "hashicorp/azuread"
      version = "~> 2.41.0"
    }

    tfe = {
      # https://registry.terraform.io/providers/hashicorp/tfe/latest/docs
      source  = "hashicorp/tfe"
      version = "~> 0.48.0"
    }
  }
}

provider "azurerm" {
  features {}
}

data "azurerm_client_config" "current" {}

variable "github_app_installation_id" {
  description = "The installation id of GitHub App used with the TFE module."
  default     = null
}

locals {
  tfe_tests = {
    test = {
      environment_name = "test"
    },
  }
}

module "station-tfe" {
  for_each         = local.tfe_tests
  source           = "../../"
  environment_name = each.value.environment_name
  # Step 1: Create GitHub/BitBucket repositories

  # Step 2: Federated Identity Credential

  # Step 3: Terraform Cloud integration

  #  federated_identity_credential_config = {
  #    "plan" = {
  #      display_name = "plan"
  #      audiences    = ["api://AzureADTokenExchange"]
  #      issuer       = "https://app.terraform.io"
  #      subject      = "organization:managed-devops:project:Station Development:workspace:Test:run_phase:plan"
  #    },
  #    "apply" = {
  #      display_name = "apply"
  #      audiences    = ["api://AzureADTokenExchange"]
  #      issuer       = "https://app.terraform.io"
  #      subject      = "organization:managed-devops:project:Station Development:workspace:Test:run_phase:apply"
  #    }
  #  }

  tfe = {
    organization_name     = "managed-devops"
    project_name          = local.tfe_projects.tfe_tests.project_name
    workspace_name        = "tfe-${each.value.environment_name}"
    workspace_description = "This workspace is for testing Station's TFE integration"
    vcs_repo = {
      identifier                 = "kimfy/tfe-testing"
      github_app_installation_id = var.github_app_installation_id
    }
    module_outputs_to_workspace_var = {
      groups                   = true
      user_assigned_identities = true
      applications             = true
    }
    create_federated_identity_credential = true
  }
  applications = {
    "web" = {
      settings = {
        application_name = "tfe_test_tfc"

        web = {
          redirect_uris = ["http://localhost:7007/api/auth/microsoft/handler/frame"]

          implicit_grant = {
            access_token_issuance_enabled = true
            id_token_issuance_enabled     = true
          }
        }
      }

    }
  }

  user_assigned_identities = {
    "container-app-x" = {
      name = "id-ca-x"
      role_assignments = [
        "GroupMember.Read.All",
        "User.Read.All"
      ]
    }
  }

  groups = {
    admins = {
      settings = {
        display_name     = "tfe-testing Administrators"
        security_enabled = true
        owners           = [data.azurerm_client_config.current.object_id]
      }
    }
  }

  tags = {
    "owner" = "Kim"
  }
  depends_on = [
    tfe_project.projects
  ]
}

module "station-bitbucket" {
  source           = "../../"
  environment_name = "prod"

  tfe = {
    project_name          = local.tfe_projects.bitbucket.project_name
    workspace_name        = "testing-bitbucket-integration"
    workspace_description = "asd"
    vcs_repo = {
      identifier     = "blinq-kim/min-service"
      oauth_token_id = var.VCS_OAUTH_TOKEN_ID
    }
  }

  depends_on = [tfe_project.projects]
}


variable "VCS_OAUTH_TOKEN_ID" {
  type      = string
  sensitive = true
}
