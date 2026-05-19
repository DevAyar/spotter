#!/usr/bin/env bash
# plugin-quality-check: read-only auditor of installed plugins under
# ~/.claude/plugins/cache/. Implements 3 heuristics (i, ii, iii) and
# emits observations to .claude/observations/ using session-observer's
# existing schema. v1.1.4 first plugin-verification component; composes
# with cruft-checker + drift-checker as the project-level audit triad.
# Invoked by the SessionStart hook chain (with --hook + 24h cooldown)
# or manually (no flag, ignores cooldown). For testing, --plugin-dir
# <path> overrides the default cache location. NEVER auto-fixes. NEVER
# hits the network. NEVER writes outside .claude/observations/ +
# .claude/.last-plugin-quality-check. Always exits 0 so the hook chain
# never blocks.

set -uo pipefail

# ---- constants ----
COOLDOWN_HOURS=24
COOLDOWN_FILE=".claude/.last-plugin-quality-check"
OBS_DIR=".claude/observations"
EVIDENCE_CAP=20
HOOK_FLAG=false
PLUGIN_DIR_OVERRIDE=""
DEFAULT_PLUGIN_DIR="$HOME/.claude/plugins/cache"
BASH_LIB=".claude/lib/destructive-bash-patterns.sh"
PS_LIB=".claude/lib/destructive-powershell-patterns.sh"

# ---- args ----
while [ "$#" -gt 0 ]; do
  case "$1" in
    --hook) HOOK_FLAG=true; shift ;;
    --plugin-dir) PLUGIN_DIR_OVERRIDE="${2:-}"; shift 2 ;;
    --plugin-dir=*) PLUGIN_DIR_OVERRIDE="${1#--plugin-dir=}"; shift ;;
    *) shift ;; # silently ignore unknown args; best-effort
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

PLUGIN_DIR="${PLUGIN_DIR_OVERRIDE:-$DEFAULT_PLUGIN_DIR}"

command -v python >/dev/null 2>&1 || exit 0
mkdir -p "$OBS_DIR" 2>/dev/null || exit 0

python - "$PLUGIN_DIR" "$OBS_DIR" "$EVIDENCE_CAP" "$BASH_LIB" "$PS_LIB" 2>/dev/null <<'PYIMPL'
import hashlib, json, os, re, sys
from datetime import datetime, timezone
from glob import glob

plugin_dir = sys.argv[1]
obs_dir = sys.argv[2]
evidence_cap = int(sys.argv[3])
bash_lib = sys.argv[4]
ps_lib = sys.argv[5]

# Module-level set of pattern_ids emitted this run.
emitted_ids = set()

def now_iso():
    return datetime.now(timezone.utc).strftime('%Y-%m-%dT%H:%M:%SZ')

def pattern_id(signature):
    h = hashlib.sha256()
    h.update(b'plugin_quality\n')
    h.update(signature.encode('utf-8', errors='replace'))
    return h.hexdigest()

def emit(signature, notes, confidence='high'):
    if len(notes) > 120:
        notes = notes[:119] + '…'
    pid = pattern_id(signature)
    emitted_ids.add(pid)
    path = os.path.join(obs_dir, pid + '.json')
    ts = now_iso()
    new_evidence = {'timestamp': ts, 'kind': 'plugin_audit', 'summary': notes}

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
        prior_notes = existing.get('notes', notes)
    else:
        occurrences = 1
        first_seen = ts
        evidence = [new_evidence]
        prior_notes = notes

    # Phase 46: plugin-quality observations are share-with-redaction —
    # plugin name + heuristic shareable across installs, but plugin paths
    # under ~/.claude/plugins/cache/<marketplace>/... may leak local user
    # info via marketplace name. target_resource derived from signature:
    # signatures all follow "<heuristic-id>:<plugin_name>:..." so we split
    # on ':' and take the second token (plugin_name) for the target.
    target_resource = None
    sig_parts = signature.split(':', 2)
    if len(sig_parts) >= 2 and sig_parts[1]:
        target_resource = f'plugin:{sig_parts[1]}'

    out = {
        'pattern_id': pid,
        'source': 'code-quality-auditor',
        'pattern_type': 'plugin_quality',
        'occurrences': occurrences,
        'first_seen': first_seen,
        'last_seen': ts,
        'resolved_at': None,
        'evidence': evidence,
        'confidence': confidence,
        'notes': prior_notes,
        'privacy_class': 'share-with-redaction',
    }
    if target_resource:
        out['target_resource'] = target_resource
    tmp = path + f'.tmp.{os.getpid()}'
    with open(tmp, 'w', encoding='utf-8', newline='\n') as f:
        json.dump(out, f, indent=2, sort_keys=True)
        f.write('\n')
    os.replace(tmp, path)

