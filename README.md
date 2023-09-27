# Station Terraform Module

Station is a Terraform module that lets you quickly spin up new workload environments in Azure and Terraform Cloud. Station enables high level of automation for something as simple as a workload environment.

## Why does Station exist?

To quickly enable users to deploy workload environments safely into Azure. Isolating Entra ID and Azure Subscription interactions from the actual workload environment. Station consists of three parts; bootstrap, deployments and workload environment.

- Bootstrap: setting up a Station for your Azure subscription(s) and tenant. (Administrator with permissions on Subscription and Entra ID/Azure AD)
- Deployments: Where workload environments are defined and deployed. (Application Team/DevOps/SRE/Platform Engineer/Cloud Engineer)
- Workload Environment: The workload environment where infrastructure is deployed to. (Application Team)

## Who uses Station? 

Station is used primarily in context of application development and hosting; DevOps, GitOps, SRE's or Platform Engineers. There is nothing wrong with using Station in operations; we encourage it!

---

Check out our Design Decision document [here.](https://github.com/blinqas/station/blob/trunk/DESIGN_DESICIONS.md)

Station is maintained by the DevOps team at blinQ (https://blinq.no).

## Usage

The following example deploys a workload environment for common resources, in this environment we would deploy Container Registries for example.

Consider the following file structure:

```bash
common.tf
github_repositories.tf
tags.tf
variables.tf
```

```bash
cat common.tf
```

```terraform
module "common" {
  source              = "git::https://github.com/blinqas/station.git?ref=1.3.0"
  environment_name    = "prod"
  resource_group_name = "common"
  tags                = local.tags.common
  tfe = {
    organization_name     = "my-tfc-organization"
    project_name          = "Azure"
    workspace_name        = "common"
    workspace_description = "Common resources which are shared between workloads."
    vcs_repo = {
      identifier     = github_repository.repos["common"].full_name
      branch         = "trunk"
      oauth_token_id = var.vcs_repo_oauth_token_id
    }
  }
}
```

This file would provision the following:

- Resource Group
- Managed Identity
    - Service Principal is assigned Owner on Resource Group
- Federated Credential (OIDC to authenticate Terraform Cloud runners)
- Terraform Cloud (TFC) Workspace
    - Configured to run on commits to trunk branch
    - Configured to authenticate to VCS with token already in Terraform Cloud
- TFC Environment Variables for OIDC authentication with Managed Identity

### Requirements

- Terraform Cloud account
    - Permission to create Team Token
- Azure- Tenant and Subscription
    - Global Administrator on Azure AD
    - Owner on Subscription

## Contact

- Kim Iversen | [kim.iversen@blinq.no](mailto:kim.iversen@blinq.no)
- Sander Blomvågnes | [sander@blinq.no](mailto:sander@blinq.no)
- Erik Hansen | [erik.hansen@blinq.no](mailto:erik.hansen@blinq.no)


## License

MIT
