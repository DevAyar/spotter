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
# shellcheck source=../lib/detect-python.sh
. "$ROOT/.claude/lib/detect-python.sh"
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
  # Phase 112: selection comes from the canonical probe (sourced above);
  # this wrapper keeps THIS script's failure semantics — die with a true
  # message. The audit's complaint was misdiagnosis, so the message names
  # the real cause rather than a remedy that does not match it.
  PY="$DETECTED_PYTHON"
  [ -n "$PY" ] || die "$(python_required_message)"
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
# Phase 117: this URL is stored in share-config and handed back to git on
# every later push, and git treats some URL shapes as code (ext:: executes
# a command; a leading dash parses as an option). Validate at the door —
# smg_url_ok is the one allowlist every consumer shares.
smg_url_ok "$REMOTE_URL" \
  || die "remote url rejected — allowed shapes: https://, ssh://, user@host:path, file://, or an absolute path. Got: $REMOTE_URL"
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
git clone --quiet -- "$REMOTE_URL" "$TMP_CLONE" 2>/dev/null \
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
# Read the confirmation from wherever the human's answer actually arrives:
# stdin when it is the keyboard (interactive) or a pipe (the /share-enable slash
# command pipes 'enable\n'); else the controlling terminal /dev/tty when stdin is
# redirected/disconnected but a terminal exists; else stdin → EOF → fail-closed.
if [ -t 0 ] || [ -p /dev/stdin ]; then
  read -r CONFIRM || CONFIRM=""
elif { exec 3</dev/tty; } 2>/dev/null; then
  read -r CONFIRM <&3 || CONFIRM=""
  exec 3<&-
else
  read -r CONFIRM || CONFIRM=""
fi
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
