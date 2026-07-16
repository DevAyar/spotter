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
  local out
  out=$(bash "$SKELETON_DIR/scripts/install.sh" \
    --source "$SKELETON_DIR" --target "$TEST_DIR" \
    --mode=fresh --claude-only)
  verify_marker 75
  # Phase 72: the post-install message points somewhere real, and the
  # greeting surface carries no literal placeholder.
  assert_contains "$out" "GETTING-STARTED"
  assert_contains "$out" "agents"
  if grep -q '{{' "$TEST_DIR/.claude/settings.json"; then
    echo "ERROR: literal placeholder survived install in settings.json" >&2
    exit 1
  fi
  grep -q "Durable rules" "$TEST_DIR/.claude/settings.json" \
    || { echo "ERROR: generic compactPrompt default missing" >&2; exit 1; }
  # The default ships IN the template (no placeholder, no install-time
  # substitution), so a fresh install's settings.json is genuinely
  # UNCHANGED — no spurious prompt on the very first update.
  local dout
  dout=$(bash "$SKELETON_DIR/scripts/update.sh" --source "$SKELETON_DIR" --target "$TEST_DIR" --dry-run < /dev/null 2>&1)
  assert_contains "$dout" "locally modified files:       0"
  assert_contains "$dout" "template updates available:   0"
  # Phase 73: the first-run welcome fires exactly once, then never again.
  [ -f "$TEST_DIR/.claude/.first-run" ] || { echo "ERROR: install did not drop .first-run flag" >&2; exit 1; }
  local hout1 hout2 hout3
  hout1=$(cd "$TEST_DIR" && CLAUDE_PROJECT_DIR="$TEST_DIR" bash .claude/hooks/sessionstart-rules.sh 2>/dev/null || true)
  assert_contains "$hout1" "First session in this project"
  assert_contains "$hout1" "Durable rules"
  [ ! -f "$TEST_DIR/.claude/.first-run" ] || { echo "ERROR: welcome did not consume the flag" >&2; exit 1; }
  hout2=$(cd "$TEST_DIR" && CLAUDE_PROJECT_DIR="$TEST_DIR" bash .claude/hooks/sessionstart-rules.sh 2>/dev/null || true)
  if printf '%s' "$hout2" | grep -q "First session in this project"; then
    echo "ERROR: welcome fired twice" >&2; exit 1
  fi
  # Existing-install leg: an update run never recreates the flag.
  bash "$SKELETON_DIR/scripts/update.sh" --source "$SKELETON_DIR" --target "$TEST_DIR" < /dev/null > /dev/null 2>&1 || true
  [ ! -f "$TEST_DIR/.claude/.first-run" ] || { echo "ERROR: update.sh recreated the first-run flag" >&2; exit 1; }
  hout3=$(cd "$TEST_DIR" && CLAUDE_PROJECT_DIR="$TEST_DIR" bash .claude/hooks/sessionstart-rules.sh 2>/dev/null || true)
  if printf '%s' "$hout3" | grep -q "First session in this project"; then
    echo "ERROR: welcome resurfaced after update" >&2; exit 1
  fi
  echo "  first-run welcome: once, consumed, never again (incl. post-update) OK"
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

# Phase 47c-1: the SessionEnd orchestrator clones the remote, runs the producer,
# and pushes; events land in the remote and /share-status reports the last push.
scenario_share_push_enabled() {
  echo ">> share-push-enabled: orchestrator clones, produces, pushes; files land; share-status reports (Phase 47c-1)"
  init_target
  bash "$SKELETON_DIR/scripts/install.sh" \
    --source "$SKELETON_DIR" --target "$TEST_DIR" \
    --mode=fresh --claude-only
  local bare="$TEST_DIR/sm.git"
  git init --bare -q "$bare"
  printf 'enable\n' | bash "$TEST_DIR/.claude/scripts/share-enable.sh" "$bare" >/dev/null 2>&1 \
    || { echo "ERROR: share-enable failed" >&2; exit 1; }
  local uuid
  uuid=$(python -c "import json,sys; sys.stdout.write(json.load(open(sys.argv[1]))['install_uuid'])" "$TEST_DIR/.claude/.skeleton-version")
  cat > "$TEST_DIR/.claude/captures/capQ.md" <<'CAP'
---
capture_id: capQ
source_pattern_id: capQ
source_pattern_type: other
status: shipped
confidence: high
suggested_artifact_type: script
created_at: 2026-05-10T00:00:00Z
---
body
CAP
  bash "$TEST_DIR/.claude/scripts/shared-memory-push.sh" \
    || { echo "ERROR: orchestrator exit != 0" >&2; exit 1; }
  [ -d "$TEST_DIR/.claude/shared-memory/.git" ] \
    || { echo "ERROR: shared-memory is not a working clone" >&2; exit 1; }
  local ref
  ref=$(git -C "$bare" for-each-ref --format='%(refname)' refs/heads | head -1)
  [ -n "$ref" ] || { echo "ERROR: remote has no branch after push" >&2; exit 1; }
  git -C "$bare" ls-tree -r --name-only "$ref" | grep -q "captures/$uuid/.*/capQ.json" \
    || { echo "ERROR: capture event not in remote" >&2; git -C "$bare" ls-tree -r --name-only "$ref" >&2; exit 1; }
  git -C "$bare" cat-file -e "$ref:version/$uuid/version.json" 2>/dev/null \
    || { echo "ERROR: version event not in remote" >&2; exit 1; }
  local out
  out=$(bash "$TEST_DIR/.claude/scripts/share-status.sh")
  assert_contains "$out" "Last push:"
  assert_contains "$out" "Files pushed:"
  echo "PASS share-push-enabled"
}

# Phase 47c-1: an unreachable remote must not block session end (exit 0, no clone
# left as a working tree); a later run with the remote present catches up.
scenario_share_push_failsoft() {
  echo ">> share-push-failsoft: unreachable remote → exit 0; later run catches up (Phase 47c-1)"
  init_target
  bash "$SKELETON_DIR/scripts/install.sh" \
    --source "$SKELETON_DIR" --target "$TEST_DIR" \
    --mode=fresh --claude-only
  local bare="$TEST_DIR/later.git"
  printf '{"schema_version":1,"enabled":true,"remote_url":"%s","enabled_at":"2026-05-22T00:00:00Z","disabled_at":null}\n' \
    "$bare" > "$TEST_DIR/.claude/share-config.json"
  cat > "$TEST_DIR/.claude/captures/capF.md" <<'CAP'
---
capture_id: capF
source_pattern_id: capF
source_pattern_type: other
status: shipped
confidence: high
suggested_artifact_type: script
created_at: 2026-05-10T00:00:00Z
---
body
CAP
  GIT_TERMINAL_PROMPT=0 bash "$TEST_DIR/.claude/scripts/shared-memory-push.sh" \
    || { echo "ERROR: orchestrator must exit 0 when remote unreachable" >&2; exit 1; }
  if [ -d "$TEST_DIR/.claude/shared-memory/.git" ]; then
    echo "ERROR: a working clone should not exist after a failed first run" >&2
    exit 1
  fi
  echo "  unreachable remote tolerated (exit 0, no clone)"
  git init --bare -q "$bare"
  GIT_TERMINAL_PROMPT=0 bash "$TEST_DIR/.claude/scripts/shared-memory-push.sh" \
    || { echo "ERROR: catch-up run failed" >&2; exit 1; }
  local ref
  ref=$(git -C "$bare" for-each-ref --format='%(refname)' refs/heads | head -1)
  [ -n "$ref" ] && git -C "$bare" ls-tree -r --name-only "$ref" | grep -q "capF.json" \
    || { echo "ERROR: catch-up did not land capF" >&2; exit 1; }
  echo "PASS share-push-failsoft"
}

# Phase 47c-1: with share mode not configured, the orchestrator no-ops — exit 0,
# no clone created.
scenario_share_push_disabled() {
  echo ">> share-push-disabled: no share-config → orchestrator no-op, no clone (Phase 47c-1)"
  init_target
  bash "$SKELETON_DIR/scripts/install.sh" \
    --source "$SKELETON_DIR" --target "$TEST_DIR" \
    --mode=fresh --claude-only
  bash "$TEST_DIR/.claude/scripts/shared-memory-push.sh" \
    || { echo "ERROR: orchestrator should exit 0 when disabled" >&2; exit 1; }
  if [ -d "$TEST_DIR/.claude/shared-memory" ]; then
    echo "ERROR: clone/dir created while share disabled" >&2
    exit 1
  fi
  echo "PASS share-push-disabled"
}

# Phase 47c-1: /share-push (shared-memory-push.sh --manual) pushes on-change with
# user-facing output, and reports "Nothing to push" when the tree is clean.
scenario_share_push_manual() {
  echo ">> share-push-manual: manual trigger pushes on-change; reports nothing-to-push when clean (Phase 47c-1)"
  init_target
  bash "$SKELETON_DIR/scripts/install.sh" \
    --source "$SKELETON_DIR" --target "$TEST_DIR" \
    --mode=fresh --claude-only
  local bare="$TEST_DIR/sm.git"
  git init --bare -q "$bare"
  printf 'enable\n' | bash "$TEST_DIR/.claude/scripts/share-enable.sh" "$bare" >/dev/null 2>&1 \
    || { echo "ERROR: share-enable failed" >&2; exit 1; }
  cat > "$TEST_DIR/.claude/captures/capM.md" <<'CAP'
---
capture_id: capM
source_pattern_id: capM
source_pattern_type: other
status: shipped
confidence: high
suggested_artifact_type: script
created_at: 2026-05-10T00:00:00Z
---
body
CAP
  local out1
  out1=$(bash "$TEST_DIR/.claude/scripts/shared-memory-push.sh" --manual) \
    || { echo "ERROR: manual push exit != 0" >&2; exit 1; }
  assert_contains "$out1" "Pushed"
  local out2
  out2=$(bash "$TEST_DIR/.claude/scripts/shared-memory-push.sh" --manual) \
    || { echo "ERROR: second manual push exit != 0" >&2; exit 1; }
  assert_contains "$out2" "Nothing to push"
  echo "PASS share-push-manual"
}

