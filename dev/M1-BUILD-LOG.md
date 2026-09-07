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
| D144 | Step 6 fixes usage at the literal exit 2, and `bin/tally.ml:33-34` states that usage is printed on stderr while stdout carries only a rendered decision. | Review round 1, finding L4-1: a top-level `--help` clause printed usage on stdout and returned 0. The clause is deleted, so every argv shape that is not `check` or `build` reaches the catch-all: usage on stderr, exit 2, empty stdout, observed `exit=2 stdout_bytes=0 stderr_bytes=270`. T1-5 now captures stderr, asserts `test "$hst" -eq 2` and `test ! -s "$OUT/help-stdout.txt"` before the two word checks, which still read `$OUT/help.txt`. Mutation `c1-help` puts the clause back and reds at `test 0 -eq 2` (`tally-m1/stage-b-validation/review-r1-mutations/`). |
| D145 | The Cterm sketch expects one switch block per source match. | Review round 1, finding L2-1: `anf.ml:79` normalizes every arm with the SAME continuation and `anf.mli:4-5` has no join constructor, so switch blocks grow as `2^N-1` in the number of let-bound matches. Measured 1, 3, 7, 15, 255, 4095, 32767 for N of 1, 2, 3, 4, 8, 12, 15, with frame slots at `6*(2^N-1)` on that shape and wall clock under 0.01 s at N of 15 (`tally-m1/stage-b-validation/review-r1-anf-growth.md`). A join binder changes the Anf and Clos block types and the lowering, which Stage B does not own, so the size is PINNED instead: T1-8 asserts max `switch-defaults` at most 4 and max `frame-slots` at most 42, the measured maxima on the ten positives. Mutation `c2-regrowth` reds at `test 7 -le 4`. |
| D146 | `Verify.program` bounds every local slot by the frame its code records. | Review round 1, finding L3-2: continuation bodies were verified with `frame = None`, so `verify.ml:23-24` skipped the bound for every continuation. `kont_frame_slots` joins the kont record, `layout.ml` measures it exactly as codes get theirs, from `kont_result :: kont_capture_slots` joined with the body high-water, and `verify.ml` passes it plus a nonnegative check. Six assertions in `tally-m1/stage-b-validation/review-r1-kont-frame-selftest.ml` and its `.txt` output pass, including the mirrored `undersized continuation frame`. Mutation `c3-kont-frame` stores 0 and reds with `Cerror.Cerr_verify <kont 0>: local slot exceeds the recorded frame`. |
| D147 | One `Cerror.t` constructor per rejection (`design-cterm.md:414-416`), with `Cerr_arena_over` exactly the computed footprint above the parameter D2 supplies (`design-cterm.md:431`). | Review round 1, finding L2-3: seven sites raised `Cerr_arena_over` and six were not the footprint. `Cerr_slot_overflow` now carries the slot counters in `anf.ml`, `clos.ml` and `tramp.ml` plus the layout addition overflow, `Cerr_host_capacity` carries the read-only blob capacity and `Cerr_usage` carries a negative caller limit; `layout.ml` no longer hard-codes one constructor in its shared helper. None of the three is reachable from the 14 fixtures, which is the unreached-constructor deviation the rules at `M1-PLAN.md:1606-1609` require a row for. T1-10 still reads four distinct tokens, `Cerr_arena_over`, `Cerr_host_io`, `Cerr_host_string` and `Cerr_unary_numeral` (`tally-m1/stage-b-validation/review-r1-live-legs.log`). |
| D148 | `--verify` runs `Verify.program` explicitly (`M1-PLAN.md:1310`). | Review round 1, finding L3-1: both `--verify` and `--dump-cterm` called `Verify.summary` alone, the counter that `verify.mli:8-9` warns is not a verified fact, and the printed line was true only because `pipeline` verifies on every build. Both branches now bind `middle (Verify.program program)` before they print, so the T1-8 assertion cannot become vacuous if pipeline verification ever turns conditional. The printed bytes are unchanged and T1-8 stays green. |
| D149 | Any change to a committed gate body is a deviation with its own row AND a fresh mutation row, and `M1-PLAN.md:1582-1584` lists three compiler-source mutations for T1-8. | Review round 1, finding L5-1: the staged T1-8 rows were assertion replays and the staged T1-10 `--arena-limit` injection had no mutation row at all. All four now run on a scratch copy of the tree: `Tramp` routing a non-tail `RCallKnown` through the trampoline, read on `cterm-known-call` and again on `cterm-selfrec`, `Verify` printing `callknown-edges` as a constant zero, and the T1-10 leg with the injection removed. Every red is quoted in `dev/MUTATION-LOG.md` and traced in `tally-m1/stage-b-validation/review-r1-mutations/`. D142 is unchanged and still describes the original eleven controls. |
| D143 | Stage B entry expects a complete new live M0 green. | The first pre-change run failed inherited DIV-MEMO timing at exit 0 and 24 seconds. The retry passed the functional word tower but failed JITTER-NOISY; its ratio was 1.079, below the unchanged 2.0 ceiling. Preserve both runs and their raw artifacts. No timing threshold, watchdog, sample count or frozen source was modified. |

