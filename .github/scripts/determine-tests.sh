#!/bin/bash
set -euo pipefail

# Script to determine which Terraform tests to run based on changed files
# Returns a JSON array of test files to run

# Get the list of changed files
# For PRs, compare against the base branch
# For pushes, compare against the previous commit
if [ -n "${GITHUB_BASE_REF:-}" ]; then
  # Pull request
  git fetch origin "$GITHUB_BASE_REF" --depth=1
  CHANGED_FILES=$(git diff --name-only "origin/$GITHUB_BASE_REF"...HEAD)
else
  # Push event - compare against previous commit if it exists
  if git rev-parse HEAD^ >/dev/null 2>&1; then
    CHANGED_FILES=$(git diff --name-only HEAD^ HEAD)
  else
    # First commit - compare against empty tree
    CHANGED_FILES=$(git diff --name-only --diff-filter=A HEAD)
  fi
fi

echo "Changed files:"
echo "$CHANGED_FILES"
echo ""

# Initialize arrays for test categories
run_application=false
run_group=false
run_tfe=false
run_connectivity=false
run_identity=false
run_user_assigned_identities=false
run_all=false

# Core files that affect all tests
CORE_FILES=(
  "variables.tf"
  "providers.tf"
  "resource_group.tf"
  "id.tf"
  "tags.tf"
  "data.tf"
  "outputs.tf"
  "role_assignment.tf"
)

# Check each changed file and determine which tests to run
while IFS= read -r file; do
  # Skip empty lines
  [ -z "$file" ] && continue
  
  echo "Analyzing: $file"
  
  # Track if this file was categorized
  file_categorized=false
  
  # Check for core files that trigger all tests
  for core_file in "${CORE_FILES[@]}"; do
    if [[ "$file" == "$core_file" ]]; then
      echo "  -> Core file detected, running all tests"
      run_all=true
      break 2
    fi
  done
  
  # Check for test files themselves
  if [[ "$file" == tests/*.tftest.hcl ]] || [[ "$file" == tests/setup-*/* ]]; then
    echo "  -> Test infrastructure changed, running all tests"
    run_all=true
    break
  fi
  
  # Check for workflow files
  if [[ "$file" == .github/workflows/terraform.yaml ]] || [[ "$file" == .github/scripts/determine-tests.sh ]]; then
    echo "  -> Workflow/script changed, running all tests"
    run_all=true
    break
  fi
  
  # Application-related files
  if [[ "$file" == application/* ]] || \
     [[ "$file" == "variables.applications.tf" ]] || \
     [[ "$file" == "applications.tf" ]] || \
     [[ "$file" == "application_federated_identity_credential.tf" ]]; then
    echo "  -> Application file detected"
    run_application=true
    file_categorized=true
  fi
  
  # Group-related files
  if [[ "$file" == group/* ]] || [[ "$file" == "groups.tf" ]]; then
    echo "  -> Group file detected"
    run_group=true
    file_categorized=true
  fi
  
  # TFE-related files
  if [[ "$file" == hashicorp/tfe/* ]] || [[ "$file" == "tfe.tf" ]]; then
    echo "  -> TFE file detected"
    run_tfe=true
    file_categorized=true
  fi
  
  # Connectivity-related files
  if [[ "$file" == "connectivity.tf" ]]; then
    echo "  -> Connectivity file detected"
    run_connectivity=true
    file_categorized=true
  fi
  
  # Identity-related files (affects both identity and user_assigned_identities tests)
  if [[ "$file" == user_assigned_identity/* ]] || \
     [[ "$file" == "user_assigned_identities.tf" ]] || \
     [[ "$file" == "variables.identity.tf" ]]; then
    echo "  -> Identity file detected"
    run_identity=true
    run_user_assigned_identities=true
    file_categorized=true
  fi
  
  # Bootstrap files - run all tests as it's foundational
  if [[ "$file" == bootstrap/* ]]; then
    echo "  -> Bootstrap file detected, running all tests"
    run_all=true
    break
  fi
  
  # Any other .tf file not yet categorized should trigger all tests (safety)
  if [[ "$file" == *.tf ]] && [[ "$file" != tests/* ]]; then
    if ! $file_categorized; then
      echo "  -> Uncategorized .tf file, running all tests for safety"
      run_all=true
      break
    fi
  fi
  
done <<< "$CHANGED_FILES"

# Build the list of tests to run
TEST_FILES=()

if $run_all; then
  echo ""
  echo "Running ALL tests"
  TEST_FILES=(
    "tests/application.tftest.hcl"
    "tests/group.tftest.hcl"
    "tests/tfe.tftest.hcl"
    "tests/connectivity.tftest.hcl"
    "tests/identity.tftest.hcl"
    "tests/user_assigned_identities.tftest.hcl"
  )
else
  echo ""
  echo "Running selective tests:"
  
  if $run_application; then
    echo "  - application tests"
    TEST_FILES+=("tests/application.tftest.hcl")
  fi
  
  if $run_group; then
    echo "  - group tests"
    TEST_FILES+=("tests/group.tftest.hcl")
  fi
  
  if $run_tfe; then
    echo "  - tfe tests"
    TEST_FILES+=("tests/tfe.tftest.hcl")
  fi
  
  if $run_connectivity; then
    echo "  - connectivity tests"
    TEST_FILES+=("tests/connectivity.tftest.hcl")
  fi
  
  if $run_identity; then
    echo "  - identity tests"
    TEST_FILES+=("tests/identity.tftest.hcl")
  fi
  
  if $run_user_assigned_identities; then
    echo "  - user_assigned_identities tests"
    TEST_FILES+=("tests/user_assigned_identities.tftest.hcl")
  fi
  
  # If no tests were selected, default to running all (e.g., documentation-only changes)
  if [ ${#TEST_FILES[@]} -eq 0 ]; then
    echo ""
    echo "No matching changes detected. Defaulting to all tests for safety."
    TEST_FILES=(
      "tests/application.tftest.hcl"
      "tests/group.tftest.hcl"
      "tests/tfe.tftest.hcl"
      "tests/connectivity.tftest.hcl"
      "tests/identity.tftest.hcl"
      "tests/user_assigned_identities.tftest.hcl"
    )
  fi
fi

# Convert to JSON array for GitHub Actions
echo ""
echo "Test files to run:"
printf '%s\n' "${TEST_FILES[@]}"

# Output as JSON array
printf -v joined '"%s",' "${TEST_FILES[@]}"
echo "[${joined%,}]"
