#!/usr/bin/env bash
# plugin-discovery: mechanical inventory of the local plugin ecosystem into
# the per-install recommendation manifest (.claude/recommendations/manifest.md,
# contract: .claude/recommendations/recommendation.schema.md). Phase 76.
#
# Reads marketplace clones under ~/.claude/plugins/marketplaces/ plus
# installed_plugins.json plus this project's context surfaces, and writes the
# manifest as a DRAFT: installed plugins enter as `installed` (never
# candidate), everything else as `candidate` with its marketplace.json entry
# as evidence. NO scoring, NO verdicts (recommended / not_recommended are
# Phase 77 matcher territory), NO network, NO install/enable actions —
# /plugin stays the only install path. Read-only toward everything except
# the manifest itself. The user-owned discipline_preferences block is
# preserved verbatim across refreshes.
#
# Dispatched tool, not a hook: real failure exits nonzero. An empty or
# absent marketplace tree is NOT a failure — it produces an honest stub
# manifest and exits 0.
#
# For testing: PLUGIN_MARKETPLACES_DIR_OVERRIDE and
# INSTALLED_PLUGINS_FILE_OVERRIDE point the scan at synthetic trees.

set -uo pipefail

# ---- constants ----
PROJECT_ROOT="${CLAUDE_PROJECT_DIR:-.}"
MARKETPLACES_DIR="${PLUGIN_MARKETPLACES_DIR_OVERRIDE:-$HOME/.claude/plugins/marketplaces}"
INSTALLED_FILE="${INSTALLED_PLUGINS_FILE_OVERRIDE:-$HOME/.claude/plugins/installed_plugins.json}"
OUT_DIR="$PROJECT_ROOT/.claude/recommendations"
OUT_FILE="$OUT_DIR/manifest.md"

# ---- helpers ----
# python||python3 validated by EXECUTION, not presence — the Windows Store
# alias stub passes `command -v` but exits nonzero (the Phase 57 silent-inert
# class; probe pattern per Phase 63).
PYBIN=""
for _cand in python python3; do
  if command -v "$_cand" >/dev/null 2>&1 && "$_cand" -c 'pass' >/dev/null 2>&1; then
    PYBIN="$_cand"
    break
  fi
done

# ---- main ----
if [ -z "$PYBIN" ]; then
  echo "plugin-discovery: no working python/python3 found" >&2
  exit 1
fi
mkdir -p "$OUT_DIR" || { echo "plugin-discovery: cannot create $OUT_DIR" >&2; exit 1; }

"$PYBIN" - "$MARKETPLACES_DIR" "$INSTALLED_FILE" "$PROJECT_ROOT" "$OUT_FILE" <<'PYIMPL'
import json, os, re, sys
from datetime import datetime, timezone

marketplaces_dir, installed_file, project_root, out_file = sys.argv[1:5]

SUMMARY_CAP = 160
STACK_PROBES = [
    'package.json', 'tsconfig.json', 'pyproject.toml', 'requirements.txt',
    'setup.py', 'go.mod', 'Cargo.toml', 'pubspec.yaml', 'project.godot',
    'Gemfile', 'pom.xml', 'build.gradle', 'build.gradle.kts',
    'composer.json', 'CMakeLists.txt', 'Makefile', 'Dockerfile',
    'docker-compose.yml', '.github/workflows', 'VERSION',
]

def now_iso():
    return datetime.now(timezone.utc).strftime('%Y-%m-%dT%H:%M:%SZ')

def load_json(path):
    try:
        with open(path, encoding='utf-8') as f:
            return json.load(f)
    except (OSError, ValueError):
        return None

# ---- prior manifest: preserve the user-owned discipline block verbatim ----
DEFAULT_DISCIPLINES = (
    "discipline_preferences: |\n"
    "  (user-owned: describe the disciplines plugins should respect here —\n"
    "  e.g. \"no network at session seams\", \"draft-only writers\".\n"
    "  Discovery preserves this block verbatim on every refresh.)\n"
)

def extract_disciplines(path):
    """Return the discipline_preferences block (key line + indented
    continuation lines) from an existing manifest's frontmatter, or None."""
    try:
        with open(path, encoding='utf-8') as f:
            lines = f.read().splitlines()
    except OSError:
        return None
    if not lines or lines[0].strip() != '---':
        return None
    block, capturing = [], False
    for line in lines[1:]:
        if line.strip() == '---':
            break
        if capturing:
            if line.startswith((' ', '\t')) or line.strip() == '':
                block.append(line)
                continue
            break
        if re.match(r'^discipline_preferences\s*:', line):
            capturing = True
            block.append(line)
    if not block:
        return None
    while block and block[-1].strip() == '':
        block.pop()
    return '\n'.join(block) + '\n'

disciplines = extract_disciplines(out_file) or DEFAULT_DISCIPLINES

# ---- project context (mechanical file-evidence only) ----
def probe_stack_markers(root):
    return [p for p in STACK_PROBES if os.path.exists(os.path.join(root, p))]

