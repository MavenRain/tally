# tally M1 build log

## Stage A: citations, frozen replay and provisioning, 2026-09-06

Stage A implements the first five M1 gates against tally `262d643` and
vendor/tot `de61f4e094b82755478f214050d5b2258a466009`. The kernel PIN remains
`66b444fe8380c82f0a74093ffaa779371d014a9b`. No compiler, kernel, fixture or
frozen M0 gate source changed. The user's current instruction authorizes
staging this work; no commit was created.

The citation ledger now has 36 unique rows. Thirty-three terminal cells
start with VERIFIED, including the refuted acyclicity claim in C11.
S18, S19 and S20 remain UNVERIFIED and retain their later-stage obligations.
The five source HEADs match `dev/m1-source-pins.txt`; the source worktrees
were clean and the cited spans were read again. S15 uses the corrected
value-to-line order `execution_budget.rs:174,167,171`. C2's dated cluster
observation remains dated evidence. The repeated OCaml 5.2.1 bytecode
experiment returned min_int for min_int / -1 and zero for its remainder.

The entry helper groups complete row alternatives, checks their grammar
and derived count, and rejects terminal UNVERIFIED cells, including those
with obligation prose. T1-2 additionally checks both fence cells, all 15
Stage A selected VERIFIED cells, and the three remaining obligations.
Future obligation discharges must update the selected-row literal and
the remaining-obligation literal together.

The replay has independent Git metadata and frozen indexes, with local
object sharing. All four absolute roots, the two called helpers and the
path-bearing golden are rebound through sentinels. Each inverse map must
reproduce the committed bytes. Its builds, corpus output, initial interpreter
cache and timing files live under `tally-m1/replay` or `tally-m1/gate-out/m1`.
The inherited vendor gate can unset its cache override and use the user's
normal interpreter cache; the two write-escape assertions cover the live
tally sources and the M0 output root.

The provisioning script lives at `tally-m1/provision-toolchain.sh`. In the
Stage A state it prints exactly four waiting lines, exits zero, creates no
files and invokes no fetch or build. Later branches fetch each dependency
graph, build both images explicitly for v3, and record the toolchain,
platform-tools version, command, artifact digest and input digest. Local
command doubles exercise manifest arrival, artifact reuse, changed input,
corrupt images and stale version evidence. Actual future Rust dependency
fetches and image builds remain unexecuted because their manifests belong
to later stages.

### Validation

The frozen live M0 battery completed with exit 0 and all 20 distinct
`PASS-T0-*` markers. Its inherited vendor suite printed 398 PASS rows.
The M1 battery printed exactly five markers, T1-0 through T1-4, and exited
9 at the T1-5 placeholder. The embedded replay completed with exit 0 and
20 M0 markers. Both final timing samples reported `JITTER-OK`: the live
candidate/base warm median ratio was 0.992, and the replay ratio was 1.088,
within the unchanged 2.0 ceiling.

Both gate scripts and provisioning pass Zsh syntax checks. The frozen M0
battery has 275 lines and SHA256
`5966c5ab57685077658ad4f945b65f73aace094aa6c18008d9c55efc984e851b`,
identical to the committed source. Whitespace and authored-character checks
are clean. The mutation section below records the final observed results.

Evidence is collected under
`/Users/oobi/Documents/gpt7/tally-stage-a/checks/` and copied to
`/Users/oobi/Documents/tally-m1/stage-a-validation/` at close.

The first live M0 run completed all 398 inherited vendor checks and the
word-tower battery, then failed the unchanged timing validity check with
`JITTER-NOISY`. Its candidate/base median ratio was 0.911, below the 2.0
ceiling, but the sample variance was invalid. A focused rerun printed the
single line `FAIL-T0-SPEED-INVALID` and kept no speed table, so it reports no
ratio; its whole output is
`stage-a-validation/m0-live-timing-retry.log`. These failed observations
remain in the evidence; no threshold, sample count or timing source was
changed.

### Mutation evidence

All 24 measured scratch cycles passed: the 22 planned Stage A rows plus
regressions for obligation suffixes and multiline row selectors. The real
mutant replay completed with exit 0 and 19 M0 markers, then the unchanged
marker assertion rejected 19 against 20 with exit 1. Its positive control
used the preserved successful full replay. Six provisioning command-double
groups also passed, including the later-stage manifest/lockfile transition.
The six-column rows are appended to `dev/MUTATION-LOG.md`; the standalone
summary, traces and runnable harnesses are in `stage-a-validation`.

