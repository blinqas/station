resource "github_repository" "this" {
  name        = var.config.github.repository
  description = var.config.github.description
  visibility  = "private"
  auto_init   = true
}

resource "github_repository" "bootstrap" {
  name        = var.config.github.bootstrap_repository
  description = var.config.github.bootstrap_description
  visibility  = "private"
  auto_init   = true
}

resource "github_repository_file" "bootstrap" {
  for_each = toset([
    "main.tf",
    "providers.tf",
    "variables.tf",
    "github.tf",
    "locals.tf",
    "application-landing-zone.auto.tfvars",
    "README.md"
  ])
  file                = each.value
  content             = file("${path.root}/${each.value}")
  repository          = github_repository.bootstrap.name
  commit_message      = "${each.value} [skip ci]"
  overwrite_on_create = true # required as auto_init on repo is on
}

resource "github_repository_file" "alz_applications" {
  for_each = toset([
    "providers.tf",
    "variables.tf"
  ])
  file                = each.value
  content             = file("${path.root}/files/${each.value}")
  repository          = github_repository.this.name
  commit_message      = "${each.value} [skip ci]"
  overwrite_on_create = true # required as auto_init on repo is on
  lifecycle {
    ignore_changes = [content] # allow end user to make changes to their LZ
  }
}
