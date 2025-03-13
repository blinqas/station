# Design Decision: Merging Multiple Variables into the Identity Block

**Date:** Feb 19, 2025  

## Context  
Station was unable to manage connectivity (networking) between Landing Zones provisioned with Station. This left the caller of the module with a lot of manual work, managing this in a landing zone instead.

## Reasoning  
- Simplifies network connectivity between landing zones
- Enables creation of Hub & Spoke, Mesh and other topologies within Station

## Implementation
Establish connectivity by configuring the `connectivity` block. This block is meant to configure multiple networks for your Landing Zone. Use the `connectivity.*.peerings` map to configure peering between the Landing Zone network and other networks.

## Known Limitations
- Connecting Virtual Networks in different resource groups managed by this landing zone is currently unavailable. Configure this manually in the landing zone configuration.
- The key used for a peering object must be unique across all connectivity objects

## Summary  
- Introduced `var.connectivity` for network connectivity.

