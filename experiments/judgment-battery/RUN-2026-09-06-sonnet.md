# Battery run: sonnet, 2026-09-06 (the first real run)

Candidate model: `sonnet` (Claude Sonnet, dispatched via the Agent tool with `model: sonnet`). 17 blind refuter dispatches, one per case; total subagent usage 1,313,903 tokens as reported by the harness per dispatch (this figure includes cache reads; the telemetry event rows for the same 17 dispatches record 128,989 tokens in+out and carry no cache fields, so the two numbers measure different things); per-dispatch wall time 26 s to 3.5 min. Files: `verdicts-sonnet.json`, `evidence-sonnet.md`.

## Raw score against the key as shipped

```
scored: 17/17
  confirmed real correctly (tp): 9
  refuted correctly        (tn): 0
  MISSED REAL              (fn): 1  <- case-09
  false alarm              (fp): 7  <- case-11, case-12, case-13, case-14, case-15, case-16, case-17
agreement: 53%
VERDICT: does not enter the judgment lane - missed real findings are invisible in live work.
```

## What the raw score means

Nothing, yet. Adjudicating every disagreement against the code at the pinned commit (`git show <pin>:<path>`, plus `git merge-base --is-ancestor <fix> <pin>` for the real cases) shows the key, not the model, is wrong in 8 of 17 cases. The run measured the battery.

## Adjudication

| case | key | sonnet | code at pin | disposition |
|---|---|---|---|---|
| case-01 | real | real | real | agree |
| case-02 | real | real | real | agree |
| case-03 | real | real | real | agree |
| case-04 | real | real | real | agree |
| case-05 | real | real | real | agree |
| case-06 | real | real | real | agree |
| case-07 | real | real | real | agree |
| case-08 | real | real | real | agree |
| case-09 | real | refuted | refuted | KEY DEFECT: pin c32c0ee6 is Phase 119 B, fix 9e1f03c is its ancestor; sonnet right |
| case-10 | real | real | refuted | KEY DEFECT: pin 11a2709 is Phase 121 B, fix d1db191 is its ancestor; sonnet WRONG (read the fix's comment about the old bug as current); agreement with the key is accidental |
| case-11 | refuted | real | refuted | sonnet FALSE ALARM: trusted the Phase 113 comment over the Phase 125 executed refutation (141c4e9) |
| case-12 | refuted | real | real | KEY DEFECT: assertion holds at the pin (README:36 says '24h cooldown ... version drift'; drift-check.sh has no cooldown); the Phase 130 disposition describes the later corrected tree; sonnet right |
| case-13 | refuted | real | real | KEY DEFECT: assertion holds at the pin (share-disable.sh:12-13 then :51-53; nothing between depends on ROOT); the 'detector source dies loud' mechanism arrived after f6967faf; sonnet right |
| case-14 | refuted | real | real | KEY DEFECT: true assertion (update.sh:909 read precedes the :914 DRY_RUN check); 'acceptable as-is' is a tolerability call; sonnet right |
| case-15 | refuted | real | real | KEY DEFECT: true assertion (commit.sh:19,21); tolerability call; sonnet right |
| case-16 | refuted | real | real | KEY DEFECT: true assertion (deploy.sh extension regex matches --config=deploy.yml); tolerability call; sonnet right |
| case-17 | refuted | real | real | KEY DEFECT: true assertion (share-disable.sh:9,60,83); tolerability call; sonnet right |

Sonnet agrees with the code at the pin in **15 of 17** cases. Its two errors share one shape: a comment in the file describing a bug (case-10: the Phase 121 fix's own comment; case-11: the Phase 113 comment) was read as the present mechanism. Among the 8 validly pinned real cases it missed none. At the CORRECTED pin for case-10 (abbe43fadbf0, where the bare truncating redirect is present at task-watchdog.sh:75) a fresh sonnet dispatch returned `refuted`: one missed real finding out of 10 real cases at correct pins, the class the README's bar disqualifies on. See the verification section below.

## Battery defects found by this run

1. **Mis-pinned real cases (09, 10):** the judge-at commit is the guard commit (Phase N B) rather than the pre-fix state; the fix (Phase N A) is already in it. Re-pin to `9e1f03c~1` and `d1db191~1` after verifying the defect is present there.
2. **Refuted cases that are not refutations (12-17):** 12 and 13 were adjudicated against a later tree than their pin; 14-17 are 'acceptable as-is' tolerability dispositions, which `README.md`'s own selection rule excludes. Only case-11 (Phase 125, refuted by execution) is a valid refutation. Replacements should come from mechanically refuted findings (Phase 114's set).
3. **Integrity leg gap:** `judgment-battery-integrity` cannot catch either class. A `fix_commit` field per real case lets it assert the pin predates the fix; a refuted adjudication should be required to cite an execution or a line at the pin.

Filed as an observation against `verdict-key.json` (2026-09-06). Until repaired, the battery licenses nothing: 8 valid real, 1 valid refuted.

## Verification (same day)

Every adjudication above was handed to two adversarial refuters on the session model (fable), one reproducing the git
facts and one arguing the key's side of the claim reading: 18 of 18 upheld the adjudication (17 at high confidence, case-11's
claim-reading lens at medium). One characterisation nuance from the case-09 refuters: the key's stated basis "repo state at
filing time" is LITERALLY satisfied by the pin, because the source observation was filed at its resolution commit; the root
defect is the battery's pinning convention (pin at filing time) applied to findings that were filed already resolved.

Re-pinned re-runs at the corrected pre-fix commits (6c2857075d10 for case-09, abbe43fadbf0 for case-10): sonnet returned
real / refuted; haiku returned real / real. Sonnet's case-10 miss is recorded in `evidence-haiku.md` with its mechanism text.
A haiku run over the valid subset is in `RUN-2026-09-06-haiku.md`.
