module "station-identity" {
  depends_on      = [tfe_project.test]
  source          = "./.."
  tenant_id       = var.tenant_id
  subscription_id = var.subscription_id

  tfe = {
    project_name          = tfe_project.test.name
    organization_name     = data.tfe_organization.test.name
    workspace_description = "This workspace contains identity_tests from https://github.com/blinqas/station.git"
    workspace_name        = "station-tests-identity_tests"
  }

  resource_groups = {
    test = {
      name     = "rg-identity-test-2"
      location = "norwayeast"
    }
  }

  identity = {
    name = "testname-test"
    role_assignments = {
      key_vault_admin = {
        role_definition_name = "Key Vault Administrator"
      }
      key_vault_crypto_officer = {
        role_definition_id = "/subscriptions/${data.azurerm_client_config.current.subscription_id}/providers/Microsoft.Authorization/roleDefinitions/db79e9a7-68ee-4b58-9aeb-b90e7c24fcba" # Key Vault Certificate User
        scope              = azurerm_resource_group.identity_test_rg.id
      }
    }
    app_role_assignments = ["User.Read.All"]
    group_memberships = {
      "Identity Test Group" = azuread_group.identity_group.object_id
    }
    directory_role_assignment = {
      minimal = {
        role_name = "Application Administrator"
      }
      directory_scope = {
        role_name           = "Application Developer"
        principal_object_id = data.azurerm_client_config.current.object_id
        directory_scope_id  = "/"
      }
    }
  }
}

resource "azurerm_resource_group" "identity_test_rg" {
  name     = "rg-identity-test"
  location = "norwayeast"
}

resource "azuread_group" "identity_group" {
  display_name     = "Identity Test Group"
  security_enabled = true
  description      = "This group is used to test the identity module"
}
