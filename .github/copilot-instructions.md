Our team uses Github for tracking items of work.

This project is called Station, and it is a Terraform module that allows for deployment of Application Landing Zones in Azure.

Station is meant to be called as a module, from a parent module. This means you need to refer to the `variables.tf` file (and other variable files) to understand the input to Station.

We run `terraform fmt -recursive` to format the code before it is committed.

We do not run `terraform validate` before committing, as it is not supported when we use `configuration_aliases` on the `azurerm` provider.


## Session Continuity (Do this first in new sessions)

When switching branches locally and reusing in-progress changes, use stash intentionally so work can be applied on multiple branches.

- Current shared WIP stash name: `station-multi-branch-wip-2026-02-26`
- Typical flow:

```bash
git stash list
git switch <target-branch>
git stash apply stash@{0}
```

- Use `git stash apply` (not `pop`) when the same changes are needed on multiple branches.
- Keep `.agent.test.env` local-only and never commit it.
- If test execution is requested, run preflight first:

```bash
sh ./.agents/skills/terraform-station-test/scripts/check-az-context.sh ./.agent.test.env
```
