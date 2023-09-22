variable "display_name" {
  description = "Display name of the AD Group"
  type        = string
}

variable "owners" {
  description = "Object IDs of the owners for the group"
  type        = set(string)
}

variable "members" {
  description = "Object IDs of the members for the group"
  type        = set(string)
}

variable "security_enabled" {
  description = "Whether the security is enabled for the AD Group"
  type        = bool
}


variable "dynamic_membership" {
  description = "Dynamic membership settings for the AD Group"
  type = object({
    enabled = bool,
    rule    = string
  })
}

variable "types" {
  description = "A set of group types to configure for the group."
  type        = set(string)
  nullable    = true
}

