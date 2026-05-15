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

# ---- scenarios ----

scenario_fresh_install() {
  echo ">> fresh-install: clean target, --mode=fresh --claude-only"
  init_target
  bash "$SKELETON_DIR/scripts/install.sh" \
    --source "$SKELETON_DIR" --target "$TEST_DIR" \
    --mode=fresh --claude-only
  verify_marker 35
  echo "PASS fresh-install"
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
  verify_marker 35
  echo "PASS backfill-migrate"
}

# ---- dispatch ----
case "${1:-}" in
  fresh-install)       scenario_fresh_install ;;
  fresh-refuse)        scenario_fresh_refuse ;;
  merge-add)           scenario_merge_add ;;
  local-mod-detect)    scenario_local_mod_detect ;;
  local-mod-preserve)  scenario_local_mod_preserve ;;
  backfill-migrate)    scenario_backfill_migrate ;;
  all)
    scenario_fresh_install
    scenario_fresh_refuse
    scenario_merge_add
    scenario_local_mod_detect
    scenario_local_mod_preserve
    scenario_backfill_migrate
    echo "ALL SCENARIOS PASSED"
    ;;
  ""|-h|--help)
    cat <<EOF
Usage: bash scenarios.sh <scenario>

Scenarios:
  fresh-install       Clean target → install --mode=fresh; verify JSON marker.
  fresh-refuse        Populated target → --mode=fresh exits non-zero; marker unchanged.
  merge-add           Delete a file → --mode=merge re-adds only that file.
  local-mod-detect    Modify a file → update.sh --dry-run reports LOCALLY_MODIFIED.
  local-mod-preserve  Modify a file → update.sh with [K]eep leaves it intact.
  backfill-migrate    Legacy shell marker → update.sh migrates to JSON.
  all                 Run every scenario in sequence.
EOF
    [ -z "${1:-}" ] && exit 0 || exit 0
    ;;
  *)
    echo "unknown scenario: $1" >&2
    bash "$0" --help >&2
    exit 1
    ;;
esac