### Handoff

All Stage B repository changes are prepared for staging in one commit.
T1-11 through T1-21 remain exit-9 placeholders. Stage C starts after the
user commits Stage B and owns target parameters, emission, and target limits.
This is the first compiler stage for which live M0 entries 15 and 16 are
expected red: Cterm names violate the retired word fence and library sources
violate the former zero-source count. Both reds were observed separately.
T1-1 is the frozen M0 fence from this stage onward. No commit is created here.

## Stage B review round 1 (2026-09-07)

Seven kept findings, all repaired in place. Build and test after every OCaml
edit: `dune build` exit 0, `zsh dev/test-tally.sh` exit 0 (with
TOT_PRELUDE=vendor/tot/stdlib/prelude.tot, as the gate exports). The three
legs that changed run green on the live tree:
`tally-m1/stage-b-validation/review-r1-live-legs.log`. New deviations D144
to D149 and seven mutation cycles are recorded above and in
dev/MUTATION-LOG.md.

- L2-1, ANF copies the continuation into every match arm. `anf.ml:79` hands
  the same `k` to each arm and `Switch` is terminal in `anf.mli`, so switch
  blocks are `2^N-1` in the number of let-bound matches (measured 1, 3, 7,
  15, 255, 4095, 32767). Repair: a join binder is a Cterm type change Stage
  B does not own, so T1-8 now PINS the size, max `switch-defaults` at most 4
  and max `frame-slots` at most 42, the measured maxima on the ten
  positives. D145, mutation `match-arm-regrowth`, evidence
  `review-r1-anf-growth.md`.
- L5-1, the T1-8 mutation record was assertion replays only and the T1-10
  `--arena-limit` injection had no row. Repair: the three compiler-source
  mutations of `M1-PLAN.md:1582-1584` plus the missing arena-limit row now
  run on a scratch copy, four rows in dev/MUTATION-LOG.md. D149.
- L4-1, an undocumented `--help` clause printed usage on stdout and exited
  0, against the exit 2 usage rule. Repair: the clause is deleted; T1-5 now
  asserts exit 2 and empty stdout before its two word checks. D144,
  mutation `help-clause-restored`.
- L3-2, continuations were verified with `frame = None`, so no continuation
  body was bounded. Repair: `kont_frame_slots` joins the kont record,
  `layout.ml` measures it and `verify.ml` enforces it, plus a nonnegative
  check. D146, mutation `kont-frame-zero`, evidence
  `review-r1-kont-frame-selftest.ml` and `.txt`, six checks, zero failures.
- L2-3, `Cerr_arena_over` carried six causes that are not the arena
  footprint. Repair: `Cerr_slot_overflow`, `Cerr_host_capacity` and
  `Cerr_usage` join `Cerror.t` and take those sites, and `layout.ml` stops
  hard-coding one constructor in its shared helper. T1-10 still reads four
  distinct tokens. D147.
- L3-1, `--verify` and `--dump-cterm` printed a `Verify.summary` count
  without calling `Verify.program`, so the gate assertion was true only by
  way of `pipeline`. Repair: both branches bind `Verify.program` before they
  print. Output bytes unchanged. D148.
- L2-4, eager `Option.fold ~none:` arguments at `tramp.ml:100` and
  `decl.ml:15-17` built a value on every accepted input. Repair: both
  `~none:` arguments are thunks applied at the end, with a comment naming
  the cost. Behavior and messages unchanged, so no D-row.

