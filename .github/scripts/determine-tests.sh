#!/bin/bash
set -euo pipefail

# Script to determine which Terraform tests to run based on changed files
# Returns a JSON array of test files to run

# Get the list of changed files
# For PRs, compare against the base branch
# For pushes, compare against the previous commit
if [ -n "${GITHUB_BASE_REF:-}" ]; then
  # Pull request - fetch base branch if not already available
  if ! git rev-parse "origin/$GITHUB_BASE_REF" >/dev/null 2>&1; then
    git fetch origin "$GITHUB_BASE_REF" --depth=1
  fi
  CHANGED_FILES=$(git diff --name-only "origin/$GITHUB_BASE_REF"...HEAD)
elif [ "${GITHUB_EVENT_NAME:-}" = "issue_comment" ]; then
  # Issue comment on PR - need to fetch base branch
  PR_NUMBER="${GITHUB_EVENT_ISSUE_NUMBER:-}"
  if [ -n "$PR_NUMBER" ]; then
    if command -v gh >/dev/null 2>&1; then
      BASE_REF=$(gh pr view "$PR_NUMBER" --json baseRefName --jq '.baseRefName' 2>&1)
      if [ $? -eq 0 ] && [ -n "$BASE_REF" ]; then
        git fetch origin "$BASE_REF" --depth=1
        CHANGED_FILES=$(git diff --name-only "origin/$BASE_REF"...HEAD)
      else
        echo "Warning: Could not get PR base ref via gh CLI: $BASE_REF" >&2
        CHANGED_FILES=""
      fi
    else
      echo "Warning: gh CLI not available for issue_comment event" >&2
      CHANGED_FILES=""
    fi
  else
    CHANGED_FILES=""
  fi
else
  # Push event - compare against previous commit if it exists
  if git rev-parse HEAD^ >/dev/null 2>&1; then
    CHANGED_FILES=$(git diff --name-only HEAD^ HEAD)
  else
    # First commit - compare against empty tree (git's special empty tree hash)
    CHANGED_FILES=$(git diff --name-only 4b825dc642cb6eb9a060e54bf8d69288fbee4904 HEAD)
  fi
fi

echo "Changed files:"
echo "$CHANGED_FILES"
echo ""

# Check if there are any changes
if [ -z "$CHANGED_FILES" ]; then
  echo "No changes detected. Defaulting to all tests."
  # Output all test files
  files=$(find tests -name '*.tftest.hcl' | jq -R -s -c 'split("\n") | map(select(length > 0))')
  echo "$files"
  exit 0
fi

# Initialize arrays for test categories
run_application=false
run_group=false
run_tfe=false
run_connectivity=false
run_identity=false
run_user_assigned_identities=false
run_policy_exemptions=false
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
  
  # Check for test files themselves - map to corresponding test
  if [[ "$file" == tests/application.tftest.hcl ]]; then
    echo "  -> Application test file detected"
    run_application=true
    file_categorized=true
  elif [[ "$file" == tests/group.tftest.hcl ]]; then
    echo "  -> Group test file detected"
    run_group=true
    file_categorized=true
  elif [[ "$file" == tests/tfe.tftest.hcl ]]; then
    echo "  -> TFE test file detected"
    run_tfe=true
    file_categorized=true
  elif [[ "$file" == tests/connectivity.tftest.hcl ]]; then
    echo "  -> Connectivity test file detected"
    run_connectivity=true
    file_categorized=true
  elif [[ "$file" == tests/identity.tftest.hcl ]]; then
    echo "  -> Identity test file detected"
    run_identity=true
    file_categorized=true
  elif [[ "$file" == tests/user_assigned_identities.tftest.hcl ]]; then
    echo "  -> User assigned identities test file detected"
    run_user_assigned_identities=true
    file_categorized=true
  elif [[ "$file" == tests/policy_exemptions.tftest.hcl ]]; then
    echo "  -> Policy exemptions test file detected"
    run_policy_exemptions=true
    file_categorized=true
  elif [[ "$file" == tests/setup-* ]] || [[ "$file" == tests/README.md ]]; then
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
  
  # Policy exemptions-related files
  if [[ "$file" == "policy_exemptions.tf" ]] || \
     [[ "$file" == "variables.policy_exemptions.tf" ]]; then
    echo "  -> Policy exemptions file detected"
    run_policy_exemptions=true
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
    "tests/policy_exemptions.tftest.hcl"
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
  
  if $run_policy_exemptions; then
    echo "  - policy_exemptions tests"
    TEST_FILES+=("tests/policy_exemptions.tftest.hcl")
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
      "tests/policy_exemptions.tftest.hcl"
    )
  fi
fi

# Convert to JSON array for GitHub Actions
echo ""
echo "Test files to run:"
printf '%s\n' "${TEST_FILES[@]}"

# Output as JSON array
if [ ${#TEST_FILES[@]} -eq 0 ]; then
  echo "[]"
else
  printf -v joined '"%s",' "${TEST_FILES[@]}"
  echo "[${joined%,}]"
fi
