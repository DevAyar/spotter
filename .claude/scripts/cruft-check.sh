#!/usr/bin/env bash
# cruft-check: dogfood-only auditor of the skeleton repo's own docs/refs.
# Implements 9 heuristics (i, ii, iii, iv, v, vii, viii, ix, x; vi deferred)
# and emits observations to .claude/observations/ using the observation
# schema (session-observer.schema.md; 10 required fields). Third producer
# against that schema. Invoked by the
# SessionStart hook chain (with --hook + 24h cooldown) or manually
# (no flag, ignores cooldown). NEVER auto-fixes. NEVER hits the network.
# NEVER writes outside .claude/observations/ + .claude/.last-cruft-check.
# Always exits 0 so the hook chain never blocks.

set -uo pipefail

# ---- constants ----
COOLDOWN_HOURS=24
COOLDOWN_FILE=".claude/.last-cruft-check"
OBS_DIR=".claude/observations"
EVIDENCE_CAP=20
HOOK_FLAG=false

# ---- project-root anchor (Phase 116) ----
# Every path below is project-relative. settings.json invokes this by an
# absolute $CLAUDE_PROJECT_DIR path but sets no cwd, so from any other
# directory the scan found nothing and reported clean while `mkdir -p`
# planted a stray .claude/ tree where the caller happened to be standing.
# Anchoring as a chdir rather than a path prefix is deliberate and load
# bearing: each observation's pattern_id hashes a signature containing the
# file path, and the exemption sets match by relative prefix, so prefixing
# would change every id -- writing a duplicate corpus and mass-resolving
# the existing one -- and would un-exempt .git/ and the history-heavy docs.
ROOT="${CLAUDE_PROJECT_DIR:-$PWD}"
cd "$ROOT" || exit 0

# ---- args ----
for arg in "$@"; do
  case "$arg" in
    --hook) HOOK_FLAG=true ;;
    *) ;; # silently ignore unknown args; this is best-effort
  esac
done

# ---- helpers ----
now_epoch() { date -u +%s; }

check_cooldown() {
  [ "$HOOK_FLAG" = true ] || return 0
  [ -f "$COOLDOWN_FILE" ] || return 0
  local last now diff
  last=$(cat "$COOLDOWN_FILE" 2>/dev/null || echo 0)
  case "$last" in ''|*[!0-9]*) last=0 ;; esac
  now=$(now_epoch)
  diff=$((now - last))
  if [ "$diff" -lt $((COOLDOWN_HOURS * 3600)) ]; then
    exit 0
  fi
}

# ---- main ----
check_cooldown

# Phase 112: pre-112 this silently exit-0'd when no interpreter was
# usable, so a broken probe made the auditor APPEAR to pass a clean
# audit. It still exits 0 — this runs from the SessionStart chain and
# must never block a session — but it now says why on stderr instead of
# vanishing. Diagnosis-only change; the exit contract is unchanged.
# shellcheck source=../lib/detect-python.sh
. "$(cd "$(dirname "$0")/../lib" 2>/dev/null && pwd)/detect-python.sh"
if [ -z "$DETECTED_PYTHON" ]; then
  printf 'cruft-check: skipped — %s
' "$(python_required_message)" >&2
  exit 0
fi
mkdir -p "$OBS_DIR" 2>/dev/null || exit 0

"$DETECTED_PYTHON" - "$OBS_DIR" "$EVIDENCE_CAP" 2>/dev/null <<'PYIMPL'
import hashlib, json, os, re, subprocess, sys
from datetime import datetime, timezone
from glob import glob

obs_dir = sys.argv[1]
evidence_cap = int(sys.argv[2])

# Module-level set of pattern_ids emitted this run. Populated by emit() and
# consumed by resolve_untouched() to mark cruft-checker observations whose
# underlying pattern is no longer detected this scan.
emitted_ids = set()

def now_iso():
    return datetime.now(timezone.utc).strftime('%Y-%m-%dT%H:%M:%SZ')

def pattern_id(signature):
    h = hashlib.sha256()
    h.update(b'other\n')
    h.update(signature.encode('utf-8', errors='replace'))
    return h.hexdigest()

