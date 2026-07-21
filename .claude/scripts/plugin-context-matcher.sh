#!/usr/bin/env bash
# plugin-context-matcher: the verdict layer over the Phase 76 recommendation
# manifest (Phase 77). Reads the DRAFT manifest plus the same closed surfaces
# discovery reads (marketplace clones, installed registry, project context)
# and updates candidate entries in place where MECHANICAL evidence permits:
#
#   recommended      needs >=1 positive class: STACK-MARKER match (cited to
#                    the detected file), CAPABILITY-GAP (an unresolved
#                    observation the candidate's category addresses), or
#                    COMPOSITION-PRECEDENT (same author as an installed,
#                    clean-auditing plugin).
#   not_recommended  needs >=1 of exactly three classes: SURFACE-CONFLICT
#                    (command/agent name collision vs the skeleton's .claude/
#                    or an installed plugin, cited file-to-file),
#                    STACK-MISMATCH (candidate targets a stack the detected
#                    markers contradict, cited both sides), or
#                    CANDIDATE-AUDIT-FAIL (plugin-quality-check
#                    --candidate-plugin findings on the pre-install source).
#   candidate        everything else — the honest middle is the default,
#                    not a failure. No editorial rejections, no ranks, no
#                    scores (a ranked list is a directory in disguise).
#
# Repo-hosted candidates get the pre-install audit; external-sha candidates
# are metadata-eligible only and are marked candidate_audit: deferred —
# never guessed, never fetched. The manifest stays status: draft — the
# user's review is the approval gate; NOTHING here installs, enables, or
# fetches anything. /plugin remains the only install path.
#
# Dispatched tool, not a hook: real failure exits nonzero. Missing manifest
# -> exit 1 with a pointer at plugin-discovery.sh (discovery runs first).
#
# For testing: PLUGIN_MARKETPLACES_DIR_OVERRIDE, INSTALLED_PLUGINS_FILE_OVERRIDE,
# PLUGIN_CACHE_DIR_OVERRIDE point the scan at synthetic trees.

set -uo pipefail

# ---- constants ----
PROJECT_ROOT="${CLAUDE_PROJECT_DIR:-.}"
MARKETPLACES_DIR="${PLUGIN_MARKETPLACES_DIR_OVERRIDE:-$HOME/.claude/plugins/marketplaces}"
INSTALLED_FILE="${INSTALLED_PLUGINS_FILE_OVERRIDE:-$HOME/.claude/plugins/installed_plugins.json}"
CACHE_DIR="${PLUGIN_CACHE_DIR_OVERRIDE:-$HOME/.claude/plugins/cache}"
MANIFEST="$PROJECT_ROOT/.claude/recommendations/manifest.md"
SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd -P)
QUALITY_CHECK="$SCRIPT_DIR/plugin-quality-check.sh"

# ---- helpers ----
# python||python3 validated by EXECUTION, not presence (Phase 57/63 class).
PYBIN=""
for _cand in python python3; do
  if command -v "$_cand" >/dev/null 2>&1 && "$_cand" -c 'pass' >/dev/null 2>&1; then
    PYBIN="$_cand"
    break
  fi
done

# ---- main ----
if [ -z "$PYBIN" ]; then
  echo "plugin-context-matcher: no working python/python3 found" >&2
  exit 1
fi
if [ ! -f "$MANIFEST" ]; then
  echo "plugin-context-matcher: no manifest at $MANIFEST — run plugin-discovery.sh first" >&2
  exit 1
fi

"$PYBIN" - "$MANIFEST" "$MARKETPLACES_DIR" "$INSTALLED_FILE" "$CACHE_DIR" "$PROJECT_ROOT" "$QUALITY_CHECK" <<'PYIMPL'
import json, os, re, subprocess, sys

manifest_path, marketplaces_dir, installed_file, cache_dir, project_root, quality_check = sys.argv[1:7]

