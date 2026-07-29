#!/usr/bin/env bash
# receipt-render: turn a Phase 92 ship-report receipt block (FIELD: sentence
# lines) into a small self-contained HTML card (Phase 93). Input: a file
# argument, or stdin when no argument is given. Output: writes
# .claude/receipts/latest.html plus a dated copy
# .claude/receipts/YYYY-MM-DD-phase-<N>.html (phase parsed from the VERDICT
# line; "receipt" when absent) so history accrues. The receipt TEXT is the
# canonical record - the HTML is a render of it. Self-contained by
# constraint: inline CSS only, zero JS, zero external references; light/dark
# via prefers-color-scheme; per-section tooltips are static title attributes
# carrying GENERIC field explanations, never per-line custom text. Absent
# fields are omitted honestly, never fabricated. Malformed input (no
# recognized field lines) -> one-line stderr error, exit 1, NO partial file
# (tmp-write + atomic rename). Exits nonzero on failure - this is a
# user-invoked tool, not a hook; it is allowed to fail loudly.

set -uo pipefail

# ---- constants ----
ROOT="${CLAUDE_PROJECT_DIR:-$PWD}"
OUT_DIR="$ROOT/.claude/receipts"

# ---- helpers ----
# render_live_strip: rebuild .claude/receipts/live.html (Phase 97) from
# on-disk state - the verdict stash, the cost hook's own line (invoked
# with COST_LINE_ONLY so no nudge state is touched; single source of the
# Phase 91 display rules), and due-audit chips. Event-fresh: this runs
# when hooks fire and at ship renders; the page's 10s meta-refresh only
# re-reads the file.
render_live_strip() {
  local cost_line=""
  if [ -f "$ROOT/.claude/hooks/sessionstart-cost-summary.sh" ]; then
    cost_line=$(COST_LINE_ONLY=1 bash "$ROOT/.claude/hooks/sessionstart-cost-summary.sh" 2>/dev/null | head -1 | sed 's/^\[token-cost\] //')
  fi
  "$PYBIN" -c "$STRIP_PROGRAM" "$OUT_DIR" "$cost_line" "$ROOT"
}

# send_toast <text>: Phase 102 fire-once OS notification - best-effort,
# capability-gated, never fails the render. RECEIPT_TOAST_BIN (env, the
# COST_LINE_ONLY invocation-contract class) is the test seam: when set,
# that binary receives the text instead of any real notifier - guards
# prove the attempt and the capability-miss with zero real popups.
# Windows: BurntToast when already installed, else the raw
# Windows.UI.Notifications WinRT path on PowerShell 5.1 (zero
# dependencies; the standard PowerShell AppId). Click-to-open is
# attempted via protocol activation where the API allows it -
# file-protocol activation is often blocked, and the plain notification
# is the honest degradation. Non-Windows: notify-send / osascript,
# existence-gated. Nothing available -> silent skip.
send_toast() {
  local text="$1"
  if [ -n "${RECEIPT_TOAST_BIN:-}" ]; then
    if [ -x "$RECEIPT_TOAST_BIN" ]; then
      "$RECEIPT_TOAST_BIN" "$text" >/dev/null 2>&1 || true
    fi
    return 0
  fi
  case "$(uname -s)" in
    MINGW*|MSYS*|CYGWIN*)
      command -v powershell.exe >/dev/null 2>&1 || return 0
      local ps_text launch_url
      ps_text=$(printf '%s' "$text" | sed "s/'/''/g")
      launch_url="file:///$(cygpath -m "$OUT_DIR/latest.html" 2>/dev/null || true)"
      powershell.exe -NoProfile -Command "
        if (Get-Module -ListAvailable BurntToast) {
          Import-Module BurntToast; New-BurntToastNotification -Text 'Spotter ship', '$ps_text'
        } else {
          [Windows.UI.Notifications.ToastNotificationManager, Windows.UI.Notifications, ContentType = WindowsRuntime] | Out-Null
          \$xml = [Windows.UI.Notifications.ToastNotificationManager]::GetTemplateContent([Windows.UI.Notifications.ToastTemplateType]::ToastText02)
          \$texts = \$xml.GetElementsByTagName('text')
          \$texts.Item(0).AppendChild(\$xml.CreateTextNode('Spotter ship')) | Out-Null
          \$texts.Item(1).AppendChild(\$xml.CreateTextNode('$ps_text')) | Out-Null
          try {
            \$xml.DocumentElement.SetAttribute('activationType','protocol')
            \$xml.DocumentElement.SetAttribute('launch','$launch_url')
          } catch {}
          \$appId = '{1AC14E77-02E7-4E5D-B744-2EB1AE5198B7}\\WindowsPowerShell\\v1.0\\powershell.exe'
          [Windows.UI.Notifications.ToastNotificationManager]::CreateToastNotifier(\$appId).Show([Windows.UI.Notifications.ToastNotification]::new(\$xml))
        }
      " >/dev/null 2>&1 || true
      ;;
    Darwin)
      command -v osascript >/dev/null 2>&1 && \
        osascript -e "display notification \"$text\" with title \"Spotter ship\"" >/dev/null 2>&1 || true
      ;;
    *)
      command -v notify-send >/dev/null 2>&1 && \
        notify-send "Spotter ship" "$text" >/dev/null 2>&1 || true
      ;;
  esac
  return 0
}