# Phase 47c-2: --preview reports what the next push would include (count + per-
# producer breakdown) and pushes/commits NOTHING — the remote is untouched.
scenario_share_preview_enabled() {
  echo ">> share-preview-enabled: --preview reports the would-include set; remote untouched (Phase 47c-2)"
  init_target
  bash "$SKELETON_DIR/scripts/install.sh" \
    --source "$SKELETON_DIR" --target "$TEST_DIR" \
    --mode=fresh --claude-only
  local bare="$TEST_DIR/sm.git"
  git init --bare -q "$bare"
  printf 'enable\n' | bash "$TEST_DIR/.claude/scripts/share-enable.sh" "$bare" >/dev/null 2>&1 \
    || { echo "ERROR: share-enable failed" >&2; exit 1; }
  cat > "$TEST_DIR/.claude/captures/capP.md" <<'CAP'
---
capture_id: capP
source_pattern_id: capP
source_pattern_type: other
status: shipped
confidence: high
suggested_artifact_type: script
created_at: 2026-05-10T00:00:00Z
---
body
CAP
  local out
  out="$(bash "$TEST_DIR/.claude/scripts/shared-memory-push.sh" --preview)" \
    || { echo "ERROR: preview exit != 0" >&2; exit 1; }
  assert_contains "$out" "Preview:"
  assert_contains "$out" "captures"
  # Remote must carry NO capture data — preview commits/pushes nothing.
  local ref
  ref=$(git -C "$bare" for-each-ref --format='%(refname)' refs/heads | head -1)
  if [ -n "$ref" ] && git -C "$bare" ls-tree -r --name-only "$ref" | grep -q '^captures/'; then
    echo "ERROR: preview pushed capture data to the remote" >&2
    git -C "$bare" ls-tree -r --name-only "$ref" >&2
    exit 1
  fi
  echo "PASS share-preview-enabled"
}

# Phase 47c-2: --preview with share off reports not-enabled, exits 0, no clone.
scenario_share_preview_disabled() {
  echo ">> share-preview-disabled: --preview with share off reports not-enabled, exits 0, no clone (Phase 47c-2)"
  init_target
  bash "$SKELETON_DIR/scripts/install.sh" \
    --source "$SKELETON_DIR" --target "$TEST_DIR" \
    --mode=fresh --claude-only
  local out
  out="$(bash "$TEST_DIR/.claude/scripts/shared-memory-push.sh" --preview)" \
    || { echo "ERROR: preview should exit 0 when disabled" >&2; exit 1; }
  assert_contains "$out" "not enabled"
  if [ -d "$TEST_DIR/.claude/shared-memory" ]; then
    echo "ERROR: clone created while share disabled" >&2
    exit 1
  fi
  echo "PASS share-preview-disabled"
}

# Phase 47c-2: --purge-remote removes THIS install's uuid-keyed paths from the
# remote (per-producer subtrees + installs/<uuid>/), leaves other installs' data,
# and ends disabled. Typed 'purge' confirmation supplied on stdin.
scenario_share_purge_remote() {
  echo ">> share-purge-remote: --purge-remote removes this install's files; a 2nd install's stay; ends disabled (Phase 47c-2)"
  init_target
  bash "$SKELETON_DIR/scripts/install.sh" \
    --source "$SKELETON_DIR" --target "$TEST_DIR" \
    --mode=fresh --claude-only
  local bare="$TEST_DIR/sm.git"
  git init --bare -q "$bare"
  printf 'enable\n' | bash "$TEST_DIR/.claude/scripts/share-enable.sh" "$bare" >/dev/null 2>&1 \
    || { echo "ERROR: share-enable failed" >&2; exit 1; }
  local uuid
  uuid=$(python -c "import json,sys; sys.stdout.write(json.load(open(sys.argv[1]))['install_uuid'])" "$TEST_DIR/.claude/.skeleton-version")
  cat > "$TEST_DIR/.claude/captures/capR.md" <<'CAP'
---
capture_id: capR
source_pattern_id: capR
source_pattern_type: other
status: shipped
confidence: high
suggested_artifact_type: script
created_at: 2026-05-10T00:00:00Z
---
body
CAP
  bash "$TEST_DIR/.claude/scripts/shared-memory-push.sh" >/dev/null 2>&1 \
    || { echo "ERROR: initial push failed" >&2; exit 1; }
  # Seed a SECOND install's paths directly into the remote.
  local other="$TEST_DIR/other" ouid="22222222-2222-4222-8222-222222222222"
  git clone -q "$bare" "$other"
  git -C "$other" config user.email o@t.local; git -C "$other" config user.name other
  mkdir -p "$other/captures/$ouid/2026-05-23" "$other/installs/$ouid"
  printf '{"x":1}\n' > "$other/captures/$ouid/2026-05-23/o.json"
  printf '{"s":1}\n' > "$other/installs/$ouid/sentinel.json"
  git -C "$other" add -A; git -C "$other" commit -q -m "second install"; git -C "$other" push -q origin HEAD
  # Purge THIS install (typed confirmation on stdin).
  printf 'purge\n' | bash "$TEST_DIR/.claude/scripts/share-disable.sh" --purge-remote >"$TEST_DIR/purge.out" 2>&1 \
    || { echo "ERROR: purge failed" >&2; cat "$TEST_DIR/purge.out" >&2; exit 1; }
  local ref tree
  ref=$(git -C "$bare" for-each-ref --format='%(refname)' refs/heads | head -1)
  tree=$(git -C "$bare" ls-tree -r --name-only "$ref")
  if printf '%s\n' "$tree" | grep -q "/$uuid/"; then
    echo "ERROR: this install's paths still on remote after purge" >&2; printf '%s\n' "$tree" >&2; exit 1
  fi
  printf '%s\n' "$tree" | grep -q "$ouid" \
    || { echo "ERROR: second install's paths were removed by the purge" >&2; printf '%s\n' "$tree" >&2; exit 1; }
  python -c "import json,sys; c=json.load(open(sys.argv[1])); sys.exit(0 if c.get('enabled') is False else 1)" \
    "$TEST_DIR/.claude/share-config.json" || { echo "ERROR: share mode not disabled after purge" >&2; exit 1; }
  echo "PASS share-purge-remote"
}

# Phase 47c-2: --purge-remote when this install never pushed → clean no-op, disables.
scenario_share_purge_nothing() {
  echo ">> share-purge-nothing: --purge-remote with nothing pushed → no-op, disables (Phase 47c-2)"
  init_target
  bash "$SKELETON_DIR/scripts/install.sh" \
    --source "$SKELETON_DIR" --target "$TEST_DIR" \
    --mode=fresh --claude-only
  local bare="$TEST_DIR/sm.git"
  git init --bare -q "$bare"
  # Enable via a manual config pointing at the empty bare — no sentinel, no events.
  printf '{"schema_version":1,"enabled":true,"remote_url":"%s","enabled_at":"2026-05-22T00:00:00Z","disabled_at":null}\n' \
    "$bare" > "$TEST_DIR/.claude/share-config.json"
  printf 'purge\n' | bash "$TEST_DIR/.claude/scripts/share-disable.sh" --purge-remote >"$TEST_DIR/p.out" 2>&1 \
    || { echo "ERROR: purge-nothing failed" >&2; cat "$TEST_DIR/p.out" >&2; exit 1; }
  assert_contains "$(cat "$TEST_DIR/p.out")" "nothing to remove"
  python -c "import json,sys; c=json.load(open(sys.argv[1])); sys.exit(0 if c.get('enabled') is False else 1)" \
    "$TEST_DIR/.claude/share-config.json" || { echo "ERROR: not disabled after no-op purge" >&2; exit 1; }
  echo "PASS share-purge-nothing"
}

# Phase 47c-2: --purge-remote with no confirmation (EOF) fails closed; the
# feature stays ENABLED and remote data is untouched.
scenario_share_purge_confirm_eof() {
  echo ">> share-purge-confirm-eof: EOF confirmation fails closed; stays enabled; remote intact (Phase 47c-2)"
  init_target
  bash "$SKELETON_DIR/scripts/install.sh" \
    --source "$SKELETON_DIR" --target "$TEST_DIR" \
    --mode=fresh --claude-only
  local bare="$TEST_DIR/sm.git"
  git init --bare -q "$bare"
  printf 'enable\n' | bash "$TEST_DIR/.claude/scripts/share-enable.sh" "$bare" >/dev/null 2>&1 \
    || { echo "ERROR: share-enable failed" >&2; exit 1; }
  set +e
  bash "$TEST_DIR/.claude/scripts/share-disable.sh" --purge-remote </dev/null >"$TEST_DIR/e.out" 2>&1
  local rc=$?
  set -e
  [ "$rc" -ne 0 ] || { echo "ERROR: expected non-zero exit on EOF confirmation" >&2; cat "$TEST_DIR/e.out" >&2; exit 1; }
  python -c "import json,sys; c=json.load(open(sys.argv[1])); sys.exit(0 if c.get('enabled') is True else 1)" \
    "$TEST_DIR/.claude/share-config.json" || { echo "ERROR: share mode disabled despite cancelled purge" >&2; exit 1; }
  local ref uuid
  ref=$(git -C "$bare" for-each-ref --format='%(refname)' refs/heads | head -1)
  uuid=$(python -c "import json,sys; sys.stdout.write(json.load(open(sys.argv[1]))['install_uuid'])" "$TEST_DIR/.claude/.skeleton-version")
  git -C "$bare" cat-file -e "$ref:installs/$uuid/sentinel.json" 2>/dev/null \
    || { echo "ERROR: remote data was touched on a cancelled purge" >&2; exit 1; }
  echo "PASS share-purge-confirm-eof"
}

# Phase 47c-2: plain /share-disable (no flag) stops pushing, leaves remote data,
# needs no confirmation.
scenario_share_disable_plain() {
  echo ">> share-disable-plain: plain disable stops pushing, leaves remote data, no confirmation (Phase 47c-2)"
  init_target
  bash "$SKELETON_DIR/scripts/install.sh" \
    --source "$SKELETON_DIR" --target "$TEST_DIR" \
    --mode=fresh --claude-only
  local bare="$TEST_DIR/sm.git"
  git init --bare -q "$bare"
  printf 'enable\n' | bash "$TEST_DIR/.claude/scripts/share-enable.sh" "$bare" >/dev/null 2>&1 \
    || { echo "ERROR: share-enable failed" >&2; exit 1; }
  local uuid
  uuid=$(python -c "import json,sys; sys.stdout.write(json.load(open(sys.argv[1]))['install_uuid'])" "$TEST_DIR/.claude/.skeleton-version")
  bash "$TEST_DIR/.claude/scripts/share-disable.sh" >"$TEST_DIR/d.out" 2>&1 \
    || { echo "ERROR: plain disable failed" >&2; cat "$TEST_DIR/d.out" >&2; exit 1; }
  python -c "import json,sys; c=json.load(open(sys.argv[1])); sys.exit(0 if c.get('enabled') is False else 1)" \
    "$TEST_DIR/.claude/share-config.json" || { echo "ERROR: not disabled" >&2; exit 1; }
  local ref
  ref=$(git -C "$bare" for-each-ref --format='%(refname)' refs/heads | head -1)
  git -C "$bare" cat-file -e "$ref:installs/$uuid/sentinel.json" 2>/dev/null \
    || { echo "ERROR: plain disable removed remote data" >&2; exit 1; }
  echo "PASS share-disable-plain"
}

