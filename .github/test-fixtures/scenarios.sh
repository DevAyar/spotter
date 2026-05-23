#!/usr/bin/env bash
# CI test scenarios for claude-skeleton install.sh / update.sh.
# Usage:  bash scenarios.sh <scenario-name>
# Each scenario creates a throwaway target via mktemp, exercises the
# install/update path, asserts on the result, and exits non-zero on
# any failure.

set -euo pipefail

# Resolve the skeleton checkout root: this script lives at
# .github/test-fixtures/scenarios.sh — root is two levels up.
SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd -P)
SKELETON_DIR=$(cd "$SCRIPT_DIR/../.." && pwd -P)

# Each scenario runs in its own mktemp dir; trap wipes it on exit.
TEST_DIR=""
cleanup() {
  if [ -n "$TEST_DIR" ] && [ -d "$TEST_DIR" ]; then
    rm -rf "$TEST_DIR"
  fi
}
trap cleanup EXIT INT TERM

# ---- portable hashing ----
SHA256_CMD=""
if command -v sha256sum >/dev/null 2>&1; then
  SHA256_CMD="sha256sum"
elif command -v shasum >/dev/null 2>&1; then
  SHA256_CMD="shasum -a 256"
else
  echo "ERROR: sha256sum or shasum required" >&2
  exit 1
fi

sha256_of() {
  $SHA256_CMD "$1" | awk '{print $1}'
}

# ---- helpers ----
init_target() {
  TEST_DIR=$(mktemp -d 2>/dev/null || mktemp -d -t claude-skel-ci)
  cd "$TEST_DIR"
  git init -q
  git config user.email "ci@test.local"
  git config user.name "CI Test"
  printf '# test target\n' > README.md
  git add README.md
  git commit -q -m "init"
}

# verify_marker: assert JSON marker exists with expected keys and a
# files object whose entries each have a 64-char lowercase hex hash.
verify_marker() {
  local expected_count="${1:-25}"
  local marker="$TEST_DIR/.claude/.skeleton-version"
  [ -f "$marker" ] || { echo "ERROR: marker not at $marker" >&2; return 1; }
  python -c "
import json, re, sys
with open(sys.argv[1]) as f:
    d = json.load(f)
required = ['version','commit','installed_at','mode','claude_only','source','files']
for k in required:
    if k not in d:
        sys.exit(f'ERROR: missing key {k!r} in marker')
files = d['files']
if len(files) != int(sys.argv[2]):
    sys.exit(f'ERROR: expected {sys.argv[2]} files in marker, got {len(files)}')
for p, h in files.items():
    if not re.fullmatch(r'[0-9a-f]{64}', h):
        sys.exit(f'ERROR: bad hash for {p!r}: {h!r}')
print(f'  marker OK: {len(files)} files, all 64-char hex hashes')
" "$marker" "$expected_count"
}

assert_eq() {
  if [ "$1" != "$2" ]; then
    echo "ERROR: assertion failed — expected $2, got $1" >&2
    exit 1
  fi
}

assert_contains() {
  local haystack="$1" needle="$2"
  if ! printf '%s' "$haystack" | grep -qF -- "$needle"; then
    echo "ERROR: expected output to contain: $needle" >&2
    echo "---- actual output ----" >&2
    printf '%s\n' "$haystack" >&2
    exit 1
  fi
}

# have_glob: 0 if at least one path matches any given glob (expanded by the
# shell). Avoids `find | grep -q` SIGPIPE flakiness under pipefail.
have_glob() {
  local g
  for g in "$@"; do
    [ -e "$g" ] && return 0
  done
  return 1
}

# ---- scenarios ----

scenario_fresh_install() {
  echo ">> fresh-install: clean target, --mode=fresh --claude-only"
  init_target
  bash "$SKELETON_DIR/scripts/install.sh" \
    --source "$SKELETON_DIR" --target "$TEST_DIR" \
    --mode=fresh --claude-only
  verify_marker 60
  echo "PASS fresh-install"
}

# Phase 52: fresh install must record raw_template_baselines, and each hash must
# equal the sha256 of its template source file (raw template, as shipped).
scenario_raw_baseline_install() {
  echo ">> raw-baseline-install: fresh install populates raw_template_baselines matching template hashes (Phase 52)"
  init_target
  bash "$SKELETON_DIR/scripts/install.sh" \
    --source "$SKELETON_DIR" --target "$TEST_DIR" \
    --mode=fresh --claude-only
  local marker="$TEST_DIR/.claude/.skeleton-version"
  [ -f "$marker" ] || { echo "ERROR: marker not at $marker" >&2; return 1; }
  python -c "
import json, re, sys, hashlib, os
with open(sys.argv[1]) as f:
    d = json.load(f)
raw = d.get('raw_template_baselines')
if not isinstance(raw, dict):
    sys.exit('ERROR: raw_template_baselines missing or not an object')
files = d.get('files', {})
if len(raw) != len(files):
    sys.exit(f'ERROR: raw_template_baselines count {len(raw)} != files count {len(files)}')
def tmpl_path(rel):
    rel = rel[len('.claude/'):] if rel.startswith('.claude/') else rel
    base = os.path.join(sys.argv[2], 'template', '.claude', *rel.split('/'))
    return base if os.path.isfile(base) else base + '.template'
for rel, h in raw.items():
    if not re.fullmatch(r'[0-9a-f]{64}', h):
        sys.exit(f'ERROR: bad raw hash for {rel!r}: {h!r}')
    p = tmpl_path(rel)
    if not os.path.isfile(p):
        sys.exit(f'ERROR: template source not found for {rel!r} (tried {p})')
    digest = hashlib.sha256(open(p, 'rb').read()).hexdigest()
    if digest != h:
        sys.exit(f'ERROR: raw baseline for {rel!r} = {h[:12]} != template sha256 {digest[:12]}')
print(f'  raw_template_baselines OK: {len(raw)} entries, all match template sha256')
" "$marker" "$SKELETON_DIR"
  echo "PASS raw-baseline-install"
}

# Phase 47a: a fresh install must record install_uuid (UUID v4), a non-empty
# install_label, and an ISO8601 install_created.
scenario_install_uuid_fresh() {
  echo ">> install-uuid-fresh: fresh install records install_uuid / install_label / install_created (Phase 47a)"
  init_target
  bash "$SKELETON_DIR/scripts/install.sh" \
    --source "$SKELETON_DIR" --target "$TEST_DIR" \
    --mode=fresh --claude-only
  local marker="$TEST_DIR/.claude/.skeleton-version"
  [ -f "$marker" ] || { echo "ERROR: marker not at $marker" >&2; return 1; }
  python -c "
import json, re, sys
with open(sys.argv[1]) as f:
    d = json.load(f)
uuid = d.get('install_uuid')
if not isinstance(uuid, str) or not re.fullmatch(r'[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}', uuid):
    sys.exit(f'ERROR: install_uuid missing or not UUID v4: {uuid!r}')
label = d.get('install_label')
if not isinstance(label, str) or not label.strip():
    sys.exit(f'ERROR: install_label missing or empty: {label!r}')
created = d.get('install_created')
if not isinstance(created, str) or not re.fullmatch(r'\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}Z', created):
    sys.exit(f'ERROR: install_created missing or not ISO8601: {created!r}')
print(f'  identity OK: uuid={uuid} label={label!r} created={created}')
" "$marker"
  echo "PASS install-uuid-fresh"
}

