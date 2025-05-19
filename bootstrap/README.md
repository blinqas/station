# Station Bootstrap

Bootstrap process for **Station** — a Terraform module that provisions secure, automated landing zones in Azure, ready for infrastructure deployment.

---

## Who is this for?

DevOps and Platform Engineers deploying Azure infrastructure using GitHub and Terraform Cloud. This bootstraps a complete CI/CD flow using GitHub Apps, Terraform Cloud, and OIDC-based identity.

---

## Prerequisites

- A GitHub [User | Org | Enterprise] account
- An HCP Terraform account
- Terraform CLI installed

---

## Overview

This bootstrap process does the following:

- Creates two GitHub Apps:
  - One for Terraform Cloud VCS connection
  - One for managing GitHub via Terraform (`integrations/github`)
- Creates service accounts (workaround for TFC user bindings)
- Links GitHub and HCP Terraform
- Runs initial Terraform to set up the Station landing zone and migrate state

---

## 1. Create GitHub Service Account

> [!NOTE]
> Required because Terraform Cloud links GitHub App to *user*, not *org*.

1. Create a new GitHub user
2. Invite it to your organization
3. Assign it admin permissions

Use this account for all GitHub App actions below.

---

## 2. Create HCP Terraform Service Account

[Background](https://github.com/hashicorp/terraform-provider-tfe/issues/853)

1. Create a dedicated HCP Terraform user
2. Add it to the `owners` team
3. Generate a User API Token:
   - Description: `Station Landing Zones`
   - Expiration: `No expiration`
4. Store the token securely

---

## 3. Create GitHub App: Station LZ Management

Used by Terraform to manage GitHub (via `integrations/github` provider)

1. Create a new GitHub App at `https://github.com/organizations/<your-org>/settings/apps/new`

   Recommended settings:
   - Name: `Station LZ (Org Name)`
   - Description: GitHub app for Terraform-based org/repo management via Station
   - Homepage: `<your org’s website>`
   - **Webhook: Disabled**
   - **Repository permissions:**
     - Administration: Read/Write
     - Contents: Read/Write
2. Generate a private key  
   Save it as `station-landing-zones.pem` in the bootstrap directory.
3. Install the app in your GitHub org

---

## 4. Create GitHub App: HCP Terraform VCS Link

Used by HCP Terraform to watch GitHub commits and trigger runs.

> [!CAUTION]
> Perform this as the GitHub *Service Account* (step 1) and authenticate in Terraform Cloud as the *TFC Service Account* (step 2)

1. In HCP Terraform:
   - Go to **Settings > VCS Providers > Add VCS Provider**
   - Follow the flow to register the GitHub App

2. After installation, note:
   - GitHub App Installation ID: `ghain-xxxxxxxxxxxx`

---

## 5. Run Bootstrap

### Environment variables

- Set up environment:

```bash
# bash:
export TF_VAR_github_app_pem_file=$(base64 -i ./station-landing-zones.pem)
export TF_VAR_tfe_token="your-tfc-token"
export TFE_TOKEN="$TF_VAR_tfe_token"
export TF_TOKEN="$TF_VAR_tfe_token"

# fish:
set -x TF_VAR_github_app_pem_file (base64 -i ./station-landing-zones.pem)
set -x TF_VAR_tfe_token "your-tfc-token"
set -x TFE_TOKEN "$TF_VAR_tfe_token"
set -x TF_TOKEN "$TF_VAR_tfe_token"
```

- Configure variables

Fill out the configuration file `application-landing-zone.auto.tfvars`:
```hcl
# hints
vcs_repo_github_app_installation_id = "<string>" # Installation ID from step 4.2 (ghain-xxxxxx...)
github.provider.id                  = "<string>" # App ID from step 3
github.provider.installation_id     = "<string>" # Installation ID from step 3
```

- Run Terraform

```shell
# bash:
export TF_WORKSPACE=$(awk -F'"' '/bootstrap_workspace_name/ {print $2}' application-landing-zone.auto.tfvars)
terraform init
terraform plan -out plan.tfplan
terraform apply plan.tfplan

# fish:
set -x TF_WORKSPACE (awk -F'"' '/bootstrap_workspace_name/ {print $2}' application-landing-zone.auto.tfvars)
terraform init
terraform plan -out plan.tfplan
terraform apply plan.tfplan
```

- Migrate state to Terraform Cloud

```shell
# bash:
export TF_CLOUD_ORGANIZATION=$(awk -F'"' '/organization_name/ {print $2}' application-landing-zone.auto.tfvars)
export TF_WORKSPACE=$(awk -F'"' '/bootstrap_workspace_name/ {print $2}' application-landing-zone.auto.tfvars)
terraform init
terraform plan -out plan.tfplan
terraform apply plan.tfplan
unset TF_CLOUD_ORGANIZATION
unset TF_WORKSPACE

# fish:
set -x TF_CLOUD_ORGANIZATION (awk -F'"' '/organization_name/ {print $2}' application-landing-zone.auto.tfvars)
set -x TF_WORKSPACE (awk -F'"' '/bootstrap_workspace_name/ {print $2}' application-landing-zone.auto.tfvars)
terraform init
terraform plan -out plan.tfplan
terraform apply plan.tfplan
set -e TF_CLOUD_ORGANIZATION
set -e TF_WORKSPACE
```

---

- Clean up

> [!IMPORTANT]
> Final terraform destroy will fail to update state, because the state has already moved to Terraform Cloud. This is expected. You can safely ignore the error.

- To destroy:
```shell
# bash:
export TF_CLOUD_ORGANIZATION=$(awk -F'"' '/organization_name/ {print $2}' application-landing-zone.auto.tfvars)
export TF_WORKSPACE=$(awk -F'"' '/bootstrap_workspace_name/ {print $2}' application-landing-zone.auto.tfvars)
terraform destroy
unset TF_CLOUD_ORGANIZATION
unset TF_WORKSPACE

# fish:
set -x TF_CLOUD_ORGANIZATION (awk -F'"' '/organization_name/ {print $2}' application-landing-zone.auto.tfvars)
set -x TF_WORKSPACE (awk -F'"' '/bootstrap_workspace_name/ {print $2}' application-landing-zone.auto.tfvars)
terraform destroy
set -e TF_CLOUD_ORGANIZATION
set -e TF_WORKSPACE
```