# ---- evidence maps (closed lists — the classes are the contract) ----
# stack marker file -> keywords whose presence in a candidate's
# name/category/description constitutes a STACK-MARKER match.
MARKER_KEYWORDS = {
    'package.json':      ['node', 'npm', 'javascript', 'typescript', 'react', 'eslint', 'frontend', 'vue', 'svelte'],
    'tsconfig.json':     ['typescript'],
    'pyproject.toml':    ['python', 'pip', 'django', 'flask', 'pytest'],
    'requirements.txt':  ['python', 'pip'],
    'setup.py':          ['python'],
    'go.mod':            ['golang', ' go '],
    'Cargo.toml':        ['rust', 'cargo'],
    'pubspec.yaml':      ['flutter', 'dart'],
    'project.godot':     ['godot', 'gdscript'],
    'Gemfile':           ['ruby', 'rails'],
    'pom.xml':           ['java', 'maven'],
    'build.gradle':      ['java', 'gradle', 'android'],
    'build.gradle.kts':  ['kotlin', 'gradle', 'android'],
    'composer.json':     ['php', 'laravel', 'composer'],
    'CMakeLists.txt':    ['cmake', 'c++'],
    'Dockerfile':        ['docker', 'container'],
    'docker-compose.yml': ['docker', 'container'],
    '.github/workflows': ['github actions', 'ci/cd'],
}
# exclusive-stack keyword -> the marker files that would justify it.
# STACK-MISMATCH fires only when the candidate names stack S, the project
# has NO marker for S, and the project DOES have a marker for a different
# exclusive stack — a contradiction cited on both sides.
EXCLUSIVE_STACKS = {
    'unity':     [],  # no marker in the probe list can justify unity
    'unreal':    [],
    'flutter':   ['pubspec.yaml'],
    'godot':     ['project.godot'],
    'django':    ['pyproject.toml', 'requirements.txt', 'setup.py'],
    'rails':     ['Gemfile'],
    'laravel':   ['composer.json'],
    'wordpress': ['composer.json'],
    'android':   ['build.gradle', 'build.gradle.kts'],
    'xcode':     [],
    'swiftui':   [],
}
# Markers that positively indicate SOME exclusive stack (used as the
# "project is already committed elsewhere" side of a mismatch).
STACK_MARKERS = {'package.json', 'pyproject.toml', 'requirements.txt', 'setup.py',
                 'go.mod', 'Cargo.toml', 'pubspec.yaml', 'project.godot',
                 'Gemfile', 'pom.xml', 'build.gradle', 'build.gradle.kts',
                 'composer.json'}
# Platform-scoped markers (Phase 78): a marker here declares a HOST platform.
# Its keywords may serve as STACK-MARKER evidence only for platform-agreeing
# or platform-neutral candidates — a candidate declaring ONLY a rival
# platform against a detected host marker (with zero corroborating rival
# marker) is a STACK-MISMATCH, cited both sides. Born from Phase 77's first
# live profile, which recommended a gitlab-targeting plugin on a
# GitHub-hosted repo via the coarse 'ci/cd' mapping.
PLATFORM_MARKERS = {
    '.github/workflows': 'github',
    '.gitlab-ci.yml': 'gitlab',
    'bitbucket-pipelines.yml': 'bitbucket',
    'azure-pipelines.yml': 'azure-devops',
}
PLATFORM_KEYWORDS = {
    'github': ['github'],
    'gitlab': ['gitlab'],
    'bitbucket': ['bitbucket'],
    'azure-devops': ['azure devops', 'azure-devops', 'azure pipelines'],
}
# CAPABILITY-GAP: narrow by design — an UNRESOLVED observation of this
# pattern_type is addressed by candidates in these categories.
GAP_CATEGORIES = {
    'recurring_failure': {'debugging', 'testing'},
}

def load_json(path):
    try:
        with open(path, encoding='utf-8') as f:
            return json.load(f)
    except (OSError, ValueError):
        return None

def fs(p):
    """Citation paths are forward-slash, never backslash (Phase 56 rule)."""
    return str(p).replace('\\', '/')

def word_hit(keyword, text):
    if keyword.startswith(' ') or keyword.endswith(' '):
        return keyword in ' ' + text + ' '
    return re.search(r'(?<![a-z0-9])' + re.escape(keyword) + r'(?![a-z0-9])', text) is not None

# ---- manifest parse (line-preserving) ----
with open(manifest_path, encoding='utf-8') as f:
    lines = f.read().splitlines()

# frontmatter bounds
assert lines and lines[0].strip() == '---', 'manifest missing frontmatter'
fm_end = next(i for i in range(1, len(lines)) if lines[i].strip() == '---')

stack_markers = []
in_sm = False
for ln in lines[1:fm_end]:
    if re.match(r'^stack_markers\s*:', ln):
        in_sm = '[]' not in ln
        continue
    if in_sm:
        m = re.match(r'^\s+-\s+(.*)$', ln)
        if m:
            stack_markers.append(m.group(1).strip())
            continue
        in_sm = False
