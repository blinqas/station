# Selective Test Execution

This directory contains the script used to determine which Terraform tests should run based on file changes in a pull request or push.

## How It Works

The `determine-tests.sh` script analyzes changed files and maps them to the relevant test files:

### Test Mapping Rules

| Changed Files | Tests Triggered |
|--------------|----------------|
| `application/**`, `variables.applications.tf`, `applications.tf`, `application_federated_identity_credential.tf` | `tests/application.tftest.hcl` |
| `group/**`, `groups.tf` | `tests/group.tftest.hcl` |
| `hashicorp/tfe/**`, `tfe.tf` | `tests/tfe.tftest.hcl` |
| `connectivity.tf` | `tests/connectivity.tftest.hcl` |
| `user_assigned_identity/**`, `user_assigned_identities.tf`, `variables.identity.tf` | `tests/identity.tftest.hcl`, `tests/user_assigned_identities.tftest.hcl` |
| **Core files** (see below) | **All tests** |

### Core Files (Trigger All Tests)

Changes to these files affect all modules and trigger all tests:
- `variables.tf` - Main variables used by all modules
- `providers.tf` - Provider configuration
- `resource_group.tf` - Resource group creation (used by all modules)
- `id.tf` - Station ID (used throughout)
- `tags.tf` - Tags (applied to all resources)
- `data.tf` - Data sources
- `outputs.tf` - Module outputs
- `role_assignment.tf` - Role assignments (can affect multiple modules)
- `bootstrap/**` - Bootstrap module (foundational)
- `tests/**/*.tftest.hcl` - Test files themselves
- `tests/setup-*/**` - Test setup modules
- `.github/workflows/terraform.yaml` - Workflow configuration
- `.github/scripts/determine-tests.sh` - This script

### Safety Features

- **Uncategorized files**: Any `.tf` file not explicitly categorized will trigger all tests for safety
- **Documentation-only changes**: If no relevant Terraform files changed, all tests run as a safety measure
- **Multiple changes**: If files from multiple modules are changed, the corresponding tests for each module will run

## Manual Test Triggering

You can manually trigger all tests on a pull request by commenting:

```
/test-all
```

or

```
/test all
```

The workflow will react with a 🚀 emoji to acknowledge the trigger.

## Automatic Triggers

All tests automatically run for:
- **Manual workflow dispatch** (workflow_dispatch event)
- **Releases** (release events)
- **Comment triggers** (`/test-all` or `/test all` comments on PRs)

## Examples

### Example 1: Application Module Change
**Changed files:**
```
application/azuread_application.tf
variables.applications.tf
```
**Tests run:**
- `tests/application.tftest.hcl`

### Example 2: Multiple Module Changes
**Changed files:**
```
group/group.tf
hashicorp/tfe/tfe_workspace.tf
```
**Tests run:**
- `tests/group.tftest.hcl`
- `tests/tfe.tftest.hcl`

### Example 3: Core File Change
**Changed files:**
```
variables.tf
```
**Tests run:**
- All tests (application, group, tfe, connectivity, identity, user_assigned_identities)

### Example 4: Identity Module Change
**Changed files:**
```
user_assigned_identity/user_assigned_identity.tf
```
**Tests run:**
- `tests/identity.tftest.hcl`
- `tests/user_assigned_identities.tftest.hcl`

(Both tests run because they both test identity-related functionality)

## Benefits

- **Faster CI/CD**: Only run tests affected by your changes
- **Cost savings**: Reduce GitHub Actions minutes by avoiding unnecessary test runs
- **Better feedback**: Get faster feedback on changes that affect specific modules
- **Safety**: Conservative approach ensures all tests run when core files change or when changes are uncertain
