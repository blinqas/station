output "group" {
  value = azuread_group.group
}

output "display_name" {
  value = azuread_group.group.display_name 
}

output "object_id" {
  value = azuread_group.group.object_id 
}