def emit(signature, notes, summary=None):
    summary = summary or notes
    if len(summary) > 120:
        summary = summary[:119] + '…'
    if len(notes) > 120:
        notes = notes[:119] + '…'
    pid = pattern_id(signature)
    emitted_ids.add(pid)
    path = os.path.join(obs_dir, pid + '.json')
    ts = now_iso()
    new_evidence = {'timestamp': ts, 'kind': 'doc_cruft', 'summary': summary}

    existing = None
    if os.path.exists(path):
        try:
            with open(path, encoding='utf-8') as f:
                existing = json.load(f)
        except Exception:
            existing = None

    if existing:
        occurrences = int(existing.get('occurrences', 0)) + 1
        first_seen = existing.get('first_seen', ts)
        prior = existing.get('evidence') or []
        evidence = (prior + [new_evidence])[-evidence_cap:]
        source = existing.get('source', 'cruft-checker')
        prior_notes = existing.get('notes', notes)
    else:
        occurrences = 1
        first_seen = ts
        evidence = [new_evidence]
        source = 'cruft-checker'
        prior_notes = notes

    # cruft-checker confidence override: med-floor because every cruft sighting is
    # deterministic-detected; schema default's `low` tier doesn't apply (per
    # session-observer.schema.md producer override clause + occurrences=1 carve-out).
    if occurrences >= 5:
        confidence = 'high'
    elif occurrences >= 3:
        confidence = 'med'
    else:
        confidence = 'med'  # cruft-checker baselines at med even at occurrences=1

    # Phase 46: cruft-checker observations are always local-only — they
    # carry doc names, file paths, and project structure that should never
    # leak cross-install. target_resource is optional/encouraged on other
    # types; deferred to a follow-up phase for cruft-checker (each heuristic
    # has its own target shape; mapping in emit() would be brittle).
    out = {
        'pattern_id': pid,
        'source': source,
        'pattern_type': 'other',
        'occurrences': occurrences,
        'first_seen': first_seen,
        'last_seen': ts,
        'resolved_at': None,
        'evidence': evidence,
        'confidence': confidence,
        'notes': prior_notes,
        'privacy_class': 'local-only',
    }
    tmp = path + f'.tmp.{os.getpid()}'
    with open(tmp, 'w', encoding='utf-8', newline='\n') as f:
        json.dump(out, f, indent=2, sort_keys=True)
        f.write('\n')
    os.replace(tmp, path)

def resolve_untouched():
    """For each existing cruft-checker observation whose pattern_id was NOT
    touched by this scan's emit() calls, set resolved_at to now if currently
    null. Already-resolved observations stay frozen at their original timestamp.
    Per the schema's Resolution lifecycle: cruft-checker runs a full resolve
    pass because every scan covers the entire skeleton repo."""
    ts = now_iso()
    for obs_path in glob(os.path.join(obs_dir, '*.json')):
        pid_from_name = os.path.basename(obs_path).replace('.json', '')
        if pid_from_name in emitted_ids:
            continue
        try:
            with open(obs_path, encoding='utf-8') as f:
                data = json.load(f)
        except Exception:
            continue
        if data.get('source') != 'cruft-checker':
            continue
        if data.get('resolved_at'):
            continue
        data['resolved_at'] = ts
        tmp = obs_path + f'.tmp.{os.getpid()}'
        with open(tmp, 'w', encoding='utf-8', newline='\n') as f:
            json.dump(data, f, indent=2, sort_keys=True)
            f.write('\n')
        os.replace(tmp, obs_path)

# ---- file discovery ----
EXCLUDE_DIRS = {'.git', '.claude/observations', '.claude/captures', '.claude/scripts/drafts', 'node_modules'}
# Gitignored runtime outputs are not doc surfaces — refreshed wholesale per
# dispatch, they carry data (e.g. plugin version strings) that heuristics
# misread as claims (Phase 86; the manifest:48 FP).
EXCLUDE_FILES = {'.claude/recommendations/manifest.md'}
def walk_md_files():
    for root, dirs, files in os.walk('.'):
        rel_root = os.path.relpath(root, '.').replace('\\', '/')
        if rel_root == '.': rel_root = ''
        # prune
        prune = []
        for d in dirs:
            sub = (rel_root + '/' + d if rel_root else d).replace('\\', '/')
            if sub in EXCLUDE_DIRS or any(sub.startswith(e + '/') or sub == e for e in EXCLUDE_DIRS):
                prune.append(d)
        for d in prune:
            dirs.remove(d)
        for f in files:
            if f.endswith('.md'):
                p = (rel_root + '/' + f if rel_root else f).replace('\\', '/')
                if p in EXCLUDE_FILES:
                    continue
                yield p

