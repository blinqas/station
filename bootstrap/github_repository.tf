resource "github_repository" "deployments" {
  name        = var.vcs_repo_name
  description = "Station deployments"
  visibility  = "private"
}

resource "github_branch" "deployments" {
  repository = github_repository.deployments.name
  branch     = var.vcs_repo_branch == null ? "trunk" : var.vcs_repo_branch
}

resource "github_branch_default" "deployments"{
  repository = github_repository.deployments.name
  branch     = github_branch.deployments.branch
}