# pin_window <title>: Phase 103 always-on-top with what the OS already
# carries - powershell.exe + user32 SetWindowPos (the --toast precedent;
# zero installs). Title-matching is the reliable location path here BY
# EVIDENCE: Chromium --app launches hand off to the running browser
# process, so launcher PIDs are meaningless, while the window titles are
# ours deterministically ("Ship receipt" / "Spotter live" - the pages
# set them). Bounded retry ~5s doubles as the launch-settle wait;
# HWND_TOPMOST with NOMOVE|NOSIZE|NOACTIVATE|SHOWWINDOW (0x53) so the
# pin never steals focus. Miss -> ONE honest stderr line, exit 0 -
# never hang, never fail the render. RECEIPT_PIN_BIN (env test seam,
# the toast-stub class): set -> that binary receives "<title> topmost"
# instead of any real call. Non-Windows: wmctrl -b add,above where
# present, else silent skip. CI-suppressed at the call sites.
pin_window() {
  local title="$1"
  if [ -n "${RECEIPT_PIN_BIN:-}" ]; then
    if [ -x "$RECEIPT_PIN_BIN" ]; then
      "$RECEIPT_PIN_BIN" "$title" topmost >/dev/null 2>&1 || true
    fi
    return 0
  fi
  case "$(uname -s)" in
    MINGW*|MSYS*|CYGWIN*)
      command -v powershell.exe >/dev/null 2>&1 || return 0
      if ! powershell.exe -NoProfile -Command "
        Add-Type -TypeDefinition 'using System; using System.Runtime.InteropServices; public class SpotterPin { [DllImport(\"user32.dll\")] public static extern bool SetWindowPos(IntPtr hWnd, IntPtr hWndAfter, int x, int y, int cx, int cy, uint flags); }'
        \$deadline = (Get-Date).AddSeconds(5)
        \$h = [IntPtr]::Zero
        while ((Get-Date) -lt \$deadline) {
          \$p = Get-Process msedge, chrome -ErrorAction SilentlyContinue | Where-Object { \$_.MainWindowTitle -eq '$title' } | Select-Object -First 1
          if (\$p -and \$p.MainWindowHandle -ne [IntPtr]::Zero) { \$h = \$p.MainWindowHandle; break }
          Start-Sleep -Milliseconds 500
        }
        if (\$h -eq [IntPtr]::Zero) { exit 1 }
        [SpotterPin]::SetWindowPos(\$h, [IntPtr]::new(-1), 0, 0, 0, 0, 0x0053) | Out-Null
      " >/dev/null 2>&1; then
        echo "receipt-render: window not found; not pinned" >&2
      fi
      ;;
    *)
      if command -v wmctrl >/dev/null 2>&1; then
        wmctrl -r "$title" -b add,above >/dev/null 2>&1 || echo "receipt-render: window not found; not pinned" >&2
      fi
      ;;
  esac
  return 0
}

# launch_window <file>: Phase 99 app-mode launch - a chrome-free window
# (no URL bar, no tabs) the user can pin with Always On Top. Probes a
# closed list of Chromium installs and passes --app= with a file URL
# (cygpath -m: forward-slash Windows form). --window-size is best-effort
# (honored for new app windows; an existing profile process may ignore
# it). No probe hit -> degrade to the plain --open launch (chromed, but
# the strip still appears). Best-effort throughout - never fails the
# render. Suppressed under CI by the caller.
launch_window() {
  local target="$1" exe=""
  case "$(uname -s)" in
    MINGW*|MSYS*|CYGWIN*)
      for exe in \
        "/c/Program Files (x86)/Microsoft/Edge/Application/msedge.exe" \
        "/c/Program Files/Google/Chrome/Application/chrome.exe" \
        "/c/Program Files (x86)/Google/Chrome/Application/chrome.exe"; do
        if [ -f "$exe" ] && command -v cygpath >/dev/null 2>&1; then
          "$exe" --app="file:///$(cygpath -m "$target")" --window-size=900,120 >/dev/null 2>&1 &
          return 0
        fi
      done
      # no app-capable browser found: chromed fallback
      if command -v cmd.exe >/dev/null 2>&1 && command -v cygpath >/dev/null 2>&1; then
        cmd.exe //c start "" "$(cygpath -w "$target")" >/dev/null 2>&1 || true
      fi
      ;;
    Darwin)
      if [ -d "/Applications/Google Chrome.app" ]; then
        open -na "Google Chrome" --args --app="file://$target" >/dev/null 2>&1 || true
      else
        command -v open >/dev/null 2>&1 && { open "$target" >/dev/null 2>&1 || true; }
      fi
      ;;
    *)
      for exe in google-chrome chromium chromium-browser; do
        if command -v "$exe" >/dev/null 2>&1; then
          "$exe" --app="file://$target" --window-size=900,120 >/dev/null 2>&1 &
          return 0
        fi
      done
      command -v xdg-open >/dev/null 2>&1 && { xdg-open "$target" >/dev/null 2>&1 & } || true
      ;;
  esac
  return 0
}