def count_glob(root, subdir, suffix, exclude_suffix=None, dirs_only=False, recursive=False):
    base = os.path.join(root, '.claude', subdir)
    if not os.path.isdir(base):
        return 0
    n = 0
    if dirs_only:
        return sum(1 for e in os.listdir(base)
                   if os.path.isdir(os.path.join(base, e)))
    if recursive:
        for dirpath, dirnames, filenames in os.walk(base):
            dirnames[:] = [d for d in dirnames if d != 'drafts']
            for f in filenames:
                if f.endswith(suffix) and not (exclude_suffix and f.endswith(exclude_suffix)):
                    n += 1
        return n
    return sum(1 for f in os.listdir(base)
               if os.path.isfile(os.path.join(base, f))
               and f.endswith(suffix)
               and not (exclude_suffix and f.endswith(exclude_suffix)))

def claude_inventory(root):
    gate = load_json(os.path.join(root, '.claude', 'gate-config.json')) or {}
    audits = gate.get('audits') if isinstance(gate.get('audits'), dict) else {}
    return {
        'agents': count_glob(root, 'agents', '.md', exclude_suffix='.schema.md', recursive=True),
        'scripts': count_glob(root, 'scripts', '.sh'),
        'hooks': count_glob(root, 'hooks', '.sh'),
        'skills': count_glob(root, 'skills', '', dirs_only=True),
        'commands': count_glob(root, 'commands', '.md'),
        'audits_registered': len(audits),
    }

def observation_profile(root):
    obs_dir = os.path.join(root, '.claude', 'observations')
    hist = {}
    if not os.path.isdir(obs_dir):
        return hist
    for f in sorted(os.listdir(obs_dir)):
        if not f.endswith('.json'):
            continue
        data = load_json(os.path.join(obs_dir, f))
        if isinstance(data, dict) and data.get('source'):
            src = str(data['source'])
            hist[src] = hist.get(src, 0) + 1
    return hist

# ---- plugin ecosystem surfaces ----
def installed_index(path):
    """installed_plugins.json -> {'<name>@<marketplace>': first-record-dict}"""
    data = load_json(path)
    plugins = data.get('plugins') if isinstance(data, dict) else None
    if not isinstance(plugins, dict):
        return {}
    idx = {}
    for key, records in plugins.items():
        rec = records[0] if isinstance(records, list) and records and isinstance(records[0], dict) else {}
        idx[key] = rec
    return idx

def enumerate_marketplaces(root):
    """-> list of (marketplace_name, marketplace_json_path, entries list)."""
    if not os.path.isdir(root):
        return []
    result = []
    for name in sorted(os.listdir(root)):
        mp_json = os.path.join(root, name, '.claude-plugin', 'marketplace.json')
        if not os.path.isfile(mp_json):
            continue
        data = load_json(mp_json)
        entries = data.get('plugins') if isinstance(data, dict) else None
        result.append((name, mp_json, entries if isinstance(entries, list) else []))
    return result

def known_but_uncloned(marketplaces_dir, cloned_names):
    """Names in known_marketplaces.json (sibling of the marketplaces dir)
    with no readable clone — reported honestly, never fetched."""
    reg = load_json(os.path.join(os.path.dirname(marketplaces_dir.rstrip('/\\')),
                                 'known_marketplaces.json'))
    if not isinstance(reg, dict):
        return []
    return sorted(k for k in reg if k not in cloned_names)

def entry_lines(entry, mp_name, mp_json, installed):
    """Render one plugin entry per the recommendation schema. Returns
    (lines, disposition) where disposition is 'installed' or 'candidate'."""
    name = entry.get('name') if isinstance(entry, dict) else None
    if not name:
        return None, None
    source = entry.get('source')
    if isinstance(source, str):
        source_class = 'repo_hosted'
    else:
        source_class = 'external_sha'
    key = f'{name}@{mp_name}'
    rec = installed.get(key)
    lines = [f'### {name}', '']
    if rec is not None:
        lines.append('- status: installed')
    else:
        lines.append('- status: candidate')
    lines.append(f'- source_class: {source_class}')
    if rec is not None:
        # version is OPTIONAL by design — record it only when the registry has it
        if rec.get('version'):
            lines.append(f'- version: {rec["version"]}')
        if rec.get('installedAt'):
            lines.append(f'- installed_at: {rec["installedAt"]}')
        if rec.get('scope'):
            lines.append(f'- install_scope: {rec["scope"]}')
    if entry.get('category'):
        lines.append(f'- category: {entry["category"]}')
    if rec is not None:
        lines.append(f'- evidence: installed_plugins.json :: {key}')
    else:
        lines.append(f'- evidence: {mp_json} :: {name}')
    if source_class == 'repo_hosted':
        lines.append(f'- source_path: {source}')
    else:
        src = source if isinstance(source, dict) else {}
        url = src.get('url') or src.get('repo') or '(unrecorded)'
        sha = src.get('sha') or src.get('commit') or '(unrecorded)'
        lines.append(f'- source_url: {url}')
        lines.append(f'- pinned_sha: {sha}')
        lines.append('- source_not_inspected_offline: true')
    desc = entry.get('description')
    if isinstance(desc, str) and desc.strip():
        d = ' '.join(desc.split())
        if len(d) > SUMMARY_CAP:
            d = d[:SUMMARY_CAP - 1] + '…'
        lines.append(f'- summary: {d}')
    lines.append('')
    return lines, ('installed' if rec is not None else 'candidate')