markers = set(stack_markers)

# body blocks: (start, end) per '### name', plus the marketplace each sits in
blocks = []
current_mp = None
i = fm_end + 1
while i < len(lines):
    ln = lines[i]
    m = re.match(r'^## (\S+) \(', ln)
    if m:
        current_mp = m.group(1)
    m = re.match(r'^### (.+)$', ln)
    if m:
        start = i
        j = i + 1
        while j < len(lines) and not lines[j].startswith('### ') and not lines[j].startswith('## '):
            j += 1
        blocks.append({'name': m.group(1).strip(), 'mp': current_mp, 'start': start, 'end': j})
        i = j
        continue
    i += 1

def field(block, key):
    for k in range(block['start'], block['end']):
        m = re.match(r'^- ' + re.escape(key) + r':\s*(.*)$', lines[k])
        if m:
            return m.group(1).strip()
    return None

# ---- context surfaces ----
def md_basenames(path):
    if not os.path.isdir(path):
        return set()
    return {f for f in os.listdir(path) if f.endswith('.md') and not f.endswith('.schema.md')}

skeleton_commands = md_basenames(os.path.join(project_root, '.claude', 'commands'))
skeleton_agents = set()
agents_root = os.path.join(project_root, '.claude', 'agents')
if os.path.isdir(agents_root):
    for dirpath, _dirs, files in os.walk(agents_root):
        skeleton_agents |= {f for f in files if f.endswith('.md') and not f.endswith('.schema.md')}

installed_reg = load_json(installed_file) or {}
installed_keys = set((installed_reg.get('plugins') or {}).keys()) if isinstance(installed_reg, dict) else set()
installed_names = {k.split('@', 1)[0] for k in installed_keys}

# installed plugins' cache surfaces: name -> {kind: {basenames}} + path
installed_surfaces = {}
if os.path.isdir(cache_dir):
    for mp in sorted(os.listdir(cache_dir)):
        mp_path = os.path.join(cache_dir, mp)
        if not os.path.isdir(mp_path):
            continue
        for plugin in sorted(os.listdir(mp_path)):
            p_path = os.path.join(mp_path, plugin)
            if not os.path.isdir(p_path):
                continue
            for version in sorted(os.listdir(p_path)):
                v_path = os.path.join(p_path, version)
                if not os.path.isdir(v_path):
                    continue
                installed_surfaces[plugin] = {
                    'path': v_path,
                    'commands': md_basenames(os.path.join(v_path, 'commands')),
                    'agents': md_basenames(os.path.join(v_path, 'agents')),
                }

# unresolved observations by pattern_type; plugin-audit observations by plugin
unresolved_by_type = {}
plugin_audit_open = set()
obs_dir = os.path.join(project_root, '.claude', 'observations')
if os.path.isdir(obs_dir):
    for f in os.listdir(obs_dir):
        if not f.endswith('.json'):
            continue
        d = load_json(os.path.join(obs_dir, f))
        if not isinstance(d, dict) or d.get('resolved_at'):
            continue
        pt = d.get('pattern_type', '')
        unresolved_by_type.setdefault(pt, []).append(f)
        tr = d.get('target_resource') or ''
        if d.get('source') == 'code-quality-auditor' and tr.startswith('plugin:'):
            plugin_audit_open.add(tr.split(':', 1)[1])

# marketplace index entries: name -> entry + index path (evidence anchor)
index_entries = {}
if os.path.isdir(marketplaces_dir):
    for mp in sorted(os.listdir(marketplaces_dir)):
        mp_json = os.path.join(marketplaces_dir, mp, '.claude-plugin', 'marketplace.json')
        data = load_json(mp_json)
        if not isinstance(data, dict):
            continue
        for entry in data.get('plugins') or []:
            if isinstance(entry, dict) and entry.get('name'):
                index_entries[f"{entry['name']}@{mp}"] = (entry, mp_json, mp)

# authors of installed plugins whose installed-mode audit is clean
clean_installed_authors = {}
for key in installed_keys:
    name = key.split('@', 1)[0]
    if name in plugin_audit_open:
        continue
    ie = index_entries.get(key)
    if ie:
        author = (ie[0].get('author') or {}).get('name') if isinstance(ie[0].get('author'), dict) else None
        if author:
            clean_installed_authors.setdefault(author, name)