def read_file(path):
    try:
        with open(path, encoding='utf-8', errors='replace') as f:
            return f.read()
    except OSError:
        return None

def slugify(s):
    s = s.strip().lower()
    s = re.sub(r'[^\w\s-]', '', s)
    s = re.sub(r'\s+', '-', s)
    return s

def extract_headers(md_text):
    headers = set()
    for line in md_text.splitlines():
        m = re.match(r'^(#{1,6})\s+(.+?)\s*$', line)
        if m:
            headers.add(slugify(m.group(2)))
    return headers

LINK_RE = re.compile(r'\[([^\]]+)\]\(([^)\s]+)(?:\s+"[^"]*")?\)')
URL_SCHEMES = ('http://', 'https://', 'mailto:', 'tel:', 'ftp://', '#')

def strip_code(text):
    """Replace fenced + inline code regions with whitespace (preserving offsets so line numbers stay accurate)."""
    def blank(m):
        return ''.join('\n' if c == '\n' else ' ' for c in m.group(0))
    # Fenced ```...```
    text = re.sub(r'```.*?```', blank, text, flags=re.DOTALL)
    # Inline `...` (single-line)
    text = re.sub(r'`[^`\n]+`', blank, text)
    return text

# ---- VERSION + CHANGELOG parsing ----
version = None
v = read_file('VERSION')
if v:
    version = v.strip().split()[0] if v.strip() else None

changelog_text = read_file('docs/CHANGELOG.md') or ''
dated_headers = re.findall(r'^##\s*\[(\d+\.\d+\.\d+)\]\s*-', changelog_text, re.MULTILINE)
top_changelog_version = dated_headers[0] if dated_headers else None

# valid phase set
valid_phases = set()
for m in re.finditer(r'Phase\s+(\d+[a-z]*)\b', changelog_text):
    valid_phases.add(m.group(1))

# ---- Heuristic i + ii: markdown links ----
def check_links():
    for md_file in walk_md_files():
        text = read_file(md_file)
        if text is None: continue
        scanned = strip_code(text)
        for m in LINK_RE.finditer(scanned):
            target = m.group(2).strip()
            if not target or target.startswith(URL_SCHEMES):
                continue
            # split file vs anchor
            file_part, _, anchor = target.partition('#')
            if not file_part:
                continue  # anchor-only, skip
            # resolve relative to md_file's directory
            base = os.path.dirname(md_file)
            resolved = os.path.normpath(os.path.join(base, file_part)).replace('\\', '/')
            if not os.path.exists(resolved):
                line_no = text.count('\n', 0, m.start()) + 1
                sig = f'link-missing-file:{md_file}:{file_part}'
                notes = f'i: {md_file}:{line_no} → {file_part} (file missing)'
                emit(sig, notes)
                continue
            # heuristic ii: anchor check (only for .md targets)
            if anchor and resolved.endswith('.md'):
                target_text = read_file(resolved)
                if target_text is None:
                    continue
                headers = extract_headers(target_text)
                if slugify(anchor) not in headers:
                    line_no = text.count('\n', 0, m.start()) + 1
                    sig = f'link-missing-header:{md_file}:{resolved}#{anchor}'
                    notes = f'ii: {md_file}:{line_no} → {file_part}#{anchor} (header absent)'
                    emit(sig, notes)

check_links()

# ---- Heuristic iii: VERSION ↔ CHANGELOG ----
if version and top_changelog_version and version != top_changelog_version:
    sig = 'version-changelog-mismatch'
    notes = f'iii: VERSION={version} but top CHANGELOG header is [{top_changelog_version}]'
    emit(sig, notes)

