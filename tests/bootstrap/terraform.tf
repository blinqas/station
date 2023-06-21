terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "3.49.0"
    }

    azuread = {
      source  = "hashicorp/azuread"
      version = "2.36.0"
    }
  }

  backend "azurerm" {
    resource_group_name  = "rg-station-tests"
    storage_account_name = "sastationtests"
    container_name       = "station-tests-remote-state"
    key                  = "station_tests.tfstate"
  }
}

provider "azurerm" {
  features {

  }
}

data "azuread_client_config" "current" {}

data "azurerm_client_config" "current" {}

