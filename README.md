# Station Terraform Module

Terraform Station is a flexible module you can use to provision and manage workload environments in Azure. Quickly create environments for different workloads with automatic provisioning of applications, service principals, groups, user assigned identities and more. Station focuses on a modern approach for infrastructure deployment; Station lets you create Terraform Cloud workspaces which are automatically configured to deploy with your workload identity, powered by OIDC. Station uses a flat structure with preferrably a monorepo for your different workloads. You can deploy multiple versions of Station if you need to. 

This module is aimed at small teams who manage Azure workload environments. You can think of Station as a train station, and Azure as your destination. To get to Azure, your IaC deployments must start with Station.

Check out our Design Decision document [here.](https://github.com/blinqas/station/blob/trunk/DESIGN_DESICIONS.md)

Station is maintained by the DevOps team at blinQ (https://blinq.no).

## Usage

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

### Requirements

- Terraform Cloud account
- Azure- Tenant and Subscription
- Global Administrator on Azure AD
- Owner on Subscription

### Example

```terraform

```

## How it works

## Contact

- Kim Iversen | [kim.iversen@blinq.no](mailto:kim.iversen@blinq.no)

