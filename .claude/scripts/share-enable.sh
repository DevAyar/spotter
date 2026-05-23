#!/usr/bin/env bash
# share-enable: opt THIS install into cross-project git memory (Phase 47a).
# Pushes an identity sentinel (install_uuid + label + skeleton version/commit)
# to a user-provided git remote, then records the opt-in in
# .claude/share-config.json. NO observation / capture / telemetry data is pushed
# — that lands in Phase 47b/c. Opt-in only: requires typing the exact word
# "enable". See docs/INSTALLATION.md § Share mode opt-in.
set -uo pipefail

# ---- constants ----
ROOT="$(cd "$(dirname "$0")/../.." 2>/dev/null && pwd)"
MARKER="$ROOT/.claude/.skeleton-version"
SHARE_CONFIG="$ROOT/.claude/share-config.json"
SCHEMA_VERSION=1
REMOTE_URL="${1:-}"
PY=""
TMP_CLONE=""
export GIT_TERMINAL_PROMPT=0

# Phase 47c-1: shared push mechanic (bounded pull-rebase retry, fail-soft).
. "$ROOT/.claude/lib/shared-memory-git.sh"

# ---- helpers ----
err() { printf '%s\n' "$*" >&2; }
die() { err "share-enable: error: $*"; exit 1; }

detect_python() {
  if command -v python  >/dev/null 2>&1; then PY="python"
  elif command -v python3 >/dev/null 2>&1; then PY="python3"
  else die "python (3) is required on PATH"; fi
}

# marker_field <key> → value on stdout (empty if missing/null)
marker_field() {
  "$PY" -c "
import json, sys
with open(sys.argv[1]) as f:
    d = json.load(f)
v = d.get(sys.argv[2])
sys.stdout.write('' if v is None else str(v))
" "$MARKER" "$1"
}

cleanup() {
  [ -n "$TMP_CLONE" ] && [ -d "$TMP_CLONE" ] && rm -rf "$TMP_CLONE"
}
trap cleanup EXIT INT TERM

# ---- main ----
command -v git >/dev/null 2>&1 || die "git is required on PATH"
detect_python
[ -n "$REMOTE_URL" ] || die "usage: share-enable.sh <remote-url>"
[ -f "$MARKER" ] || die "no .claude/.skeleton-version found — run install.sh first"

INSTALL_UUID="$(marker_field install_uuid)"
[ -n "$INSTALL_UUID" ] \
  || die "marker has no install_uuid — run 'bash scripts/update.sh' to backfill it, then retry"
# Path-shape guard: install_uuid is interpolated into a path on the remote.
printf '%s' "$INSTALL_UUID" | grep -Eq '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$' \
  || die "install_uuid is not a well-formed UUID: $INSTALL_UUID"

INSTALL_LABEL="$(marker_field install_label)"
SK_VERSION="$(marker_field version)"
SK_COMMIT="$(marker_field commit)"
[ -n "$INSTALL_LABEL" ] || INSTALL_LABEL="$INSTALL_UUID"

TS="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"

# Clone the remote (empty-bare and populated both handled).
TMP_CLONE="$(mktemp -d 2>/dev/null || mktemp -d -t skeleton-share)"
git clone --quiet "$REMOTE_URL" "$TMP_CLONE" 2>/dev/null \
  || die "could not clone remote '$REMOTE_URL' — nothing was pushed"

cd "$TMP_CLONE" || die "could not enter clone dir — nothing was pushed"
git config user.email "share@claude-skeleton.local" >/dev/null 2>&1 || true
git config user.name  "claude-skeleton share"        >/dev/null 2>&1 || true

# Empty remote → initialize the shared-tree skeleton.
if [ -z "$(git rev-parse --verify HEAD 2>/dev/null || true)" ]; then
  mkdir -p .skeleton-shared-schema
  printf '%s\n' "$SCHEMA_VERSION" > .skeleton-shared-schema/version
  cat > README.md <<'RDME'
# claude-skeleton shared memory

Cross-project memory bus for one person's claude-skeleton installs. Each install
opts in explicitly and writes an identity sentinel under `installs/<install_uuid>/`.
No observation, capture, or telemetry data is stored here yet — Phase 47a ships
identity + opt-in only. See `docs/INSTALLATION.md` § Share mode opt-in in the
claude-skeleton repo for the schema and trust model.
RDME
fi

# Write the identity sentinel (idempotent per install_uuid).
mkdir -p "installs/$INSTALL_UUID"
"$PY" -c "
import json, sys
out = {
  'schema_version': int(sys.argv[1]),
  'install_uuid': sys.argv[2],
  'install_label': sys.argv[3],
  'version': sys.argv[4],
  'commit': sys.argv[5],
  'sentinel_timestamp': sys.argv[6],
}
with open(sys.argv[7], 'w', newline='\n') as f:
    json.dump(out, f, indent=2, sort_keys=True)
    f.write('\n')
" "$SCHEMA_VERSION" "$INSTALL_UUID" "$INSTALL_LABEL" "$SK_VERSION" "$SK_COMMIT" "$TS" "installs/$INSTALL_UUID/sentinel.json" \
  || die "failed to write sentinel.json — nothing was pushed"

# Surface the opt-in for explicit confirmation (Q5: type the word "enable").
printf '\n'
printf 'About to enable share mode pushing to %s\n' "$REMOTE_URL"
printf '  Install UUID:     %s\n' "$INSTALL_UUID"
printf '  Install label:    %s\n' "$INSTALL_LABEL"
printf '  Skeleton version: %s (commit %s)\n' "$SK_VERSION" "${SK_COMMIT:0:12}"
printf "Type 'enable' to confirm or anything else to cancel: "
read -r CONFIRM || CONFIRM=""
CONFIRM="${CONFIRM%$'\r'}"
[ "$CONFIRM" = "enable" ] || die "cancelled — share mode NOT enabled, nothing was pushed"

# Commit + push the sentinel via the shared push mechanic (bounded retry).
smg_push "$TMP_CLONE" "$INSTALL_LABEL opt-in sentinel $TS" \
  || die "git push to '$REMOTE_URL' failed — the sentinel was committed in a local temp clone but did NOT reach the remote; retry when the remote is reachable"

# Push succeeded → record the opt-in locally.
cd "$ROOT" || die "pushed to remote, but could not return to project root to write share-config.json"
"$PY" -c "
import json, sys
out = {
  'schema_version': int(sys.argv[1]),
  'enabled': True,
  'remote_url': sys.argv[2],
  'enabled_at': sys.argv[3],
  'disabled_at': None,
}
with open(sys.argv[4], 'w', newline='\n') as f:
    json.dump(out, f, indent=2, sort_keys=True)
    f.write('\n')
" "$SCHEMA_VERSION" "$REMOTE_URL" "$TS" "$SHARE_CONFIG" \
  || die "pushed to remote, but failed to write $SHARE_CONFIG — rerun to record the opt-in"

printf '\n'
printf 'Share mode ENABLED for this install.\n'
printf '  Remote:   %s\n' "$REMOTE_URL"
printf '  Sentinel: installs/%s/sentinel.json\n' "$INSTALL_UUID"
printf 'No project data is pushed yet — producer integration lands in Phase 47b/c.\n'
printf 'Disable any time with /share-disable; check state with /share-status.\n'
