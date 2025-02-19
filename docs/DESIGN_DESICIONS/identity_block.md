### Design Decision: Merging Multiple Variables into the Identity Block

**Date:** Feb 19, 2025  
**Author:** Sander Blomvågnes  

#### Context  
Previously, the landing zone/workload identity was configured using the following variables:  

- `var.managed_identity_name`  
- `var.app_role_assignments`  
- `var.group_memberships`  
- `var.role_assignment`  

To improve organization and usability, these variables have now been consolidated into a new variable named `var.identity`.  

#### Reasoning  
- Enhances module usability by grouping related variables into a single map variable.  

#### Implementation

#### Known Limitations
- All `role_assignments` without a specified scope will be created on all resource groups in the landing zone (LZ).

#### Summary  
- Introduced `var.identity` to centralize identity configuration for the landing zone.  
- Migrated existing variables to the new structure:  
  - `var.managed_identity_name` → `var.identity.name`
  - `var.app_role_assignments` → `var.identity.app_role_assignments`  
  - `var.group_memberships` → `var.identity.group_memberships`  
  - `var.role_assignment` → `var.identity.role_assignments` (now supporting multiple role assignments)  
- Added support for assigning `azuread_directory_role_assignment` to the landing zone identity. 