# Phase 47d: graduation-review (dogfood-only maintainer tool) groups captures by
# suggested_artifact_type and observations by pattern_type across installs, with
# overlap stated vs the 15/75 threshold; telemetry events are excluded.
scenario_graduation_review_report() {
  echo ">> graduation-review-report: grouped multi-install report; telemetry excluded (Phase 47d)"
  init_target
  bash "$SKELETON_DIR/scripts/install.sh" \
    --source "$SKELETON_DIR" --target "$TEST_DIR" \
    --mode=fresh --claude-only
  # graduation-review is dogfood-only (not installed by install.sh) — copy it in.
  cp "$SKELETON_DIR/.claude/scripts/graduation-review.sh" "$TEST_DIR/.claude/scripts/graduation-review.sh"
  local bare="$TEST_DIR/sm.git"
  git init --bare -q "$bare"
  local side="$TEST_DIR/seed"
  git clone -q "$bare" "$side"
  git -C "$side" config user.email s@t.local; git -C "$side" config user.name seed
  python - "$side" <<'PY'
import json, os, sys
seed = sys.argv[1]
DATE = "2026-05-23"
def write(rel, obj):
    path = os.path.join(seed, rel)
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, "w", newline="\n") as f:
        json.dump(obj, f, sort_keys=True); f.write("\n")
def env(producer, uuid, label, payload):
    return {"schema_version":1,"producer":producer,"install_uuid":uuid,"install_label":label,
            "version":"1.1.4","commit":"abc123","event_timestamp":"2026-05-23T00:00:00Z","payload":payload}
def cap(status, at):
    return {"status":status,"confidence":"high","suggested_artifact_type":at,"created_at":"2026-05-10T00:00:00Z","body_redacted":"x"}
def obs(pt):
    return {"pattern_id":"x","source":"session-observer","pattern_type":pt,"occurrences":3,"first_seen":"2026-05-10T00:00:00Z","last_seen":"2026-05-11T00:00:00Z","resolved_at":None,"confidence":"high","privacy_class":"share-with-redaction"}
inst = [("aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa","alpha"),
        ("bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb","bravo"),
        ("cccccccc-cccc-4ccc-8ccc-cccccccccccc","charlie")]
# captures: script shipped in all 3; skill shipped in alpha only; bravo also has a script DRAFT (must not count)
write(f"captures/{inst[0][0]}/{DATE}/cap-script.json",       env("captures",*inst[0],cap("shipped","script")))
write(f"captures/{inst[0][0]}/{DATE}/cap-skill.json",        env("captures",*inst[0],cap("shipped","skill")))
write(f"captures/{inst[1][0]}/{DATE}/cap-script.json",       env("captures",*inst[1],cap("shipped","script")))
write(f"captures/{inst[1][0]}/{DATE}/cap-script-draft.json", env("captures",*inst[1],cap("draft","script")))
write(f"captures/{inst[2][0]}/{DATE}/cap-script.json",       env("captures",*inst[2],cap("shipped","script")))
# observations: recurring_failure in alpha+bravo; plugin_quality in bravo; repeated_command in charlie
write(f"observations/{inst[0][0]}/{DATE}/obs-rf.json", env("observations",*inst[0],obs("recurring_failure")))
write(f"observations/{inst[1][0]}/{DATE}/obs-rf.json", env("observations",*inst[1],obs("recurring_failure")))
write(f"observations/{inst[1][0]}/{DATE}/obs-pq.json", env("observations",*inst[1],obs("plugin_quality")))
write(f"observations/{inst[2][0]}/{DATE}/obs-rc.json", env("observations",*inst[2],obs("repeated_command")))
# version: one per install (no date dir)
for u,l in inst:
    write(f"version/{u}/version.json", env("version",u,l,{"version":"1.1.4","commit":"abc123","install_uuid":u,"install_label":l,"install_created":"2026-05-01T00:00:00Z"}))
# telemetry: alpha has one — must be EXCLUDED from the report
write(f"telemetry/{inst[0][0]}/{DATE}/sess1.json", env("telemetry",*inst[0],{"k":1}))
PY
  git -C "$side" add -A; git -C "$side" commit -q -m "seed multi-install"; git -C "$side" push -q origin HEAD
  printf '{"schema_version":1,"enabled":true,"remote_url":"%s","enabled_at":"2026-05-22T00:00:00Z","disabled_at":null}\n' \
    "$bare" > "$TEST_DIR/.claude/share-config.json"
  local out
  out="$(bash "$TEST_DIR/.claude/scripts/graduation-review.sh")" \
    || { echo "ERROR: graduation-review exit != 0" >&2; exit 1; }
  assert_contains "$out" "Installs seen: 3"
  assert_contains "$out" "script: shipped in 3 of 3"
  assert_contains "$out" "skill: shipped in 1 of 3"
  assert_contains "$out" "recurring_failure: observed in 2 of 3"
  assert_contains "$out" "graduation threshold 15 installs / 75%; not yet"
  if printf '%s' "$out" | grep -qi "telemetry"; then
    echo "ERROR: telemetry leaked into the report" >&2; printf '%s\n' "$out" >&2; exit 1
  fi
  echo "PASS graduation-review-report"
}

