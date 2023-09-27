# Station bootstrapping

This folder contains Terraform files to bootstrap Azure and Terraform Cloud for Station.

## What does it do?

1. Create a service principal in Azure AD
2. Assigns it Global Administrator on the logged in Azure AD tenant
3. Assigns it Owner on the logged in subscription
4. Create two Federated Identity Credential configurations for OIDC between the Terraform Cloud Workspace it provisions for Station Deployments.
5. Creates a Terraform Cloud Project in the logged in Terraform Cloud Organization
6. Creates a Terraform Cloud Workspace for the bootstrap state
7. Creates a Terraform Cloud Workspace for the deployment state
8. Connects the deployment workspace with the user specified VCS repo
9. Creates Terraform Environment variables in the deployment workspace for Azure authentication

## Why the need for this?

Provisioning all these resources and linking them together and what not is very cumbersome. This hopfully solves that and makes it easier to understand what Station requires.

Demoing Station is also very fast now!

## Usage

IMPORTANT! Do not scripts from the internet without understanding what it does.

Before you begin:
- Log in to Azure with `az login`
- Log in to Terraform Cloud CLI with `terraform login`
- Log in to Github and create an oauth token or an app installation. You will have to provide this inside the `varibles.tfvars.json`` file
- This script is not idempotent, only run this once!
- You might want to modify it to include all `-var` from `variables.tf`.

```bash
./bootstrap.sh
```

