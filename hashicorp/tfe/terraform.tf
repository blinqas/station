terraform {
  required_providers {
    tfe = {
      # https://registry.terraform.io/providers/hashicorp/tfe/latest/docs
      source  = "hashicorp/tfe"
      version = "~> 0.48.0"
    }
  }
}

provider "tfe" {
  # Configuration options
  # Authentication token sourced from TFE_TOKEN
}