# ---- main ----
# python||python3 validated by EXECUTION, not presence — the Windows Store
# alias stub passes `command -v` but exits nonzero (the Phase 57
# silent-inert class; hardened Phase 63).
PYBIN=""
for _cand in python python3; do
  if command -v "$_cand" >/dev/null 2>&1 && "$_cand" -c 'pass' >/dev/null 2>&1; then
    PYBIN="$_cand"
    break
  fi
done
if [ -z "$PYBIN" ]; then
  echo "receipt-render: no working python found" >&2
  exit 1
fi

# Args: --open launches the default browser on latest.html after a
# successful write (Phase 94); the first non-flag arg is the input file
# (default: stdin). Rendering is byte-identical with or without the flag.
OPEN=0
LIVE=0
WINDOW=0
ANSI=0
SHOW=0
TOAST=0
PIN=0
INPUT="-"
for arg in "$@"; do
  case "$arg" in
    --open) OPEN=1 ;;
    --live) LIVE=1 ;;
    --window) WINDOW=1 ;;   # app-mode launch (chrome-free); wins over --open
    --ansi) ANSI=1 ;;       # terminal card to stdout (files still written)
    --show) SHOW=1 ;;       # auto dispatcher: vscode note / TTY ansi / silent
    --toast) TOAST=1 ;;     # fire-once OS notification at ship time
    --pin) PIN=1 ;;         # set the target window always-on-top (zero-install)
    *) INPUT="$arg" ;;
  esac
done

# Phase 100: --show auto dispatch. Precedence: explicit --open/--window
# override; CI -> silent file-write only; VS Code terminal -> path + a
# Live Preview line (its tab auto-reloads on change - better than the
# meta refresh); interactive TTY -> the ANSI card; non-TTY -> silent.
VSCODE_NOTE=0
if [ "$SHOW" -eq 1 ] && [ "$OPEN" -eq 0 ] && [ "$WINDOW" -eq 0 ]; then
  if [ -n "${CI:-}" ]; then
    :
  elif [ "${TERM_PROGRAM:-}" = "vscode" ]; then
    VSCODE_NOTE=1
  elif [ -t 1 ]; then
    ANSI=1
  fi
fi

# Capability-honest color depth + width for the ANSI card. NO_COLOR
# respected absolutely (plain box, zero escape sequences).
ANSI_DEPTH="0"
ANSI_WIDTH=80
if [ "$ANSI" -eq 1 ]; then
  if [ -z "${NO_COLOR:-}" ]; then
    case "${COLORTERM:-}" in
      *truecolor*|*24bit*) ANSI_DEPTH="24" ;;
      *)
        _colors=$(tput colors 2>/dev/null || echo 0)
        case "$_colors" in ''|*[!0-9]*) _colors=0 ;; esac
        if [ "$_colors" -ge 256 ]; then ANSI_DEPTH="256"
        elif [ "$_colors" -ge 8 ]; then ANSI_DEPTH="16"; fi
        ;;
    esac
  fi
  ANSI_WIDTH="${COLUMNS:-$(tput cols 2>/dev/null || echo 80)}"
  case "$ANSI_WIDTH" in ''|*[!0-9]*) ANSI_WIDTH=80 ;; esac
  [ "$ANSI_WIDTH" -lt 60 ] && ANSI_WIDTH=60
fi
if [ "$LIVE" -eq 0 ] && [ "$INPUT" != "-" ] && [ ! -f "$INPUT" ]; then
  echo "receipt-render: input file not found: $INPUT" >&2
  exit 1
fi

