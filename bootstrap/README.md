# Station Bootstrap

Bootstrap process for **Station** — a Terraform module that provisions secure, automated landing zones in Azure, ready for infrastructure deployment.

---

## Who is this for?

DevOps and Platform Engineers deploying Azure infrastructure using GitHub and Terraform Cloud. This bootstraps a complete CI/CD flow using GitHub Apps, Terraform Cloud, and OIDC-based identity.


## Security ⚠️
By default, this configuration provisions a **managed identity** with:

- **Owner** on the subscription  
- **Global Administrator** in Entra ID  

You **can** change these defaults, but doing so may **limit which permissions** can be assigned to application landing zones later.  
For example, assigning a landing zone the **Fabric Administrator** role requires the identity to have at least **Privileged Role Administrator** or Grant tenant wide permissions to application requires other priviliged permissions.

This bootstrap process is **not intended to be rerun**, so avoid expecting to add more roles later.

---

### 🔐 Security Recommendations

To secure the landing zone application repository:

1. **Restrict access** to only required users, as they indirectly inherit **GA** and **Owner** permissions.
2. **Block direct pushes** to the `main` branch.
3. **Require pull requests** with at least **one reviewer**.
4. Enforce **2FA/MFA** for all users with access.
---

## Prerequisites

- A GitHub [User | Org | Enterprise] account
- An HCP Terraform account
- Terraform CLI installed

---

## Overview

This bootstrap process does the following:

- Creates two apps:
  - One for Terraform Cloud VCS connection (OAuth app)
  - One for managing GitHub via Terraform (`integrations/github`) (Github app)
- Creates service accounts (workaround for TFC user bindings)
- Links GitHub and HCP Terraform
- Runs initial Terraform to set up the Station landing zone and migrate state

---

## 2. Create GitHub App: Station LZ Management

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

## 3. Create GitHub OAuth App for HCP Terraform VCS Integration

HCP Terraform uses a **custom GitHub OAuth app** to watch commits and trigger runs.

> **Note:**  
> Do **not** use the official GitHub app.  
> It links the integration to the user who adds it, which would require a dedicated service account.  
> Using a custom OAuth app avoids this issue.

---

### 1. Configure VCS Provider in HCP Terraform

1. Go to [**Settings → VCS Providers → Add VCS Provider**](https://app.terraform.io/app/ccbas/settings/version-control/add).
2. Select **GitHub (Custom)** and follow the setup guide.

---

### 2. Ensure OAuth App Is Registered at the GitHub Organization

- Verify that the OAuth app is registered at the **organization level**.  
- If not, [**transfer ownership**](https://docs.github.com/en/apps/oauth-apps/maintaining-oauth-apps/transferring-ownership-of-an-oauth-app) to the organization.

---

### 3. Write down the app ID for later usage

Save the APP ID for later. To find it do the following:

1. Go to  
   `https://github.com/organizations/<your-org>/settings/applications/`
2. Click on the OAuth application.
3. Copy the **application ID** from the URL, e.g.:  

---

## 4. Run Bootstrap

### Environment variables

#### Set up environment:

```bash
# bash:
export TF_VAR_tfe_token="your-tfc-token"
export TFE_TOKEN="$TF_VAR_tfe_token"
export TF_TOKEN="$TF_VAR_tfe_token"

# fish:
set -x TF_VAR_tfe_token "your-tfc-token"
set -x TFE_TOKEN "$TF_VAR_tfe_token"
set -x TF_TOKEN "$TF_VAR_tfe_token"
```

```powershell
#Powershell 7.x
$env:TF_VAR_tfe_token = "your-tfc-token"
$env:TFE_TOKEN       = $env:TF_VAR_tfe_token
$env:TF_TOKEN       = $env:TF_VAR_tfe_token
``` 
#### Configure variables

Fill out the configuration file `application-landing-zone.auto.tfvars`:
```hcl
# hints
config.terraform_cloud.vcs_repo_github_oauth_token_id = "<string>" # Oauth APP ID from step 3.3 (1234567)
config.github.provider.id                  = "<string>" # App ID from step 2 (1234567)
config.github.provider.installation_id     = "<string>" # Installation ID from step 2 (12345678)
config.github.pem_file_path                = "<string>" # Path to the .pem file you downloaded after creating the Github App
```

#### Run Terraform

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
```powershell
#Powershell 7.x
$env:TF_WORKSPACE = (Select-String 'bootstrap_workspace_name' application-landing-zone.auto.tfvars | ForEach-Object { ($_ -split '"')[1] });
terraform init;
terraform plan -out plan.tfplan;
terraform apply plan.tfplan;
``` 

#### Migrate state to Terraform Cloud

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
```powershell
#Powershell 7.x
$env:TF_CLOUD_ORGANIZATION = (Select-String 'organization_name' application-landing-zone.auto.tfvars | ForEach-Object { ($_ -split '"')[1] }); `
$env:TF_WORKSPACE = (Select-String 'bootstrap_workspace_name' application-landing-zone.auto.tfvars | ForEach-Object { ($_ -split '"')[1] }); `
terraform init; terraform plan -out plan.tfplan; terraform apply plan.tfplan; `
Remove-Item Env:TF_CLOUD_ORGANIZATION; Remove-Item Env:TF_WORKSPACE
``` 
---

#### Clean up

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

```powershell
#Powershell 7.x
$env:TF_CLOUD_ORGANIZATION = (Select-String 'organization_name' application-landing-zone.auto.tfvars | ForEach-Object { ($_ -split '"')[1] }); `
$env:TF_WORKSPACE = (Select-String 'bootstrap_workspace_name' application-landing-zone.auto.tfvars | ForEach-Object { ($_ -split '"')[1] }); `
terraform destroy; `
Remove-Item Env:TF_CLOUD_ORGANIZATION; Remove-Item Env:TF_WORKSPACE
``` 