### Deviations

D112 through D119 reconcile executable contradictions found while building
the Stage A plan. D120 records the provisioning implementation and review
fixes; D121 records the explicit staging instruction and D122 records a
mutation-harness correction. D123 and D124 come from review round 1: the
watchdog relocation and the new root `.gitignore`. The numeric table
below is the second record required by M1-PLAN.md section 5.6.

| D-id | The plan or prior claim | What was found or done, with evidence |
|---|---|---|
| D112 | The design memo counted three absolute roots in the frozen battery. | There are four, including the design verdict. The plan's Stage A entry already records this correction; the replay copies and rebinds all four. |
| D113 | Literal T1-4 names a source key in a shell script and requires `.git` to be a directory. | The key violates the live G5 fence, while one pinned source is a linked worktree with a `.git` file. Resolve the reference tree by its pinned SHA; check root identity and HEAD with Git, validate five unique keys, and retain both fixture checks. |
| D114 | Archives alone supply the frozen replay. | M0 probes Git ancestry, indexes and diffs. Local shared clones with independent HEADs and indexes supply that metadata before archive extraction. Exclude metadata from the file-count floor. No checkout, commit or network operation occurs. |
| D115 | Rebinding only the battery isolates its output. | Called helpers have live absolute roots, the syntax golden has absolute filenames, and entry 13 also needs baseline corpus evidence. Copy that evidence; rebind helpers and golden with checked inverse maps. Bind temporary files, the initial cache and vendor measurement log to the replay. |
| D116 | The ROWS blacklist enforces the stated grammar and matches every obligation. | It admits empty alternatives, wildcards, anchors and extra groups, and exact UNVERIFIED matching misses obligation suffixes. Positively validate the grammar, reject line breaks, and match terminal UNVERIFIED prefixes. T1-2 owns positive status checks. |
| D117 | Abbreviated PIN and gitlink comparisons reject any one-digit mutation. | A changed suffix passes the abbreviations. Compare the full measured values and retain the independent submodule HEAD check. |
| D118 | Stage A requires a frozen unresolved count of three, but literal T1-2 omits it. | Add that assertion. A scratch S18 discharge requires both selected count 15 to 16 and unresolved count 3 to 2; later owning stages must make those changes together. |
| D119 | Twenty distinct replay markers suffice. | Retain the distinct-name check and also require exactly twenty printed marker lines, rejecting duplicates. |
| D120 | Provisioning must be idempotent and preserve v3 provenance. | Fetch each graph independently; record input and image digests and both version lines. Reuse checks all of them. The offline locked reuse probe falls back to an ordinary fetch so Stage E can update the rig lockfile when its manifest gains the runtime oracle. Command-double checks cover that transition, stale version evidence, and altered images or sources. Both image commands explicitly pass `--arch v3`. |
| D121 | Imported Stage A prose says no agent stages. | The user's current instruction is `Stage all changes`. Stage tally changes and the supporting Stage A artifacts explicitly; ignore generated `_build/` output. Stage B still waits for the user's Stage A commit. |
| D122 | The marker mutation should reach the 19-versus-20 marker assertion. | The first harness run instead failed the inherited diagnostic length check: its deeply nested temporary path made a short error 242 characters, above the existing 200-character bound. Preserve that raw failure and use a short scratch alias for temporary paths. Keep the runner and its assertions unchanged. The harness now retains raw red output and checks assertion reachability before reporting a pass. |
| D123 | The `gtimeout` watchdog check opened T1-1, the entry that replays the frozen battery. | M1-PLAN.md:646 puts that line at the end of the shared 5.1 environment block, where `gates-tally.sh:14` puts the M0 form. In the T1-1 position T1-0 prints `PASS-T1-M0-FROZEN` before the rig defect is named. Review round 1 moved the line into the prologue, after `GITLINK=` and before `rm -rf "$OUT"`. Evidence: `tally-m1/stage-a-validation/watchdog-prologue-mutation.log`. The mutant without the line exits 0 and writes `PASS-T1-M0-FROZEN` to `markers.txt` with no `gtimeout` on PATH; with the line kept the same block exits 1 on `FAIL-T1-NO-WATCHDOG` and writes no `markers.txt`. |
| D124 | The Stage A file table at M1-PLAN.md:801-812 lists ten paths and none is `.gitignore`, and M1-PLAN.md:1139-1140 scopes the commit to `dev/` only. | Stage A adds a root `.gitignore` with the single row `_build/`. The build output under `_build/` is generated, and without that row the worktree cannot equal the index for any check that reads untracked paths. The file holds no code and adds nothing under `bin/`, `lib/` or `test/`. Review round 1 records the departure here; D121 keeps its own subject, the staging instruction. |
| D125 | The Stage A restore cells describe the mutation cycles as they ran. | The 24 rows were recorded between 17:08 and 17:23 with the saved-baseline restore, before review round 1 added the `restore()` helper with its re-read assertion at 19:53. The cells claimed the assertion, while the paragraph above the table records that those runs had no assertion. M1-PLAN.md:728-729 binds every observed cell to text the builder observed. Review round 2 removes the re-read clause from all 24 restore cells and keeps the paragraph, which dates the helper. |
| D126 | `mutation-evidence.txt:603-604` shows the FOUND and EXPECT values of the derived count leg. | Those two lines hold the gate invocation and a blank line, and the 2,078-line file holds no `FOUND` or `EXPECT` text. Review round 2 reran the same mutation on scratch copies of the gate and the ledger under `zsh -x` and saved the trace to `tally-m1/stage-a-validation/derived-count-trace.log`. The red cell now cites that file for `EXPECT=3` at :29, `FOUND=2` at :32, `test 2 -eq 3` at :34 and exit 1 at :35. The new mutation row at the end of `dev/MUTATION-LOG.md` records the same cycle. |
| D127 | The `ledger-refreeze` row said the cycle restored the scratch ledger from its saved baseline. | The harness discharges scratch row S18, adds its id to `ROWS`, and keeps the expected count at 15 for the red leg (`tally-m1/stage-a-validation/run-mutations.py:258-273`). It never writes the ledger back: the green leg runs the same block with the expected VERIFIED count raised from 15 to 16 and the unresolved count lowered from 3 to 2, on the still discharged ledger. Review round 3 kept that design, which is the two-sided control D118 requires, and rewrote the restore cell of `dev/MUTATION-LOG.md:160` and of `tally-m1/stage-a-validation/mutations.md:15` to state it. The harness now emits the same text for that case. `mutations.json` holds no restore claim, so it needed no change. |
| D128 | The restore column of every mutation row named a restore of a mutated scratch file. | The `save()` row builder wrote one literal restore text for every result, while four cycles mutate no file: `ledger-derived-count`, `ledger-grammar` and `ledger-multiline-grammar` only change the `ROWS` argument of the scratch gate, and `provision-waiting` runs a copied script twice in a scratch home. Review round 3 gave the row builder a per-result restore field, set it for those four cases and for `ledger-refreeze`, and rewrote the four cells at `dev/MUTATION-LOG.md:157`, `:158`, `:159` and `:167`. The prose paragraph above the table now records that five rows run no restore. Evidence of the new row text on a scratch copy of the harness: `tally-m1/stage-a-validation/restore-cell-provenance.log`. |