# ---- Heuristic iv: README count claims ----
README_BULLET_RE = re.compile(
    r'(\d+)\s+agents.*?(\d+)\s+skills.*?(\d+)\s+scripts.*?(\d+)\s+slash commands.*?(\d+)\s+hooks',
    re.DOTALL,
)
def count_dir(pattern, exclude_suffix=None, only_dirs=False):
    count = 0
    for p in glob(pattern, recursive=True):
        if only_dirs and not os.path.isdir(p):
            continue
        if exclude_suffix and p.endswith(exclude_suffix):
            continue
        if not only_dirs and not os.path.isfile(p):
            continue
        count += 1
    return count

readme_text = read_file('README.md') or ''
m = README_BULLET_RE.search(readme_text)
if m:
    claimed = {
        'agents':   int(m.group(1)),
        'skills':   int(m.group(2)),
        'scripts':  int(m.group(3)),
        'commands': int(m.group(4)),
        'hooks':    int(m.group(5)),
    }
    # actuals in template/.claude/ (the baseline that ships)
    agents_all = glob('template/.claude/agents/**/*.md', recursive=True)
    actual_agents = sum(1 for p in agents_all if not p.endswith('.schema.md'))
    actual_skills = sum(
        1 for d in glob('template/.claude/skills/*')
        if os.path.isdir(d) and os.path.basename(d) != '.gitkeep'
    )
    scripts_all = glob('template/.claude/scripts/*.sh')
    actual_scripts = sum(1 for p in scripts_all if 'drafts' not in p.split(os.sep))
    actual_commands = len(glob('template/.claude/commands/*.md'))
    actual_hooks = len(glob('template/.claude/hooks/*.sh'))
    actual = {
        'agents':   actual_agents,
        'skills':   actual_skills,
        'scripts':  actual_scripts,
        'commands': actual_commands,
        'hooks':    actual_hooks,
    }
    for which in claimed:
        if claimed[which] != actual[which]:
            sig = f'readme-count:{which}'
            notes = f'iv: README claims {claimed[which]} {which}; template/.claude has {actual[which]}'
            emit(sig, notes)

# ---- Heuristic v: phase references ----
PHASE_RE = re.compile(r'\bPhase\s+(\d+[a-z]*)\b')
EXEMPT_PHASE_FILES = {
    'docs/CHANGELOG.md',
    'docs/SESSION_LOG.md',
    'docs/AUDIT-v1.1.4-state.md',    # Phase 29 state-dump references phases (incl. future Phase 30+) by design
    'docs/AUDIT-v1.1.4-cc-side.md',  # Phase 30 CC-side audit references audit-emergent phase queue (30b, 31-46+) by design
    'CLAUDE_MANAGER.md',             # Phase 33: directive layer references future phases (e.g. Phase 39 / v1.5-B) as forward-looking dispatch guidance
    'docs/PLUGIN-INSTALLS-v1.1.4.md',  # Phase 34 references future phases (34b, 35, 36) as evaluation/retire-candidate guidance
}

# Broaden valid_phases beyond CHANGELOG: include git commit messages.
# (The handoff-doc source retired with the file, Phase 80 — every phase it
# named appears in commit subjects, so coverage is preserved by this block.)
try:
    log_result = subprocess.run(
        ['git', 'log', '--all', '--pretty=%s'],
        capture_output=True, text=True, timeout=10,
    )
    if log_result.returncode == 0:
        for m in PHASE_RE.finditer(log_result.stdout):
            valid_phases.add(m.group(1))
except Exception:
    pass

def check_phase_refs():
    if not valid_phases:
        return
    for md_file in walk_md_files():
        if md_file in EXEMPT_PHASE_FILES:
            continue
        text = read_file(md_file)
        if text is None: continue
        scanned = strip_code(text)
        for m in PHASE_RE.finditer(scanned):
            phase = m.group(1)
            if phase in valid_phases:
                continue
            line_no = text.count('\n', 0, m.start()) + 1
            sig = f'phase-ref:{md_file}:Phase {phase}'
            notes = f'v: {md_file}:{line_no} references Phase {phase} (not in CHANGELOG / handoff / git history)'
            emit(sig, notes)

check_phase_refs()