def resolve_untouched():
    """Full resolve pass — code-quality-auditor scans every plugin every
    run, so absence in a scan is meaningful. Mirrors cruft-checker's
    resolve discipline."""
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
        if data.get('source') != 'code-quality-auditor':
            continue
        if data.get('resolved_at'):
            continue
        data['resolved_at'] = ts
        tmp = obs_path + f'.tmp.{os.getpid()}'
        with open(tmp, 'w', encoding='utf-8', newline='\n') as f:
            json.dump(data, f, indent=2, sort_keys=True)
            f.write('\n')
        os.replace(tmp, obs_path)

# ---- destructive patterns: parse from shared libs (single source of truth) ----
def read_patterns_from_lib(lib_path):
    """Parse bash array literal from a destructive-pattern lib file.
    Lines inside the array declaration that are quoted regex patterns
    are extracted. Empty / commented / outside-array lines skipped."""
    if not os.path.isfile(lib_path):
        return []
    patterns = []
    in_array = False
    with open(lib_path, encoding='utf-8', errors='replace') as f:
        for line in f:
            stripped = line.rstrip('\n')
            if 'DESTRUCTIVE_BASH_PATTERNS=(' in stripped or 'DESTRUCTIVE_POWERSHELL_PATTERNS=(' in stripped:
                in_array = True
                continue
            if not in_array:
                continue
            if stripped.strip() == ')':
                in_array = False
                continue
            m = re.match(r"^\s*'(.*)'\s*$", stripped)
            if m:
                patterns.append(m.group(1))
    return patterns

BASH_PATTERNS = read_patterns_from_lib(bash_lib)
PS_PATTERNS = read_patterns_from_lib(ps_lib)

def compile_posix_ere(p, case_insensitive=False):
    """Convert POSIX ERE pattern (as used by [[ =~ ]] in bash) to a
    compiled Python re. Replaces [[:space:]] with \\s; other ERE shapes
    in our pattern set translate directly."""
    py = p.replace('[[:space:]]', r'\s')
    flags = re.IGNORECASE if case_insensitive else 0
    try:
        return re.compile(py, flags)
    except re.error:
        return None

BASH_REGEX = [(compile_posix_ere(p), p) for p in BASH_PATTERNS]
PS_REGEX = [(compile_posix_ere(p, case_insensitive=True), p) for p in PS_PATTERNS]

# ---- plugin enumeration ----
def enumerate_plugins(root):
    """Walk root/<marketplace>/<plugin>/<version>/ -> list of (name, path).
    Skips entries without .claude-plugin/plugin.json. Missing root -> []."""
    if not os.path.isdir(root):
        return []
    plugins = []
    for marketplace in sorted(os.listdir(root)):
        mpath = os.path.join(root, marketplace)
        if not os.path.isdir(mpath):
            continue
        for plugin in sorted(os.listdir(mpath)):
            ppath = os.path.join(mpath, plugin)
            if not os.path.isdir(ppath):
                continue
            for version in sorted(os.listdir(ppath)):
                vpath = os.path.join(ppath, version)
                if not os.path.isdir(vpath):
                    continue
                manifest = os.path.join(vpath, '.claude-plugin', 'plugin.json')
                if os.path.isfile(manifest):
                    plugins.append((f'{marketplace}/{plugin}@{version}', vpath))
    return plugins

def read_manifest(plugin_path):
    manifest_path = os.path.join(plugin_path, '.claude-plugin', 'plugin.json')
    try:
        with open(manifest_path, encoding='utf-8') as f:
            return json.load(f)
    except (OSError, ValueError):
        return None

# ---- Heuristic i: manifest path missing or empty ----
COMPONENT_EXTS = {
    'commands': ('.md',),
    'agents': ('.md',),
    'skills': ('.md',),
    # hooks/ doesn't have a generic extension match — handled by heuristic ii.
}

