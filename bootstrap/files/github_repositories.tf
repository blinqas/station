resource "github_repository" "this" {
  for_each     = local.repositories
  name         = each.value.name
  description  = each.value.description
  visibility   = try(each.value.visibility, "private")
  has_wiki     = try(each.value.has_wiki, false)
  auto_init    = try(each.value.auto_init, true)
  has_issues   = true
  has_projects = try(each.value.has_projects, true)
  template {
    owner                = var.github_owner
    repository           = "gh-template-station-workload"
    include_all_branches = false
  }
}
resource "github_branch_default" "default" {
  for_each   = github_repository.this
  repository = each.value.name
  branch     = "trunk"
}

locals {
  repositories = {
    common = {
      name         = "common"
      description  = "Terraform configuration for Common resources"
      has_projects = true
    }
  }
}