# ---- Heuristic vii: schema field-count claims ----
# Fully exempt: history-heavy docs that legitimately reference past field counts.
# Mirrors heuristic x's EXEMPT_VFILES philosophy. CHANGELOG historical entries
# document schema field counts as they were at ship time — accurate-at-ship-time,
# not live cruft.
EXEMPT_SCHEMA_CLAIM_FILES = {'docs/CHANGELOG.md'}

def count_schema_fields(schema_path):
    text = read_file(schema_path)
    if text is None: return None
    in_fields_table = False
    fields = 0
    lines = text.splitlines()
    for i, line in enumerate(lines):
        if not in_fields_table:
            # find the header row of the fields table
            if re.match(r'^\|\s*Field\s*\|', line, re.IGNORECASE):
                # next line should be separator |---|---|
                if i + 1 < len(lines) and re.match(r'^\|\s*-+', lines[i+1]):
                    in_fields_table = True
            continue
        # we're in the table; skip separator
        if re.match(r'^\|\s*-+', line):
            continue
        if line.startswith('|'):
            # check this is a field row (has content beyond just |)
            cells = [c.strip() for c in line.strip().strip('|').split('|')]
            if cells and cells[0]:
                fields += 1
        else:
            # blank line or non-table; end of fields table
            break
    return fields if in_fields_table else None

SCHEMA_PATHS = sorted(glob('template/.claude/agents/05_meta/*.schema.md'))
schema_field_counts = {}
for sp in SCHEMA_PATHS:
    fc = count_schema_fields(sp)
    if fc:
        schema_name = os.path.basename(sp).replace('.schema.md', '')
        schema_field_counts[schema_name] = fc

def check_schema_claims():
    for md_file in walk_md_files():
        if md_file in EXEMPT_SCHEMA_CLAIM_FILES:
            continue
        text = read_file(md_file)
        if text is None: continue
        scanned = strip_code(text)
        # look for "<schema-name>... N-field" or "N field"
        for schema_name, actual_count in schema_field_counts.items():
            for m in re.finditer(re.escape(schema_name), scanned, re.IGNORECASE):
                window = scanned[m.end():m.end() + 200]
                fm = re.search(r'\b(\d+)[-\s]?field', window)
                if fm:
                    claimed = int(fm.group(1))
                    if claimed != actual_count:
                        line_no = text.count('\n', 0, m.start()) + 1
                        sig = f'schema-field-count:{schema_name}:{md_file}:{claimed}'
                        notes = f'vii: {md_file}:{line_no} claims {schema_name} is {claimed}-field; actual {actual_count}'
                        emit(sig, notes)

check_schema_claims()

# ---- Heuristic viii: hook entry config schema ----
# Validates settings.json hook entries against the canonical Anthropic hook
# schema (docs/HOOK_SCHEMA.md). Catches missing `type: "command"` and missing
# `command` field on inner hook objects — the Phase 14c-diag silent-inert
# failure mode. Skipped silently if a settings file is missing or
# unparseable (JSON syntax errors aren't this heuristic's responsibility).
def check_hook_entries():
    settings_paths = [
        '.claude/settings.json',
        'template/.claude/settings.json.template',
    ]
    for path in settings_paths:
        text = read_file(path)
        if text is None:
            continue
        try:
            data = json.loads(text)
        except (ValueError, json.JSONDecodeError):
            continue
        hooks_root = data.get('hooks') if isinstance(data, dict) else None
        if not isinstance(hooks_root, dict):
            continue
        for event_name, entries in hooks_root.items():
            if not isinstance(entries, list):
                continue
            for entry_idx, entry in enumerate(entries):
                if not isinstance(entry, dict):
                    continue
                inner_hooks = entry.get('hooks')
                if not isinstance(inner_hooks, list):
                    sig = f'hook-schema:{path}:{event_name}:{entry_idx}:no-hooks-array'
                    notes = f'viii: {path} hooks.{event_name}[{entry_idx}] missing "hooks" array'
                    emit(sig, notes)
                    continue
                for hook_idx, inner in enumerate(inner_hooks):
                    if not isinstance(inner, dict):
                        continue
                    type_val = inner.get('type')
                    if type_val != 'command':
                        sig = f'hook-schema:{path}:{event_name}:{entry_idx}:hooks[{hook_idx}]:type'
                        if type_val is None:
                            notes = f'viii: {path} hooks.{event_name}[{entry_idx}].hooks[{hook_idx}] missing "type" (expected "command")'
                        else:
                            notes = f'viii: {path} hooks.{event_name}[{entry_idx}].hooks[{hook_idx}] type="{type_val}" (expected "command")'
                        emit(sig, notes)
                    if not inner.get('command'):
                        sig = f'hook-schema:{path}:{event_name}:{entry_idx}:hooks[{hook_idx}]:command'
                        notes = f'viii: {path} hooks.{event_name}[{entry_idx}].hooks[{hook_idx}] missing "command" field'
                        emit(sig, notes)

