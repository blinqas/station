variable "provider_configuration" {
  description = "See the official docs: https://registry.terraform.io/providers/hashicorp/tfe/latest/docs"
  type = object({
    organization = optional(string) 
  })
  default = {} 
}