### Handoff

T1-5 through T1-21 remain numbered `exit 9` placeholders. Stage B is the
next implementation slice and explicitly requires Stage A committed.
Its next work is the first-order intermediate representation and the six
compiler gates. Commit text is in `tally-m1/stage-a-commit-msg.txt`.

## Stage A review round 1 (2026-09-06)

An adversarial review of the staged Stage A slice kept seven findings. Each
one and its repair follows. No `M1-PLAN.md` line was changed, and no ledger
or mutation row was edited except the rows a finding names.

| id | finding | repair |
|---|---|---|
| L6-2 | This log claimed a focused-rerun jitter ratio of 0.979. No artifact on disk holds that number. `stage-a-validation/m0-live-timing-retry.log` holds one line, `FAIL-T0-SPEED-INVALID`. | The paragraph above now states only what that log shows: the rerun kept no speed table and reports no ratio. The 0.911 ratio of the first live run keeps its speed table and stays. |
| L1-1 | The `gtimeout` watchdog check opened T1-1, so T1-0 could print `PASS-T1-M0-FROZEN` before a missing watchdog was named. M1-PLAN.md:646 puts the line in the shared environment block. | Moved the line in `dev/gates-tally-m1.sh` to the prologue, after `GITLINK=` and before `rm -rf "$OUT"`. Gate text changed, so deviation D123 and a new `PASS-T1-M0-FROZEN` mutation row record it. The mutation ran on scratch copies; evidence is `stage-a-validation/watchdog-prologue-mutation.log`. |
| L2-1 | Stage A rewrote column two of ledger rows C10 and C11, not only the status cell. M1-PLAN.md:803 and M1-PLAN.md:5102-5104 limit Stage A to the status cell. | Restored column two of `dev/CITATION-LEDGER.md` C10 to `transaction byte cap (drives the M1+ deploy pipeline)` and C11 to `acyclic call-graph verifier rule (the recursion-to-trampoline strategy depends on it)`. Both status cells stay character for character as M1-PLAN.md:5122-5123 gives them, so no new departure appears. |
| L5-1 | The new root `.gitignore` sits outside the plan file table and outside the `dev/`-only commit scope, with no deviation row. | Added deviation D124, which names both plan lines and the reason. D121 keeps its own subject. |
| L4-2 | `stage-a-validation/check-provision.py` isolated its paths with two unchecked `str.replace` calls. A silent miss would run the mock harness against the live `tally` and `tally-m1` trees. | Four assertions after the substitutions prove both scratch roots are present and both live roots are gone, before the script is written. |
| L3-2 | Four `PASS-T1-CITATIONS` rows carried an empty `red (observed)` cell. | Filled the four cells in `dev/MUTATION-LOG.md` from `stage-a-validation/mutation-evidence.txt` lines 177, 229, 552 and 603-604. Three cells carry the matched ledger line; the fourth carries the derived-count leg, which reds with no output on FOUND 2 against EXPECT 3. |
| L4-4 | `run-mutations.py` restored mutated files from saved bytes and never re-read them, so no Stage A row could claim byte identity. | Added a `restore()` helper that writes the saved bytes and asserts the file re-reads equal to them, and routed all twelve restore sites through it. The Stage A restore column now names the re-read. `stage-a-validation/restore-assert-check.log` holds the positive control and a negative control that raises `AssertionError`. |