# Phase 47a: a pre-47a marker (no identity fields) gains install_uuid /
# install_label / install_created on the next update.sh run, without disturbing
# existing fields. Models the Phase 52 raw-baseline migration gate.
scenario_install_uuid_backfill() {
  echo ">> install-uuid-backfill: update.sh backfills install identity into a pre-47a marker (Phase 47a)"
  init_target
  bash "$SKELETON_DIR/scripts/install.sh" \
    --source "$SKELETON_DIR" --target "$TEST_DIR" \
    --mode=fresh --claude-only
  local marker="$TEST_DIR/.claude/.skeleton-version"
  # Simulate a pre-47a marker: drop the three identity fields, recording the
  # pre-existing version/commit so we can prove they survive the backfill.
  python -c "
import json, sys
sys.stdout.reconfigure(newline='\n')
with open(sys.argv[1]) as f:
    d = json.load(f)
for k in ('install_uuid', 'install_label', 'install_created'):
    d.pop(k, None)
with open(sys.argv[1], 'w', newline='\n') as f:
    json.dump(d, f, indent=2, sort_keys=True)
    f.write('\n')
sys.stdout.write(d['version'] + '\t' + d['commit'] + '\n')
" "$marker" > "$TEST_DIR/pre.tsv"
  local pre_version pre_commit
  IFS=$'\t' read -r pre_version pre_commit < "$TEST_DIR/pre.tsv"
  pre_version="${pre_version%$'\r'}"
  pre_commit="${pre_commit%$'\r'}"
  # Decline template updates (S) and orphans (n): only the identity backfill
  # should drive the marker rewrite.
  printf 'S\nn\n' | bash "$SKELETON_DIR/scripts/update.sh" \
                      --source "$SKELETON_DIR" --target "$TEST_DIR" \
                      > "$TEST_DIR/update.out" 2>&1 || { cat "$TEST_DIR/update.out" >&2; exit 1; }
  assert_contains "$(cat "$TEST_DIR/update.out")" "install identity (Phase 47a)"
  python -c "
import json, re, sys
with open(sys.argv[1]) as f:
    d = json.load(f)
uuid = d.get('install_uuid')
if not isinstance(uuid, str) or not re.fullmatch(r'[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}', uuid):
    sys.exit(f'ERROR: install_uuid not backfilled as UUID v4: {uuid!r}')
label = d.get('install_label')
if not isinstance(label, str) or not label.strip():
    sys.exit(f'ERROR: install_label not backfilled: {label!r}')
created = d.get('install_created')
if not isinstance(created, str) or not re.fullmatch(r'\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}Z', created):
    sys.exit(f'ERROR: install_created not backfilled ISO8601: {created!r}')
ver, com = d.get('version'), d.get('commit')
if ver != sys.argv[2]:
    sys.exit(f'ERROR: version disturbed: {ver!r} != {sys.argv[2]!r}')
if com != sys.argv[3]:
    sys.exit(f'ERROR: commit disturbed: {com!r} != {sys.argv[3]!r}')
print(f'  backfill OK: uuid={uuid} label={label!r}; version/commit intact')
" "$marker" "$pre_version" "$pre_commit"
  echo "PASS install-uuid-backfill"
}

# Phase 47a: share-enable against a fresh empty bare repo writes the identity
# sentinel into the remote history and records the opt-in in share-config.json.
scenario_share_enable_fresh_remote() {
  echo ">> share-enable-fresh-remote: opt-in pushes sentinel to a bare remote + writes share-config.json (Phase 47a)"
  init_target
  bash "$SKELETON_DIR/scripts/install.sh" \
    --source "$SKELETON_DIR" --target "$TEST_DIR" \
    --mode=fresh --claude-only
  local bare="$TEST_DIR/skeleton-shared-test.git"
  git init --bare -q "$bare"
  # Auto-confirm with the literal word "enable" on stdin.
  printf 'enable\n' | bash "$TEST_DIR/.claude/scripts/share-enable.sh" "$bare" \
    > "$TEST_DIR/enable.out" 2>&1 || { echo "ERROR: share-enable failed" >&2; cat "$TEST_DIR/enable.out" >&2; exit 1; }
  # share-config.json must be written locally with enabled=true.
  local cfg="$TEST_DIR/.claude/share-config.json"
  [ -f "$cfg" ] || { echo "ERROR: share-config.json not written" >&2; cat "$TEST_DIR/enable.out" >&2; exit 1; }
  python -c "
import json, sys
with open(sys.argv[1]) as f:
    c = json.load(f)
if c.get('enabled') is not True:
    sys.exit('ERROR: share-config enabled != true')
if c.get('disabled_at') is not None:
    sys.exit('ERROR: share-config disabled_at != null')
if not c.get('remote_url'):
    sys.exit('ERROR: share-config remote_url empty')
if not c.get('enabled_at'):
    sys.exit('ERROR: share-config enabled_at empty')
if c.get('schema_version') != 1:
    sys.exit('ERROR: share-config schema_version != 1')
print('  share-config OK: enabled=true remote=' + c['remote_url'])
" "$cfg"
  # Sentinel must appear in the bare repo history under installs/<uuid>/.
  local uuid ref
  uuid=$(python -c "import json,sys; sys.stdout.write(json.load(open(sys.argv[1]))['install_uuid'])" "$TEST_DIR/.claude/.skeleton-version")
  ref=$(git -C "$bare" for-each-ref --format='%(refname)' refs/heads | head -1)
  [ -n "$ref" ] || { echo "ERROR: bare repo has no branches after push" >&2; exit 1; }
  git -C "$bare" cat-file -e "$ref:installs/$uuid/sentinel.json" 2>/dev/null \
    || { echo "ERROR: sentinel.json missing in bare repo at installs/$uuid/sentinel.json" >&2; git -C "$bare" ls-tree -r --name-only "$ref" >&2; exit 1; }
  # Sentinel content sanity: native version/commit keys present, schema_version 1.
  git -C "$bare" show "$ref:installs/$uuid/sentinel.json" | python -c "
import json, sys
s = json.load(sys.stdin)
for k in ('schema_version', 'install_uuid', 'install_label', 'version', 'commit', 'sentinel_timestamp'):
    if k not in s:
        sys.exit('ERROR: sentinel missing key: ' + k)
if s['install_uuid'] != sys.argv[1]:
    sys.exit('ERROR: sentinel install_uuid mismatch')
if s['schema_version'] != 1:
    sys.exit('ERROR: sentinel schema_version != 1')
print('  sentinel OK: ' + s['install_uuid'])
" "$uuid"
  echo "PASS share-enable-fresh-remote"
}

