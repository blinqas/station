resource "github_repository" "deployments" {
  name        = var.vcs_repo_name
  description = "Station deployments"
  visibility  = "private"
}