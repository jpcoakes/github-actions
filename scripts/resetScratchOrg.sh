#!/usr/bin/env bash
#
# Recreates a named scratch org from scratch: deletes it if it already exists,
# creates a fresh one, pushes source, assigns permission sets, and stands up
# the Birding Community Experience Cloud site.
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

echo "==> Pushing source to '$SCRATCH_ORG_ALIAS'..."
sf project source push --target-org "$SCRATCH_ORG_ALIAS"

echo "==> Assigning permission sets..."
sf org assign permset --name Bird_Watch_Admin --target-org "$SCRATCH_ORG_ALIAS"
sf org assign permset --name Birder --target-org "$SCRATCH_ORG_ALIAS"

# echo "==> Checking for existing '$SITE_NAME' site..."
# if sf community list --target-org "$SCRATCH_ORG_ALIAS" --json | grep -q "\"name\": \"$SITE_NAME\""; then
#   echo "    Site already exists, skipping creation."
# else
#   echo "==> Creating '$SITE_NAME' site..."
#   sf community create \
#     --name "$SITE_NAME" \
#     --template-name "$SITE_TEMPLATE" \
#     --url-path-prefix birding \
#     --target-org "$SCRATCH_ORG_ALIAS"

#   echo "==> Publishing '$SITE_NAME' site..."
#   sf community publish --name "$SITE_NAME" --target-org "$SCRATCH_ORG_ALIAS"
# fi

# echo "==> Retrieving generated site metadata (ExperienceBundle, Network) into source..."
# sf project retrieve start --metadata "ExperienceBundle,Network" --target-org "$SCRATCH_ORG_ALIAS"

# echo "==> Done. '$SCRATCH_ORG_ALIAS' is ready (expires in ${DURATION_DAYS} day(s))."
# echo "    Review the retrieved ExperienceBundle/Network files with 'git status' before committing."