Repo state note: this review began against a worktree whose HEAD is
`d339e81 M1 Stage B ...` with a clean tree and an empty index, not the
45-path staged slice the review brief assumed. Every repair above is
therefore an uncommitted worktree edit on top of the committed Stage B
slice.

## Stage C leaf emission and independent loader (2026-09-07)

Stage B was committed at `d339e81` before this work began. Concurrent
Stage B review fixes were merged from the live checkout, including the
continuation-frame bound, explicit reporting-time verification, typed
resource errors, lazy fallback evaluation, help contract, and growth checks.
Their source and evidence entries are preserved above.

The Stage C entry gate accepted this 25-row selection:

```
C_ROWS='C1|C2|C3|C4|C5|C6|C7|C8|C9|C10|C11|C12|F-SPEC|F-EMIT|F-EMIT-SHIFT|S1|S2|S3|S4|S5|S6|S7|S15|S16|S17'
```

Implemented: the target library and citation parser, byte encoder, label
linker, ELF writer and symbols, manifest, leaf register allocation,
frame/arena/callgraph checks, guarded arithmetic, static-string logging,
CLI output, loader rig, second-author source and provisioned image.
`frame_reserve` is zero and each build prints it. The loader's actual V3
alignment requires 64-byte frame adjustments. No C1 depth constant was
introduced. S18, S19 and S20 remain UNVERIFIED.

This is an incomplete Stage C slice. Native calls, closures and continuation
execution reject with `Row_unverified S18` before instruction selection.
Constructor payload allocation/projection and dynamic string construction
also remain unsupported. Nullary constructors, switches, word arithmetic,
static string aliases, and leaf spills are supported. `--emit-none` retains
the Stage B pipeline; the emission path seeds its own logging and signed
division/remainder names. The signed emitter follows the Stage C semantics,
not the older unsigned interpretation of sign tags in the M0 word evaluator.

### Validation

The merged tree builds with zero errors and warnings. The reproducible
`dev/check-stage-c.py` run records 103 distinct emitted machine images,
seven source fixtures, 145 commands with their expected statuses, and 177
passing assertions. It also reruns the ten Stage B differential fixtures.
The image corpus covers all word widths, signed edges, masking, comparison
switches, full-width literals and register spill pressure. The exact S17
sixteen-byte floor is checked before being loaded independently.

The target tests reject missing or unverified required rows, malformed and
duplicate ledger rows, unknown targets and a forged S18 status. They check
24 independent Murmur vectors. All 100 opcode entries were compared against
the pinned source. Review found and fixed a missing C5 requirement and
output paths that could alias a source or ledger. Both image and manifest
destinations now undergo identity checks before temporary files are written.

The rig's six tests pass. The second-author program builds with
`cargo-build-sbf 2.3.13`, platform-tools v1.48, and `--arch v3`; the strict
loader runs its 1096-byte image and returns zero. A mismatched expectation
returns exit one. Its image SHA256 is
`34e3a0c99d91102a0560b0c48e3dbfdf1876a840796f20ffd6b41144b5b50f21`.

The scoped T1-2 through T1-12 run passes all eleven entries, then T1-13
returns exit one with OPEN-T1-EMIT for S18. The T1-14 and T1-15 leg bodies
were rerun by hand at review round 1 against image bytes rebuilt by
`_build/default/bin/tally.exe build -o smoke-log.so test/fixtures/smoke-log.tot`
and read by `rig/target/debug/loadcheck --headers`, which produced the
`hdr-ours.txt`, `hdr-strict.txt`, `hdr-syscall.txt` and `hdr-sa.txt` captures.
Both bodies exit zero. Those captures, the `provenance.txt` reads and the
loadcheck digest are in
`tally-m1/stage-c-validation/review-r1-legs-and-mutations.log`, whose working
copies stay under `tally-m1/scratch/stage-c-review/fix2/legs/`. Neither entry
is reachable in a full battery while row S18 is UNVERIFIED: the script is
`set -e` and T1-13 exits at OPEN-T1-EMIT before them, so this is a scoped
rerun of the leg bodies and not a battery pass. It does not bypass the
full battery's fail-fast behavior or open Stage D.

The final clean-source full retry stopped at T1-1 with
FAIL-T0-SPEED-INVALID and JITTER-NOISY. Its measured ratio was 0.955,
inside the unchanged performance ceiling, but the sample-validity check
failed. The preceding clean-source retry had the same validity failure.
There is no claim of a complete green full battery.

