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
  verify_marker 45
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
  verify_marker 45
  echo "PASS backfill-migrate"
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
  fresh-refuse)                 scenario_fresh_refuse ;;
  merge-add)                    scenario_merge_add ;;
  local-mod-detect)             scenario_local_mod_detect ;;
  local-mod-preserve)           scenario_local_mod_preserve ;;
  backfill-migrate)             scenario_backfill_migrate ;;
  check-remote-cached)              scenario_check_remote_cached ;;
  hook-fail-closed-bash-safety)     scenario_hook_fail_closed_bash_safety ;;
  cruft-check-fixture)              scenario_cruft_check_fixture ;;
  replace-with-yes-piped)           scenario_replace_with_yes_piped ;;
  hook-fp-exemption-git-commit-message) scenario_hook_fp_exemption_git_commit_message ;;
  all)
    scenario_fresh_install
    scenario_fresh_refuse
    scenario_merge_add
    scenario_local_mod_detect
    scenario_local_mod_preserve
    scenario_backfill_migrate
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
  fresh-refuse                 Populated target → --mode=fresh exits non-zero; marker unchanged.
  merge-add                    Delete a file → --mode=merge re-adds only that file.
  local-mod-detect             Modify a file → update.sh --dry-run reports LOCALLY_MODIFIED.
  local-mod-preserve           Modify a file → update.sh with [K]eep leaves it intact.
  backfill-migrate             Legacy shell marker → update.sh migrates to JSON.
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