Repairs outside the repository: `tally-m1/stage-a-validation/check-provision.py`,
`tally-m1/stage-a-validation/run-mutations.py`, and two new evidence files,
`tally-m1/stage-a-validation/watchdog-prologue-mutation.log` and
`tally-m1/stage-a-validation/restore-assert-check.log`.

## Stage A review round 2 (2026-09-06)

Round 2 re-reviewed the whole staged slice, with the round 1 repairs as the
first suspects. Four findings were kept and all four are repaired. Two touch
repository files, two touch files outside every repository.

| finding | defect | repair |
|---|---|---|
| L3R2-1 | All 24 Stage A restore cells in `dev/MUTATION-LOG.md` claimed a re-read-and-assert restore, while the paragraph above the table records that those runs used the saved-baseline restore with no assertion. | Rewrote the restore cell of all 24 rows to `Restore only the scratch copy from its saved baseline`. The paragraph is unchanged. Deviation D125. |
| L3R2-2 | The derived count row cited `mutation-evidence.txt:603-604` for FOUND 2 against EXPECT 3, values that appear nowhere in that file. | Reran the same mutation on scratch copies of `dev/gates-m1-entry.sh` and `dev/CITATION-LEDGER.md` under `zsh -x`, saved the trace to the new file `tally-m1/stage-a-validation/derived-count-trace.log`, and rewrote the red cell to cite the evidence that exists: the silent non-zero exit with no marker at `mutation-evidence.txt:603-604`, and `EXPECT=3`, `FOUND=2`, `test 2 -eq 3`, exit 1 in the new trace. Added one mutation row for the rerun. Deviation D126. |
| L4-R2-1 | The usage string of `tally-m1/stage-a-validation/check-provision.py:9` named `provision_checks.py`, a file that does not exist. | Changed the string to `check-provision.py`. No logic changed, so no deviation row. |
| L6R2-1 | The round 2 brief asked for lines 1-33 of `dev/gates-tally-m1.sh` in the hand reproduction of the watchdog line, three lines short of `mark PASS-T1-M0-FROZEN` at :36, so the stated normal-PATH expectation could not be met. | The gate is correct and unchanged. Corrected the range to lines 1-36 at `tally-m1/stage-a-review-r2-brief.md:196`. |