check_hook_entries()

# ---- Heuristic ix: tag ↔ VERSION ↔ CHANGELOG at HEAD ----
try:
    result = subprocess.run(
        ['git', 'describe', '--exact-match', '--tags', 'HEAD'],
        capture_output=True, text=True, timeout=5,
    )
    if result.returncode == 0:
        tag = result.stdout.strip()
        tag_version = tag.lstrip('v')
        if version and tag_version != version:
            sig = 'tag-version-mismatch:tag-vs-version'
            notes = f'ix: HEAD tagged {tag} but VERSION={version}'
            emit(sig, notes)
        if top_changelog_version and tag_version != top_changelog_version:
            sig = 'tag-version-mismatch:tag-vs-changelog'
            notes = f'ix: HEAD tagged {tag} but top CHANGELOG header is [{top_changelog_version}]'
            emit(sig, notes)
except Exception:
    pass

# ---- Heuristic x: cross-doc stale version references ----
VERSION_RE = re.compile(r'\bv?(\d+)\.(\d+)\.(\d+)\b')
# Fully exempt: history-heavy docs that legitimately reference older versions throughout.
EXEMPT_VFILES = {
    'docs/CHANGELOG.md',
    'docs/SESSION_LOG.md',
    'docs/INSTALLATION.md',                 # historical migration paths (0.7.x→0.8.0 backfill, etc.)
    'docs/ARCHITECTURE.md',                 # historical version annotations on schema sections
    'docs/STORY.md',                        # narrative doc; legitimately references historical versions
    'CLAUDE_MANAGER.md',                    # directive layer; intentional v1.1.x-scope annotations on producers/consumers
    'template/.claude/captures/README.md',  # captures README anchors v1.1+ producers/consumers list
    'docs/AUDIT-v1.1.4-cc-side.md',         # Phase 30 CC-side audit; comprehensive review references all historical versions
    'docs/AUDIT-v1.1.4-marker-refresh-dryrun.md',  # Phase 32a dry-run inventory; references v0.4 fossil + multiple historical versions
    'docs/AUDIT-v1.1.4-state.md',            # Phase 29 frozen state-dump; versions throughout by design (Phase 86 — keeps the frozen record byte-untouched)
    'docs/PLUGIN-INSTALLS-v1.1.4.md',        # Phase 34 bundle-install record; references plugin versions (1.0.1, 5.1.0) + CC binary (2.1.138) + baseline 1.1.4
}
# Directory-prefix exemption: files under these dirs are full-exempt. Agent and schema
# docs anchor version annotations historically by design (e.g. "v1.1+ Phase N component").
EXEMPT_VDIRS = (
    '.claude/agents/05_meta/',
    'template/.claude/agents/05_meta/',
)
EXEMPT_VREGION_FILES = {'docs/ROADMAP.md'}
# Inline exemption marker: <!-- cruft-check:exempt-historical -->.
# - On its own line (no other content): exempts the IMMEDIATELY FOLLOWING line.
# - Same-line with other content: exempts THAT line.
# Markdown-comment style only; other comment styles deferred to a follow-up phase.
EXEMPT_MARKER_RE = re.compile(r'<!--\s*cruft-check:exempt-historical\s*-->')

