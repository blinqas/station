variable "user" {
  type = object({
    user_principal_name = string,
    display_name = string,
    job_title = string
  })
  description = "User you want to create for use in the group tests "
  
}

resource "random_password" "test_user" {
  length = 24
}

resource "azuread_user" "test" {
  user_principal_name = var.user.user_principal_name
  display_name        = var.user.display_name
  job_title = var.user.job_title
  password = random_password.test_user.result
}

output "test_user_object_id" {
  value = azuread_user.test.object_id
}

data "azuread_client_config" "current" {}

output "current" {
  value = data.azuread_client_config.current
}