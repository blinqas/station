resource "github_repository" "deployments" {
  name        = var.vcs_repo_identifier
  description = "Station deployments"

  visibility = "private"

  template {
    owner                = "blinqas"
    repository           = "gh-template-station-workload"
    include_all_branches = true
  }
}