Repairs outside the repository: `tally-m1/stage-a-validation/check-provision.py`,
`tally-m1/stage-a-review-r2-brief.md`, and one new evidence file,
`tally-m1/stage-a-validation/derived-count-trace.log`. No file under
`stage-a-validation/` was overwritten, and `M1-PLAN.md` was not edited.

## Stage A review round 3 (2026-09-06)

Round 3 re-reviewed the whole staged slice, with the round 2 repairs as the
first suspects. Four findings were kept and all four are repaired. One touches
a repository file only, one touches a repository file and a companion file,
and two touch files outside every repository.

| finding | defect | repair |
|---|---|---|
| L4R3-1 | The `ledger-refreeze` row claimed a restore of the scratch ledger, and its green cell followed a raised gate count, not a restore. The harness runs no restore in that case. | Kept the two-sided design and stopped the false claim. Rewrote the restore cell of `dev/MUTATION-LOG.md:160` and of `tally-m1/stage-a-validation/mutations.md:15` to state that the scratch ledger stays discharged and that the green leg raised the expected VERIFIED count from 15 to 16 and lowered the unresolved count from 3 to 2. Deviation D127. |
| L3R3-1 | The derived count red cell attributed the figure 2 to `mutation-evidence.txt:603-604`, two lines that hold the gate invocation and a blank line. | Deleted that clause from the parenthetical at `dev/MUTATION-LOG.md:157`. The citation now supports only the silent non-zero exit with no marker. The FOUND and EXPECT facts stay in the next sentence, cited to `stage-a-validation/derived-count-trace.log:29,32,34,35`. |
| L4R3-2 | `save()` wrote one hardcoded restore text for every row, so four cycles that mutate no file still claimed a restore. | Added a per-result restore field to `record()` and `save()` in `tally-m1/stage-a-validation/run-mutations.py`, set it for the three ROWS-argument cycles, for `provision-waiting` and for `ledger-refreeze`, and rewrote the four cells at `dev/MUTATION-LOG.md:157`, `:158`, `:159` and `:167`. Deviation D128. |
| L5R3-1 | The `stage-a-validation/README.md` inventory omitted the three review evidence logs on disk. | Added one sentence that names `watchdog-prologue-mutation.log` and `restore-assert-check.log` as the round 1 evidence and `derived-count-trace.log` as the round 2 evidence. Prose only. |

Repairs outside the repository: `tally-m1/stage-a-validation/run-mutations.py`,
`tally-m1/stage-a-validation/mutations.md` (the one row L4R3-1 names), and
`tally-m1/stage-a-validation/README.md`, plus one new evidence file,
`tally-m1/stage-a-validation/restore-cell-provenance.log`. No existing evidence
file was overwritten, no gate text changed, and `M1-PLAN.md` was not edited.

## Stage B: first-order compiler and battery handover, 2026-09-06

Stage B builds on committed Stage A `ca95f754b99f048cbeed578ce5eaea834508b617`.
The kernel PIN, vendored gitlink, frozen M0 battery and seven-row M0 deny
table remain byte-identical. The citation entry check passed for all 15
Stage B rows; this stage discharges no citation obligation.

The nine module pairs in `lib/cterm` implement reachable-global collection,
ANF, unary closure conversion, dense tags, explicit continuations, layout,
source declarations and independent structural verification. Known non-tail
calls retain native edges. Known tail calls dispatch through closure tags;
multi-argument tails use cached unary adapters that copy the target body,
so they introduce no native wrapper call. A two-argument tail-recursive
control returns `3u64` with zero native edges and zero continuation pushes.

`tally build` supports the planned inspection and execution flags, plus an
explicit `--arena-limit` argument. `check` retains its original implementation.
The build path preserves the existing bootstrap and type-checking item fold,
then continues from checked kernel definitions rather than executing source
effects. Its library depends only on `tot.kernel`. The reference machine
evaluates final Cterm blocks independently of the existing interpreter; only
canonical kernel word operations and result rendering are shared. Compiler
construction never calls the interpreter.