# Phase 47d: with share off, graduation-review prints a clean message and exits 0.
scenario_graduation_review_disabled() {
  echo ">> graduation-review-disabled: share off → nothing to review, exit 0 (Phase 47d)"
  init_target
  bash "$SKELETON_DIR/scripts/install.sh" \
    --source "$SKELETON_DIR" --target "$TEST_DIR" \
    --mode=fresh --claude-only
  cp "$SKELETON_DIR/.claude/scripts/graduation-review.sh" "$TEST_DIR/.claude/scripts/graduation-review.sh"
  local out
  out="$(bash "$TEST_DIR/.claude/scripts/graduation-review.sh")" \
    || { echo "ERROR: should exit 0 when share disabled" >&2; exit 1; }
  assert_contains "$out" "nothing to review"
  echo "PASS graduation-review-disabled"
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

# Phase 62: install.sh is first-install only. A re-run on an installed target
# used to silently rewrite the marker (fresh uuid, only-this-run baselines);
# now it refuses, naming both the update.sh redirect and the explicit
# delete-the-marker escape hatch. update.sh's NEW class owns re-adds.
scenario_install_rerun_refuse() {
  echo ">> install-rerun-refuse: re-run on installed target refuses; update.sh re-adds (Phase 62)"
  init_target
  bash "$SKELETON_DIR/scripts/install.sh" \
    --source "$SKELETON_DIR" --target "$TEST_DIR" \
    --mode=fresh --claude-only
  local marker="$TEST_DIR/.claude/.skeleton-version"
  local removed="$TEST_DIR/.claude/commands/commit.md"
  rm "$removed"
  local marker_before uuid_before
  marker_before=$(sha256_of "$marker")
  uuid_before=$(python -c "import json,sys; print(json.load(open(sys.argv[1]))['install_uuid'])" "$marker")
  local out rc=0
  out=$(bash "$SKELETON_DIR/scripts/install.sh" \
          --source "$SKELETON_DIR" --target "$TEST_DIR" \
          --mode=merge --claude-only 2>&1) || rc=$?
  [ "$rc" -ne 0 ] || { echo "ERROR: re-run on installed target should have refused" >&2; exit 1; }
  assert_contains "$out" "update.sh"
  assert_contains "$out" "delete .claude/.skeleton-version first"
  assert_eq "$(sha256_of "$marker")" "$marker_before"
  echo "  refusal: exit=$rc, marker byte-identical, message has redirect + escape hatch OK"
  # The redirect works: update.sh re-adds the deleted file (NEW class) and
  # the install identity survives.
  printf 'y\n' | bash "$SKELETON_DIR/scripts/update.sh" \
    --source "$SKELETON_DIR" --target "$TEST_DIR" > "$TEST_DIR/update.out" 2>&1 || true
  [ -f "$removed" ] || { echo "ERROR: update.sh did not re-add the deleted file" >&2; cat "$TEST_DIR/update.out" >&2; exit 1; }
  local uuid_after
  uuid_after=$(python -c "import json,sys; print(json.load(open(sys.argv[1]))['install_uuid'])" "$marker")
  assert_eq "$uuid_after" "$uuid_before"
  echo "PASS install-rerun-refuse (redirect re-added the file; uuid stable)"
}

# Phase 62 rework: install.sh re-runs on installed targets are now refused
# (see install-rerun-refuse; update.sh's NEW class owns re-adds). merge mode's
# remaining surface is the FIRST install into a marker-less target with
# pre-existing .claude/ content — custom files preserved, name-collisions
# skipped, missing template files added, marker created.
scenario_merge_add() {
  echo ">> merge-add: first install --mode=merge into marker-less target with pre-existing .claude content"
  init_target
  # Pre-existing project content: a custom agent (no template counterpart)
  # and a customized copy of a file the template also ships (name collision).
  mkdir -p "$TEST_DIR/.claude/agents/custom" "$TEST_DIR/.claude/commands"
  printf '# my custom agent\n' > "$TEST_DIR/.claude/agents/custom/mine.md"
  printf '# pre-existing customized deploy\n' > "$TEST_DIR/.claude/commands/deploy.md"
  local custom="$TEST_DIR/.claude/agents/custom/mine.md"
  local collision="$TEST_DIR/.claude/commands/deploy.md"
  local custom_before collision_before
  custom_before=$(sha256_of "$custom")
  collision_before=$(sha256_of "$collision")
  local out
  out=$(bash "$SKELETON_DIR/scripts/install.sh" \
          --source "$SKELETON_DIR" --target "$TEST_DIR" \
          --mode=merge --claude-only)
  # Missing template files added; both pre-existing files untouched; marker created.
  [ -f "$TEST_DIR/.claude/commands/commit.md" ] || { echo "ERROR: template file not added" >&2; exit 1; }
  assert_eq "$(sha256_of "$custom")" "$custom_before"
  assert_eq "$(sha256_of "$collision")" "$collision_before"
  [ -f "$TEST_DIR/.claude/.skeleton-version" ] || { echo "ERROR: marker not created" >&2; exit 1; }
  echo "PASS merge-add (collision skipped, custom preserved, template added, marker created)"
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
  verify_marker 75
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
if n != 75:
    sys.exit(f'ERROR: expected 71 raw_template_baselines after migration, got {n}')
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

scenario_watchdog_transcript_resolution() {
  echo ">> watchdog-transcript-resolution: encoded-dir + cwd-fallback both resolve; observations emitted (Phase 57)"
  # Regression guard for the silent-inert transcript-resolution defect:
  # encode_cwd must produce CC's encoding of the project dir, and the
  # fallback must find cwd on a non-first line. The CLONE is the project
  # dir under test, so OBS_DIR (derived from CLAUDE_PROJECT_DIR) stays
  # inside the sandbox and assertions read where the script writes.
  TEST_DIR=$(mktemp -d 2>/dev/null || mktemp -d -t claude-skel-ci-wd)
  git clone -q --depth 1 "file://$SKELETON_DIR" "$TEST_DIR/skel"
  (
    cd "$TEST_DIR/skel"
    clone_dir="$PWD"
    fx="$TEST_DIR/projects"
    # Mirror of task-watchdog.sh's encode_cwd — keep in sync.
    wd_encode() {
      local p="$1"
      case "$p" in
        /[A-Za-z]/*)
          local d="${p:1:1}"
          p="$(printf '%s' "$d" | tr '[:lower:]' '[:upper:]'):${p:2}"
          ;;
      esac
      printf '%s' "$p" | sed 's/[^A-Za-z0-9]/-/g'
    }
    enc=$(wd_encode "$clone_dir")
    # The transcript's cwd value must equal what the watchdog's python sees
    # in ITS argv. On Windows Git Bash, MSYS converts Unix-form argv paths
    # (/tmp/...) to Windows form (C:/Users/...) when invoking python.exe —
    # so generate the embedded cwd through the same argv channel. On
    # Linux/macOS this is the identity.
    # Execution-validated probe (Windows Store publishes python/python3
    # execution-alias stubs that pass `command -v` but exit nonzero).
    pybin=""
    for cand in python python3; do
      if command -v "$cand" >/dev/null 2>&1 && "$cand" -c 'pass' >/dev/null 2>&1; then
        pybin="$cand"; break
      fi
    done
    [ -n "$pybin" ] || { echo "SKIP watchdog-transcript-resolution (no working python)"; exit 0; }
    cwd_as_python_sees=$("$pybin" -c 'import sys; print(sys.argv[1])' "$clone_dir")

    write_transcripts() {
      mkdir -p "$1"
      # Second-newest transcript: 3x same-signature failures + one >5m bash.
      # First line deliberately carries NO cwd (matches real transcripts).
      # __CWD__ is substituted with the clone path (forward-slash, JSON-safe).
      cat > "$1/prior.jsonl.tmpl" <<'JSONL'
{"type":"summary","sessionId":"wd-prior","timestamp":"2026-07-01T00:00:00Z"}
{"type":"assistant","sessionId":"wd-prior","isSidechain":false,"cwd":"__CWD__","timestamp":"2026-07-01T00:01:00Z","message":{"content":[{"type":"tool_use","id":"t1","name":"Bash","input":{"command":"bash slow-build.sh"}}]}}
{"type":"user","sessionId":"wd-prior","isSidechain":false,"cwd":"__CWD__","timestamp":"2026-07-01T00:08:00Z","toolUseResult":{"durationMs":400000,"exitCode":0},"message":{"content":[{"type":"tool_result","tool_use_id":"t1","content":"done"}]}}
{"type":"assistant","sessionId":"wd-prior","isSidechain":false,"cwd":"__CWD__","timestamp":"2026-07-01T00:09:00Z","message":{"content":[{"type":"tool_use","id":"t2","name":"Bash","input":{"command":"pytest"}}]}}
{"type":"user","sessionId":"wd-prior","isSidechain":false,"cwd":"__CWD__","timestamp":"2026-07-01T00:09:30Z","toolUseResult":{"exitCode":1},"message":{"content":[{"type":"tool_result","tool_use_id":"t2","content":"assert failed: widget count mismatch","is_error":true}]}}
{"type":"assistant","sessionId":"wd-prior","isSidechain":false,"cwd":"__CWD__","timestamp":"2026-07-01T00:10:00Z","message":{"content":[{"type":"tool_use","id":"t3","name":"Bash","input":{"command":"pytest"}}]}}
{"type":"user","sessionId":"wd-prior","isSidechain":false,"cwd":"__CWD__","timestamp":"2026-07-01T00:10:30Z","toolUseResult":{"exitCode":1},"message":{"content":[{"type":"tool_result","tool_use_id":"t3","content":"assert failed: widget count mismatch","is_error":true}]}}
{"type":"assistant","sessionId":"wd-prior","isSidechain":false,"cwd":"__CWD__","timestamp":"2026-07-01T00:11:00Z","message":{"content":[{"type":"tool_use","id":"t4","name":"Bash","input":{"command":"pytest"}}]}}
{"type":"user","sessionId":"wd-prior","isSidechain":false,"cwd":"__CWD__","timestamp":"2026-07-01T00:11:30Z","toolUseResult":{"exitCode":1},"message":{"content":[{"type":"tool_result","tool_use_id":"t4","content":"assert failed: widget count mismatch","is_error":true}]}}
JSONL
      sed "s|__CWD__|$cwd_as_python_sees|g" "$1/prior.jsonl.tmpl" > "$1/prior.jsonl"
      rm -f "$1/prior.jsonl.tmpl"
      # Newest transcript: the just-started current session. Carries a cwd
      # event so the fallback sees TWO candidates and picks the second-newest.
      printf '{"type":"summary","sessionId":"wd-current","timestamp":"2026-07-02T00:00:00Z"}\n{"type":"user","sessionId":"wd-current","isSidechain":false,"cwd":"%s","timestamp":"2026-07-02T00:00:01Z","message":{"content":[]}}\n' "$cwd_as_python_sees" > "$1/current.jsonl"
      touch -t 202607010000 "$1/prior.jsonl"
      touch -t 202607020000 "$1/current.jsonl"
    }

    # Sub-case A: primary path — fixture dir named with CC's real encoding
    # of the clone path.
    write_transcripts "$fx/$enc"
    rm -f .claude/observations/.last-watchdog-session
    CLAUDE_PROJECT_DIR="$clone_dir" CLAUDE_PROJECTS_DIR_OVERRIDE="$fx" \
      bash .claude/scripts/task-watchdog.sh > /dev/null 2>&1
    found=$(grep -l '"source": "task-watchdog"' .claude/observations/*.json 2>/dev/null || true)
    if [ -z "$found" ] || [ ! -f .claude/observations/.last-watchdog-session ]; then
      echo "ERROR: primary-path (encoded dir) resolution emitted no observation/marker" >&2
      ls "$fx" >&2 2>/dev/null || true
      exit 1
    fi
    echo "  primary (encoded dir: $enc) OK"

    # Sub-case B: fallback path — dir name matches no encoding; cwd events
    # on non-first lines must resolve it.
    rm -f .claude/observations/*.json .claude/observations/.last-watchdog-session
    rm -rf "$fx"
    write_transcripts "$fx/renamed-beyond-recognition"
    CLAUDE_PROJECT_DIR="$clone_dir" CLAUDE_PROJECTS_DIR_OVERRIDE="$fx" \
      bash .claude/scripts/task-watchdog.sh > /dev/null 2>&1
    found=$(grep -l '"source": "task-watchdog"' .claude/observations/*.json 2>/dev/null || true)
    if [ -z "$found" ]; then
      echo "ERROR: cwd-fallback resolution emitted no observation" >&2
      exit 1
    fi
    echo "  fallback (cwd match) OK"
  )
  echo "PASS watchdog-transcript-resolution"
}

# Phase 67: producer fixes. (1) Resumed-session transcripts REPLAY the full
# prior history under a new sessionId (the Phase 66 lineage phenomenon) — the
# merge path must dedup by event identity or occurrences double and evidence
# arrives twice. (2) Bash failure signatures narrow by exit code + command
# head so heterogeneous one-offs stay in separate sub-threshold buckets.
scenario_watchdog_dedup_reobserve() {
  echo ">> watchdog-dedup-reobserve: replayed lineage merges without duplication; heterogeneous one-offs stay sub-threshold (Phase 67)"
  TEST_DIR=$(mktemp -d 2>/dev/null || mktemp -d -t claude-skel-ci-wdd)
  git clone -q --depth 1 "file://$SKELETON_DIR" "$TEST_DIR/skel"
  (
    cd "$TEST_DIR/skel"
    clone_dir="$PWD"
    fx="$TEST_DIR/projects"
    # Mirror of task-watchdog.sh's encode_cwd — keep in sync.
    wd_encode() {
      local p="$1"
      case "$p" in
        /[A-Za-z]/*)
          local d="${p:1:1}"
          p="$(printf '%s' "$d" | tr '[:lower:]' '[:upper:]'):${p:2}"
          ;;
      esac
      printf '%s' "$p" | sed 's/[^A-Za-z0-9]/-/g'
    }
    pybin=""
    for cand in python python3; do
      if command -v "$cand" >/dev/null 2>&1 && "$cand" -c 'pass' >/dev/null 2>&1; then
        pybin="$cand"; break
      fi
    done
    [ -n "$pybin" ] || { echo "SKIP watchdog-dedup-reobserve (no working python)"; exit 0; }
    cwd_as_python_sees=$("$pybin" -c 'import sys; print(sys.argv[1])' "$clone_dir")
    enc=$(wd_encode "$clone_dir")
    dir="$fx/$enc"; mkdir -p "$dir"

    # fail_pair <sid> <ts_use> <ts_result> <tool_id> <command> <error_content>
    fail_pair() {
      printf '{"type":"assistant","sessionId":"%s","isSidechain":false,"cwd":"%s","timestamp":"%s","message":{"content":[{"type":"tool_use","id":"%s","name":"Bash","input":{"command":"%s"}}]}}\n' "$1" "$cwd_as_python_sees" "$2" "$4" "$5"
      printf '{"type":"user","sessionId":"%s","isSidechain":false,"cwd":"%s","timestamp":"%s","toolUseResult":{"exitCode":1},"message":{"content":[{"type":"tool_result","tool_use_id":"%s","content":"%s","is_error":true}]}}\n' "$1" "$cwd_as_python_sees" "$3" "$4" "$6"
    }

    # Leg 1 — dedup. Prior session: 3 SAME-signature failures (same command,
    # same exit, same error line — a legitimate recurrence).
    {
      printf '{"type":"summary","sessionId":"wd67-a","timestamp":"2026-07-01T00:00:00Z"}\n'
      fail_pair wd67-a "2026-07-01T00:01:00Z" "2026-07-01T00:01:30Z" a1 "pytest" "assert failed: widget count mismatch"
      fail_pair wd67-a "2026-07-01T00:02:00Z" "2026-07-01T00:02:30Z" a2 "pytest" "assert failed: widget count mismatch"
      fail_pair wd67-a "2026-07-01T00:03:00Z" "2026-07-01T00:03:30Z" a3 "pytest" "assert failed: widget count mismatch"
    } > "$dir/one.jsonl"
    printf '{"type":"summary","sessionId":"wd67-b","timestamp":"2026-07-02T00:00:00Z"}\n{"type":"user","sessionId":"wd67-b","isSidechain":false,"cwd":"%s","timestamp":"2026-07-02T00:00:01Z","message":{"content":[]}}\n' "$cwd_as_python_sees" > "$dir/two.jsonl"
    touch -t 202607010000 "$dir/one.jsonl"
    touch -t 202607020000 "$dir/two.jsonl"
    rm -f .claude/observations/.last-watchdog-session
    CLAUDE_PROJECT_DIR="$clone_dir" CLAUDE_PROJECTS_DIR_OVERRIDE="$fx" \
      bash .claude/scripts/task-watchdog.sh > /dev/null 2>&1
    obs=$(grep -l '"pattern_type": "recurring_failure"' .claude/observations/*.json 2>/dev/null | head -n 1)
    [ -n "$obs" ] || { echo "ERROR: first observation not emitted" >&2; exit 1; }
    "$pybin" -c "
import json, sys
d = json.load(open(sys.argv[1]))
assert d['occurrences'] == 3, f\"first pass occ {d['occurrences']} != 3\"
assert len(d['evidence']) == 3, f\"first pass ev {len(d['evidence'])} != 3\"
print('  first pass: occ=3, ev=3 OK')
" "$obs"

    # The resume: a NEW sessionId whose transcript REPLAYS the same 3 events
    # (cumulative lineage), plus a fresh newest placeholder so the replayed
    # transcript is second-newest.
    {
      printf '{"type":"summary","sessionId":"wd67-c","timestamp":"2026-07-03T00:00:00Z"}\n'
      fail_pair wd67-c "2026-07-01T00:01:00Z" "2026-07-01T00:01:30Z" a1 "pytest" "assert failed: widget count mismatch"
      fail_pair wd67-c "2026-07-01T00:02:00Z" "2026-07-01T00:02:30Z" a2 "pytest" "assert failed: widget count mismatch"
      fail_pair wd67-c "2026-07-01T00:03:00Z" "2026-07-01T00:03:30Z" a3 "pytest" "assert failed: widget count mismatch"
    } > "$dir/three.jsonl"
    printf '{"type":"summary","sessionId":"wd67-d","timestamp":"2026-07-04T00:00:00Z"}\n{"type":"user","sessionId":"wd67-d","isSidechain":false,"cwd":"%s","timestamp":"2026-07-04T00:00:01Z","message":{"content":[]}}\n' "$cwd_as_python_sees" > "$dir/four.jsonl"
    touch -t 202607030000 "$dir/three.jsonl"
    touch -t 202607040000 "$dir/four.jsonl"
    CLAUDE_PROJECT_DIR="$clone_dir" CLAUDE_PROJECTS_DIR_OVERRIDE="$fx" \
      bash .claude/scripts/task-watchdog.sh > /dev/null 2>&1
    "$pybin" -c "
import json, sys
d = json.load(open(sys.argv[1]))
ts = [e['timestamp'] for e in d['evidence']]
assert d['occurrences'] == 3, f\"replay doubled occurrences: {d['occurrences']} != 3\"
assert len(ts) == len(set(ts)), f'replay duplicated evidence: {ts}'
print('  replayed lineage: occ stays 3, evidence unique OK')
" "$obs"

    # Leg 2 — heterogeneous one-offs: 3 DIFFERENT commands each failing once
    # with the generic exit-code content. Must NOT aggregate into one bucket.
    rm -f .claude/observations/*.json .claude/observations/.last-watchdog-session
    rm -rf "$fx"
    dir="$fx/$enc"; mkdir -p "$dir"
    {
      printf '{"type":"summary","sessionId":"wd67-e","timestamp":"2026-07-05T00:00:00Z"}\n'
      fail_pair wd67-e "2026-07-05T00:01:00Z" "2026-07-05T00:01:30Z" e1 "alpha --run" "Exit code 1"
      fail_pair wd67-e "2026-07-05T00:02:00Z" "2026-07-05T00:02:30Z" e2 "beta --run" "Exit code 1"
      fail_pair wd67-e "2026-07-05T00:03:00Z" "2026-07-05T00:03:30Z" e3 "gamma --run" "Exit code 1"
    } > "$dir/five.jsonl"
    printf '{"type":"summary","sessionId":"wd67-f","timestamp":"2026-07-06T00:00:00Z"}\n{"type":"user","sessionId":"wd67-f","isSidechain":false,"cwd":"%s","timestamp":"2026-07-06T00:00:01Z","message":{"content":[]}}\n' "$cwd_as_python_sees" > "$dir/six.jsonl"
    touch -t 202607050000 "$dir/five.jsonl"
    touch -t 202607060000 "$dir/six.jsonl"
    CLAUDE_PROJECT_DIR="$clone_dir" CLAUDE_PROJECTS_DIR_OVERRIDE="$fx" \
      bash .claude/scripts/task-watchdog.sh > /dev/null 2>&1
    if grep -l '"pattern_type": "recurring_failure"' .claude/observations/*.json >/dev/null 2>&1; then
      echo "ERROR: heterogeneous one-off failures aggregated into a false recurrence" >&2
      grep -l '"pattern_type": "recurring_failure"' .claude/observations/*.json >&2
      exit 1
    fi
    echo "  heterogeneous one-offs: separate sub-threshold buckets, no observation OK"
  )
  echo "PASS watchdog-dedup-reobserve"
}

scenario_match_rebaseline() {
  echo ">> match-rebaseline: stale-but-matching entry -> UNCHANGED + baseline caught up; converse stays LOCALLY_MODIFIED (Phase 59)"
  # Clone the skeleton as a MUTABLE source — the live repo is never mutated.
  TEST_DIR=$(mktemp -d 2>/dev/null || mktemp -d -t claude-skel-ci-rebase)
  local src="$TEST_DIR/src" target="$TEST_DIR/target"
  git clone -q --depth 1 "file://$SKELETON_DIR" "$src"
  mkdir -p "$target"
  ( cd "$target" && git init -q && git config user.email "ci@test.local" \
      && git config user.name "CI Test" && printf '# t\n' > README.md \
      && git add README.md && git commit -q -m init )
  bash "$src/scripts/install.sh" --source "$src" --target "$target" \
    --mode=fresh --claude-only > /dev/null 2>&1

  local relmatch=".claude/agents/01_research/research-helper.md"
  local relmod=".claude/agents/02_audit/audit-helper.md"
  local marker="$target/.claude/.skeleton-version"
  base_of() { python -c "import json,sys; print(json.load(open(sys.argv[1]))['raw_template_baselines'][sys.argv[2]])" "$1" "$2"; }
  local base_before
  base_before=$(base_of "$marker" "$relmatch")

  # Stale-but-matching: edit IDENTICALLY in source-template AND target
  # (baseline lags, current == current template).
  printf '\n<!-- rebase test -->\n' >> "$src/template/$relmatch"
  printf '\n<!-- rebase test -->\n' >> "$target/$relmatch"
  # Converse: modify ONLY the target copy (current != template).
  printf '\n<!-- local only -->\n' >> "$target/$relmod"

  # (c) dry-run reports both classes and writes nothing.
  local marker_pre out
  marker_pre=$(sha256_of "$marker")
  out=$(bash "$src/scripts/update.sh" --source "$src" --target "$target" --dry-run < /dev/null 2>&1)
  assert_contains "$out" "match-rebaseline:             1"
  assert_contains "$out" "locally modified files:       1"
  [ "$(sha256_of "$marker")" = "$marker_pre" ] || { echo "ERROR: dry-run mutated the marker" >&2; exit 1; }
  echo "  (c) dry-run reports both, marker untouched OK"

  # (a) real run, keep the LOCALLY_MODIFIED file -> match file re-baselined.
  printf 'k\n' | bash "$src/scripts/update.sh" --source "$src" --target "$target" \
    > "$TEST_DIR/out.txt" 2>&1 || true
  assert_contains "$(cat "$TEST_DIR/out.txt")" "match-rebaseline"
  local base_after cur_hash
  base_after=$(base_of "$marker" "$relmatch")
  cur_hash=$(sha256_of "$target/$relmatch")
  if [ "$base_after" != "$cur_hash" ] || [ "$base_after" = "$base_before" ]; then
    echo "ERROR: match file baseline not caught up (before=$base_before after=$base_after cur=$cur_hash)" >&2
    exit 1
  fi
  echo "  (a) match file re-baselined to current hash OK"

  # (b) converse: modified-only file still LOCALLY_MODIFIED, never re-baselined;
  #     the match class is now drained (nothing left to catch up).
  local out2
  out2=$(bash "$src/scripts/update.sh" --source "$src" --target "$target" --dry-run < /dev/null 2>&1)
  assert_contains "$out2" "locally modified files:       1"
  assert_contains "$out2" "$relmod"
  if printf '%s' "$out2" | grep -q "match-rebaseline"; then
    echo "ERROR: match-rebaseline class not drained after real run" >&2
    exit 1
  fi
  echo "  (b) modified-only stays LOCALLY_MODIFIED, match class drained OK"

  echo "PASS match-rebaseline"
}

# Phase 62: the rebase-ONLY path — all four action buckets empty — must still
# persist the marker. Pre-fix, the "everything up to date" early exit dropped
# RAW_BASELINE_REBASED, so the catch-up was computed, printed, and discarded.
scenario_rebase_only_persist() {
  echo ">> rebase-only-persist: stale-but-matching entry with NOTHING else pending -> baseline persisted through the early-exit path (Phase 62)"
  TEST_DIR=$(mktemp -d 2>/dev/null || mktemp -d -t claude-skel-ci-rebonly)
  local src="$TEST_DIR/src" target="$TEST_DIR/target"
  git clone -q --depth 1 "file://$SKELETON_DIR" "$src"
  mkdir -p "$target"
  ( cd "$target" && git init -q && git config user.email "ci@test.local" \
      && git config user.name "CI Test" && printf '# t\n' > README.md \
      && git add README.md && git commit -q -m init )
  bash "$src/scripts/install.sh" --source "$src" --target "$target" \
    --mode=fresh --claude-only > /dev/null 2>&1

  local rel=".claude/agents/01_research/research-helper.md"
  local marker="$target/.claude/.skeleton-version"
  base_of() { python -c "import json,sys; print(json.load(open(sys.argv[1]))['raw_template_baselines'][sys.argv[2]])" "$1" "$2"; }
  local base_before
  base_before=$(base_of "$marker" "$rel")

  # Stale-but-matching, and ONLY that: identical edit in source template and
  # target, no other divergence -> NEW/TEMPLATE_UPDATED/LOCALLY_MODIFIED/ORPHAN
  # all empty -> the run takes the "everything up to date" early exit.
  printf '\n<!-- rebase-only test -->\n' >> "$src/template/$rel"
  printf '\n<!-- rebase-only test -->\n' >> "$target/$rel"

  local out
  out=$(bash "$src/scripts/update.sh" --source "$src" --target "$target" < /dev/null 2>&1)
  assert_contains "$out" "everything up to date"
  assert_contains "$out" "match-rebaseline"

  local base_after cur_hash
  base_after=$(base_of "$marker" "$rel")
  cur_hash=$(sha256_of "$target/$rel")
  if [ "$base_after" != "$cur_hash" ] || [ "$base_after" = "$base_before" ]; then
    echo "ERROR: rebase-only run did not persist the baseline (before=$base_before after=$base_after cur=$cur_hash)" >&2
    exit 1
  fi
  echo "  baseline persisted through the early-exit path OK"

  # Second dry-run: the class must be drained — 0 pending.
  local out2
  out2=$(bash "$src/scripts/update.sh" --source "$src" --target "$target" --dry-run < /dev/null 2>&1)
  if printf '%s' "$out2" | grep -q "match-rebaseline"; then
    echo "ERROR: match-rebaseline still pending after rebase-only run — marker write was dropped" >&2
    exit 1
  fi
  echo "PASS rebase-only-persist"
}

# Phase 62: --check-remote must round-trip install identity verbatim. Pre-fix
# it passed 10 of 13 args to write_marker_json, silently deleting
# install_uuid/install_label/install_created; the next full update then minted
# a NEW uuid, orphaning shared-memory history keyed by the old one.
scenario_check_remote_identity() {
  echo ">> check-remote-identity: --check-remote preserves install_uuid/label/created byte-identical (Phase 62)"
  init_target
  bash "$SKELETON_DIR/scripts/install.sh" \
    --source "$SKELETON_DIR" --target "$TEST_DIR" \
    --mode=fresh --claude-only
  local marker="$TEST_DIR/.claude/.skeleton-version"
  id_fields() { python -c "
import json, sys
d = json.load(open(sys.argv[1]))
print(d.get('install_uuid'), d.get('install_label'), d.get('install_created'))
" "$1"; }
  local before
  before=$(id_fields "$marker")
  case "$before" in *None*) echo "ERROR: fresh install did not mint identity: $before" >&2; exit 1 ;; esac

  # Mock remote with a semver tag (same recipe as check-remote-cached).
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
    git tag v1.0.0
    git remote add origin "$mock_bare"
    git push -q origin HEAD --tags
  )
  SKELETON_REPO_URL="$mock_bare" bash "$SKELETON_DIR/scripts/update.sh" \
    --target "$TEST_DIR" --check-remote > "$TEST_DIR/check-remote.out" 2>&1

  local after
  after=$(id_fields "$marker")
  assert_eq "$after" "$before"
  # And the cache still refreshed (the call keeps doing its day job).
  python -c "
import json, sys
d = json.load(open(sys.argv[1]))
if d.get('cached_skeleton_head') != '1.0.0':
    sys.exit(f'ERROR: cached_skeleton_head not refreshed: {d.get(\"cached_skeleton_head\")!r}')
" "$marker"
  echo "PASS check-remote-identity (identity byte-identical)"
}

# Phase 63: the Phase 46 telemetry generator must produce schema-valid
# artifacts from a synthetic transcript via the cwd-match FALLBACK path —
# the transcript lives under a wrongly-encoded project dir, so the encoded
# lookup misses and resolution relies on the bounded multi-line cwd scan
# (the first line carries no cwd, matching real transcripts). Guards the
# Phase 63 fallback fixes: reachability, multi-line scan, normalized compare.
scenario_telemetry_generator_fixture() {
  echo ">> telemetry-generator-fixture: synthetic transcript -> events + rollup + observation via cwd fallback (Phase 63)"
  init_target
  bash "$SKELETON_DIR/scripts/install.sh" \
    --source "$SKELETON_DIR" --target "$TEST_DIR" \
    --mode=fresh --claude-only > /dev/null
  local pybin=""
  local cand
  for cand in python python3; do
    if command -v "$cand" >/dev/null 2>&1 && "$cand" -c 'pass' >/dev/null 2>&1; then
      pybin="$cand"; break
    fi
  done
  [ -n "$pybin" ] || { echo "SKIP telemetry-generator-fixture (no working python)"; return 0; }
  # Embedded cwd must equal what the generator's python sees in ITS argv
  # (MSYS converts Unix-form argv when invoking python.exe — same-channel
  # technique from the watchdog scenario).
  local cwd_as_python_sees
  cwd_as_python_sees=$("$pybin" -c 'import sys; print(sys.argv[1])' "$TEST_DIR")
  # WRONGLY-encoded dir name: the primary lookup must miss; the fallback
  # must match by cwd on a non-first line.
  local fx="$TEST_DIR/projects/not-the-encoded-name"
  mkdir -p "$fx"
  cat > "$fx/sess.jsonl.tmpl" <<'JSONL'
{"type":"summary","sessionId":"sess-tg-1","timestamp":"2026-07-01T00:00:00Z"}
{"type":"assistant","sessionId":"sess-tg-1","isSidechain":false,"cwd":"__CWD__","timestamp":"2026-07-01T00:01:00Z","message":{"usage":{"input_tokens":100,"output_tokens":40,"cache_read_input_tokens":10,"cache_creation_input_tokens":5},"content":[{"type":"tool_use","id":"t1","name":"Read","input":{"file_path":"docs/x.md"}}]}}
{"type":"assistant","sessionId":"sess-tg-1","isSidechain":false,"cwd":"__CWD__","timestamp":"2026-07-01T00:02:00Z","message":{"usage":{"input_tokens":60,"output_tokens":20,"cache_read_input_tokens":0,"cache_creation_input_tokens":0},"content":[{"type":"tool_use","id":"t2","name":"Bash","input":{"command":"ls"}}]}}
JSONL
  sed "s|__CWD__|$cwd_as_python_sees|g" "$fx/sess.jsonl.tmpl" > "$fx/sess.jsonl"
  rm -f "$fx/sess.jsonl.tmpl"

  CLAUDE_PROJECT_DIR="$TEST_DIR" CLAUDE_PROJECTS_DIR_OVERRIDE="$TEST_DIR/projects" \
  CLAUDE_HOOK_SESSION_ID= CLAUDE_HOOK_TRANSCRIPT_PATH= \
    bash "$TEST_DIR/.claude/lib/generate-session-telemetry.sh" > "$TEST_DIR/gen.out" 2>&1

  local ev="$TEST_DIR/.claude/telemetry/events/sess-tg-1.jsonl"
  local md="$TEST_DIR/.claude/telemetry/sessions/sess-tg-1.md"
  # Phase 65: the schema mandates <pattern_id>.json as the filename.
  local obs_pid obs
  obs_pid=$("$pybin" -c "import hashlib; print(hashlib.sha256(('token_telemetry\n' + 'sess-tg-1').encode()).hexdigest())")
  obs="$TEST_DIR/.claude/observations/$obs_pid.json"
  if [ ! -f "$ev" ]; then
    echo "ERROR: events JSONL missing — transcript resolution failed" >&2
    cat "$TEST_DIR/gen.out" >&2 2>/dev/null || true
    ls "$TEST_DIR/.claude/telemetry/events" >&2 2>/dev/null || true
    exit 1
  fi
  assert_eq "$(grep -c . "$ev")" "2"
  grep -q '"tool_name": "Read"' "$ev" || { echo "ERROR: Read tool line missing in events JSONL" >&2; exit 1; }
  assert_contains "$(cat "$md")" "total_tokens_in: 160"
  assert_contains "$(cat "$md")" "total_tokens_out: 60"
  assert_contains "$(cat "$md")" "data_available: true"
  [ -f "$obs" ] || { echo "ERROR: observation not at <pattern_id>.json (Phase 65 filename rule)" >&2; ls "$TEST_DIR/.claude/observations" >&2 2>/dev/null; exit 1; }
  "$pybin" -c "
import json, os, sys
d = json.load(open(sys.argv[1]))
required = ['pattern_id','source','pattern_type','occurrences','first_seen','last_seen','resolved_at','evidence','confidence','privacy_class']
missing = [k for k in required if k not in d]
if missing: sys.exit(f'ERROR: observation missing schema fields: {missing}')
if d['total_tokens_in'] != 160: sys.exit(f\"ERROR: total_tokens_in {d['total_tokens_in']} != 160\")
if d['pattern_type'] != 'token_telemetry': sys.exit('ERROR: wrong pattern_type')
# Phase 65 schema-conformance counts:
if os.path.basename(sys.argv[1]) != d['pattern_id'] + '.json': sys.exit('ERROR: filename != <pattern_id>.json')
if d['resolved_at'] is not None: sys.exit(f\"ERROR: resolved_at non-null at emission: {d['resolved_at']}\")
ev0 = d['evidence'][0]
if not ev0.get('summary') or len(ev0['summary']) > 120: sys.exit('ERROR: evidence summary missing or >120 chars')
if d['confidence'] != 'high': sys.exit(f\"ERROR: data-case confidence should be high, got {d['confidence']}\")
print('  observation schema fields + totals + Phase 65 conformance OK')
" "$obs"

  # Phase 65 stub leg: an empty projects dir must produce an HONEST stub —
  # confidence not 'high', resolved_at null, filename == pattern_id, summary present.
  local target2="$TEST_DIR/target2"
  mkdir -p "$target2/.claude" "$target2/projects-empty"
  CLAUDE_PROJECT_DIR="$target2" CLAUDE_PROJECTS_DIR_OVERRIDE="$target2/projects-empty" \
  CLAUDE_HOOK_SESSION_ID= CLAUDE_HOOK_TRANSCRIPT_PATH= \
    bash "$TEST_DIR/.claude/lib/generate-session-telemetry.sh" > "$TEST_DIR/gen2.out" 2>&1
  local stub
  stub=$(ls "$target2/.claude/observations/"*.json 2>/dev/null | head -n 1)
  [ -n "$stub" ] || { echo "ERROR: stub observation not written" >&2; cat "$TEST_DIR/gen2.out" >&2 2>/dev/null; exit 1; }
  "$pybin" -c "
import json, os, sys
d = json.load(open(sys.argv[1]))
if d['data_available'] is not False: sys.exit('ERROR: stub should carry data_available false')
if d['confidence'] == 'high': sys.exit('ERROR: no-data stub must not claim confidence high')
if d['resolved_at'] is not None: sys.exit('ERROR: stub resolved_at non-null at emission')
if os.path.basename(sys.argv[1]) != d['pattern_id'] + '.json': sys.exit('ERROR: stub filename != <pattern_id>.json')
if not d['evidence'][0].get('summary'): sys.exit('ERROR: stub evidence summary missing')
print('  stub emission honest (confidence, resolved_at, filename, summary) OK')
" "$stub"
  echo "PASS telemetry-generator-fixture"
}

# Phase 66: the SessionStart cost line's headline must be the PER-SITTING
# delta (latest rollup minus the prior checkpoint in the same lineage), not
# the newest lineage's cumulative total — and warn_usd_per_session compares
# the sitting delta. Pre-66, a resumed lineage printed its multi-day
# cumulative as "last session" and permanently tripped the warn once
# cumulative spend crossed the fixed value.
scenario_cost_line_sitting_delta() {
  echo ">> cost-line-sitting-delta: resumed lineage prints delta with no false trip; heavy single sitting still trips (Phase 66)"
  TEST_DIR=$(mktemp -d 2>/dev/null || mktemp -d -t claude-skel-ci-cost)
  local root="$TEST_DIR/proj"
  mkdir -p "$root/.claude/telemetry/sessions"
  # Fixture pricing: $1 per Mtok in/out, no cache multipliers -> USD == Mtok in.
  cat > "$root/.claude/telemetry/model-pricing.json" <<'JSON'
{"models": {"test-model": {"input_per_mtok": 1, "output_per_mtok": 1}}, "cache_read_multiplier": 0, "cache_write_multiplier_5m": 0}
JSON
  cat > "$root/.claude/gate-config.json" <<'JSON'
{"cost": {"enabled": true, "assumed_model": "test-model", "warn_usd_per_session": 5, "warn_usd_per_7d": 10000}}
JSON
  mk_rollup() { # <path> <started> <ended> <in_tokens>
    cat > "$1" <<EOF
---
session_id: $(basename "$1" .md)
started: $2
ended: $3
total_tokens_in: $4
total_tokens_out: 0
total_cache_creation: 0
total_cache_read: 0
turns_with_usage: 1
data_available: true
---
EOF
  }
  # One lineage, resumed: checkpoint 5M in (\$5), cumulative 8M (\$8). Sitting = \$3.
  mk_rollup "$root/.claude/telemetry/sessions/ckpt.md" "2026-07-01T00:00:00Z" "2026-07-10T00:00:00Z" 5000000
  mk_rollup "$root/.claude/telemetry/sessions/cum.md"  "2026-07-01T00:00:00Z" "2026-07-12T00:00:00Z" 8000000
  local out
  out=$(CLAUDE_PROJECT_DIR="$root" bash "$SKELETON_DIR/.claude/hooks/sessionstart-cost-summary.sh" 2>&1)
  assert_contains "$out" "last sitting ~\$3.00"
  assert_contains "$out" "lineage ~\$8.00 since 2026-07-01"
  if printf '%s' "$out" | grep -q '!!'; then
    echo "ERROR: resumed lineage falsely tripped the per-sitting threshold: $out" >&2
    exit 1
  fi
  echo "  leg 1: sitting-delta headline + lineage context + no false trip OK"
  # Converse leg: a genuinely heavy SINGLE sitting (9M in = \$9 > 5) must still trip.
  local root2="$TEST_DIR/proj2"
  mkdir -p "$root2/.claude/telemetry/sessions"
  cp "$root/.claude/telemetry/model-pricing.json" "$root2/.claude/telemetry/model-pricing.json"
  cp "$root/.claude/gate-config.json" "$root2/.claude/gate-config.json"
  mk_rollup "$root2/.claude/telemetry/sessions/big.md" "2026-07-12T00:00:00Z" "2026-07-12T02:00:00Z" 9000000
  local out2
  out2=$(CLAUDE_PROJECT_DIR="$root2" bash "$SKELETON_DIR/.claude/hooks/sessionstart-cost-summary.sh" 2>&1)
  assert_contains "$out2" "last sitting ~\$9.00"
  assert_contains "$out2" "sitting>5"
  echo "PASS cost-line-sitting-delta"
}

# Phase 74: the infrastructure-audit coordinator — per-audit session counters
# increment at SessionEnd (registry-driven from gate-config's audits block);
# the rules chain surfaces ONE due line when an enabled audit passes its
# sessions_between_dispatches cadence, 24h anti-repeat marker; under-cadence
# and marker-gated runs stay silent. The line surfaces; nothing auto-runs.
scenario_audit_cadence_nudge() {
  echo ">> audit-cadence-nudge: counter increments; past-cadence -> one line; under-cadence + cooldown -> silent (Phase 74)"
  TEST_DIR=$(mktemp -d 2>/dev/null || mktemp -d -t claude-skel-ci-audit)
  local root="$TEST_DIR/proj"
  mkdir -p "$root/.claude/telemetry"
  printf '{"compactPrompt": ""}\n' > "$root/.claude/settings.json"
  cat > "$root/.claude/gate-config.json" <<'JSON'
{"audits": {"artifact_fit_analyzer": {"enabled": true, "sessions_between_dispatches": 18}}}
JSON
  # Leg 0: the SessionEnd counter creates/increments the state entry.
  ( cd "$root" && CLAUDE_PROJECT_DIR="$root" bash "$SKELETON_DIR/.claude/hooks/sessionend-cost-proposals.sh" > /dev/null 2>&1 )
  python -c "
import json, sys
d = json.load(open(sys.argv[1]))
assert d['artifact_fit_analyzer']['sessions_since_dispatch'] == 1, d
print('  leg 0: SessionEnd counter created entry at 1 OK')
" "$root/.claude/telemetry/audit-state.json"
  # Leg 1: state past cadence -> exactly one due line + marker written.
  printf '{"artifact_fit_analyzer": {"sessions_since_dispatch": 20, "last_dispatched_at": null}}\n' > "$root/.claude/telemetry/audit-state.json"
  local out
  out=$(cd "$root" && bash "$SKELETON_DIR/.claude/hooks/sessionstart-rules.sh" 2>/dev/null || true)
  assert_contains "$out" "[infrastructure-audit] due: artifact_fit_analyzer (last dispatched 20 sessions ago)"
  [ -f "$root/.claude/.last-audit-nudge" ] || { echo "ERROR: anti-repeat marker not written" >&2; exit 1; }
  echo "  leg 1: past-cadence due line + marker OK"
  # Leg 2: under cadence -> silent.
  local root2="$TEST_DIR/proj2"
  mkdir -p "$root2/.claude/telemetry"
  printf '{"compactPrompt": ""}\n' > "$root2/.claude/settings.json"
  cp "$root/.claude/gate-config.json" "$root2/.claude/gate-config.json"
  printf '{"artifact_fit_analyzer": {"sessions_since_dispatch": 3, "last_dispatched_at": null}}\n' > "$root2/.claude/telemetry/audit-state.json"
  local out2
  out2=$(cd "$root2" && bash "$SKELETON_DIR/.claude/hooks/sessionstart-rules.sh" 2>/dev/null || true)
  if printf '%s' "$out2" | grep -q "infrastructure-audit"; then
    echo "ERROR: under-cadence audit surfaced: $out2" >&2; exit 1
  fi
  echo "  leg 2: under-cadence silent OK"
  # Leg 3: leg 1's root again — the 24h marker gates the repeat.
  local out3
  out3=$(cd "$root" && bash "$SKELETON_DIR/.claude/hooks/sessionstart-rules.sh" 2>/dev/null || true)
  if printf '%s' "$out3" | grep -q "infrastructure-audit"; then
    echo "ERROR: anti-repeat cooldown not honored: $out3" >&2; exit 1
  fi
  echo "  leg 3: cooldown silent OK"
  echo "PASS audit-cadence-nudge"
}

# Phase 68: the scheduled-goals surfacer prints exactly ONE ambient line for
# approved+due specs and NOTHING for drafts — a draft never surfaces as
# actionable (the approval gate is load-bearing) — and --hook honors the
# 24h cooldown marker.
scenario_goals_surface() {
  echo ">> goals-surface: approved+due -> one line; overdue-but-draft -> silent; --hook cooldown (Phase 68)"
  TEST_DIR=$(mktemp -d 2>/dev/null || mktemp -d -t claude-skel-ci-goals)
  local root="$TEST_DIR/proj"
  mkdir -p "$root/.claude/specs"
  mk_spec() { # <path> <status> <schedule> <id>
    cat > "$1" <<EOF
---
id: $4
status: $2
created: 2026-07-01T00:00:00Z
schedule: $3
goal: fixture goal for $4
---

## Research findings
- fixture
EOF
  }
  # Leg 1: approved + past date -> exactly one [goals] line naming the slug,
  # cooldown marker written.
  mk_spec "$root/.claude/specs/ship-widget.md" approved 2026-01-01 ship-widget
  local out
  out=$(CLAUDE_PROJECT_DIR="$root" bash "$SKELETON_DIR/.claude/scripts/goals-surface.sh" 2>&1)
  assert_contains "$out" "[goals] 1 scheduled goal(s) due"
  assert_contains "$out" "ship-widget"
  assert_eq "$(printf '%s\n' "$out" | grep -c .)" "1"
  [ -f "$root/.claude/.last-goals-surface" ] || { echo "ERROR: cooldown marker not written" >&2; exit 1; }
  echo "  leg 1: one line, slug named, marker written OK"
  # Leg 2: overdue but DRAFT -> silent.
  local root2="$TEST_DIR/proj2"
  mkdir -p "$root2/.claude/specs"
  mk_spec "$root2/.claude/specs/still-draft.md" draft 2026-01-01 still-draft
  local out2
  out2=$(CLAUDE_PROJECT_DIR="$root2" bash "$SKELETON_DIR/.claude/scripts/goals-surface.sh" 2>&1)
  if [ -n "$out2" ]; then
    echo "ERROR: draft spec surfaced as actionable: $out2" >&2
    exit 1
  fi
  echo "  leg 2: overdue draft stays silent OK"
  # Leg 3: --hook honors the cooldown leg 1 just wrote.
  out=$(CLAUDE_PROJECT_DIR="$root" bash "$SKELETON_DIR/.claude/scripts/goals-surface.sh" --hook 2>&1)
  if [ -n "$out" ]; then
    echo "ERROR: cooldown not honored under --hook: $out" >&2
    exit 1
  fi
  echo "  leg 3: --hook cooldown honored OK"
  echo "PASS goals-surface"
}

# Phase 63: python3-only guard. A failing `python` stub on PATH simulates
# the Windows Store execution alias (found by `command -v`, exits nonzero);
# a `python3` shim execs the real interpreter. A presence-only probe goes
# silent-inert here — the pre-63 generator wrote ZERO artifacts. The
# execution-validated probe must reject the stub, fall back to python3,
# and produce real telemetry through the PRIMARY encoded-dir lookup
# (which also exercises the portable ls -1t newest-first path).
scenario_telemetry_python3_only() {
  echo ">> telemetry-python3-only: failing python stub + real python3 -> probe falls back, artifacts written (Phase 63)"
  init_target
  bash "$SKELETON_DIR/scripts/install.sh" \
    --source "$SKELETON_DIR" --target "$TEST_DIR" \
    --mode=fresh --claude-only > /dev/null
  local realpy=""
  local cand
  for cand in python python3; do
    if command -v "$cand" >/dev/null 2>&1 && "$cand" -c 'pass' >/dev/null 2>&1; then
      realpy=$(command -v "$cand"); break
    fi
  done
  [ -n "$realpy" ] || { echo "SKIP telemetry-python3-only (no working python)"; return 0; }
  local shim="$TEST_DIR/shim-bin"
  mkdir -p "$shim"
  printf '#!/usr/bin/env bash\nexit 9\n' > "$shim/python"
  printf '#!/usr/bin/env bash\nexec "%s" "$@"\n' "$realpy" > "$shim/python3"
  chmod +x "$shim/python" "$shim/python3"
  # Mirror of the lib's encode_cwd — keep in sync (correctly-encoded dir:
  # this scenario exercises the primary lookup).
  te_encode() {
    local p="$1"
    case "$p" in
      /[A-Za-z]/*)
        local d="${p:1:1}"
        p="$(printf '%s' "$d" | tr '[:lower:]' '[:upper:]'):${p:2}"
        ;;
    esac
    printf '%s' "$p" | sed 's/[^A-Za-z0-9]/-/g'
  }
  local enc cwd_as_python_sees
  enc=$(te_encode "$TEST_DIR")
  cwd_as_python_sees=$("$realpy" -c 'import sys; print(sys.argv[1])' "$TEST_DIR")
  local fx="$TEST_DIR/projects/$enc"
  mkdir -p "$fx"
  cat > "$fx/sess.jsonl.tmpl" <<'JSONL'
{"type":"summary","sessionId":"sess-tp-1","timestamp":"2026-07-01T00:00:00Z"}
{"type":"assistant","sessionId":"sess-tp-1","isSidechain":false,"cwd":"__CWD__","timestamp":"2026-07-01T00:01:00Z","message":{"usage":{"input_tokens":100,"output_tokens":40,"cache_read_input_tokens":10,"cache_creation_input_tokens":5},"content":[{"type":"tool_use","id":"t1","name":"Read","input":{"file_path":"docs/x.md"}}]}}
JSONL
  sed "s|__CWD__|$cwd_as_python_sees|g" "$fx/sess.jsonl.tmpl" > "$fx/sess.jsonl"
  rm -f "$fx/sess.jsonl.tmpl"

  PATH="$shim:$PATH" \
  CLAUDE_PROJECT_DIR="$TEST_DIR" CLAUDE_PROJECTS_DIR_OVERRIDE="$TEST_DIR/projects" \
  CLAUDE_HOOK_SESSION_ID= CLAUDE_HOOK_TRANSCRIPT_PATH= \
    bash "$TEST_DIR/.claude/lib/generate-session-telemetry.sh" > "$TEST_DIR/gen.out" 2>&1

  local md="$TEST_DIR/.claude/telemetry/sessions/sess-tp-1.md"
  if [ ! -f "$md" ]; then
    echo "ERROR: no rollup written — probe went silent-inert under the failing python stub" >&2
    cat "$TEST_DIR/gen.out" >&2 2>/dev/null || true
    find "$TEST_DIR/.claude/telemetry" -type f >&2 2>/dev/null || true
    exit 1
  fi
  assert_contains "$(cat "$md")" "data_available: true"
  assert_contains "$(cat "$md")" "total_tokens_in: 100"
  echo "PASS telemetry-python3-only (probe rejected the stub, fell back to python3)"
}

# Phase 62 rework: replace-mode re-runs on installed targets are now refused
# (install.sh is first-install only). The YES-pipe overwrite coverage (Phase
# 30b H7) moves to replace mode's remaining surface: first install into a
# marker-less target that already carries a modified copy of a template file.
scenario_replace_with_yes_piped() {
  echo ">> replace-with-yes-piped: --mode=replace overwrites pre-existing marker-less content with YES piped"
  init_target
  local rel=".claude/agents/01_research/research-helper.md"
  local target_file="$TEST_DIR/$rel"
  mkdir -p "$(dirname "$target_file")"
  cp "$SKELETON_DIR/template/$rel" "$target_file"
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
  share-push-enabled)           scenario_share_push_enabled ;;
  share-push-failsoft)          scenario_share_push_failsoft ;;
  share-push-disabled)          scenario_share_push_disabled ;;
  share-push-manual)            scenario_share_push_manual ;;
  share-preview-enabled)        scenario_share_preview_enabled ;;
  share-preview-disabled)       scenario_share_preview_disabled ;;
  share-purge-remote)           scenario_share_purge_remote ;;
  share-purge-nothing)          scenario_share_purge_nothing ;;
  share-purge-confirm-eof)      scenario_share_purge_confirm_eof ;;
  share-disable-plain)          scenario_share_disable_plain ;;
  graduation-review-report)     scenario_graduation_review_report ;;
  graduation-review-disabled)   scenario_graduation_review_disabled ;;
  fresh-refuse)                 scenario_fresh_refuse ;;
  install-rerun-refuse)         scenario_install_rerun_refuse ;;
  merge-add)                    scenario_merge_add ;;
  local-mod-detect)             scenario_local_mod_detect ;;
  local-mod-preserve)           scenario_local_mod_preserve ;;
  backfill-migrate)             scenario_backfill_migrate ;;
  raw-baseline-migrate)         scenario_raw_baseline_migrate ;;
  check-remote-cached)              scenario_check_remote_cached ;;
  hook-fail-closed-bash-safety)     scenario_hook_fail_closed_bash_safety ;;
  cruft-check-fixture)              scenario_cruft_check_fixture ;;
  watchdog-transcript-resolution)   scenario_watchdog_transcript_resolution ;;
  watchdog-dedup-reobserve)         scenario_watchdog_dedup_reobserve ;;
  match-rebaseline)                 scenario_match_rebaseline ;;
  rebase-only-persist)              scenario_rebase_only_persist ;;
  check-remote-identity)            scenario_check_remote_identity ;;
  telemetry-generator-fixture)      scenario_telemetry_generator_fixture ;;
  telemetry-python3-only)           scenario_telemetry_python3_only ;;
  cost-line-sitting-delta)          scenario_cost_line_sitting_delta ;;
  goals-surface)                    scenario_goals_surface ;;
  audit-cadence-nudge)              scenario_audit_cadence_nudge ;;
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
    scenario_share_push_enabled
    scenario_share_push_failsoft
    scenario_share_push_disabled
    scenario_share_push_manual
    scenario_share_preview_enabled
    scenario_share_preview_disabled
    scenario_share_purge_remote
    scenario_share_purge_nothing
    scenario_share_purge_confirm_eof
    scenario_share_disable_plain
    scenario_graduation_review_report
    scenario_graduation_review_disabled
    scenario_fresh_refuse
    scenario_install_rerun_refuse
    scenario_merge_add
    scenario_local_mod_detect
    scenario_local_mod_preserve
    scenario_backfill_migrate
    scenario_raw_baseline_migrate
    scenario_check_remote_cached
    scenario_hook_fail_closed_bash_safety
    scenario_cruft_check_fixture
    scenario_watchdog_transcript_resolution
    scenario_watchdog_dedup_reobserve
    scenario_match_rebaseline
    scenario_rebase_only_persist
    scenario_check_remote_identity
    scenario_telemetry_generator_fixture
    scenario_telemetry_python3_only
    scenario_cost_line_sitting_delta
    scenario_goals_surface
    scenario_audit_cadence_nudge
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
  share-push-enabled           SessionEnd orchestrator clones, produces, pushes; files land; status reports (Phase 47c-1).
  share-push-failsoft          Unreachable remote → orchestrator exits 0; a later run catches up (Phase 47c-1).
  share-push-disabled          No share-config → orchestrator no-op, no clone created (Phase 47c-1).
  share-push-manual            /share-push pushes on-change; reports nothing-to-push when clean (Phase 47c-1).
  share-preview-enabled        --preview reports the would-include set; remote untouched (Phase 47c-2).
  share-preview-disabled       --preview with share off reports not-enabled, exits 0 (Phase 47c-2).
  share-purge-remote           --purge-remote removes this install's files; a 2nd install's stay; ends disabled (Phase 47c-2).
  share-purge-nothing          --purge-remote with nothing pushed → no-op, disables (Phase 47c-2).
  share-purge-confirm-eof      --purge-remote EOF confirmation fails closed; stays enabled (Phase 47c-2).
  share-disable-plain          Plain disable stops pushing, leaves remote data, no confirmation (Phase 47c-2).
  graduation-review-report     graduation-review groups captures/observations across installs vs the 15/75 threshold; telemetry excluded (Phase 47d).
  graduation-review-disabled   graduation-review with share off → nothing to review, exits 0 (Phase 47d).
  fresh-refuse                 Populated target → --mode=fresh exits non-zero; marker unchanged.
  install-rerun-refuse         Re-run on installed target refuses (redirect + escape hatch); update.sh re-adds (Phase 62).
  merge-add                    First --mode=merge into marker-less target: collision skipped, custom preserved, missing added.
  local-mod-detect             Modify a file → update.sh --dry-run reports LOCALLY_MODIFIED.
  local-mod-preserve           Modify a file → update.sh with [K]eep leaves it intact.
  backfill-migrate             Legacy shell marker → update.sh migrates to JSON.
  raw-baseline-migrate         Pre-Phase-52 marker → inline migration; tuner edit stays LOCALLY_MODIFIED (Phase 52).
  check-remote-cached          --check-remote against mock bare repo populates cached_skeleton_head (Phase 30b H5).
  hook-fail-closed-bash-safety Missing lib → PreToolUse hook emits deny JSON (Phase 30b H5).
  cruft-check-fixture          Broken markdown link → cruft-check.sh heuristic-i observation (Phase 30b H5).
  watchdog-transcript-resolution  Encoded-dir + cwd-fallback transcript resolution emits observations (Phase 57).
  watchdog-dedup-reobserve     Replayed lineage merges without x2 duplication; heterogeneous one-offs sub-threshold (Phase 67).
  match-rebaseline             Stale-but-matching baseline -> UNCHANGED + caught up; converse stays LOCALLY_MODIFIED (Phase 59).
  rebase-only-persist          Rebase-only run (all buckets empty) persists the marker through the early exit (Phase 62).
  check-remote-identity        --check-remote round-trips install_uuid/label/created byte-identical (Phase 62).
  telemetry-generator-fixture  Synthetic transcript -> events/rollup/observation via the cwd-match fallback (Phase 63).
  telemetry-python3-only       Failing python stub + real python3 -> execution-validated probe falls back (Phase 63).
  cost-line-sitting-delta      Cost headline = per-sitting delta; no false trip on resumed lineages (Phase 66).
  goals-surface                Approved+due spec -> one ambient line; drafts silent; --hook cooldown (Phase 68).
  audit-cadence-nudge          Session counters + past-cadence due line; under-cadence/cooldown silent (Phase 74).
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