# ---- verdict engine ----
n_rec = n_not = n_cand = n_audit_clean = n_audit_fail = n_audit_deferred = 0
edits = []  # (insert_at_line_end_of_block, block, new_status, reason, audit_line)

for block in blocks:
    if field(block, 'status') != 'candidate':
        continue
    key = f"{block['name']}@{block['mp']}"
    ie = index_entries.get(key)
    entry = ie[0] if ie else {}
    mp_json = ie[1] if ie else '(index unavailable)'
    text = ' '.join(str(entry.get(k, '') or '') for k in ('name', 'category', 'description')).lower()
    source_class = field(block, 'source_class') or ''
    reasons_neg, reasons_pos = [], []
    audit_line = None

    # (b) STACK-MISMATCH, platform leg (Phase 78) — the candidate's declared
    # platform set shares NOTHING with the detected host platform(s) and no
    # rival marker corroborates it. A cross-platform candidate that also
    # names the host platform agrees — no mismatch; no host marker detected
    # -> stays out of this leg entirely (conservative default).
    detected_platforms = {PLATFORM_MARKERS[m] for m in markers if m in PLATFORM_MARKERS}
    cand_platforms = {p for p, kws in PLATFORM_KEYWORDS.items()
                      if any(word_hit(kw, text) for kw in kws)}
    if detected_platforms and cand_platforms and not (cand_platforms & detected_platforms):
        p = sorted(cand_platforms)[0]
        host_markers = sorted(m for m in markers if m in PLATFORM_MARKERS)
        reasons_neg.append(
            f"STACK-MISMATCH: entry text declares platform '{p}' ({fs(mp_json)} :: "
            f"{block['name']}) but detected platform marker(s) ({', '.join(host_markers)}) "
            f"indicate {'/'.join(sorted(detected_platforms))} and no {p} marker corroborates")

    # (b) STACK-MISMATCH, exclusive-stack leg — metadata class, applies to
    # every candidate.
    for stack, justifying in EXCLUSIVE_STACKS.items():
        if not word_hit(stack, text):
            continue
        if any(j in markers for j in justifying):
            continue
        committed = sorted(markers & STACK_MARKERS)
        if committed:
            reasons_neg.append(
                f"STACK-MISMATCH: entry text names '{stack}' ({fs(mp_json)} :: {block['name']}) "
                f"but detected markers ({', '.join(committed)}) indicate a different stack "
                f"and none justify {stack}")
            break

    if source_class == 'repo_hosted':
        src = field(block, 'source_path') or ''
        plugin_dir = os.path.normpath(os.path.join(os.path.dirname(os.path.dirname(mp_json)), src)) if src else ''
        if plugin_dir and os.path.isdir(plugin_dir):
            # (a) SURFACE-CONFLICT — name collisions, cited file-to-file.
            # Hook-EVENT overlap alone is NOT a conflict: hooks chain by
            # design (this machine runs three SessionStart surfaces today).
            cand_commands = md_basenames(os.path.join(plugin_dir, 'commands'))
            cand_agents = md_basenames(os.path.join(plugin_dir, 'agents'))
            for fn in sorted(cand_commands & skeleton_commands):
                reasons_neg.append(
                    f"SURFACE-CONFLICT: {fs(plugin_dir)}/commands/{fn} collides with "
                    f"{fs(os.path.join(project_root, '.claude', 'commands', fn))}")
            for fn in sorted(cand_agents & skeleton_agents):
                reasons_neg.append(
                    f"SURFACE-CONFLICT: {fs(plugin_dir)}/agents/{fn} collides with a "
                    f"skeleton agent of the same name under .claude/agents/")
            for iname, surf in sorted(installed_surfaces.items()):
                for fn in sorted(cand_commands & surf['commands']):
                    reasons_neg.append(
                        f"SURFACE-CONFLICT: {fs(plugin_dir)}/commands/{fn} collides with "
                        f"{fs(surf['path'])}/commands/{fn} (installed: {iname})")
                for fn in sorted(cand_agents & surf['agents']):
                    reasons_neg.append(
                        f"SURFACE-CONFLICT: {fs(plugin_dir)}/agents/{fn} collides with "
                        f"{fs(surf['path'])}/agents/{fn} (installed: {iname})")
            # (c) CANDIDATE-AUDIT-FAIL — the pre-install audit, composed
            # from plugin-quality-check --candidate-plugin (zero new
            # heuristics; findings quoted).
            try:
                proc = subprocess.run(
                    ['bash', quality_check, '--candidate-plugin', plugin_dir],
                    capture_output=True, text=True, timeout=120)
                findings = [ln for ln in (proc.stdout or '').splitlines()
                            if ln.startswith('CANDIDATE-FINDING')]
            except (OSError, subprocess.SubprocessError):
                findings = []
                audit_line = 'error (audit did not run)'
            if findings:
                n_audit_fail += 1
                audit_line = f'{len(findings)} finding(s)'
                joined = ' | '.join(f[len('CANDIDATE-FINDING '):] for f in findings[:3])
                reasons_neg.append(f"CANDIDATE-AUDIT-FAIL: {joined}")
            elif audit_line is None:
                n_audit_clean += 1
                audit_line = 'clean (i/ii/iii pass on pre-install source)'
        else:
            audit_line = 'error (source path not found in clone)'
    else:
        # external-sha (and unindexed): metadata-eligible, source unreadable
        # offline — the audit is DEFERRED, never guessed.
        n_audit_deferred += 1
        audit_line = 'deferred (source_not_inspected_offline)'

    if not reasons_neg:
        # positives only matter if nothing disqualified the candidate.
        for marker in sorted(markers):
            for kw in MARKER_KEYWORDS.get(marker, []):
                if word_hit(kw, text):
                    reasons_pos.append(
                        f"STACK-MARKER: detected {marker} matches '{kw.strip()}' in "
                        f"{fs(mp_json)} :: {block['name']}")
                    break
        for ptype, cats in GAP_CATEGORIES.items():
            if unresolved_by_type.get(ptype) and str(entry.get('category', '')).lower() in cats:
                reasons_pos.append(
                    f"CAPABILITY-GAP: {len(unresolved_by_type[ptype])} unresolved {ptype} "
                    f"observation(s) in .claude/observations/ and candidate category "
                    f"'{entry.get('category')}' addresses that class")
        author = (entry.get('author') or {}).get('name') if isinstance(entry.get('author'), dict) else None
        if author and author in clean_installed_authors:
            reasons_pos.append(
                f"COMPOSITION-PRECEDENT: author '{author}' also ships installed plugin "
                f"'{clean_installed_authors[author]}' with zero unresolved "
                f"code-quality-auditor observations")

    if reasons_neg:
        new_status, reason = 'not_recommended', ' ; '.join(reasons_neg)
        n_not += 1
    elif reasons_pos:
        new_status, reason = 'recommended', ' ; '.join(reasons_pos)
        n_rec += 1
    else:
        new_status, reason = 'candidate', None
        n_cand += 1
    edits.append((block, new_status, reason, audit_line))

