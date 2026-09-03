#!/usr/bin/env bash
#
# Recreates a named scratch org from scratch: deletes it if it already exists,
# creates a fresh one, deploys manifest/package.xml, assigns permission sets,
# and stands up the Birding Community Experience Cloud site.
#
# Usage:
#   ./scripts/resetScratchOrg.sh <scratch-org-alias> <duration-days>
#
# Example:
#   ./scripts/resetScratchOrg.sh birding-dev 7

set -euo pipefail

SCRATCH_ORG_ALIAS="${1:-}"
DURATION_DAYS="${2:-}"
SITE_NAME="Birding Community"
SITE_TEMPLATE="Build Your Own (LWR)"

if [[ -z "$SCRATCH_ORG_ALIAS" || -z "$DURATION_DAYS" ]]; then
  echo "Usage: $0 <scratch-org-alias> <duration-days>" >&2
  exit 1
fi

if ! [[ "$DURATION_DAYS" =~ ^[0-9]+$ ]] || (( DURATION_DAYS < 1 || DURATION_DAYS > 30 )); then
  echo "Error: <duration-days> must be a whole number between 1 and 30." >&2
  exit 1
fi

echo "==> Deleting existing scratch org '$SCRATCH_ORG_ALIAS' (if any)..."
sf org delete scratch --target-org "$SCRATCH_ORG_ALIAS" --no-prompt || true

echo "==> Creating scratch org '$SCRATCH_ORG_ALIAS' (${DURATION_DAYS}d)..."
sf org create scratch \
  --definition-file config/project-scratch-def.json \
  --alias "$SCRATCH_ORG_ALIAS" \
  --duration-days "$DURATION_DAYS" \
  --set-default

echo "==> Updating admin user's name to match git identity..."
GIT_NAME="$(git config user.name || true)"
if [[ -n "$GIT_NAME" && "$GIT_NAME" == *" "* ]]; then
  GIT_FIRST_NAME="${GIT_NAME%% *}"
  GIT_LAST_NAME="${GIT_NAME#* }"
  sf data record update \
    --target-org "$SCRATCH_ORG_ALIAS" \
    --sobject User \
    --where "Name='User User'" \
    --values "FirstName='$GIT_FIRST_NAME' LastName='$GIT_LAST_NAME'"
else
  echo "    Skipping: could not determine a first/last name from 'git config user.name'."
fi

echo "==> Deploying manifest/package.xml to '$SCRATCH_ORG_ALIAS'..."
sf project deploy start --manifest manifest/package.xml --target-org "$SCRATCH_ORG_ALIAS"

echo "==> Assigning permission sets..."
sf org assign permset --name Bird_Watch_Admin --target-org "$SCRATCH_ORG_ALIAS"
sf org assign permset --name Birder --target-org "$SCRATCH_ORG_ALIAS"

echo "==> Opening '$SCRATCH_ORG_ALIAS' in the browser..."
sf org open --target-org "$SCRATCH_ORG_ALIAS"