def find_exempt_regions(md_text):
    """Return list of (start, end) char offsets covering sections under v-prefixed
    level-2 or level-3 headings (e.g. `## v1.1.0`, `### v1.0.0 — recap`).
    A heading at the same OR shallower level closes the region.
    """
    regions = []
    lines = md_text.splitlines(keepends=True)
    pos = 0
    region_start = None
    region_level = None  # depth of the heading that opened the region
    HEADING_RE = re.compile(r'^(#{1,6})\s+(.*)$')
    # Matches either:
    #   - `^v\d+\.\d+` — top-of-section version headings (e.g. `## v1.1.0`).
    #   - `^Phase \d+\w?\b.*\bv\d+\.\d+` — Phase-recap headings that
    #     legitimately reference older versions in their bodies
    #     (e.g. `### Phase 6 — ... v1.1.0 release cut`).
    # Phase headings WITHOUT a version reference are NOT matched.
    V_HEADING_RE = re.compile(r'^(v\d+\.\d+|Phase \d+[a-z]?\b.*\bv\d+\.\d+)', re.IGNORECASE)
    for line in lines:
        line_start = pos
        pos += len(line)
        hm = HEADING_RE.match(line)
        if not hm:
            continue
        level = len(hm.group(1))
        title = hm.group(2)
        if region_start is not None and level <= region_level:
            regions.append((region_start, line_start))
            region_start = None
            region_level = None
        if V_HEADING_RE.match(title) and level in (2, 3):
            region_start = line_start
            region_level = level
    if region_start is not None:
        regions.append((region_start, pos))
    return regions

def in_region(offset, regions):
    for s, e in regions:
        if s <= offset < e:
            return True
    return False

def find_exempt_lines(md_text):
    """1-indexed line numbers exempt from heuristic-x via inline markers.
    Marker on its own line: exempts the IMMEDIATELY FOLLOWING line.
    Marker inline with other content: exempts THAT line.
    """
    exempt = set()
    lines = md_text.splitlines()
    for i, line in enumerate(lines):
        if not EXEMPT_MARKER_RE.search(line):
            continue
        rest = EXEMPT_MARKER_RE.sub('', line).strip()
        if rest:
            exempt.add(i + 1)
        elif i + 1 < len(lines):
            exempt.add(i + 2)
    return exempt

def version_tuple(s):
    parts = s.split('.')
    return tuple(int(p) for p in parts)

current_v = version_tuple(version) if version else None

def check_version_refs():
    if current_v is None:
        return
    for md_file in walk_md_files():
        if md_file in EXEMPT_VFILES:
            continue
        if md_file.startswith(EXEMPT_VDIRS):
            continue
        text = read_file(md_file)
        if text is None: continue
        regions = []
        if md_file in EXEMPT_VREGION_FILES:
            regions = find_exempt_regions(text)
        exempt_lines = find_exempt_lines(text)
        scanned = strip_code(text)
        for m in VERSION_RE.finditer(scanned):
            matched_v = (int(m.group(1)), int(m.group(2)), int(m.group(3)))
            # Only flag refs strictly less than current VERSION
            if matched_v >= current_v:
                continue
            if in_region(m.start(), regions):
                continue
            line_no = text.count('\n', 0, m.start()) + 1
            if line_no in exempt_lines:
                continue
            matched_text = m.group(0)
            sig = f'version-ref:{md_file}:{line_no}:{matched_text}'
            notes = f'x: {md_file}:{line_no} stale version "{matched_text}" (VERSION={version})'
            emit(sig, notes)

check_version_refs()

# ---- resolution pass ----
resolve_untouched()

PYIMPL
PYIMPL_RC=$?

if [ "$PYIMPL_RC" -ne 0 ]; then
  # python helper failed; bail silent (cooldown not updated)
  exit 0
fi

# ---- cleanup: update cooldown marker ----
# Phase 121: temp beside the target, then rename. `>` truncates first, so an
# interrupt left a zero-byte marker; check_cooldown reads that as epoch 0 and
# rescans. Fails open exactly as before — this script must never block the
# SessionStart chain — but it no longer leaves a torn marker behind.
_cd_tmp="${COOLDOWN_FILE}.tmp.$$"
if now_epoch > "$_cd_tmp" 2>/dev/null; then
  mv -f "$_cd_tmp" "$COOLDOWN_FILE" 2>/dev/null || rm -f "$_cd_tmp" 2>/dev/null
else
  rm -f "$_cd_tmp" 2>/dev/null
fi
exit 0