# ---- build the manifest ----
installed = installed_index(installed_file)
marketplaces = enumerate_marketplaces(marketplaces_dir)
uncloned = known_but_uncloned(marketplaces_dir, {m[0] for m in marketplaces})

body = []
n_indexed = n_candidates = n_installed = 0
seen_installed_keys = set()

for mp_name, mp_json, entries in marketplaces:
    body.append(f'## {mp_name} ({len(entries)} plugins)')
    body.append('')
    for entry in entries:
        lines, disposition = entry_lines(entry, mp_name, mp_json, installed)
        if lines is None:
            continue
        n_indexed += 1
        if disposition == 'installed':
            n_installed += 1
            name = entry.get('name')
            seen_installed_keys.add(f'{name}@{mp_name}')
        else:
            n_candidates += 1
        body.extend(lines)

# installed-but-unindexed: installed state comes from the registry, not the index
orphans = sorted(k for k in installed if k not in seen_installed_keys)
if orphans:
    body.append('## installed (unindexed)')
    body.append('')
    for key in orphans:
        rec = installed[key]
        n_indexed += 1
        n_installed += 1
        body.append(f'### {key.split("@", 1)[0]}')
        body.append('')
        body.append('- status: installed')
        body.append('- source_class: unindexed')
        if rec.get('version'):
            body.append(f'- version: {rec["version"]}')
        if rec.get('installedAt'):
            body.append(f'- installed_at: {rec["installedAt"]}')
        if rec.get('scope'):
            body.append(f'- install_scope: {rec["scope"]}')
        body.append(f'- evidence: installed_plugins.json :: {key}')
        body.append('- source_not_inspected_offline: true')
        body.append('')

notes = []
if not marketplaces:
    notes.append(f'- no readable marketplace clones under `{marketplaces_dir}` — '
                 'empty machine or missing tree; nothing to index (not an error).')
for name in uncloned:
    notes.append(f'- marketplace `{name}` is registered in known_marketplaces.json '
                 'but has no readable clone — not indexed, never fetched.')

fm = []
fm.append('---')
fm.append('status: draft')
fm.append(f'generated: {now_iso()}')
fm.append('generator: plugin-discovery.sh (Phase 76)')
fm.append(f'marketplaces_scanned: {len(marketplaces)}')
fm.append(f'plugins_indexed: {n_indexed}')
fm.append(f'candidates: {n_candidates}')
fm.append(f'installed: {n_installed}')
markers = probe_stack_markers(project_root)
if markers:
    fm.append('stack_markers:')
    fm.extend(f'  - {m}' for m in markers)
else:
    fm.append('stack_markers: []')
inv = claude_inventory(project_root)
fm.append('claude_inventory:')
fm.extend(f'  {k}: {v}' for k, v in inv.items())
hist = observation_profile(project_root)
if hist:
    fm.append('observation_profile:')
    fm.extend(f'  {k}: {v}' for k, v in sorted(hist.items()))
else:
    fm.append('observation_profile: {}')
fm.append(disciplines.rstrip('\n'))
fm.append('---')
fm.append('')

head = [
    '# plugin recommendation manifest',
    '',
    'Draft inventory per `.claude/recommendations/recommendation.schema.md`.',
    'Discovery emits only `candidate` and `installed` — verdicts belong to the',
    'matcher (Phase 77) and require a reason, both directions. `/plugin` is the',
    'only install path; nothing here installs, enables, or fetches anything.',
    '',
]
if notes:
    head.append('## scan notes')
    head.append('')
    head.extend(notes)
    head.append('')

content = '\n'.join(fm + head + body).rstrip('\n') + '\n'
tmp = out_file + f'.tmp.{os.getpid()}'
with open(tmp, 'w', encoding='utf-8', newline='\n') as f:
    f.write(content)
os.replace(tmp, out_file)
print(f'plugin-discovery: manifest refreshed -- {n_indexed} indexed '
      f'({n_candidates} candidate, {n_installed} installed) '
      f'across {len(marketplaces)} marketplace(s) -> {out_file}')
PYIMPL
PY_RC=$?

# ---- cleanup ----
if [ "$PY_RC" -ne 0 ]; then
  echo "plugin-discovery: manifest generation failed (python rc=$PY_RC)" >&2
  exit 1
fi
exit 0
