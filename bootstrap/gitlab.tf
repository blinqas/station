data "gitlab_group" "this" {
  count     = local.use_github ? 0 : 1
  full_path = var.config.gitlab.group
}

resource "gitlab_project" "this" {
  count                  = local.use_github ? 0 : 1
  name                   = var.config.gitlab.repository
  description            = var.config.gitlab.description
  namespace_id           = tonumber(data.gitlab_group.this[0].id)
  visibility_level       = "private"
  initialize_with_readme = true
  default_branch         = var.config.gitlab.branch
}

resource "gitlab_project" "bootstrap" {
  count                  = local.use_github ? 0 : 1
  name                   = var.config.gitlab.bootstrap_repository
  description            = var.config.gitlab.bootstrap_description
  namespace_id           = tonumber(data.gitlab_group.this[0].id)
  visibility_level       = "private"
  initialize_with_readme = true
  default_branch         = var.config.gitlab.bootstrap_branch
}

resource "gitlab_repository_file" "bootstrap" {
  for_each = local.use_github ? toset([]) : toset([
    "main.tf",
    "providers.tf",
    "variables.tf",
    "github.tf",
    "gitlab.tf",
    "locals.tf",
    "providers/providers.cloud.tf",
    "providers/providers.local.tf",
    "files/providers.tf",
    "files/providers.gitlab.tf",
    "files/variables.tf",
    "files/variables.gitlab.tf",
    "files/variables.bootstrap.tf",
    "lz.auto.tfvars",
    "README.md",
    "PERMISSIONS.md"
  ])

  project             = gitlab_project.bootstrap[0].id
  file_path           = each.value
  branch              = var.config.gitlab.bootstrap_branch
  encoding            = "text"
  content             = file("${path.root}/${each.value}")
  commit_message      = "${each.value} [skip ci]"
  overwrite_on_create = true # Replaces the README created by initialize_with_readme.
}

resource "gitlab_repository_file" "alz" {
  for_each = local.use_github ? toset([]) : toset([
    "providers.tf",
    "variables.tf"
  ])

  project             = gitlab_project.this[0].id
  file_path           = each.value
  branch              = var.config.gitlab.branch
  encoding            = "text"
  content             = file("${path.root}/files/${each.value == "providers.tf" ? "providers.gitlab.tf" : "variables.gitlab.tf"}")
  commit_message      = "${each.value} [skip ci]"
  overwrite_on_create = true

  lifecycle {
    ignore_changes = [content]
  }

  depends_on = [module.station]
}

resource "gitlab_repository_file" "alz_bootstrap_variables" {
  count = local.use_github ? 0 : 1

  project        = gitlab_project.this[0].id
  file_path      = "variables.bootstrap.tf"
  branch         = var.config.gitlab.branch
  encoding       = "text"
  content        = file("${path.root}/files/variables.bootstrap.tf")
  commit_message = "variables.bootstrap.tf [skip ci]"

  depends_on = [gitlab_repository_file.alz]
}
