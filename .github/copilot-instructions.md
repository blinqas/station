Our team uses Github for tracking items of work.

This project is called Station, and it is a Terraform module that allows for deployment of Application Landing Zones in Azure.

Station is meant to be called as a module, from a parent module. This means you need to refer to the `variables.tf` file (and other variable files) to understand the input to Station.

We run `terraform fmt -recursive` to format the code before it is committed.

We do not run `terraform validate` before committing, as it is not supported when we use `configuration_aliases` on the `azurerm` provider.