# Phase 47a: share-status on a fresh install (no share-config.json) reports
# "not configured" cleanly; the default state is opt-out (file absent).
scenario_share_status_disabled_default() {
  echo ">> share-status-disabled-default: fresh install (no share-config) reports not configured (Phase 47a)"
  init_target
  bash "$SKELETON_DIR/scripts/install.sh" \
    --source "$SKELETON_DIR" --target "$TEST_DIR" \
    --mode=fresh --claude-only
  if [ -f "$TEST_DIR/.claude/share-config.json" ]; then
    echo "ERROR: share-config.json must NOT exist on a fresh install" >&2
    exit 1
  fi
  local out
  out=$(bash "$TEST_DIR/.claude/scripts/share-status.sh")
  assert_contains "$out" "not configured"
  echo "PASS share-status-disabled-default"
}

# Phase 47b: redact-capture.sh converts a terminal-state capture to a redacted
# envelope (exit 0), skips draft/approved (exit 2), and refuses malformed
# frontmatter (exit 3).
scenario_share_capture_redact() {
  echo ">> share-capture-redact: terminal capture → redacted envelope; draft skipped; malformed refused (Phase 47b)"
  init_target
  bash "$SKELETON_DIR/scripts/install.sh" \
    --source "$SKELETON_DIR" --target "$TEST_DIR" \
    --mode=fresh --claude-only
  local cap_redact="$TEST_DIR/.claude/lib/redact-capture.sh"
  local capdir="$TEST_DIR/.claude/captures"
  mkdir -p "$capdir"

  # Terminal capture (shipped) carrying a secret + an absolute path in the body.
  cat > "$capdir/shipped.md" <<'CAP'
---
capture_id: a3f5b2e1c4d8f7a9b6c2e5d4f8a1b3c7e9d6f2a4b8c1e3d5f7a9c2b4e6d8f0a2
source_pattern_id: a3f5b2e1c4d8f7a9b6c2e5d4f8a1b3c7e9d6f2a4b8c1e3d5f7a9c2b4e6d8f0a2
source_pattern_type: repeated_command
status: shipped
confidence: high
suggested_artifact_type: script
created_at: 2026-05-15T12:00:00Z
---
Ran at /Users/secret/path and used API_TOKEN=hunter2longtokenvalue to auth.
CAP
  local out
  out=$(bash "$cap_redact" "$capdir/shipped.md") \
    || { echo "ERROR: redact-capture exit != 0 on terminal capture" >&2; exit 1; }
  printf '%s' "$out" | python -c "
import json, sys
d = json.load(sys.stdin)
assert d['producer'] == 'captures', 'producer != captures'
assert d['schema_version'] == 1, 'schema_version != 1'
assert d['install_uuid'], 'install_uuid empty'
assert d.get('created_at') == '2026-05-15T12:00:00Z', 'envelope created_at: ' + repr(d.get('created_at'))
p = d['payload']
for k in ('status','confidence','suggested_artifact_type','created_at','body_redacted'):
    assert k in p, 'payload missing ' + k
assert p['status'] == 'shipped', 'payload status'
b = p['body_redacted']
assert 'hunter2longtokenvalue' not in b, 'token leaked: ' + b
assert '/Users/secret' not in b, 'abs path leaked: ' + b
print('  capture envelope OK: redacted; install_uuid=' + d['install_uuid'][:8])
"

  # Draft capture → skipped (exit 2).
  cat > "$capdir/draft.md" <<'CAP'
---
capture_id: bbbbbbbbccccddddeeeeffff0000111122223333444455556666777788889999
source_pattern_id: bbbbbbbbccccddddeeeeffff0000111122223333444455556666777788889999
source_pattern_type: other
status: draft
confidence: med
suggested_artifact_type: script
created_at: 2026-05-15T12:00:00Z
---
nothing terminal here
CAP
  set +e
  bash "$cap_redact" "$capdir/draft.md" >/dev/null 2>&1
  local draft_rc=$?
  set -e
  [ "$draft_rc" -eq 2 ] || { echo "ERROR: draft capture expected exit 2, got $draft_rc" >&2; exit 1; }
  echo "  draft skipped (exit 2) OK"

  # Malformed (no frontmatter) → refused (exit 3).
  printf 'plain text\nno frontmatter here\n' > "$capdir/bad.md"
  set +e
  bash "$cap_redact" "$capdir/bad.md" >/dev/null 2>&1
  local bad_rc=$?
  set -e
  [ "$bad_rc" -eq 3 ] || { echo "ERROR: malformed capture expected exit 3, got $bad_rc" >&2; exit 1; }
  echo "  malformed refused (exit 3) OK"

  echo "PASS share-capture-redact"
}

# Phase 47b: with share enabled (via the real 47a opt-in), producers write
# redacted envelopes into producer/install/date; local-only is refused;
# telemetry routes to telemetry/ (not double-emitted under observations);
# version is current-state (no date dir, no created_at).
scenario_share_produce_enabled() {
  echo ">> share-produce-enabled: producers write redacted envelopes; local-only refused; telemetry routed (Phase 47b)"
  command -v jq >/dev/null 2>&1 || { echo "ERROR: jq is required (redact-observation.sh)" >&2; exit 1; }
  init_target
  bash "$SKELETON_DIR/scripts/install.sh" \
    --source "$SKELETON_DIR" --target "$TEST_DIR" \
    --mode=fresh --claude-only
  local bare="$TEST_DIR/skeleton-shared-test.git"
  git init --bare -q "$bare"
  printf 'enable\n' | bash "$TEST_DIR/.claude/scripts/share-enable.sh" "$bare" >/dev/null 2>&1 \
    || { echo "ERROR: share-enable failed" >&2; exit 1; }
  local uuid
  uuid=$(python -c "import json,sys; sys.stdout.write(json.load(open(sys.argv[1]))['install_uuid'])" "$TEST_DIR/.claude/.skeleton-version")
  [ -n "$uuid" ] || { echo "ERROR: no install_uuid" >&2; exit 1; }

  # Seed one artifact of each input class.
  cat > "$TEST_DIR/.claude/captures/capX.md" <<'CAP'
---
capture_id: capX
source_pattern_id: capX
source_pattern_type: other
status: rejected
confidence: high
suggested_artifact_type: script
created_at: 2026-05-10T00:00:00Z
---
body referencing /Users/me/secret and TOKEN=longsecretvalue here
CAP
  cat > "$TEST_DIR/.claude/observations/obs-local.json" <<'J'
{"pattern_id":"localpid","source":"session-observer","pattern_type":"repeated_command","occurrences":3,"first_seen":"2026-05-10T00:00:00Z","last_seen":"2026-05-11T00:00:00Z","resolved_at":null,"evidence":[],"confidence":"high","privacy_class":"local-only"}
J
  cat > "$TEST_DIR/.claude/observations/obs-safe.json" <<'J'
{"pattern_id":"safepid","source":"task-watchdog","pattern_type":"recurring_failure","occurrences":4,"first_seen":"2026-05-09T00:00:00Z","last_seen":"2026-05-11T00:00:00Z","resolved_at":null,"evidence":[],"confidence":"high","privacy_class":"safe-to-share"}
J
  cat > "$TEST_DIR/.claude/observations/token-telemetry-sessZ.json" <<'J'
{"pattern_id":"telpid","source":"session-end-telemetry","pattern_type":"token_telemetry","occurrences":1,"first_seen":"2026-05-08T00:00:00Z","last_seen":"2026-05-08T01:00:00Z","resolved_at":"2026-05-08T01:00:00Z","evidence":[],"confidence":"high","privacy_class":"safe-to-share","target_resource":"session:sessZ"}
J
  bash "$TEST_DIR/.claude/scripts/shared-memory-produce.sh" \
    || { echo "ERROR: produce exit != 0" >&2; exit 1; }

  local tree="$TEST_DIR/.claude/shared-memory"
  have_glob "$tree/captures/$uuid"/*/capX.json        || { echo "ERROR: capture event missing" >&2; exit 1; }
  have_glob "$tree/observations/$uuid"/*/safepid.json || { echo "ERROR: safe-to-share observation event missing" >&2; exit 1; }
  have_glob "$tree/telemetry/$uuid"/*/sessZ.json      || { echo "ERROR: telemetry event missing" >&2; exit 1; }
  [ -f "$tree/version/$uuid/version.json" ]            || { echo "ERROR: version event missing" >&2; exit 1; }
  if have_glob "$tree/observations/$uuid"/*/localpid.json; then echo "ERROR: local-only observation leaked" >&2; exit 1; fi
  if have_glob "$tree/observations/$uuid"/*/sessZ.json;    then echo "ERROR: telemetry double-emitted under observations" >&2; exit 1; fi

  local capfiles=( "$tree/captures/$uuid"/*/capX.json )
  python -c "
