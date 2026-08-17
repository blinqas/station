#!/usr/bin/env sh
set -eu

ENV_FILE="${1:-./.agent.test.env}"

if [ ! -f "$ENV_FILE" ]; then
  echo "ERROR: Missing env file: $ENV_FILE"
  echo "Create it from ./.agent.test.env.example and fill in values."
  exit 1
fi

# shellcheck disable=SC1090
. "$ENV_FILE"

require_var() {
  var_name="$1"
  eval "var_value=\${$var_name-}"
  if [ -z "$var_value" ]; then
    echo "ERROR: Required variable '$var_name' is empty in $ENV_FILE"
    exit 1
  fi
}

require_var TF_VAR_tenant_id
require_var TF_VAR_subscription_id
require_var ARM_SUBSCRIPTION_ID
require_var TFE_TOKEN

if [ "$TF_VAR_subscription_id" != "$ARM_SUBSCRIPTION_ID" ]; then
  echo "ERROR: TF_VAR_subscription_id and ARM_SUBSCRIPTION_ID must match."
  echo "  TF_VAR_subscription_id=$TF_VAR_subscription_id"
  echo "  ARM_SUBSCRIPTION_ID=$ARM_SUBSCRIPTION_ID"
  exit 1
fi

if ! command -v az >/dev/null 2>&1; then
  echo "ERROR: Azure CLI ('az') not found in PATH."
  exit 1
fi

if ! az account show >/dev/null 2>&1; then
  echo "ERROR: Azure CLI is not logged in."
  echo "Run: az login --tenant $TF_VAR_tenant_id"
  exit 1
fi

current_subscription_id="$(az account show --query id -o tsv)"
current_tenant_id="$(az account show --query tenantId -o tsv)"
current_user="$(az account show --query user.name -o tsv 2>/dev/null || true)"

if [ "$current_tenant_id" != "$TF_VAR_tenant_id" ]; then
  echo "ERROR: Logged into wrong tenant."
  echo "  Expected: $TF_VAR_tenant_id"
  echo "  Current:  $current_tenant_id"
  echo "Run: az login --tenant $TF_VAR_tenant_id"
  exit 1
fi

if [ "$current_subscription_id" != "$TF_VAR_subscription_id" ]; then
  echo "ERROR: Active Azure subscription does not match test subscription."
  echo "  Expected: $TF_VAR_subscription_id"
  echo "  Current:  $current_subscription_id"
  echo "Run: az account set --subscription $TF_VAR_subscription_id"
  exit 1
fi

echo "Azure context OK"
echo "  User:         ${current_user:-unknown}"
echo "  Tenant:       $current_tenant_id"
echo "  Subscription: $current_subscription_id"
