variable "projects" {
  description = "Projects to create"
  type = map(object({
    project_name = string
  }))
  default = {}
}