import json, sys
d = json.load(open(sys.argv[1]))
assert d['producer'] == 'captures', 'producer'
assert d['schema_version'] == 1, 'schema_version'
assert d['install_uuid'] == sys.argv[2], 'install_uuid mismatch'
blob = json.dumps(d)
assert 'longsecretvalue' not in blob, 'token leaked'
assert '/Users/me' not in blob, 'abs path leaked'
v = json.load(open(sys.argv[3]))
assert 'created_at' not in v, 'version envelope must omit created_at'
assert v['payload']['version'], 'version payload missing version'
print('  envelopes OK: capture redacted; version current-state (no created_at)')
" "${capfiles[0]}" "$uuid" "$tree/version/$uuid/version.json"
  echo "PASS share-produce-enabled"
}

# Phase 47b: re-running the producers adds no duplicate events (append-only
# producers skip existing keys; version overwrites in place).
scenario_share_produce_idempotent() {
  echo ">> share-produce-idempotent: second producer run adds zero events (Phase 47b)"
  command -v jq >/dev/null 2>&1 || { echo "ERROR: jq is required (redact-observation.sh)" >&2; exit 1; }
  init_target
  bash "$SKELETON_DIR/scripts/install.sh" \
    --source "$SKELETON_DIR" --target "$TEST_DIR" \
    --mode=fresh --claude-only
  printf '{"schema_version":1,"enabled":true,"remote_url":"x","enabled_at":"2026-05-22T00:00:00Z","disabled_at":null}\n' \
    > "$TEST_DIR/.claude/share-config.json"
  cat > "$TEST_DIR/.claude/captures/capY.md" <<'CAP'
---
capture_id: capY
source_pattern_id: capY
source_pattern_type: other
status: shipped
confidence: high
suggested_artifact_type: script
created_at: 2026-05-10T00:00:00Z
---
body
CAP
  cat > "$TEST_DIR/.claude/observations/obs-safe.json" <<'J'
{"pattern_id":"safepid","source":"task-watchdog","pattern_type":"recurring_failure","occurrences":4,"first_seen":"2026-05-09T00:00:00Z","last_seen":"2026-05-11T00:00:00Z","resolved_at":null,"evidence":[],"confidence":"high","privacy_class":"safe-to-share"}
J
  bash "$TEST_DIR/.claude/scripts/shared-memory-produce.sh"
  local n1 n2
  n1=$(find "$TEST_DIR/.claude/shared-memory" -type f | wc -l | tr -d ' ')
  bash "$TEST_DIR/.claude/scripts/shared-memory-produce.sh"
  n2=$(find "$TEST_DIR/.claude/shared-memory" -type f | wc -l | tr -d ' ')
  assert_eq "$n2" "$n1"
  [ "$n1" -ge 3 ] || { echo "ERROR: expected >=3 events, got $n1" >&2; exit 1; }
  echo "  idempotent OK: $n1 events on both runs"
  echo "PASS share-produce-idempotent"
}

# Phase 47b: with share mode not configured, producers no-op — no tree, exit 0.
scenario_share_produce_disabled() {
  echo ">> share-produce-disabled: no share-config → producers no-op, no tree (Phase 47b)"
  init_target
  bash "$SKELETON_DIR/scripts/install.sh" \
    --source "$SKELETON_DIR" --target "$TEST_DIR" \
    --mode=fresh --claude-only
  cat > "$TEST_DIR/.claude/captures/capZ.md" <<'CAP'
---
capture_id: capZ
source_pattern_id: capZ
source_pattern_type: other
status: shipped
confidence: high
suggested_artifact_type: script
created_at: 2026-05-10T00:00:00Z
---
body
CAP
  bash "$TEST_DIR/.claude/scripts/shared-memory-produce.sh" \
    || { echo "ERROR: produce should exit 0 when share disabled" >&2; exit 1; }
  if [ -d "$TEST_DIR/.claude/shared-memory" ]; then
    echo "ERROR: shared-memory tree created while share disabled" >&2
    exit 1
  fi
  echo "PASS share-produce-disabled"
}

