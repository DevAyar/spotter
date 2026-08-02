#!/usr/bin/env bash
# Mechanical commit wrapper. Emits five verbatim sections to stdout so the
# manager can quote them back without paraphrasing.
#
# Usage: bash .claude/scripts/commit.sh "<commit message>"
#
# Path-shape guard: rejects a first arg that looks like a file path. This
# catches the common manager mistake of passing a file path as the message.
# If your message legitimately contains a slash or extension, rephrase or
# relax the guard per project.
set -uo pipefail

# ---- project-repo anchor (Phase 117) ----
# git discovers its repository by walking up from the CALLER'S cwd, so a
# run from inside a nested repo — .claude/shared-memory/ is a real working
# clone once share mode is on — committed to the WRONG repository, printed
# a real hash under NEW COMMIT HASH, and exited 0. Indistinguishable from
# a correct commit. Anchor to the project root and refuse rather than
# fall through: a commit is mutating, so a wrong guess is worse than no
# commit at all.
ROOT="${CLAUDE_PROJECT_DIR:-$PWD}"
cd "$ROOT" || { echo "ERROR: cannot cd to project root '$ROOT' — refusing to commit." >&2; exit 2; }

usage() {
  echo "Usage: $0 \"<commit message>\""
  echo "  First arg must be the commit message, not a file path."
  exit 1
}

[ "$#" -lt 1 ] && usage

MSG="$1"

# Path-shape guard: reject obvious file paths.
if echo "$MSG" | grep -qE '/' ; then
  echo "ERROR: first arg looks like a path (contains /). Pass the commit message, not files." >&2
  exit 2
fi
if echo "$MSG" | grep -qE '\.(md|yaml|yml|json|toml|py|ts|tsx|js|jsx|rb|go|rs|c|cpp|h|hpp|sh|sql)$' ; then
  echo "ERROR: first arg ends in a code/config extension. Pass the commit message, not a filename." >&2
  exit 2
fi

echo "=== PRE-COMMIT STATUS ==="
git status --short

echo ""
echo "=== STAGE COMMAND ==="
echo "Already-staged files will be committed. No further staging performed by this script."

echo ""
echo "=== COMMIT STDOUT ==="
git commit -m "$MSG"
COMMIT_EXIT=$?

echo ""
echo "=== POST-COMMIT STATUS ==="
git status --short

echo ""
echo "=== NEW COMMIT HASH ==="
if [ "$COMMIT_EXIT" -eq 0 ]; then
  git rev-parse HEAD
else
  echo "(commit failed, no new hash)"
fi

exit $COMMIT_EXIT