def check_heuristic_i(plugin_name, plugin_path, manifest):
    components = manifest.get('components') if isinstance(manifest, dict) else None
    if not isinstance(components, dict):
        return
    for comp_type, comp_path in components.items():
        if not isinstance(comp_path, str):
            continue
        resolved = os.path.normpath(os.path.join(plugin_path, comp_path))
        if not os.path.exists(resolved):
            sig = f'i:{plugin_name}:{comp_type}:{comp_path}:missing'
            notes = f'i: {plugin_name} manifest declares {comp_type} at {comp_path} but path missing'
            emit(sig, notes, confidence='high')
            continue
        if os.path.isdir(resolved):
            extensions = COMPONENT_EXTS.get(comp_type)
            if extensions:
                has_match = any(
                    f.endswith(extensions)
                    for f in os.listdir(resolved)
                    if os.path.isfile(os.path.join(resolved, f))
                )
                if not has_match:
                    sig = f'i:{plugin_name}:{comp_type}:{comp_path}:empty'
                    notes = f'i: {plugin_name} manifest declares {comp_type} at {comp_path} but path empty'
                    emit(sig, notes, confidence='high')

# ---- Heuristic ii: hooks.json schema validation ----
# Canonical source: cruft-check.sh heuristic viii. Duplicated here because
# both scripts use inline Python heredocs and sharing across heredoc scopes
# would mean introducing a separate Python lib file (diverging from the
# established self-contained-script pattern). Keep these two implementations
# in sync — the Anthropic hook schema is stable so drift is unlikely.
def check_heuristic_ii(plugin_name, plugin_path):
    hooks_dir = os.path.join(plugin_path, 'hooks')
    if not os.path.isdir(hooks_dir):
        return
    hooks_json = os.path.join(hooks_dir, 'hooks.json')
    if not os.path.isfile(hooks_json):
        sig = f'ii:{plugin_name}:hooks-dir-no-json'
        notes = f'ii: {plugin_name} hooks/ dir present but hooks.json missing'
        emit(sig, notes, confidence='high')
        return
    try:
        with open(hooks_json, encoding='utf-8') as f:
            data = json.load(f)
    except (OSError, ValueError) as e:
        sig = f'ii:{plugin_name}:hooks-json-parse-error'
        notes = f'ii: {plugin_name} hooks.json parse error: {str(e)[:50]}'
        emit(sig, notes, confidence='high')
        return
    hooks_root = data.get('hooks') if isinstance(data, dict) else None
    if not isinstance(hooks_root, dict):
        sig = f'ii:{plugin_name}:hooks-json-no-root'
        notes = f'ii: {plugin_name} hooks.json missing top-level "hooks" object'
        emit(sig, notes, confidence='high')
        return
    if not hooks_root:
        sig = f'ii:{plugin_name}:hooks-json-empty'
        notes = f'ii: {plugin_name} hooks.json "hooks" object is empty'
        emit(sig, notes, confidence='high')
        return
    for event_name, entries in hooks_root.items():
        if not isinstance(entries, list):
            continue
        for entry_idx, entry in enumerate(entries):
            if not isinstance(entry, dict):
                continue
            inner_hooks = entry.get('hooks')
            if not isinstance(inner_hooks, list):
                sig = f'ii:{plugin_name}:{event_name}:{entry_idx}:no-hooks-array'
                notes = f'ii: {plugin_name} hooks.{event_name}[{entry_idx}] missing inner "hooks" array'
                emit(sig, notes, confidence='high')
                continue
            for hook_idx, inner in enumerate(inner_hooks):
                if not isinstance(inner, dict):
                    continue
                if inner.get('type') != 'command':
                    sig = f'ii:{plugin_name}:{event_name}:{entry_idx}:hooks[{hook_idx}]:type'
                    notes = f'ii: {plugin_name} hooks.{event_name}[{entry_idx}].hooks[{hook_idx}] type missing or not "command"'
                    emit(sig, notes, confidence='high')
                if not inner.get('command'):
                    sig = f'ii:{plugin_name}:{event_name}:{entry_idx}:hooks[{hook_idx}]:command'
                    notes = f'ii: {plugin_name} hooks.{event_name}[{entry_idx}].hooks[{hook_idx}] missing "command" field'
                    emit(sig, notes, confidence='high')