# Phase 47c-1: the git layer's first push to a freshly init --bare'd remote
# establishes the branch (no unrelated-histories) and the event lands.
scenario_share_push_empty_remote() {
  echo ">> share-push-empty-remote: git layer first push to an empty bare remote establishes the branch (Phase 47c-1)"
  init_target
  bash "$SKELETON_DIR/scripts/install.sh" \
    --source "$SKELETON_DIR" --target "$TEST_DIR" \
    --mode=fresh --claude-only
  local bare="$TEST_DIR/sm.git"
  git init --bare -q "$bare"
  local dir="$TEST_DIR/.claude/shared-memory"
  . "$TEST_DIR/.claude/lib/shared-memory-git.sh"
  smg_ensure_clone "$bare" "$dir" || { echo "ERROR: ensure_clone failed" >&2; exit 1; }
  [ -d "$dir/.git" ] || { echo "ERROR: shared-memory is not a working clone" >&2; exit 1; }
  mkdir -p "$dir/captures/uuidX/2026-05-23"
  printf '{"k":1}\n' > "$dir/captures/uuidX/2026-05-23/evt.json"
  smg_push "$dir" "first push" || { echo "ERROR: smg_push failed on empty remote" >&2; exit 1; }
  local ref
  ref=$(git -C "$bare" for-each-ref --format='%(refname)' refs/heads | head -1)
  [ -n "$ref" ] || { echo "ERROR: no branch established on empty remote" >&2; exit 1; }
  git -C "$bare" cat-file -e "$ref:captures/uuidX/2026-05-23/evt.json" 2>/dev/null \
    || { echo "ERROR: event not in remote after first push" >&2; exit 1; }
  echo "PASS share-push-empty-remote"
}

# Phase 47c-1: two clones of one remote push disjoint files; the second push is
# rejected (non-fast-forward), pull --rebase + retry lands it. Both files end up
# in the remote — the thin race net resolves the push-vs-push race.
scenario_share_push_race() {
  echo ">> share-push-race: two clones push disjoint files; pull-rebase-retry lands both (Phase 47c-1)"
  init_target
  bash "$SKELETON_DIR/scripts/install.sh" \
    --source "$SKELETON_DIR" --target "$TEST_DIR" \
    --mode=fresh --claude-only
  local bare="$TEST_DIR/sm.git"
  git init --bare -q "$bare"
  . "$TEST_DIR/.claude/lib/shared-memory-git.sh"
  local a="$TEST_DIR/cloneA" b="$TEST_DIR/cloneB"
  # Seed the remote with a base commit from cloneA.
  smg_ensure_clone "$bare" "$a" || { echo "ERROR: cloneA ensure failed" >&2; exit 1; }
  mkdir -p "$a/x"; printf 'a\n' > "$a/x/a.json"
  smg_push "$a" "seed a" || { echo "ERROR: seed push failed" >&2; exit 1; }
  # cloneB starts from the seeded remote.
  smg_ensure_clone "$bare" "$b" || { echo "ERROR: cloneB ensure failed" >&2; exit 1; }
  # cloneA advances the remote; cloneB is now behind.
  printf 'a2\n' > "$a/x/a2.json"
  smg_push "$a" "A adds a2" || { echo "ERROR: A second push failed" >&2; exit 1; }
  # cloneB pushes a disjoint file → rejected → pull --rebase → retry → lands.
  mkdir -p "$b/x"; printf 'b\n' > "$b/x/b.json"
  smg_push "$b" "B adds b" || { echo "ERROR: race push (B) failed" >&2; exit 1; }
  local ref f
  ref=$(git -C "$bare" for-each-ref --format='%(refname)' refs/heads | head -1)
  for f in x/a.json x/a2.json x/b.json; do
    git -C "$bare" cat-file -e "$ref:$f" 2>/dev/null \
      || { echo "ERROR: $f missing in remote after race" >&2; exit 1; }
  done
  echo "PASS share-push-race"
}

scenario_fresh_refuse() {
  echo ">> fresh-refuse: re-run --mode=fresh, expect refusal"
  init_target
  bash "$SKELETON_DIR/scripts/install.sh" \
    --source "$SKELETON_DIR" --target "$TEST_DIR" \
    --mode=fresh --claude-only
  local marker_hash_before
  marker_hash_before=$(sha256_of "$TEST_DIR/.claude/.skeleton-version")
  # Second --mode=fresh should refuse (non-zero exit).
  if bash "$SKELETON_DIR/scripts/install.sh" \
       --source "$SKELETON_DIR" --target "$TEST_DIR" \
       --mode=fresh --claude-only 2>/dev/null; then
    echo "ERROR: --mode=fresh against populated target should have refused" >&2
    exit 1
  fi
  local marker_hash_after
  marker_hash_after=$(sha256_of "$TEST_DIR/.claude/.skeleton-version")
  assert_eq "$marker_hash_after" "$marker_hash_before"
  echo "PASS fresh-refuse (marker unchanged)"
}

scenario_merge_add() {
  echo ">> merge-add: delete a file, re-run --mode=merge, expect re-add"
  init_target
  bash "$SKELETON_DIR/scripts/install.sh" \
    --source "$SKELETON_DIR" --target "$TEST_DIR" \
    --mode=fresh --claude-only
  local target_file="$TEST_DIR/.claude/commands/commit.md"
  [ -f "$target_file" ] || { echo "ERROR: setup file missing"; exit 1; }
  # Capture hashes of two unrelated files to confirm they're untouched.
  local untouched_a untouched_b before_a after_a before_b after_b
  untouched_a="$TEST_DIR/.claude/agents/01_research/research-helper.md"
  untouched_b="$TEST_DIR/.claude/settings.json"
  before_a=$(sha256_of "$untouched_a")
  before_b=$(sha256_of "$untouched_b")
  rm "$target_file"
  local out
  out=$(bash "$SKELETON_DIR/scripts/install.sh" \
          --source "$SKELETON_DIR" --target "$TEST_DIR" \
          --mode=merge --claude-only)
  [ -f "$target_file" ] || { echo "ERROR: deleted file was not re-added"; exit 1; }
  assert_contains "$out" "copied:   1"
  after_a=$(sha256_of "$untouched_a")
  after_b=$(sha256_of "$untouched_b")
  assert_eq "$after_a" "$before_a"
  assert_eq "$after_b" "$before_b"
  echo "PASS merge-add"
}

scenario_local_mod_detect() {
  echo ">> local-mod-detect: modify a file, expect 1 LOCALLY_MODIFIED in dry-run"
  init_target
  bash "$SKELETON_DIR/scripts/install.sh" \
    --source "$SKELETON_DIR" --target "$TEST_DIR" \
    --mode=fresh --claude-only
  local target_file="$TEST_DIR/.claude/agents/01_research/research-helper.md"
  printf '\n# CI local mod\n' >> "$target_file"
  local out
  out=$(bash "$SKELETON_DIR/scripts/update.sh" \
          --source "$SKELETON_DIR" --target "$TEST_DIR" \
          --dry-run < /dev/null)
  assert_contains "$out" "locally modified files:       1"
  assert_contains "$out" ".claude/agents/01_research/research-helper.md"
  echo "PASS local-mod-detect"
}