# Phase 97: the live-strip builder. Reads the verdict stash (absent ->
# "no ship recorded yet", honest), takes the cost line as argv (gathered
# by render_live_strip from the cost hook itself), derives due-audit
# chips from gate-config vs audit-state (same n >= cadence rule the
# rules hook's due line uses; the 24h line-marker is deliberately not
# consulted - it gates the ambient LINE, this is a persistent surface).
STRIP_PROGRAM=$(cat <<'PYEOF'
import datetime, html, json, os, sys

out_dir, cost_line, root = sys.argv[1], sys.argv[2], sys.argv[3]
e = html.escape

verdict = ""
try:
    raw = open(os.path.join(out_dir, "last-verdict.txt"), encoding="utf-8-sig").read().strip()
    verdict = raw[len("VERDICT:"):].strip() if raw.startswith("VERDICT:") else raw
except Exception:
    pass
ship = verdict if verdict else "no ship recorded yet"

chips = []
try:
    conf = json.load(open(os.path.join(root, ".claude", "gate-config.json"), encoding="utf-8"))
    state = json.load(open(os.path.join(root, ".claude", "telemetry", "audit-state.json"), encoding="utf-8"))
    for name, a in (conf.get("audits") or {}).items():
        if not (isinstance(a, dict) and a.get("enabled") is True):
            continue
        cad, n = a.get("sessions_between_dispatches"), (state.get(name) or {}).get("sessions_since_dispatch")
        ok = lambda v: isinstance(v, int) and not isinstance(v, bool)
        if ok(cad) and ok(n) and n >= cad:
            chips.append(f"{name} due")
except Exception:
    chips = []

now = datetime.datetime.now().strftime("%H:%M")
cost_html = f'<span class="cost">{e(cost_line)}</span>' if cost_line.strip() else ""
chip_html = "".join(f'<span class="chip">{e(c)}</span>' for c in chips)

CSS = """
:root{color-scheme:light dark;--fg:#1c1c1e;--muted:#71717a;--bg:#fff;--line:#e0e0e6;--chipbg:#fbeed6;--chipfg:#7a5210}
@media(prefers-color-scheme:dark){:root{--fg:#ececf0;--muted:#8b8b95;--bg:#161618;--line:#2c2c33;--chipbg:#3a2e14;--chipfg:#e5b566}}
body{margin:0;font:13px/1.4 system-ui,sans-serif;color:var(--fg);background:var(--bg)}
.strip{display:flex;flex-wrap:wrap;align-items:center;gap:.6em;padding:.45em .8em;border-bottom:1px solid var(--line)}
.ship{font-weight:600}
.cost{color:var(--muted)}
.chip{background:var(--chipbg);color:var(--chipfg);border-radius:.6em;padding:.1em .55em;font-size:.85em}
.asof{margin-left:auto;color:var(--muted);font-size:.85em}
"""

page = (f'<!DOCTYPE html><html><head><meta charset="utf-8">'
        f'<meta http-equiv="refresh" content="10">'
        f'<meta name="viewport" content="width=device-width,initial-scale=1">'
        f'<title>Spotter live</title><style>{CSS}</style></head>'
        f'<body><div class="strip">'
        f'<span class="ship" title="The most recent shipped phase, from its receipt.">{e(ship)}</span>'
        f'{cost_html}{chip_html}'
        f'<span class="asof" title="This strip updates when hooks fire; it is as fresh as the last event, never real-time.">as of {now}</span>'
        f'</div></body></html>')

os.makedirs(out_dir, exist_ok=True)
dest = os.path.join(out_dir, "live.html")
tmp = dest + f".tmp.{os.getpid()}"
try:
    with open(tmp, "w", encoding="utf-8", newline="\n") as f:
        f.write(page)
    os.replace(tmp, dest)
except Exception as exc:
    try:
        os.remove(tmp)
    except OSError:
        pass
    print(f"receipt-render: live strip write failed: {exc}", file=sys.stderr)
    sys.exit(1)
PYEOF
)

# --live: standalone strip refresh - no receipt parsing, live.html only.
if [ "$LIVE" -eq 1 ]; then
  render_live_strip
  STRIP_RC=$?
  if [ "$WINDOW" -eq 1 ] && [ -z "${CI:-}" ] && [ "$STRIP_RC" -eq 0 ]; then
    launch_window "$OUT_DIR/live.html" || true
  fi
  if [ "$PIN" -eq 1 ] && [ -z "${CI:-}" ] && [ "$STRIP_RC" -eq 0 ]; then
    pin_window "Spotter live" || true
  fi
  if [ "$OPEN" -eq 1 ] && [ "$WINDOW" -eq 0 ] && [ -z "${CI:-}" ] && [ "$STRIP_RC" -eq 0 ]; then
    CARD="$OUT_DIR/live.html"
    case "$(uname -s)" in
      MINGW*|MSYS*|CYGWIN*)
        if command -v cmd.exe >/dev/null 2>&1 && command -v cygpath >/dev/null 2>&1; then
          cmd.exe //c start "" "$(cygpath -w "$CARD")" >/dev/null 2>&1 || true
        fi
        ;;
      Darwin) command -v open >/dev/null 2>&1 && { open "$CARD" >/dev/null 2>&1 || true; } ;;
      *) command -v xdg-open >/dev/null 2>&1 && { xdg-open "$CARD" >/dev/null 2>&1 & } || true ;;
    esac
  fi
  exit "$STRIP_RC"
