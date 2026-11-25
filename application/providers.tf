terraform {
  required_version = "~> 1.12"
  required_providers {
    azuread = {
      source  = "hashicorp/azuread"
      version = "~>3.0"
    }
    msgraph = {
      source  = "microsoft/msgraph"
      version = "~> 0.6.0"
    }
  }
}