scenario_local_mod_preserve() {
  echo ">> local-mod-preserve: real update with [K]eep choice, expect file unchanged"
  init_target
  bash "$SKELETON_DIR/scripts/install.sh" \
    --source "$SKELETON_DIR" --target "$TEST_DIR" \
    --mode=fresh --claude-only
  local target_file="$TEST_DIR/.claude/agents/01_research/research-helper.md"
  printf '\n# CI local mod preserve\n' >> "$target_file"
  local hash_before hash_after
  hash_before=$(sha256_of "$target_file")
  # Answer 'k' to the LOCALLY_MODIFIED prompt (keep local).
  printf 'k\n' | bash "$SKELETON_DIR/scripts/update.sh" \
                    --source "$SKELETON_DIR" --target "$TEST_DIR" \
                    > "$TEST_DIR/update.out" 2>&1 || true
  hash_after=$(sha256_of "$target_file")
  if [ "$hash_after" != "$hash_before" ]; then
    echo "ERROR: file changed when user chose [K]eep" >&2
    echo "---- update.sh output ----" >&2
    cat "$TEST_DIR/update.out" >&2
    exit 1
  fi
  echo "PASS local-mod-preserve"
}

scenario_backfill_migrate() {
  echo ">> backfill-migrate: legacy shell marker → JSON after update"
  init_target
  bash "$SKELETON_DIR/scripts/install.sh" \
    --source "$SKELETON_DIR" --target "$TEST_DIR" \
    --mode=fresh --claude-only
  # Replace the JSON marker with a legacy shell-format one.
  cat > "$TEST_DIR/.claude/.skeleton-version" <<'LEGACY'
version: 0.6.0
commit: 0000000000000000000000000000000000000000
installed_at: 2026-05-13T00:00:00Z
mode: merge
claude_only: true
source: legacy
LEGACY
  # Run update.sh, skipping all template updates (S) and orphans (n).
  printf 'S\nn\n' | bash "$SKELETON_DIR/scripts/update.sh" \
                      --source "$SKELETON_DIR" --target "$TEST_DIR" \
                      > "$TEST_DIR/update.out" 2>&1
  assert_contains "$(cat "$TEST_DIR/update.out")" "BACKFILL MODE"
  # Marker must now be JSON.
  local first_byte
  first_byte=$(head -c 1 "$TEST_DIR/.claude/.skeleton-version")
  if [ "$first_byte" != "{" ]; then
    echo "ERROR: marker is not JSON after backfill (first byte: $first_byte)" >&2
    cat "$TEST_DIR/.claude/.skeleton-version" >&2
    exit 1
  fi
  verify_marker 60
  echo "PASS backfill-migrate"
}

# Phase 52: a pre-Phase-52 JSON marker (has `files`, no `raw_template_baselines`)
# triggers the inline one-time migration. A tuner-style edit made after install
# must surface as LOCALLY_MODIFIED (NOT TEMPLATE_UPDATED) and survive [K]eep —
# this is the regression that silently overwrote tuner customizations.
scenario_raw_baseline_migrate() {
  echo ">> raw-baseline-migrate: pre-Phase-52 marker migrates inline; tuner edit -> LOCALLY_MODIFIED + kept (Phase 52)"
  init_target
  bash "$SKELETON_DIR/scripts/install.sh" \
    --source "$SKELETON_DIR" --target "$TEST_DIR" \
    --mode=fresh --claude-only
  local marker="$TEST_DIR/.claude/.skeleton-version"
  local target_file="$TEST_DIR/.claude/agents/01_research/research-helper.md"
  # Simulate a project-tuner-helper customization landing after install.
  printf '\n# CI tuner-style customization\n' >> "$target_file"
  local hash_tuned
  hash_tuned=$(sha256_of "$target_file")
  # Simulate a pre-Phase-52 marker: drop raw_template_baselines, keep files + commit.
  python -c "
import json, sys
with open(sys.argv[1]) as f:
    d = json.load(f)
d.pop('raw_template_baselines', None)
with open(sys.argv[1], 'w', newline='\n') as f:
    json.dump(d, f, indent=2, sort_keys=True)
    f.write('\n')
" "$marker"
  # Real update: migration recovers raw baselines from the install commit; the
  # tuner-edited file must surface as LOCALLY_MODIFIED and be KEEPable.
  printf 'k\n' | bash "$SKELETON_DIR/scripts/update.sh" \
                   --source "$SKELETON_DIR" --target "$TEST_DIR" \
                   > "$TEST_DIR/update.out" 2>&1 || true
  local out
  out=$(cat "$TEST_DIR/update.out")
  assert_contains "$out" "Migrating baseline scheme"
  assert_contains "$out" "locally modified files:       1"
  assert_contains "$out" ".claude/agents/01_research/research-helper.md"
  # KEEP must preserve the tuner edit.
  local hash_after
  hash_after=$(sha256_of "$target_file")
  if [ "$hash_after" != "$hash_tuned" ]; then
    echo "ERROR: tuner-edited file changed despite migration + [K]eep" >&2
    cat "$TEST_DIR/update.out" >&2
    exit 1
  fi
  # Marker must now carry raw_template_baselines.
  python -c "
import json, sys
with open(sys.argv[1]) as f:
    d = json.load(f)
raw = d.get('raw_template_baselines')
n = len(raw) if isinstance(raw, dict) else None
if n != 59:
    sys.exit(f'ERROR: expected 59 raw_template_baselines after migration, got {n}')
print(f'  raw_template_baselines present after migration: {n} entries')
" "$marker"
  echo "PASS raw-baseline-migrate"
}

# ---- Phase 30b scenarios (audit findings H5 + H7) ----

scenario_check_remote_cached() {
  echo ">> check-remote-cached: --check-remote populates cached_skeleton_head from mock remote"
  init_target
  bash "$SKELETON_DIR/scripts/install.sh" \
    --source "$SKELETON_DIR" --target "$TEST_DIR" \
    --mode=fresh --claude-only
  # Set up a mock skeleton repo with semver tags. SKELETON_REPO_URL is overridable
  # via env (Phase 30b H4 fix) so we can point update.sh at a local bare repo.
  local mock_work="$TEST_DIR/mock-skeleton"
  local mock_bare="$TEST_DIR/mock-skeleton.git"
  git init -q --bare "$mock_bare"
  git init -q "$mock_work"
  (
    cd "$mock_work"
    git config user.email "ci@test.local"
    git config user.name "CI Test"
    printf 'mock\n' > README.md
    git add README.md
    git commit -q -m "init"
    git tag v0.5.0
    git tag v0.9.5
    git tag v1.0.0
    git remote add origin "$mock_bare"
    git push -q origin HEAD --tags
  )
  # Run --check-remote with env override.
  SKELETON_REPO_URL="$mock_bare" bash "$SKELETON_DIR/scripts/update.sh" \
    --target "$TEST_DIR" --check-remote > "$TEST_DIR/check-remote.out" 2>&1
  # Verify marker was updated with highest semver.
  python -c "
import json, sys
with open(sys.argv[1]) as f:
    d = json.load(f)
got = d.get('cached_skeleton_head')
if got != '1.0.0':
    sys.exit(f'ERROR: expected cached_skeleton_head=1.0.0, got {got!r}')
if not d.get('cached_skeleton_head_fetched_at'):
    sys.exit('ERROR: cached_skeleton_head_fetched_at not set')
print(f'  cached_skeleton_head: {got}')
print(f'  cached_skeleton_head_fetched_at: {d[\"cached_skeleton_head_fetched_at\"]}')
" "$TEST_DIR/.claude/.skeleton-version"
  echo "PASS check-remote-cached"
}