fi

# Phase 96: the program is captured into a variable and passed via -c so
# the caller's stdin stays free for a piped receipt. The pre-96 shape
# ("$PYBIN" - <<'PYEOF') parked the program ON stdin, so piped input
# collided with it and every stdin invocation failed — the exact
# heredoc-occupies-stdin class the 47b shared-memory-lib documented;
# found live by EoG's 93+94+95 propagation leg. The quoted heredoc via
# command substitution keeps bash expansion out of the python, same as
# before; argv indexing is identical under - and -c, so the python body
# is byte-unchanged.
PROGRAM=$(cat <<'PYEOF'
import datetime, html, os, re, sys

input_arg, out_dir = sys.argv[1], sys.argv[2]
text = sys.stdin.read() if input_arg == "-" else open(input_arg, encoding="utf-8-sig").read()

FIELDS = ("VERDICT", "WHAT CHANGED", "SAFETY", "COST", "MODEL",
          "FLAGS", "TO DO LATER", "NEXT UP")
# Generic per-field explanations - what the SECTION means, never the line.
TIPS = {
    "VERDICT": "What shipped, in one sentence, with the commit it landed as.",
    "WHAT CHANGED": "Each line is one before/after change, written in plain language.",
    "SAFETY": "Automated checks written to fail on the old code and pass on the new.",
    "COST": "What this sitting cost, relative to this project's own history; dollar figures appear only when a spending limit trips.",
    "MODEL": "Which AI model wrote the work, read from the commit's signature line.",
    "FLAGS": "Anything surprising or nearly-missed during the work.",
    "TO DO LATER": "Known follow-ups this work leaves open, on purpose.",
    "NEXT UP": "The next planned phase, when one is already decided.",
}

parsed = []   # (field, sentence) in input order
for line in text.splitlines():
    line = line.strip()
    for f in FIELDS:
        if line.startswith(f + ":"):
            parsed.append((f, line[len(f) + 1:].strip()))
            break

if not parsed:
    print("receipt-render: no recognized receipt fields in input", file=sys.stderr)
    sys.exit(1)

by = {}
for f, v in parsed:
    by.setdefault(f, []).append(v)

verdict = by.get("VERDICT", [""])[0]
m = re.search(r"Phase (\d+)", verdict)
slug = f"phase-{m.group(1)}" if m else "receipt"
pushed = "pushed" if "pushed" in verdict.lower() else ("held" if "held" in verdict.lower() else "")

# Badge row - (text, tint) pairs derived from parsed data only.
badges = []
if pushed:
    badges.append((pushed, "good"))
sm = re.search(r"(\d+) automated checks", " ".join(by.get("SAFETY", [])))
if sm:
    badges.append((f"{sm.group(1)} checks pass", "good"))
cost_line = " ".join(by.get("COST", []))
if cost_line:
    if "typical" in cost_line.lower() and "$" not in cost_line:
        badges.append(("spending normal", "info"))
    else:
        badges.append(("spending flagged", "warn"))
mm = re.search(r"Written by ([^,]+)", " ".join(by.get("MODEL", [])))
if mm:
    badges.append((mm.group(1).strip(), "plain"))

# Display-side derivation only (field parsing above is untouched): shas
# for the top-right meta cluster come from the already-parsed verdict.
shas = re.findall(r"\b[0-9a-f]{7,10}\b", verdict)

# Sentence-case labels (the frozen design: no ALL CAPS anywhere).
LABELS = {
    "WHAT CHANGED": "What changed", "SAFETY": "Safety",
    "COST": "Cost so far this sitting", "MODEL": "Who did the work",
    "FLAGS": "Flags", "TO DO LATER": "⏳ To do later", "NEXT UP": "→ Next up",
}

e = html.escape
def section(field, cell=False):
    if field not in by:
        return ""
    cls = "cell" if cell else "row"
    rows = "".join(f'<p class="{cls}">{e(v)}</p>' for v in by[field])
    label = f'<h2>{e(LABELS[field])}</h2>'
    return (f'<div class="sec sec-{field.split()[0].lower()}" '
            f'title="{e(TIPS[field])}">{label}{rows}</div>')

badge_html = "".join(f'<span class="badge b-{k}">{e(t)}</span>' for t, k in badges)
meta = ((f'<code>{e(" ".join(shas))}</code>' if shas else "")
        + (f'<span class="chip">{e(pushed)}</span>' if pushed else ""))
head = (f'<header title="{e(TIPS["VERDICT"])}">'
        f'<div class="headrow">'
        f'<h1>Ship receipt{" - " + e(slug.replace("phase-", "Phase ")) if slug != "receipt" else ""}</h1>'
        f'{f"<div class=meta>{meta}</div>" if meta else ""}'
        f'</div>'
        f'<p class="verdict">{e(verdict)}</p>'
        f'{f"<div class=badges>{badge_html}</div>" if badges else ""}'
        f'</header>')

duo = section("COST") + section("MODEL")
body = (head
        + section("WHAT CHANGED", cell=True)
        + section("SAFETY")
        + (f'<div class="duo">{duo}</div>' if duo else "")
        + section("FLAGS")
        + f'<footer>{section("TO DO LATER")}{section("NEXT UP")}</footer>')

CSS = """
:root{color-scheme:light dark;
--fg:#1c1c1e;--fg2:#4a4a52;--muted:#71717a;--page:#ececf0;--card:#fff;--line:#e0e0e6;--well:#f4f4f7;
--good-bg:#e3f2e5;--good-fg:#1d5c28;--info-bg:#e2edf9;--info-fg:#1e4d7d;--warn-bg:#fbeed6;--warn-fg:#7a5210;
--plain-bg:#eeeef2;--plain-fg:#44444c;--amber:#d99a1f}
@media(prefers-color-scheme:dark){:root{
--fg:#ececf0;--fg2:#b8b8c2;--muted:#8b8b95;--page:#0e0e10;--card:#1a1a1e;--line:#2c2c33;--well:#232329;
--good-bg:#1e3322;--good-fg:#8fd49a;--info-bg:#1c2c40;--info-fg:#8ab8ec;--warn-bg:#3a2e14;--warn-fg:#e5b566;
--plain-bg:#28282e;--plain-fg:#c2c2cc;--amber:#c98f22}}
body{font:15px/1.5 system-ui,sans-serif;color:var(--fg);background:var(--page);margin:0;padding:2rem 1rem}
.card{max-width:640px;margin:0 auto;background:var(--card);border:1px solid var(--line);border-radius:12px;padding:1.4rem 1.5rem}
.headrow{display:flex;justify-content:space-between;align-items:baseline;gap:.8rem}
h1{font-size:1.15rem;margin:0}
.meta{white-space:nowrap}
.meta code{font:.72rem/1 ui-monospace,Consolas,monospace;color:var(--muted);margin-right:.5em}
h2{font-size:.8rem;font-weight:600;color:var(--muted);margin:0 0 .4rem}
.verdict{margin:.35rem 0 .6rem;font-size:1rem;color:var(--fg2)}
.sec{border-top:1px solid var(--line);padding:.8rem 0;margin:0}
.row{margin:.25rem 0}
.cell{background:var(--well);border-radius:8px;padding:.5rem .7rem;margin:.35rem 0}
.duo{display:grid;grid-template-columns:1fr 1fr;gap:0 1.2rem}
.duo .sec{min-width:0}
@media(max-width:520px){.duo{grid-template-columns:1fr}}
.sec-flags{border-left:3px solid var(--amber);padding-left:.8rem}
.chip{font-size:.7rem;background:var(--good-bg);color:var(--good-fg);border-radius:.6em;padding:.15em .6em;vertical-align:middle}
.badge{display:inline-block;font-size:.72rem;border-radius:.5em;padding:.18em .6em;margin-right:.35em}
.b-good{background:var(--good-bg);color:var(--good-fg)}
.b-info{background:var(--info-bg);color:var(--info-fg)}
.b-warn{background:var(--warn-bg);color:var(--warn-fg)}
.b-plain{background:var(--plain-bg);color:var(--plain-fg)}
.badges{margin:.45rem 0 .3rem}
footer{border-top:1px solid var(--line);margin-top:.2rem}
footer .sec{border-top:0;padding:.55rem 0}
footer .sec h2{margin-bottom:.15rem}
"""

# Phase 95: the capture-tight form - same body, tight override appended.
# No centering slab: the card IS the page (capture geometry for the
# ship-time inline screenshot; humans browse the normal form).
TIGHT = """
body{padding:10px;background:var(--card);font-size:12.5px;line-height:1.35;scrollbar-width:none}
body::-webkit-scrollbar{display:none}
.card{width:100%;max-width:720px;margin:0;box-sizing:border-box;padding:.9rem 1rem;border:0}
h1{font-size:1rem}
h2{font-size:.72rem;margin:0 0 .2rem}
.verdict{font-size:.95em;margin:.25rem 0 .4rem}
.sec{padding:.45rem 0}
.cell{padding:.35rem .55rem;margin:.25rem 0;border-radius:6px}
.duo{gap:0 .9rem}
.badges{margin:.25rem 0 .1rem}
.badge{font-size:.68rem;padding:.12em .5em}
footer .sec{padding:.3rem 0}
"""

def page_for(css, anchor=False, refresh=False, stamp=False):
    # Phase 100: the tight form's card carries id="top" so fragment-honoring
    # panes/browsers can force top-of-page. Phase 102: latest.html gains the
    # strip's meta-refresh + a muted rendered-at stamp so a pinned card
    # window stays current in place; DATED copies get neither (frozen
    # history) and the tight form is unchanged.
    main_open = "<main class='card' id=\"top\">" if anchor else "<main class='card'>"
    refresh_meta = '<meta http-equiv="refresh" content="10">' if refresh else ""
    stamp_html = ""
    if stamp:
        now_hm = datetime.datetime.now().strftime("%H:%M")
        stamp_html = (f'<p class="asof" style="color:var(--muted);font-size:.72rem;'
                      f'margin:.6rem 0 0">rendered {now_hm}</p>')
    return (f"<!DOCTYPE html><html><head><meta charset='utf-8'>{refresh_meta}"
            f"<meta name='viewport' content='width=device-width,initial-scale=1'>"
            f"<title>Ship receipt</title><style>{css}</style></head>"
            f"<body>{main_open}{body}{stamp_html}</main></body></html>")

pages = {
    "latest.html": page_for(CSS, refresh=True, stamp=True),
    f"{datetime.date.today().isoformat()}-{slug}.html": page_for(CSS),
    "latest-tight.html": page_for(CSS + TIGHT, anchor=True),
}

os.makedirs(out_dir, exist_ok=True)
for name, page in pages.items():
    dest = os.path.join(out_dir, name)
    tmp = dest + f".tmp.{os.getpid()}"
    try:
        with open(tmp, "w", encoding="utf-8", newline="\n") as f:
            f.write(page)
        os.replace(tmp, dest)
    except Exception as exc:
        try:
            os.remove(tmp)
        except OSError:
            pass
        print(f"receipt-render: write failed for {name}: {exc}", file=sys.stderr)
        sys.exit(1)
# Phase 97: stash the verdict for the live strip (best-effort - the
# cards are the render's product; the stash serves the strip's writers).
stash = os.path.join(out_dir, "last-verdict.txt")
tmp = stash + f".tmp.{os.getpid()}"
try:
    with open(tmp, "w", encoding="utf-8", newline="\n") as f:
        f.write("VERDICT: " + verdict + "\n")
    os.replace(tmp, stash)
except Exception:
    try:
        os.remove(tmp)
    except OSError:
        pass
# Phase 100: --ansi terminal card - same card language (frame, muted
# labels, tinted chips, sentences intact), capability-honest coloring.
mode = sys.argv[3] if len(sys.argv) > 3 else ""
depth = sys.argv[4] if len(sys.argv) > 4 else "0"
try:
    width = max(60, int(sys.argv[5])) if len(sys.argv) > 5 else 80
except ValueError:
    width = 80

if mode == "ansi":
    import textwrap
    # Windows text-mode stdout defaults to cp1252 when piped, which cannot
    # encode box-drawing - force UTF-8 (the 47b shared-memory-lib lesson).
    try:
        sys.stdout.reconfigure(encoding="utf-8", newline="\n")
    except Exception:
        pass
    PAL = {  # the HTML dark palette
        "good": ((143, 212, 154), (30, 51, 34)),
        "info": ((138, 184, 236), (28, 44, 64)),
        "plain": ((194, 194, 204), (40, 40, 46)),
        "muted": ((139, 139, 149), None),
        "amber": ((201, 143, 34), None),
    }
    def code(rgb, bg=False):
        if depth == "24":
            return f"\x1b[{48 if bg else 38};2;{rgb[0]};{rgb[1]};{rgb[2]}m"
        if depth == "256":
            idx = 16 + 36 * (rgb[0] * 5 // 255) + 6 * (rgb[1] * 5 // 255) + (rgb[2] * 5 // 255)
            return f"\x1b[{48 if bg else 38};5;{idx}m"
        if depth == "16":
            return f"\x1b[{'42' if bg else '32'}m" if rgb == PAL['good'][0] else (f"\x1b[{'44' if bg else '34'}m" if rgb == PAL['info'][0] else f"\x1b[{'47' if bg else '37'}m")
        return ""
    RST = "\x1b[0m" if depth != "0" else ""
    def chip(text, kind):
        fgc, bgc = PAL[kind]
        if depth == "0" or bgc is None:
            return f"[{text}]"
        return f"{code(bgc, bg=True)}{code(fgc)} {text} {RST}"
    def muted(text):
        return f"{code(PAL['muted'][0])}{text}{RST}" if depth != "0" else text
    inner = width - 4
    lines = []
    title = f"Ship receipt - {slug.replace('phase-', 'Phase ')}" if slug != "receipt" else "Ship receipt"
    head_meta = (" ".join(shas) + (f" [{pushed}]" if pushed else "")).strip()
    lines.append("┌" + "─" * (width - 2) + "┐")
    lines.append(f"  {title}" + (f"   {muted(head_meta)}" if head_meta else ""))
    for w in textwrap.wrap(verdict, inner):
        lines.append(f"  {w}")
    if badges:
        lines.append("  " + " ".join(chip(t, k) for t, k in badges))
    ORDER = ("WHAT CHANGED", "SAFETY", "COST", "MODEL", "FLAGS", "TO DO LATER", "NEXT UP")
    LBL = {"WHAT CHANGED": "What changed", "SAFETY": "Safety", "COST": "Cost so far this sitting",
           "MODEL": "Who did the work", "FLAGS": "Flags", "TO DO LATER": "To do later", "NEXT UP": "Next up"}
    for f in ORDER:
        if f not in by:
            continue
        lines.append("")
        if f == "FLAGS" and depth != "0":
            mark = f"{code(PAL['amber'][0])}{LBL[f]}{RST}"
        else:
            mark = muted(LBL[f])
        lines.append(f"  {mark}")
        for v in by[f]:
            for w in textwrap.wrap(v, inner - 2):
                lines.append(f"    {w}")
    lines.append("└" + "─" * (width - 2) + "┘")
    print("\n".join(lines))
else:
    print(os.path.join(out_dir, "latest.html"))
PYEOF
)

# Phase 100: optional in-terminal image leg, best-effort and dormant
# until a PNG producer exists - chafa present AND a tight-form PNG on
# disk -> show it; otherwise skip silently to the ANSI card.
if [ "$ANSI" -eq 1 ] && command -v chafa >/dev/null 2>&1 && [ -f "$OUT_DIR/latest-tight.png" ]; then
  chafa "$OUT_DIR/latest-tight.png" 2>/dev/null || true
fi

ANSI_MODE=""
[ "$ANSI" -eq 1 ] && ANSI_MODE="ansi"
"$PYBIN" -c "$PROGRAM" "$INPUT" "$OUT_DIR" "$ANSI_MODE" "$ANSI_DEPTH" "$ANSI_WIDTH"
RENDER_RC=$?
[ "$RENDER_RC" -eq 0 ] || exit "$RENDER_RC"

# Phase 97: the ship render is one of the strip's two writers -
# best-effort, never fails the render.
render_live_strip >/dev/null 2>&1 || true

# Phase 100: the VS Code branch of --show - a path + one instruction,
# no launch (Live Preview's tab auto-reloads on file change).
if [ "$VSCODE_NOTE" -eq 1 ]; then
  echo "card: $OUT_DIR/latest.html - open it in a VS Code Live Preview tab (install 'Live Preview' once; it auto-reloads on change)"
fi

# Phase 103: pin the card window always-on-top; composes with --window
# (launch + pin) or alone (pin an already-open card window).
if [ "$PIN" -eq 1 ] && [ -z "${CI:-}" ]; then
  pin_window "Ship receipt" || true
fi

# Phase 102: the ship-time toast - fire-once, CI-suppressed like --open;
# text = the verdict sentence, truncated sane.
if [ "$TOAST" -eq 1 ] && [ -z "${CI:-}" ]; then
  TOAST_TEXT=$(head -1 "$OUT_DIR/last-verdict.txt" 2>/dev/null | sed 's/^VERDICT: //' | cut -c1-120)
  if [ -n "$TOAST_TEXT" ]; then
    send_toast "$TOAST_TEXT" || true
  fi
fi

# Phase 94: --open hands latest.html to the platform's default browser.
# A process launch on a LOCAL file - not a network call; the card itself
# still references nothing external (the guard's zero-http grep proves
# it). Best-effort: a launch failure never fails the render. Suppressed
# when CI is set (GitHub Actions exports CI=true on every runner), and
# each branch is command-existence-gated so headless boxes skip silently.
if [ "$WINDOW" -eq 1 ] && [ -z "${CI:-}" ]; then
  launch_window "$OUT_DIR/latest.html" || true
elif [ "$OPEN" -eq 1 ] && [ -z "${CI:-}" ]; then
  CARD="$OUT_DIR/latest.html"
  case "$(uname -s)" in
    MINGW*|MSYS*|CYGWIN*)
      # //c dodges MSYS path-mangling; cygpath -w gives the Windows form.
      if command -v cmd.exe >/dev/null 2>&1 && command -v cygpath >/dev/null 2>&1; then
        cmd.exe //c start "" "$(cygpath -w "$CARD")" >/dev/null 2>&1 || true
      fi
      ;;
    Darwin)
      command -v open >/dev/null 2>&1 && { open "$CARD" >/dev/null 2>&1 || true; }
      ;;
    *)
      command -v xdg-open >/dev/null 2>&1 && { xdg-open "$CARD" >/dev/null 2>&1 & } || true
      ;;
  esac
fi

# ---- cleanup ----
# (exit status: the python render's - loud failure is correct here)
exit "$RENDER_RC"
