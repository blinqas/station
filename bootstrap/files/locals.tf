locals {
  vcs_repo = {
    for k, v in github_repository.this : k => {
      identifier                 = v.full_name
      branch                     = "trunk"
      github_app_installation_id = var.vcs_repo_github_app_installation_id
    }
  }
}