scenario_hook_fail_closed_bash_safety() {
  echo ">> hook-fail-closed-bash-safety: missing lib → deny JSON"
  init_target
  bash "$SKELETON_DIR/scripts/install.sh" \
    --source "$SKELETON_DIR" --target "$TEST_DIR" \
    --mode=fresh --claude-only
  # Move the lib aside to simulate missing.
  local lib="$TEST_DIR/.claude/lib/destructive-bash-patterns.sh"
  [ -f "$lib" ] || { echo "ERROR: lib not at $lib after install"; exit 1; }
  mv "$lib" "$lib.bak"
  # Construct a benign PreToolUse JSON input — even benign commands should fail-closed
  # to deny when the lib is missing (defense-in-depth).
  local input='{"tool_name":"Bash","tool_input":{"command":"echo hi"}}'
  local output
  output=$(CLAUDE_PROJECT_DIR="$TEST_DIR" printf '%s' "$input" | \
    CLAUDE_PROJECT_DIR="$TEST_DIR" bash "$TEST_DIR/.claude/hooks/pretooluse-bash-safety.sh" 2>&1)
  assert_contains "$output" '"permissionDecision":"deny"'
  assert_contains "$output" "destructive-pattern lib missing"
  # Restore the lib for the trap cleanup tidiness.
  mv "$lib.bak" "$lib"
  echo "PASS hook-fail-closed-bash-safety"
}