Retained unsuccessful observations: the first full replay obtained all
twenty M0 markers but failed its source-mtime fence because this build
session was still editing the workspace; the next full replay failed
FAIL-T0-SPEED-INVALID. Neither frozen source nor timing thresholds changed.
The first second-author attempt used an unsuitable host runtime and failed
with InvalidSyscall; its failed log is retained beside the corrected run.

### Cost report

The cited report inputs are C9's 200000 default and S15's base 100,
invocation 1000, and bytes-per-unit 250. Logging the five-byte message
`tally` has a cited syscall charge of max(100, 5), or 100. The rig's
observed instruction counts are separate interpreter observations, not a
compute-unit certificate or an end-to-end cost bound.

### Deviations

| D-id | The plan claim | What was found or done, with evidence |
|---|---|---|
| D150 | The complete Stage C closes all native and closure paths. | Deliver the independently validated leaf slice while S18 stays unratified. Native-call and closure/continuation emission remains a typed rejection; payload constructors and dynamic strings are explicitly unsupported. No Stage D entry is claimed. |
| D151 | The target constructor unconditionally needs the S18 convention. | The plan also permits leaf emission without S18. The abstract leaf parameter token checks every consumed row, including C5. Review round 1 replaced the hard-coded rejection this row first recorded: `require_calling_convention` now reads the ledger's own S18 cell, which OQ-3 makes the single discharge point, so the capability is closed exactly while that cell is not positively VERIFIED and the plan's discharge edit reaches the compiler instead of changing nothing. `Citation_ledger.verified` still owns which status tokens count, so a refuted or unresolved cell keeps it closed, and `test/target_test.ml` pins both directions. |
| D152 | The Stage B front end already exposes solLog and signed division names. | Emission seeds solLog through the checked String -> IO Unit primitive carrier and lowers that named primitive to RSyscall. It seeds signed division/remainder with the existing kernel primitive tags. Ordinary host printLine stays rejected. Check and --emit-none keep their existing state path; no vendored source changes. |
| D153 | Every V3 frame adjustment is eight-byte aligned. | Pinned verifier.rs:323-324 requires 64-byte alignment. Frame rounds to that requirement, and every emitted prologue/epilogue uses the computed size. frame_reserve is zero. Structural checks independently cover byte, count and arena limits. |
| D154 | Stage C needs only its older enumerated parameter lines. | ELF format fields, 100 opcode values and Murmur mix parameters also live in target_params.ml with ledger markers. Required rows reject stale status, and region_map/syscall_table have no numeric literals. The existing one-path deny allowlist is unchanged. |
| D155 | Fixed headers and dynsym alone suffice; reference images have five headers. | The pinned strict loader with symbol labels enabled requires section names and .dynstr. The writer supplies those sections. Both pinned images append a sixth null header, so T1-14 validates that extra header and compares the five required entries positionally. |
| D156 | The normative short gates contain all Stage C prose obligations. | T1-11 additionally checks current dependency revisions and both compiled version lines; T1-12 additionally enforces the two zero-literal modules. Scope expansions list only the new backend and named CLI/test/harness paths. The live source manifest contains 46 library files. |
| D157 | A plain second-author extern call and ordinary Rust runtime produce a suitable image. | The first image introduced unregistered abort and unresolved call behavior. The corrected no_std fixture imports the pinned SDK syscall definition by path and uses a documented non-returning panic edge. Its exact final binary loads and returns zero; the mismatch control rejects. |
| D158 | External companions require no staging decision. | The user requested all changes staged. Source, locks, reproducible evidence and the second-author image/provenance are staged by explicit paths in the existing Documents index; the tally repository has its own staged changes. Generated targets and deployment keypairs are excluded, and no unrelated parent paths are added. |
| D159 | T1-13 runs eight `--expect` fixtures, `emit-frame-call` among them (M1-PLAN.md:4162-4196). | While row S18 is UNVERIFIED the native fixture cannot build: `lib/emit/select.ml:23-25` rejects any non-zero arity with `Row_unverified S18`, so under `set -e` the eighth iteration killed the loop and `PASS-T1-EMIT` could never print even after the S18 guard is discharged. The roster is now seven run fixtures plus an explicit typed-rejection leg for `emit-frame-call`, which requires exit 2, the `Row_unverified S18` line and no image. That is the contract `dev/check-stage-c.py:67-70` already held for the same fixture. Mutation MU-R1-6. |
| D160 | `target_params.ml` may mark any constant with any ledger row, and T1-12 checks only that a MARKED row is VERIFIED. | `entry_input_register = 1` was marked S2 and `syscall_argument_registers` aggregated the five argument registers, but "r1 is the input pointer" and an ordered argument vector are S18 facts, and entry fact 3 keeps every S18 constant out of Stage C source. Both are deleted with their `.mli` declarations; neither had a caller. The five `syscall_arg_*` registers keep their S1 marker: row S18 itself records the syscall half as already pinned and S1's citation is the site that passes them, `sbpf@e7e51529 src/interpreter.rs:548-556`. `return_register` keeps S17, whose row text names `mov64 r0, 0` then `return`. T1-12 gains a leg that reads the constants themselves rather than their markers, so a MISMARKED line is no longer invisible to the entry. Mutation MU-R1-3. |
| D161 | The Stage C mutation roster of M1-PLAN.md:2110-2138 is run in full. | The staged slice recorded artifact-level loader cycles only, and no row named a new gate marker. Review round 1 ran seven cycles on scratch copies, at least one per new entry: MU-R1-1 for T1-11, MU-R1-2 and MU-R1-3 for T1-12, MU-R1-6 and MU-R1-7 for T1-13, MU-R1-4 for T1-14 and MU-R1-5 for T1-15. MU-R1-7 is the plan's `RETURN 0x9d` to `0x95` row; on disk that byte is `lib/target/target_params.ml:234`, `let op_return = 157`, not `lib/emit/encode.ml`, so the scratch tree mutates the line where the constant lives. The plan's remaining pre-shaped rows, the two negative controls, the divisor branch, the frame prologue pair, the image cap pair and the two key rows, stay open. |
| D162 | The stage-close narrative names an invocation for every claim it makes. | The sentence "T1-14 and T1-15 pass when run independently against those same image bytes" named no command, script or log, and the only recorded invocation, `dev/STAGE-C-STATUS.md:25`, runs `dev/check-stage-c.py`, whose body never reads a header or the second-author image. Round 1 reran both leg bodies by hand, exit zero for each, and the narrative now names the commands and the new evidence file `tally-m1/stage-c-validation/review-r1-legs-and-mutations.log`. It also records that under `set -e` neither entry is reachable in a full battery while T1-13 exits at OPEN-T1-EMIT. |
| D163 | The Stage C driver writes only the artifacts its options name. | `build -o` and `build --ledger` consumed the next token unconditionally, so `build -o --ledger FILE` wrote an 832-byte image literally named `--ledger` in the repository root and exited zero. Both clauses now refuse a following flag and fall through to the driver's own "output and ledger options require a path" error, which the bare form already produced. The regression lives in `dev/check-stage-c.py` rather than `test/`, because the driver's flag parser is not library-exposed. In the same pass `lib/emit/select.ml` gained a reserved-tag injectivity check, so two constructor names of one reserved class reject instead of emitting two identical `JEQ_IMM` tests. It is defensive today: the prelude binds `true`, `false`, `unit`, `lt`, `eq` and `gt`, and the front end rejects a duplicate global, so no tally source can reach the collision. |

