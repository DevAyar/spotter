#!/usr/bin/env bash
# Deploy wrapper. Configure {{DEPLOY_COMMAND}} during install, or remove this
# script entirely if the project has no deploy step. project-tuner-helper
# customizes or deletes this file per project.
#
# Usage: bash .claude/scripts/deploy.sh [deploy-flags...]
#
# Wraps the project's deploy command with:
#   - path-shape guard on the first arg (same shape as commit.sh)
#   - uncommitted-changes check (refuses to deploy a dirty tree)
#   - POST-DEPLOY SMOKE TEST REQUIRED banner on success
set -uo pipefail

# Path-shape guard on first arg, if any.
if [ "$#" -ge 1 ]; then
  FIRST="$1"
  if echo "$FIRST" | grep -qE '/' ; then
    echo "ERROR: first arg looks like a path (contains /). Pass deploy flags, not files." >&2
    exit 2
  fi
  if echo "$FIRST" | grep -qE '\.(md|yaml|yml|json|toml|py|ts|tsx|js|jsx|rb|go|rs|c|cpp|h|hpp|sh|sql)$' ; then
    echo "ERROR: first arg ends in a code/config extension. Pass deploy flags, not a filename." >&2
    exit 2
  fi
fi

# Uncommitted-changes check.
if ! git diff-index --quiet HEAD --; then
  echo "ERROR: working tree has uncommitted changes. Commit or stash before deploying." >&2
  git status --short >&2
  exit 3
fi

echo "=== DEPLOY COMMAND ==="
echo "{{DEPLOY_COMMAND}} $*"
echo ""

{{DEPLOY_COMMAND}} "$@"
DEPLOY_EXIT=$?

if [ "$DEPLOY_EXIT" -eq 0 ]; then
  echo ""
  echo "============================================================"
  echo "  POST-DEPLOY SMOKE TEST REQUIRED"
  echo ""
  echo "  Deploy succeeded. Verify the live target by hand or run"
  echo "  /smoke-test before assuming the change is good."
  echo "============================================================"
fi

exit $DEPLOY_EXIT
