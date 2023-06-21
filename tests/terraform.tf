terraform {
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
    }
  }

  backend "azurerm" {
    resource_group_name  = "rg-station-tests"
    storage_account_name = "sastationtests"
    container_name       = "station-tests-remote-state"
    key                  = "tests.tfstate"
  }
}

provider "azurerm" {
  features {

  }
}