scenario_cruft_check_fixture() {
  echo ">> cruft-check-fixture: broken markdown link → heuristic-i observation"
  # Custom TEST_DIR setup — clone skeleton via --depth 1 for isolation.
  TEST_DIR=$(mktemp -d 2>/dev/null || mktemp -d -t claude-skel-ci-cc)
  git clone -q --depth 1 "file://$SKELETON_DIR" "$TEST_DIR/skel"
  (
    cd "$TEST_DIR/skel"
    # Add a markdown file with an unambiguously broken link.
    printf '# Test\n[broken](does-not-exist.md)\n' > BROKEN_LINK_TEST.md
    # Run cruft-check.sh (no --hook → bypass cooldown). Captures stderr.
    bash .claude/scripts/cruft-check.sh > /dev/null 2>&1
    # Look for an observation file with the heuristic-i notes prefix.
    local found
    found=$(grep -l 'i: BROKEN_LINK_TEST.md' .claude/observations/*.json 2>/dev/null || true)
    if [ -z "$found" ]; then
      echo "ERROR: cruft-check.sh did not emit heuristic-i observation for broken link" >&2
      ls -la .claude/observations/ >&2 2>/dev/null || true
      exit 1
    fi
    echo "  found: $found"
  )
  echo "PASS cruft-check-fixture"
}

scenario_replace_with_yes_piped() {
  echo ">> replace-with-yes-piped: --mode=replace overwrites with YES piped to stdin"
  init_target
  bash "$SKELETON_DIR/scripts/install.sh" \
    --source "$SKELETON_DIR" --target "$TEST_DIR" \
    --mode=fresh --claude-only
  local target_file="$TEST_DIR/.claude/agents/01_research/research-helper.md"
  # Modify the file so we have something to overwrite.
  printf '\n# CI replace-mod\n' >> "$target_file"
  local hash_modified
  hash_modified=$(sha256_of "$target_file")
  # Pipe YES into install.sh --mode=replace. --force is required for replace mode.
  printf 'YES\n' | bash "$SKELETON_DIR/scripts/install.sh" \
                     --source "$SKELETON_DIR" --target "$TEST_DIR" \
                     --mode=replace --force --claude-only \
                     > "$TEST_DIR/install-replace.out" 2>&1
  local hash_after hash_template
  hash_after=$(sha256_of "$target_file")
  hash_template=$(sha256_of "$SKELETON_DIR/template/.claude/agents/01_research/research-helper.md")
  if [ "$hash_after" = "$hash_modified" ]; then
    echo "ERROR: replace mode did not overwrite the locally-modified file" >&2
    cat "$TEST_DIR/install-replace.out" >&2
    exit 1
  fi
  assert_eq "$hash_after" "$hash_template"
  echo "PASS replace-with-yes-piped"
}

# ---- Phase 30c FP exemption scenario ----

# Helpers for the FP-exemption scenario. Each helper pipes a synthetic
# PreToolUse JSON to the named hook and asserts the output JSON contains
# the expected permissionDecision. Python is used ONLY to JSON-encode the
# test command (safer than shell-string concat with arbitrary special
# chars); the hook itself remains Python-free per Phase 30c constraint.
fp_assert_bash() {
  local expected="$1" desc="$2" cmd="$3"
  local payload
  payload=$(python -c '
import json, sys
print(json.dumps({"tool_name": "Bash", "tool_input": {"command": sys.argv[1]}}))
' "$cmd")
  local out
  out=$(printf '%s' "$payload" | CLAUDE_PROJECT_DIR="$TEST_DIR" \
    bash "$TEST_DIR/.claude/hooks/pretooluse-bash-safety.sh" 2>&1)
  if ! printf '%s' "$out" | grep -q "\"permissionDecision\":\"$expected\""; then
    echo "ERROR ($desc): expected $expected; got:" >&2
    printf '%s\n' "$out" >&2
    exit 1
  fi
  echo "  OK ($desc): $expected"
}

fp_assert_ps() {
  local expected="$1" desc="$2" cmd="$3"
  local payload
  payload=$(python -c '
import json, sys
print(json.dumps({"tool_name": "PowerShell", "tool_input": {"command": sys.argv[1]}}))
' "$cmd")
  local out
  out=$(printf '%s' "$payload" | CLAUDE_PROJECT_DIR="$TEST_DIR" \
    bash "$TEST_DIR/.claude/hooks/pretooluse-powershell-safety.sh" 2>&1)
  if ! printf '%s' "$out" | grep -q "\"permissionDecision\":\"$expected\""; then
    echo "ERROR ($desc): expected $expected; got:" >&2
    printf '%s\n' "$out" >&2
    exit 1
  fi
  echo "  OK ($desc): $expected"
}

scenario_hook_fp_exemption_git_commit_message() {
  echo ">> hook-fp-exemption-git-commit-message: parser exempts -m bodies + heredocs; counter-tests still deny"
  init_target
  bash "$SKELETON_DIR/scripts/install.sh" \
    --source "$SKELETON_DIR" --target "$TEST_DIR" \
    --mode=fresh --claude-only

  # Bash variant (uses pretooluse-bash-safety.sh)
  fp_assert_bash allow "bash test 1: -m body with rm -rf" \
    'git commit -m "removed rm -rf from script"'
  fp_assert_bash allow "bash test 2: -m body with rsync --delete" \
    'git commit -m "rsync --delete /"'
  fp_assert_bash deny "bash test 3 (counter): bare rm -rf /" \
    'rm -rf /'
  fp_assert_bash deny "bash test 4 (counter): git commit then chained rm -rf" \
    'git commit -m "foo"; rm -rf /'
  fp_assert_bash allow "bash test 5: heredoc with rm -rf inside body" \
    "$(printf 'cat > x <<EOF\nrm -rf /\nEOF\n')"
  fp_assert_bash allow "bash test 6: Phase 30b realistic msg shape" \
    'git commit -m "fix(scripts): added rsync --delete + dd of=/dev/sd* + shred|srm patterns"'

  # PowerShell variant (uses pretooluse-powershell-safety.sh)
  fp_assert_ps allow "ps test 7: -m body with rm -rf" \
    'git commit -m "removed rm -rf from script"'
  fp_assert_ps allow "ps test 8: -m body with rsync --delete" \
    'git commit -m "rsync --delete /"'
  fp_assert_ps deny "ps test 9 (counter): bare Remove-Item -Recurse -Force" \
    'Remove-Item -Recurse -Force C:\temp'
  fp_assert_ps deny "ps test 10 (counter): git commit then chained Remove-Item" \
    'git commit -m "foo"; Remove-Item -Recurse -Force C:\temp'
  fp_assert_ps allow "ps test 11: here-string with destructive inside body" \
    "$(printf '$x = @"\nRemove-Item -Recurse -Force C:\\temp\n"@\n')"

  echo "PASS hook-fp-exemption-git-commit-message (11/11 cases)"
}

# ---- dispatch ----
case "${1:-}" in
  fresh-install)                scenario_fresh_install ;;
  raw-baseline-install)         scenario_raw_baseline_install ;;
  install-uuid-fresh)           scenario_install_uuid_fresh ;;
  install-uuid-backfill)        scenario_install_uuid_backfill ;;
  share-enable-fresh-remote)    scenario_share_enable_fresh_remote ;;
  share-status-disabled-default) scenario_share_status_disabled_default ;;
  share-capture-redact)         scenario_share_capture_redact ;;
  share-produce-enabled)        scenario_share_produce_enabled ;;
  share-produce-idempotent)     scenario_share_produce_idempotent ;;
  share-produce-disabled)       scenario_share_produce_disabled ;;
  share-push-empty-remote)      scenario_share_push_empty_remote ;;
  share-push-race)              scenario_share_push_race ;;
  fresh-refuse)                 scenario_fresh_refuse ;;
  merge-add)                    scenario_merge_add ;;
  local-mod-detect)             scenario_local_mod_detect ;;
  local-mod-preserve)           scenario_local_mod_preserve ;;
  backfill-migrate)             scenario_backfill_migrate ;;
  raw-baseline-migrate)         scenario_raw_baseline_migrate ;;
  check-remote-cached)              scenario_check_remote_cached ;;
  hook-fail-closed-bash-safety)     scenario_hook_fail_closed_bash_safety ;;
  cruft-check-fixture)              scenario_cruft_check_fixture ;;
  replace-with-yes-piped)           scenario_replace_with_yes_piped ;;
  hook-fp-exemption-git-commit-message) scenario_hook_fp_exemption_git_commit_message ;;
  all)
    scenario_fresh_install
    scenario_raw_baseline_install
    scenario_install_uuid_fresh
    scenario_install_uuid_backfill
    scenario_share_enable_fresh_remote
    scenario_share_status_disabled_default
    scenario_share_capture_redact
    scenario_share_produce_enabled
    scenario_share_produce_idempotent
    scenario_share_produce_disabled
    scenario_share_push_empty_remote
    scenario_share_push_race
    scenario_fresh_refuse
    scenario_merge_add
    scenario_local_mod_detect
    scenario_local_mod_preserve
    scenario_backfill_migrate
    scenario_raw_baseline_migrate
    scenario_check_remote_cached
    scenario_hook_fail_closed_bash_safety
    scenario_cruft_check_fixture
    scenario_replace_with_yes_piped
    scenario_hook_fp_exemption_git_commit_message
    echo "ALL SCENARIOS PASSED"
    ;;
  ""|-h|--help)
    cat <<EOF
Usage: bash scenarios.sh <scenario>

Scenarios:
  fresh-install                Clean target → install --mode=fresh; verify JSON marker.
  raw-baseline-install         Fresh install records raw_template_baselines matching template hashes (Phase 52).
  install-uuid-fresh           Fresh install records install_uuid / install_label / install_created (Phase 47a).
  install-uuid-backfill        Pre-47a marker → update.sh backfills install identity, existing fields intact (Phase 47a).
  share-enable-fresh-remote    /share-enable to an empty bare remote pushes the identity sentinel + writes share-config.json (Phase 47a).
  share-status-disabled-default share-status on a fresh install (no share-config.json) reports "not configured" (Phase 47a).
  share-capture-redact         redact-capture.sh: terminal capture → redacted envelope; draft skipped; malformed refused (Phase 47b).
  share-produce-enabled        Producers write redacted envelopes to producer/install/date; local-only refused; telemetry routed (Phase 47b).
  share-produce-idempotent     Second producer run adds zero duplicate events (Phase 47b).
  share-produce-disabled       No share-config → producers no-op, no tree created (Phase 47b).
  share-push-empty-remote      Git layer: first push to an empty bare remote establishes the branch (Phase 47c-1).
  share-push-race              Two clones push disjoint files; pull-rebase-retry lands both (Phase 47c-1).
  fresh-refuse                 Populated target → --mode=fresh exits non-zero; marker unchanged.
  merge-add                    Delete a file → --mode=merge re-adds only that file.
  local-mod-detect             Modify a file → update.sh --dry-run reports LOCALLY_MODIFIED.
  local-mod-preserve           Modify a file → update.sh with [K]eep leaves it intact.
  backfill-migrate             Legacy shell marker → update.sh migrates to JSON.
  raw-baseline-migrate         Pre-Phase-52 marker → inline migration; tuner edit stays LOCALLY_MODIFIED (Phase 52).
  check-remote-cached          --check-remote against mock bare repo populates cached_skeleton_head (Phase 30b H5).
  hook-fail-closed-bash-safety Missing lib → PreToolUse hook emits deny JSON (Phase 30b H5).
  cruft-check-fixture          Broken markdown link → cruft-check.sh heuristic-i observation (Phase 30b H5).
  replace-with-yes-piped       printf 'YES' | install.sh --mode=replace overwrites locally-modified file (Phase 30b H7).
  hook-fp-exemption-git-commit-message  Parser exempts -m bodies + heredoc/here-string payloads; counter-tests verify outside-region patterns still deny (Phase 30c).
  all                          Run every scenario in sequence.
EOF
    [ -z "${1:-}" ] && exit 0 || exit 0
    ;;
  *)
    echo "unknown scenario: $1" >&2
    bash "$0" --help >&2
    exit 1
    ;;
esac
