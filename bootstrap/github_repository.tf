resource "github_repository" "deployments" {
  name        = var.vcs_repo_identifier
  description = "Station deployments"

  visibility = "private"
}