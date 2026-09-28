resource "github_repository" "this" {
  count       = local.use_github ? 1 : 0
  name        = var.config.github.repository
  description = var.config.github.description
  visibility  = "private"
  auto_init   = true
}

resource "github_repository" "bootstrap" {
  count       = local.use_github ? 1 : 0
  name        = var.config.github.bootstrap_repository
  description = var.config.github.bootstrap_description
  visibility  = "private"
  auto_init   = true
}

resource "github_repository_file" "bootstrap" {
  for_each            = local.use_github ? local.bootstrap_files : toset([])
  file                = each.value
  content             = file("${path.root}/${each.value}")
  repository          = github_repository.bootstrap[0].name
  commit_message      = "${each.value} [skip ci]"
  overwrite_on_create = true # required as auto_init on repo is on
}

resource "github_repository_file" "alz" {
  for_each = local.use_github ? toset([
    "providers.github.tf",
    "variables.tf",
    "variables.github.tf"
  ]) : toset([])
  file                = each.value == "providers.github.tf" ? "providers.tf" : each.value
  content             = file("${path.root}/files/${each.value}")
  repository          = github_repository.this[0].name
  commit_message      = "${each.value} [skip ci]"
  overwrite_on_create = true # required as auto_init on repo is on
  lifecycle {
    ignore_changes = [content] # allow end user to make changes to their LZ
  }
  # explicit dependency to avoid failed initial terraform apply
  depends_on = [module.station]
}