The declaration reader preserves source positions and quoted multiline
data. Duplicate declarations, malformed names and decimal overflow return
typed errors. The default height is 1 and the target-bound map is empty.
Stage E still owns undeclared call-target rejection. Layout compares no
target limit: an optional caller limit is separate from future target checks.

Review repaired tail-call lowering, an executable-directory lookup failure
in the differential runner, unsupported hand-constructed primitive IR, and
incorrect constructor facts when verifying a mixed-arity match. The verifier
checks closed slot flow, dense and bounded tags, arities, captures, primitive
admissibility, impossible-constructor defaults, and string-blob contents.

The following deviations are recorded inline here and in the numeric table.
D129 selects the normative 18-row library manifest. D130 shares the test
reference source through a generated binary module. D131 omits the upstream
IO-only main epilogue on build. D132 resolves the two verification print
forms and strengthens content checks. D133 supplies the missing gate prelude,
help and freshness checks. D134 and D135 repair scope-gate contradictions.
D136 exposes the caller arena limit. D137 records the available recursion
fixture syntax. D138 and D139 make layout and slot representation explicit.
D140 records the transient application carrier and its mandatory rejection.
D141 records the source declaration extraction API. D142 maps outdated
mutation instructions to the actual gate consumers without claiming compiler
source mutations. D143 records the observed pre-change timing failures.

### Validation

The complete live M1 battery printed exactly 11 distinct markers, T1-0
through T1-10, and exited 9 at the unchanged Stage C placeholder. The
frozen replay returned all 20 distinct M0 markers with no FAIL rows; its
inherited vendor suite returned 398 PASS rows. The final replay timing
sample was valid. Both cold and default Stage B builds completed, with
the library manifest matching all 18 source paths.

All ten planned differential fixtures agreed, with exact coverage of all
eight Eterm constructors. All four negative fixtures returned their own
typed errors. Ten additional differential controls passed against the
final compiler, including partial application, overapplication, nested
captures, unreachable globals, value reuse and unary/multi-argument tails.
The 62 layout/verifier assertions, 15 declaration checks and 27 CLI/harness
checks passed. Unsupported hand-built primitive IR rejects, while the
previously rejected mixed-arity match now passes. The CLI/harness report
predates the final verifier refinement; the complete battery and additional
ten differential cases ran after that refinement.

Eleven source-file scope/manifest mutations and eleven pipeline gate
controls rejected at their intended checks and returned green after
restoration. The latter use saved real output or command doubles, not
compiler source changes. Their separate EMatch membership control also
reaches the membership assertion. All recorded restores were checked.
The frozen M0 source and both immutable pin values remain unchanged.

Failed observations retained: the initial pre-change live battery failed
DIV-MEMO elapsed time; its retry failed jitter validity; and the first
workspace Stage B run encountered a concurrent Dune build lock. Final
builds were serialized. The complete final replay and all implemented
Stage B gates passed without changing any inherited timing criterion.

Evidence lives in `tally-m1/stage-b-validation/`, copied from the workspace
checks with build directories and generated binaries excluded. Raw failed
runs remain beside successful runs. `stage-b-commit-msg.txt` is outside the
repository. The mutation table records observed failure and restoration
statuses; command doubles and assertion replays are explicitly distinguished
from source-file mutations.

### Deviations

