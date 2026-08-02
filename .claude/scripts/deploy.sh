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

# ---- project-repo anchor (Phase 117) ----
# git discovers its repository from the CALLER'S cwd, so run from inside a
# nested clean repo (.claude/shared-memory/ is one once share mode is on)
# the dirty-tree guard below evaluated the WRONG repository and passed
# while the project tree was dirty — a safety gate failing open. The chdir
# also puts {{DEPLOY_COMMAND}} itself at the project root, which is where
# a deploy command expects to run. Refusal, not fallthrough, on failure.
ROOT="${CLAUDE_PROJECT_DIR:-$PWD}"
cd "$ROOT" || { echo "ERROR: cannot cd to project root '$ROOT' — refusing to deploy." >&2; exit 3; }

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

# Uncommitted-changes check — fails CLOSED with the true cause named
# (Phase 117). The old `if ! git diff-index ...` treated every nonzero the
# same, so "genuinely dirty" (rc=1) and "cannot even determine" (rc=128:
# no HEAD, not a repo) produced one misleading message. A gate that cannot
# verify cleanliness refuses; it does not guess.
if ! git rev-parse --git-dir >/dev/null 2>&1; then
  echo "ERROR: '$ROOT' is not a git repository — cannot verify a clean tree; refusing to deploy." >&2
  exit 3
fi
# Refresh cached stat info first: diff-index compares against the index's
# cached stats, which can be stale after clock/checkout churn and report
# phantom dirt (or miss real dirt). Exit ignored — refresh's own nonzero
# just means "something needed refreshing".
git update-index -q --refresh 2>/dev/null || true
git diff-index --quiet HEAD --
DIRTY_RC=$?
if [ "$DIRTY_RC" -eq 1 ]; then
  echo "ERROR: working tree has uncommitted changes. Commit or stash before deploying." >&2
  git status --short >&2
  exit 3
elif [ "$DIRTY_RC" -ne 0 ]; then
  echo "ERROR: cannot verify a clean tree (git diff-index exited $DIRTY_RC — no commits yet, or a broken repo). Refusing to deploy." >&2
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
