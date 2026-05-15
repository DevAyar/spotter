---
name: bash-safety
description: Before running recursive scans (find, grep -r, wc on globs, project-wide file counts) or backgrounded bash, apply noise-path excludes, a timeout, a maxdepth where knowable, and a wait/kill discipline for background processes. Prevents zombie tasks from unbounded scans hitting .git/.godot/node_modules/build caches.
---

# bash-safety

A behavioral skill. The manager and helpers apply it whenever they're about to shell out to a recursive scan or a backgrounded command.

## When this applies

Any of the following triggers it:

- `find` at project scope (anything that walks below the cwd).
- `grep -r` / `grep -R` / `rg` over the project tree.
- `wc` / `ls -R` / any pipeline counting matches across a glob.
- A command that could plausibly take **>5 seconds**.
- Any `&` to background a process.

If the scope is a single known file or a directory of <10 files, this skill does not apply.

## Noise paths — always exclude

Recursive scans must `-prune` (or `--exclude-dir`) the following before counting / printing:

```
.git/  .godot/  .import/  node_modules/  target/  build/  dist/  out/
.next/  .nuxt/  __pycache__/  .pytest_cache/  .venv/  venv/  .idea/
.vscode/  coverage/  .coverage  vendor/
```

A scan that doesn't exclude these will walk Godot's `.import` cache or `node_modules`'s tens of thousands of files and either hang or burn minutes.

**Naked (don't):**

```bash
find . -name "*.gd" | wc -l
```

**Safe (`find -prune` form):**

```bash
find . \( -path './.git' -o -path './.godot' -o -path './.import' \) -prune \
       -o -name "*.gd" -print | wc -l
```

**Safe (`grep` form):**

```bash
grep -rn --exclude-dir={.git,.godot,.import,node_modules,build,dist,out,target,.next,.nuxt,__pycache__,.pytest_cache,.venv,venv,.idea,.vscode,coverage,vendor} \
     "pattern" .
```

## Timeout discipline

Wrap any scan whose runtime isn't bounded by `-maxdepth` or a known small input set:

```bash
timeout 30 find . ... -print | wc -l
```

Fail-fast over hang-silently. If a command genuinely needs longer (e.g. a full repo backup, a bulk download), raise the timeout explicitly **and** leave a one-line comment saying why. Omitting the timeout entirely is what produces zombie tasks.

## Maxdepth discipline

If the recursion shouldn't go past N levels, set it. Cheaper than excludes and faster:

```bash
find . -maxdepth 3 -name "CLAUDE.md"
```

Common shapes:
- "What CLAUDE.md files exist in this monorepo's top three packages?" → `-maxdepth 3`
- "What package.json files exist?" → `-maxdepth 4` (root + one nesting level for monorepos).

## Background bash discipline

`&` must be paired with **one** of:

- **PID capture + wait:** `cmd & PID=$!; …; wait $PID` — for "run two things in parallel, then continue".
- **Timeout + kill:** `cmd & sleep 30; kill $! 2>/dev/null` — for fire-and-forget where you want a hard ceiling.
- **`disown`** — only if the process is truly fire-and-forget **and** has its own internal timeout / exit condition.

Never naked `&` without one of those. Otherwise zombies accumulate in the task panel and the next command's output gets harder to read.

## What this skill does not do

- **Doesn't block legitimate slow operations.** A genuine full-repo scan with a justified timeout is fine; document the why in the surrounding commit message or comment.
- **Doesn't replace a live task-watchdog** (the runtime monitoring layer is separate, lives outside `.claude/skills/`).
- **Doesn't apply to bounded single-file ops.** `grep "x" foo.md` doesn't need any of this.

## Notes

Behavioral, not mechanical. There is no hook that rewrites or blocks bash commands — the rule lives in the manager's discipline. If a manager violates this skill 2+ times in a session, the next `monitoring-helper` pass surfaces the pattern.