| D-id | The plan claim | What was found or done, with evidence |
|---|---|---|
| D129 | The manifest prose includes every non-vendored source, but T1-7 excludes bin and test. | Follow T1-7 and commit exactly 18 library rows, one for each of the nine module pairs. The gate diffs both directions; extra-source and missing-row mutations both reject. |
| D130 | The CLI runs the reference machine kept in the test executable, without another library file. | `bin/dune` generates `cterm_reference.ml` from `test/cterm_ref.ml`. The shared source has an executable-name guard; its library functions do not run the harness. No generated file is tracked and the compiler library keeps only its kernel dependency. |
| D131 | The build path can reuse `Run.script` wholesale. | Its upstream main epilogue rejects an ordinary word-valued main even with execution disabled. Build retains Lexer, Parser and the `Run.item ~exec:false` fold, then compiles the checked globals without the IO-only epilogue. The check implementation is unchanged. |
| D132 | Step 5 requires `VERIFY-OK`, while normative T1-8 matches `verify: ok ` and omits the prose's edge checks. | `--verify` emits the latter line with computed counts; `--dump-cterm` emits `VERIFY-OK` plus layout. T1-8 passes both and asserts real edges on the three named fixtures. T1-9 asserts the exact eight constructor names, including EMatch, rather than accepting any eight strings. |
| D133 | The normative T1-5 body lacks the prose's help/freshness checks and sets no tally prelude path. | Add explicit vendored TOT_PRELUDE, cold-directory absence, and help checks for both check and build. Cold and default builds pass. Both truncated-help controls and the stale-directory control reject and restore green. |
| D134 | T1-6 requires a nonempty deny-hit set before Stage C creates the only allowed target module. | Empty Stage B deny hits are valid. Remove that contradictory floor while retaining source and scope floors, exact table shapes, actual pattern execution, and residual rejection. Deny-content and forbidden-constant source mutations prove the loop still rejects. |
| D135 | The four-row scope inventory omits the bin dune file it changes, and `rg -v ... || true` also accepts malformed filter patterns. | Add `bin/dune` to the existing Cterm row, still four rows, and accept only search statuses 0 and 1. Bad pattern and bad filter controls both fail. No general directory is admitted. |
| D136 | Section 8.5.2 gives the arena negative a caller-supplied ceiling, but the CLI and gate supply none. | Add `--arena-limit N` and pass 0 only to the arena negative in T1-10. Its nonzero allocation returns `Cerr_arena_over`; ordinary builds use no ceiling. This introduces no target number or target-parameter read. |
| D137 | The fixture roster requests mutual recursion through separate first-order definitions. | The pinned surface has neither a mutual-definition block nor forward global references. `cterm-mutual.tot` uses a two-state structural recursive function instead; it retains non-tail native edges and matches the interpreter. It does not prove a two-global cycle. |
| D138 | The design multiplies allocation by an unspecified trampoline depth bound, while the stage supplies no such bound. | `arena_words` is a static one-visit footprint over code and continuation bodies, taking the largest switch arm. It does not bound dynamic recursion or repeated execution. Arithmetic overflow is checked, and caller ceiling equality and exceedance have separate tests. |
| D139 | The design renumbers closure inputs to fixed slots and represents a field by an integer alone. | Each code and continuation carries explicit parameter/capture slot maps; captures remain sorted by original slot, and layout computes the actual high-water slot. Fields privately carry index and constructor arity, so creation and verification reject out-of-range projections. Future emission must honor these maps. |
| D140 | The Cterm sketch has no intermediate unknown-call binding. | Defun temporarily emits `RApply`; Tramp eliminates it, and both Verify and the reference machine reject any survivor. This represents non-tail unknown applications before continuation splitting without permitting them in a validated program. |
| D141 | Decl.parse reads a block, but the source syntax and block extraction are unspecified. | Raw `entry-height` and `depth-bound` lines are recognized outside quoted strings and replaced by equal-length spaces. `Decl.source` returns the stripped source and parsed declarations; `Decl.parse` remains a standalone strict block reader. Fifteen parser controls include quote escapes and multiline data. |
| D142 | Several mutation rows refer to older per-fixture driver files or a POS array absent from normative T1-9. | Eleven mutations change isolated scope/manifest source files. Eleven further controls replay the current exact assertions or use a driver double, with a supplemental EMatch membership check. They establish failure reachability and byte restoration, and are not described as compiler source mutations. |
| D143 | Stage B entry expects a complete new live M0 green. | The first pre-change run failed inherited DIV-MEMO timing at exit 0 and 24 seconds. The retry passed the functional word tower but failed JITTER-NOISY; its ratio was 1.079, below the unchanged 2.0 ceiling. Preserve both runs and their raw artifacts. No timing threshold, watchdog, sample count or frozen source was modified. |

### Handoff

All Stage B repository changes are prepared for staging in one commit.
T1-11 through T1-21 remain exit-9 placeholders. Stage C starts after the
user commits Stage B and owns target parameters, emission, and target limits.
This is the first compiler stage for which live M0 entries 15 and 16 are
expected red: Cterm names violate the retired word fence and library sources
violate the former zero-source count. Both reds were observed separately.
T1-1 is the frozen M0 fence from this stage onward. No commit is created here.