# ---- Heuristic iii: destructive patterns against unguarded paths ----
def is_rm_shape(pat):
    """Does this pattern target an rm/Remove-Item shape that has a path arg?"""
    p = pat.lower()
    return ('rm' in p and '-rf' in p) or 'remove-item' in p or ('rm|del|erase' in p)

def is_unguarded_target(arg):
    """Best-effort: is this rm target a broad-scope path?"""
    a = arg.strip().strip('"').strip("'")
    if not a:
        return True
    broad = {'/', '~', '~/', '$HOME', '${HOME}', '/*', '~/*', '$HOME/*', '${HOME}/*'}
    if a in broad:
        return True
    if a.startswith('$HOME') or a.startswith('${HOME}'):
        return True
    if a.startswith('~'):
        return True
    if a.startswith('/') and not a.startswith('//'):
        return True
    if a.startswith('$') or a.startswith('${'):
        return False  # variable other than HOME — assumed guarded
    return False  # relative path — assumed guarded

def extract_target_after_match(line, match_end):
    """Grab the next whitespace-separated token after a regex match end.
    Used to inspect the target arg of rm/Remove-Item shapes."""
    rest = line[match_end:].lstrip()
    if not rest:
        return ''
    parts = rest.split(None, 1)
    return parts[0] if parts else ''

def short_label(pat):
    """Short readable label of a regex pattern for use in notes / signature."""
    # Strip POSIX-ERE noise and bash escapes for human readability
    s = pat
    s = re.sub(r'\[\[:space:\]\]\+?', ' ', s)
    s = re.sub(r'\(\^\|', '(', s)
    s = re.sub(r'\|\$\)', ')', s)
    s = re.sub(r'\s+', ' ', s).strip()
    return s[:50]

def check_heuristic_iii(plugin_name, plugin_path):
    for root, dirs, files in os.walk(plugin_path):
        dirs[:] = [d for d in dirs if not d.startswith('.')]
        for fname in files:
            if not (fname.endswith('.sh') or fname.endswith('.ps1') or fname.endswith('.bash')):
                continue
            fpath = os.path.join(root, fname)
            rel = os.path.relpath(fpath, plugin_path).replace('\\', '/')
            try:
                with open(fpath, encoding='utf-8', errors='replace') as f:
                    content = f.read()
            except OSError:
                continue
            if fname.endswith('.ps1'):
                regex_list = PS_REGEX
                lang = 'powershell'
            else:
                regex_list = BASH_REGEX
                lang = 'bash'
            for line_no, line in enumerate(content.splitlines(), 1):
                for regex, raw_pat in regex_list:
                    if regex is None:
                        continue
                    for m in regex.finditer(line):
                        # rm-shape: filter by unguarded target
                        if is_rm_shape(raw_pat):
                            target = extract_target_after_match(line, m.end())
                            if not is_unguarded_target(target):
                                continue
                            label = short_label(raw_pat)
                            sig = f'iii:{plugin_name}:{rel}:{line_no}:{label}'
                            notes = f'iii: {plugin_name} {rel}:{line_no} {lang} {label} against unguarded "{target[:30]}"'
                            emit(sig, notes, confidence='med')
                        else:
                            # Non-rm destructive (force-push, hard-reset, format-volume, etc.)
                            # — always emit; no target-guard concept applies.
                            label = short_label(raw_pat)
                            sig = f'iii:{plugin_name}:{rel}:{line_no}:{label}'
                            notes = f'iii: {plugin_name} {rel}:{line_no} {lang} {label}'
                            emit(sig, notes, confidence='med')

# ---- run all heuristics across all plugins ----
plugins = enumerate_plugins(plugin_dir)
for plugin_name, plugin_path in plugins:
    manifest = read_manifest(plugin_path)
    if manifest is not None:
        check_heuristic_i(plugin_name, plugin_path, manifest)
    check_heuristic_ii(plugin_name, plugin_path)
    check_heuristic_iii(plugin_name, plugin_path)

# ---- resolution pass ----
resolve_untouched()

PYIMPL
PYIMPL_RC=$?

if [ "$PYIMPL_RC" -ne 0 ]; then
  # python helper failed; bail silent (cooldown not updated)
  exit 0
fi

# ---- cleanup: update cooldown marker ----
now_epoch > "$COOLDOWN_FILE" 2>/dev/null || true
exit 0