### Handoff

S18 requires the user's ratified internal calling convention under
M1-PLAN.md section 10.1 and OQ-3. This work neither supplies that answer
nor treats a source pin as its substitute. The native fixture is present
and deliberately rejects. The full Stage C mutation roster and native
frame-nesting proof remain incomplete. Stage D does not open.

Evidence is in `tally-m1/stage-c-validation/`; its README distinguishes
scoped successes, full battery observations, and remaining work. Every
repository and companion change is staged explicitly. No commit is made.

## Stage C review round 1 (2026-09-07)

Round 1 reviewed the whole staged index at `d339e81`, which carries the M1
Stage C leaf emission slice and the Stage B review round 1 fixes together. It
kept seven findings. Each repair is in place below; nothing was deferred.

| id | severity | finding | repair, in place |
|---|---|---|---|
| L5E-1 | HIGH | No mutation row exercised the five new gate entries T1-11 to T1-15. Every Stage C row was an artifact-level loader cycle, and `rg` for any new marker name across the 250-line `dev/MUTATION-LOG.md` returned nothing. | Ran seven scratch-copy cycles, at least one per new entry, and appended their six-column rows under "## Stage C review round 1, gate mutations (2026-09-07)" in `dev/MUTATION-LOG.md`. Evidence: `tally-m1/stage-c-validation/review-r1-legs-and-mutations.log`, `review-r1-source-mutations.log`, `review-r1-s18-leg-mutation.log`. Deviation D161 records which pre-shaped plan rows ran and which stay open. |
| L1-2 | HIGH | The only evidence that T1-14 and T1-15 are non-vacuous was an unattributed sentence naming no invocation, and under `set -e` neither entry can run in a full battery while T1-13 exits at OPEN-T1-EMIT. | Reran both leg bodies by hand against freshly built image bytes, exit zero for each, and rewrote the sentence to name the commands, the four `hdr-*.txt` captures and the new evidence file. The unreachability under `set -e` is now stated in the narrative and in `dev/STAGE-C-STATUS.md`. Deviation D162. |
| L2-1 | HIGH | T1-13 demanded that `emit-frame-call` build and return 7, but the build exits 2 with `Row_unverified S18`, and `dev/check-stage-c.py` encoded the opposite contract for the same fixture. Under `set -e` the loop could never reach `PASS-T1-EMIT`. | `dev/gates-tally-m1.sh` now runs seven `--expect` fixtures, `test "$n" -eq 7`, plus an explicit typed-rejection leg for `emit-frame-call` requiring exit 2, the `Row_unverified S18` line and no image. Deviation D159, mutation MU-R1-6. |
| L3-1 | HIGH | Row S18's argument-register convention was written into `target_params.ml` under the S1 and S2 markers, whose ledger rows carry no register fact, and T1-12 was structurally blind to a mismarked line. | Deleted `entry_input_register` and `syscall_argument_registers` with their `.mli` declarations; neither had a caller. Kept `syscall_arg_first` to `syscall_arg_fifth` marked S1, which row S18 itself records as the already pinned syscall half, and kept `return_register` marked S17. Added a T1-12 leg that reads the constants rather than their markers. Deviation D160, mutation MU-R1-3. |
| L4-A | HIGH | `build -o` and `build --ledger` swallowed the next token unconditionally, so `build -o --ledger FILE` wrote an 832-byte image literally named `--ledger` in the repository root and exited zero. | Both clauses now refuse a following flag and fall through to the driver's own "output and ledger options require a path" error. Regression added to `dev/check-stage-c.py`, since the flag parser is not library-exposed. Deviation D163. |
| L2-2 | MED | Constructor tags were minted from hard-coded source names that are not injective, so two constructors of one type could collide on one reserved tag and silently miscompile a switch. | `lib/emit/select.ml` records the reserved-class names it mints and rejects the program with `Unsupported_term "constructor name collides with a reserved tag: ..."`. Defensive today: the prelude binds `true`, `false`, `unit`, `lt`, `eq` and `gt`, and the front end rejects a duplicate global, so no tally source reaches it. Stage D hand-off: carry a numeric tag on `Cterm.ctor` at `lib/cterm/cterm.mli:6` and retire the name table. |
| L3-3 | MED | `require_calling_convention` discarded its ledger and hard-coded `Error (Row_unverified "S18")`, so the plan's S18 discharge edit would have changed nothing in the compiler. | It now reads `Citation_ledger.verified ledger "S18"`. `test/target_test.ml` pins both directions: a positively VERIFIED S18 cell is the only discharge, and `UNVERIFIED` or `VERIFIED-REFUTED` keep it closed. `target_params.mli` is unchanged. Deviation D151 amended. |

Build and tests after the repairs, run in the fixer's own window:
`dunecho build -- --root /Users/oobi/Documents/tally` exit 0, "OK build: 0
errors, 0 warnings"; `target_test.exe` exit 0; `image_test.exe` exit 0, 16
PASS lines; `emitter_test.exe` exit 0, 102 CASE lines; `cterm_ref.exe` exit 0,
10 interp and 10 pipeline lines. Row S18 is still UNVERIFIED, the full battery
still stops at T1-13 with OPEN-T1-EMIT, and Stage D does not open.