# ---- apply edits (line-preserving, bottom-up so indices stay valid) ----
for block, new_status, reason, audit_line in sorted(edits, key=lambda e: -e[0]['start']):
    insert = []
    if reason:
        insert.append(f'- reason: {reason}')
    if audit_line:
        insert.append(f'- candidate_audit: {audit_line}')
    end = block['end']
    while end > block['start'] and lines[end - 1].strip() == '':
        end -= 1
    lines[end:end] = insert
    for k in range(block['start'], end):
        if re.match(r'^- status:\s*candidate\s*$', lines[k]):
            lines[k] = f'- status: {new_status}'
            break

# ---- frontmatter counts ----
for k in range(1, fm_end):
    m = re.match(r'^candidates:\s*\d+\s*$', lines[k])
    if m:
        lines[k] = f'candidates: {n_cand}'
        lines[k + 1:k + 1] = [f'recommended: {n_rec}', f'not_recommended: {n_not}']
        break

tmp = manifest_path + f'.tmp.{os.getpid()}'
with open(tmp, 'w', encoding='utf-8', newline='\n') as f:
    f.write('\n'.join(lines).rstrip('\n') + '\n')
os.replace(tmp, manifest_path)

print(f'plugin-context-matcher: {len(edits)} candidates evaluated -- '
      f'{n_rec} recommended, {n_not} not_recommended, {n_cand} stay candidate; '
      f'audits: {n_audit_clean} clean, {n_audit_fail} findings, {n_audit_deferred} deferred. '
      f'Manifest stays draft — your review is the gate; /plugin is the only install path.')
PYIMPL
PY_RC=$?

# ---- cleanup ----
if [ "$PY_RC" -ne 0 ]; then
  echo "plugin-context-matcher: verdict pass failed (python rc=$PY_RC)" >&2
  exit 1
fi
exit 0
