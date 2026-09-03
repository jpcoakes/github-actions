#!/usr/bin/env bash
#
# Recreates a named scratch org from scratch: deletes it if it already exists,
# creates a fresh one, deploys manifest/package.xml, assigns permission sets,
# and stands up the Birding Community Experience Cloud site.
#
# Usage:
#   ./scripts/resetScratchOrg.sh [-n <scratch-org-alias>] [-d <duration-days>] [-r <test-level>]
#
# Example:
#   ./scripts/resetScratchOrg.sh -n birding-dev -d 5 -r RunRelevantTests

set -euo pipefail

SCRATCH_ORG_ALIAS="birding-dev"
DURATION_DAYS=7
TEST_LEVEL=""
SITE_NAME="Birding Community"
SITE_TEMPLATE="Build Your Own (LWR)"
VALID_TEST_LEVELS=("NoTestRun" "RunSpecifiedTests" "RunLocalTests" "RunAllTestsInOrg" "RunRelevantTests")

usage() {
  cat <<EOF
Usage: $0 [-n <scratch-org-alias>] [-d <duration-days>] [-r <test-level>]

  -n  Alias for the scratch org (default: $SCRATCH_ORG_ALIAS)
  -d  Number of days before the org expires, 1-30 (default: $DURATION_DAYS)
  -r  Apex test level for the package.xml deploy: ${VALID_TEST_LEVELS[*]}
      (default: unset, lets the CLI decide)

Example:
  $0 -n birding-dev -d 5 -r RunRelevantTests
EOF
}

while getopts ":n:d:r:h" opt; do
  case "$opt" in
    n) SCRATCH_ORG_ALIAS="$OPTARG" ;;
    d) DURATION_DAYS="$OPTARG" ;;
    r) TEST_LEVEL="$OPTARG" ;;
    h) usage; exit 0 ;;
    \?) echo "Error: invalid option -$OPTARG" >&2; usage; exit 1 ;;
    :) echo "Error: option -$OPTARG requires an argument" >&2; usage; exit 1 ;;
  esac
done

if ! [[ "$DURATION_DAYS" =~ ^[0-9]+$ ]] || (( DURATION_DAYS < 1 || DURATION_DAYS > 30 )); then
  echo "Error: -d <duration-days> must be a whole number between 1 and 30." >&2
  exit 1
fi

if [[ -n "$TEST_LEVEL" ]]; then
  is_valid_test_level=false
  for level in "${VALID_TEST_LEVELS[@]}"; do
    if [[ "$TEST_LEVEL" == "$level" ]]; then
      is_valid_test_level=true
      break
    fi
  done
  if [[ "$is_valid_test_level" == false ]]; then
    echo "Error: -r <test-level> must be one of: ${VALID_TEST_LEVELS[*]}" >&2
    exit 1
  fi
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
DEPLOY_ARGS=(--manifest manifest/package.xml --target-org "$SCRATCH_ORG_ALIAS")
if [[ -n "$TEST_LEVEL" ]]; then
  DEPLOY_ARGS+=(--test-level "$TEST_LEVEL")
fi
sf project deploy start "${DEPLOY_ARGS[@]}"

echo "==> Assigning permission sets..."
sf org assign permset --name Bird_Watch_Admin --target-org "$SCRATCH_ORG_ALIAS"
sf org assign permset --name Birder --target-org "$SCRATCH_ORG_ALIAS"

echo "==> Opening '$SCRATCH_ORG_ALIAS' in the browser..."
sf org open --target-org "$SCRATCH_ORG_ALIAS"
