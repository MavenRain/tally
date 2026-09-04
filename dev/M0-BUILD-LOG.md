# M0 build log

One section per stage.  Every deviation reality forces is recorded here as a
row;  gate semantics are never deviated from (a gate that cannot go green as
written is reported RED, not weakened).

## Stage A: tally repo skeleton, harnesses, DRYRUN baseline

Date 2026-09-03.  Pin `4f7513056f5b1ca073ab06eb0ebe238a5fb7f0d2`.
Run 1 result: **RED** at the DRYRUN capture matrix (capture 47 of 265).
Run 2 result: **GREEN** after the narrow harness repair recorded as D8 below
(the brief that ordered the repair calls it "D7";  that number was already
taken by the `speed-table.md` CPU row, so the repair is logged as D8 and no
existing row is renumbered).  See "Stage A blocker (run 1) and its repair
(run 2)" below.

### What ran green

| step | evidence |
|---|---|
| setup block (init, submodule add, detached checkout at PIN, PIN file, gen-corpus-a.sh, add -A) | `HEAD is now at 4f75130`;  `dev/corpus/corpus-a.tot` 300 lines |
| `dunecho build -- --root .../tally/vendor/tot` | `OK build: 0 errors, 0 warnings`;  `_build/default/bin/tot.exe` present |
| `git -C vendor/tot ls-files 'examples/*.tot' 'test/fixtures/*.tot' > dev/corpus-files.txt` | 66 rows (5 examples + 61 fixtures), the plan's expected count |
| `git -C tally add dev/corpus-files.txt` | index holds the frozen 66 rows |
| negcheck legs (`run_one` exit-file 1, `duplicate global Nat` stderr) | `exit-file = 1`;  `examples/nat.tot:2:1: duplicate global Nat` |
| timing harness DRYRUN (self against self, vendor prelude both sides) | exit 0, `$OUT/dryrun-speed` populated with the six microsecond files, `speed-table.md`, `jitter.txt` |
| run 2: `run-matrix.sh` cut into `$OUT/dryrun-base1` | 265 capture dirs, 55 s wall;  exit census 100 x `0`, 164 x `1`, 1 x `124` |
| run 2: `run-matrix.sh` cut into `$OUT/dryrun-base2` | 265 capture dirs |
| run 2: determinism leg (`diff -r` of the two cuts, `test "$hdst" -eq 0`) | `hdst=0`, `PASS-T0-HARNESS-DETERMINISM` |
| run 2: floors invocation `gates-stage-a.sh $OUT/dryrun-base1` | `fl=0`, marker leg green, `$OUT/floors-a.txt` = `PASS-T0-HARNESS-FLOORS` |
| run 2: the pathological cell, both cuts | `argv=run test/fixtures/c-regex-pathological.tot`, `exit`=124, stdout 0 bytes, stderr 0 bytes, byte-identical across cuts |

### Stage A blocker (run 1) and its repair (run 2)

`dev/run-matrix.sh` cannot complete a 265-capture cut at this pin.  The
frozen corpus row `test/fixtures/c-regex-pathological.tot` is a fixture whose
`run` mode is DESIGNED never to terminate (catastrophic backtracking on
`(a+)+b`), so `run_one`'s watchdog records exit 124 and its only status leg

```
  test "$st" -ne 124
```

fails, aborting the fail-fast matrix at capture 47 of 265.  The pin's own
`dev/gates.sh:321-325` REQUIRES that exit:

```
[ "$rcode" -eq 124 ] && echo PASS-C-REGEX-PATHOLOGICAL-RUN \
  || { echo "FAIL-C-REGEX-PATHOLOGICAL-RUN (exit=$rcode, want 124: the pathological regex must actually run)"; exit 1; }
```

So the plan's "a timeout is a gate failure, not a skipped row" rule and the
plan's own mechanical `ls-files` corpus derivation contradict each other at
this pin.  Measured both ways (stdin attached and `< /dev/null`): EXIT=124 at
30 s each time;  the `--no-prelude` form of the same row exits 1 in under a
second, and `check` mode exits 0 fast.  This needs a PLAN amendment, not a
builder workaround: the two candidate shapes are (a) a named per-row
timeout-tolerated exception carried as committed data beside the corpus, or
(b) an `ls-files` corpus derivation that excludes the row by name, with
`ROWS_FROZEN` re-derived.  Neither was taken in run 1.

Blocked by the same root cause in run 1, therefore NOT observed then: the
determinism leg, the `gates-stage-a.sh` floors invocation and its marker leg,
and three of the six non-vacuity mutations (determinism byte-append,
corpus-freeze row delete, floor-script truncation).  Run 2 takes shape (a),
recorded as D8 below, and observes all four.

### Deviations

| # | deviation | why reality forced it |
|---|---|---|
| D1 | `git submodule add` run as `git -C ... -c protocol.file.allow=always submodule add ...` | git 2.50.1 (Apple Git-155) blocks file-protocol submodules by default: the verbatim line failed `fatal: transport 'file' not allowed`.  Clone content is unchanged (committed objects only) |
| D2 | `dunecho` invoked from a script that first prepends `/Users/oobi/.opam/zxcaml-p1/bin` to `PATH` | bare `dune` is not on the session PATH and `dunecho` shells out to it: `dunecho: could not run dune: No such file or directory (os error 2)`.  The build command itself is the plan's, unchanged |
| D3 | `dev/run_one.sh`'s watchdog line gained `< /dev/null` before the two output redirections | the plan's literal `run_one` leaves the child's stdin attached to `run-matrix.sh`'s `while IFS= read -r f ... done < "$CORPUS"` loop.  `tot run examples/guard.tot` DRAINS that stdin, so the loop ended after 3 corpus rows and the cut produced 13 capture dirs, not 265 (probed: a 5-line stdin file survives `check` and `run examples/church.tot` intact, and is consumed to EOF by `run examples/guard.tot`).  Harness mechanics only: no threshold, count or marker changed, and the captures become stdin-independent, which the determinism leg wants |
| D4 | `test/fixtures/` names for the three unnamed section-8 negatives: `n2-int-literal-too-long.tot`, `n3-int-no-delta.tot`, `n4-unknown-word-vocab.tot` | section 8 names only E4's file (`int-baseline.tot`);  N2/N3/N4 carry bodies but no filenames anywhere in the plan |
| D5 | `dev/MUTATION-LOG.md` header text chosen by the builder | the plan mandates "header only" and never spells the header |
| D6 | `dev/split-manifest.txt` rows derived from the Stage C change table (section 5, Stage C) and `LC_ALL=C sort`ed | the row says "text below, leg C-e";  leg C-e spells the FORMAT (`--name-status -M`, sorted, `R<score>` normalized to `R`) and one literal row, not the whole list |
| D7 | `speed-table.md`'s machine line records `CPU unavailable` | `sysctl -n machdep.cpu.brand_string` is denied in this session's sandbox (`sysctl: sysctl fmt -1 1024 1: Operation not permitted`);  the plan itself notes this reading needs the sandbox override.  OS build, dune 3.24.2 and OCaml 5.2.1 are recorded |
| D8 | `run_one`'s final status leg gained a committed one-row watchdog allowlist (the run-2 repair of the run-1 blocker;  the ordering brief calls this "D7", already taken above) | see "D8: the watchdog allowlist" below |

### D8: the watchdog allowlist

The two-line diff in `dev/run_one.sh`, replacing the single final leg
`  test "$st" -ne 124`:

```
  local allow=/Users/oobi/Documents/tally/dev/watchdog-allowlist.txt
  test "$st" -ne 124 || rg -qxF -- "$*" "$allow"
```

The new committed data file `dev/watchdog-allowlist.txt` holds EXACTLY one
row:

```
run test/fixtures/c-regex-pathological.tot
```

Semantics: `st != 124` stays green untouched;  `st == 124` is green ONLY when
`run_one`'s joined argv matches an allowlist row exactly (`rg -qxF`, fixed
string, whole line);  a MISSING allowlist file makes `rg` exit 2, so the leg
is red, fail-closed.  `zsh -n dev/run_one.sh` exits 0.

Why this and nothing wider:

- The fixture's own header, lines 1-13, states that exit 124 is the
  documented ACCEPTED outcome and closes with "do NOT assert that this
  fixture completes".  The row is a designed non-terminator under `run`,
  not a defect the matrix should be able to catch.
- The pin's `dev/gates.sh:303-311` requires CHECK mode on this fixture to
  exit 0 fast (a watchdog kill there is a REGRESSION), and `:312-324`
  requires RUN mode to exit 124, because fast completion would be the C18
  silent-swallow regression.  The tot side already pins BOTH halves.
- The pin's `dev/M3-FIXES-LOG.md:835-843` (id-21 adjudication) explicitly
  REJECTED an accept-either shape in tot's own gate ("accepting 0 OR 124
  recreates the exact cannot-fail shape A3 removed").  So the repair must
  not touch tot or relax tot's gate: it is a narrow harness-side allowlist
  in the tally repo, carried as committed data.
- Probe evidence (`tally-m0/scratch/stage-a-probe/`): this is the ONLY
  offending cell, 1 of 264 corpus cells;  the worst other cell runs 1713 ms
  against the 30 s watchdog, 17.5x headroom;  the killed captures are
  byte-identical empty stdout and empty stderr on every run.

The regression net stays TWO-SIDED for this cell.  A future candidate binary
that COMPLETES here writes different capture bytes (a non-empty stream, a
different `exit` value), so the byte-diff against the baseline cut goes red;
the allowlist only tolerates the timeout, it does not stop comparing the
captures.  And a candidate that wedges on any OTHER cell still returns
non-zero from `run_one` and still aborts the fail-fast matrix.  Both halves
are mutation-proved in `dev/MUTATION-LOG.md` as M-ALLOW-1 and M-ALLOW-2.

### Measurement note (not a gate at Stage A)

The DRYRUN timing run reports `JITTER-NOISY` on this machine
(base stdev/median 4215/15718 = 0.27, cand 6924/21491 = 0.32, both over E2's
0.15 limit;  self-against-self ratio 1.37, not the expected ~1.0).
PASS-T0-HARNESS does not gate jitter, but battery entry 14 would print
`FAIL-T0-SPEED-INVALID` on these numbers, so E2's recovery path (b), grow
CORPUS-A until `stdev/median <= 0.15` is routinely met, is already indicated.

## Stage B: M5+M6 land, re-pin, real baseline

Date 2026-09-03.  Old pin `4f7513056f5b1ca073ab06eb0ebe238a5fb7f0d2`
(PIN_OLD), new pin `66b444fe8380c82f0a74093ffaa779371d014a9b` (PIN_M5, tot
`M6 Stage H: rulings C-G1 (a) and C-G2, gate battery 370 to 371 PASS`).
Result: **GREEN**.  Steps 2-8 ran, both stage-close gates (PASS-T0-PIN,
PASS-T0-BASELINE) are green, and all eleven Stage B mutation cycles were
observed red, restored and re-run green (`dev/MUTATION-LOG.md`).

Wording note (brief B1): the plan text says "M5 lands".  BOTH M5 and M6
landed between the pins;  PIN_M5 is tot HEAD at the moment the tree was
clean, per RATIFICATIONS.md item 3.  No gate changed meaning.

### What ran green

| step | evidence |
|---|---|
| step 2 closure re-derivation on the PIN_M5 worktree (blocking human step, risk R1) | `lib/` holds 20 dirents (17 `.ml` + `budget.mli` + `level.mli` + `dune`);  kernel closure = 15 modules;  `interp.ml` and `json_escape.ml` are the two `tot_interp` leftovers.  Raw command output: `tally-m0/scratch/stage-b-build/01-step234.out` |
| step 2 (a) name-exclusion alternation re-derived from the manifest move-out rows | `interp\.ml\|json_escape\.ml\|dune` (two `lib/ -> interp/` rename rows plus `lib/dune`) |
| step 2 (b) `dev/tower-allowlist.txt` re-checked against PIN_M5 | 9 rows, count UNCHANGED.  MEASURED: FIVE rows resolve to a real file at PIN_M5 (`lib/check.ml`, `lib/eval.ml`, `lib/literal.ml`, `lib/pp.ml`, `lib/prim.ml`) and FOUR are forward rows the plan creates later (`lib/kernel_format.ml`, `lib/word.ml`, `lib/word.mli`, `lib/word_delta.ml`;  M0-PLAN.md ~1010 and 3077-3078).  The build brief's amendment and the Stage B probe both say "6 rows resolve" while listing the same five names: an off-by-one in the prose, corrected here from the measurement (`tally-m0/scratch/stage-b-build/01-step234.out`).  New-site half, MEASURED on the `PIN_OLD..PIN_M5` diff: the only kernel files modified outside the allowlist rows are `lib/error.ml` (36 added lines, 1 with an integer literal), `lib/term.ml` (51 added, 6) and `lib/totality.ml` (31 added, 4), plus the new `lib/budget.ml` (27 added, 1) and `lib/budget.mli` (9 added, 0).  Every one of those literal-bearing added lines is either a doc comment (`error.ml`, `totality.ml`, `budget.ml`, and `term.ml`'s `[List.length m_idx + 1]` prose) or de Bruijn cutoff arithmetic in `Term.shift` (`~cutoff:(cutoff + 1)`, four sites);  none is a word-tower int-literal site.  The row COUNT stays 9 |
| step 2 (c) "named exception rows" wording | resolves to the re-derived manifest rows (now TWO renames), never to a hardcoded count |
| step 2 (d) prelude-axiom census | `rg -o '^axiom [A-Za-z0-9_]+'` at PIN_M5 = 3 rows (`ioBindPure`, `ioBindRet`, `ioBindAssoc`);  `cmp` against `dev/prelude-axioms.golden` exit 0, golden re-derived byte-identical, `AXIOM_ROWS_FROZEN` stays 3 (arithmetic row in `dev/MUTATION-LOG.md`) |
| step 2 (e) `dev/split-manifest.txt` | rename row `R<TAB>lib/json_escape.ml<TAB>interp/json_escape.ml` appended, 14 -> 15 rows, `sort -c` under `LC_ALL=C` clean |
| step 3 split invariants | `Str.` CODE sites are `lib/interp.ml:541,542,597,607,609,613` ONLY;  NO `lib/` module really references `Interp.`;  ZERO `Tot_surface`/`Tot_kernel` hits inside `lib/*.ml`.  Full raw output plus the per-hit comment triage below |
| step 4 trusted-base record | `Totality.guard` gained `~rule`;  signature recorded as an APPEND-ONLY dated sub-note in M0-PLAN.md section 9 and mirrored below |
| step 5 real baseline | `dunecho build --root .../tally-m0-pin-m5` `OK build: 0 errors, 0 warnings`;  `GATE-EXIT=0`, `pass-count.txt` = 371, `fail-count.txt` = 0 (a literal `0`, written as data);  `pin.txt` = PIN_M5;  `tot-baseline.exe` copied to `$BASEDIR` |
| step 6 re-pin, submodule and `PIN` together | `git -C vendor/tot fetch origin` succeeded WITHOUT the D1 fallback (`39234e4..66b444f  main -> origin/main`);  `checkout 66b444f`;  `PIN` rewritten;  `add vendor/tot PIN`;  then the standing TWO adds |
| step 7 corpus freeze | `git -C .../tally-m0-pin-m5 ls-files 'examples/*.tot' 'test/fixtures/*.tot'` = 101 rows (6 examples + 95 fixtures), 66 -> 101 |
| step 7 reference cuts | `base1` and `base2` both 405 capture dirs;  exit census identical on both cuts: 130 x `0`, 272 x `1`, 2 x `2`, 1 x `124` (the D8-allowlisted `run test/fixtures/c-regex-pathological.tot`) |
| step 7 ALIVE legs | `test -x "$BASE"` green before any cut;  `lst=1` (no `127` anywhere), zero-exit count 130 >= 40, `duplicate global Nat` present;  `PASS-T0-BASELINE-ALIVE` |
| step 7 PRELUDE-RESOLVED | `nfst=1` (no `no such file` in any `base1` stderr, `-i`);  `PASS-T0-BASELINE-PRELUDE-RESOLVED` |
| step 7 DETERMINISM (Stage-B-close only, NOT re-run in the battery) | `bdst=0` on `diff -r "$OUT/base1" "$OUT/base2"`;  `PASS-T0-BASELINE-DETERMINISM` |
| step 7 re-freeze | `ROWS_FROZEN` 265 -> 405 (101 x 4 + 1) written into `dev/gates-stage-c.sh`, the four floors (40 / 20 / 20000 / 5000) carried forward unchanged;  arithmetic recorded in `dev/MUTATION-LOG.md`;  `git add dev/corpus-files.txt dev/gates-stage-c.sh` |
| step 7 DRYRUN delete | `rm -rf $OUT/dryrun-*` after the three step-7 mutations were green;  `$OUT` holds `base1`, `base1.cache`, `base2`, `base2.cache`, `floors-a.txt`, `mut-speed`, `mut-speed-b2`, `negcheck`, `negcheck.cache`, `stage-b-gates.out` |
| step 8 digest fence | `awk '/^## Ratification record/,/^---$/' ... \| shasum -a 256` = `f421365b6a9008d7e7e28c444997ce874d8d4496c4c7911008e6baae2add629f` over 37 lines, MATCHING the ratified value;  written to `dev/verdict-record.digest` and staged |
| step 8 re-pin append | `## Re-pin log (builder-appended, not ratified)` created once, BELOW the `---` terminator;  digest recomputed AFTER the append: byte-identical, range still 37 lines |
| Gate PASS-T0-PIN (6 legs) | `GATE-EXIT=0`, `PASS-T0-PIN`;  evidence `$OUT/stage-b-gates.out` |
| Gate PASS-T0-BASELINE (4 legs) | `GATE-EXIT=0`, `PASS-T0-BASELINE`;  same run |
| mutation cycles | 3 step-7 cycles (base-dead, det, prel) + the probe-proved floor half + 5 PASS-T0-PIN cycles (A-E) + 3 PASS-T0-BASELINE cycles (A-C);  every one red, restored, green;  rows in `dev/MUTATION-LOG.md` |

### Step 2 classification table (PIN_M5, after manual comment triage)

Rule as applied (see D9): a `lib/` module joins `tot_kernel` iff a
kernel-closure module really references it in CODE, otherwise `tot_interp`.
Comment triage excluded every odoc `[Module.x]` cross-ref and `(* ... *)`
prose line;  a naive sweep over-counts about tenfold (probe 1's method).

| lib/ file | real CODE consumers (comment hits excluded) | verdict |
|---|---|---|
| `budget.ml`, `budget.mli` | `lib/check.ml:16,22,25,865,928,1115,1466,1569,1581,1763,1792,1847,1865` (ctx field, `empty_ctx`/`root_ctx` defaults, three `Budget.exhausted` checks, seven `?(budget : Budget.t = Budget.unlimited)` defaults);  `bin/tot.ml:37,39,43,50` (qualified `Tot_kernel.Budget`);  `surface/run.ml:208,636`.  `check.ml:18,1470` are doc comments | **tot_kernel** (NEW at M5;  `check.ml` is a closure member, so the closure absorbs it at iteration 1) |
| `json_escape.ml` | `lib/interp.ml:466,479` (json prims);  `surface/effect.ml:44` (error envelope, host-side).  `lib/pp.ml:6` is a doc comment | **tot_interp** (NEW at M5;  D9) |
| `interp.ml` | the host-side interpreter itself;  `surface/effect.ml` (~40 refs), `surface/bootstrap.ml:175,196` | **tot_interp** (the plan's standing classification) |
| `check.ml`, `erase.ml`, `error.ml`, `eterm.ml`, `eval.ml`, `global.ml`, `level.ml`, `level.mli`, `literal.ml`, `pp.ml`, `prim.ml`, `quantity.ml`, `term.ml`, `totality.ml`, `value.ml` | the pin's 14-module closure, carried forward unchanged;  `git diff PIN_OLD PIN_M5 -- lib/` adds ONLY `budget.ml`, `budget.mli`, `json_escape.ml` and modifies `check`, `error`, `eval`, `interp`, `pp`, `term`, `totality`, so no closure member moved | **tot_kernel** |
| `dune` | the `(name tot_kernel) (libraries str)` stanza, byte-identical to PIN_OLD;  rewritten by Stage C | kernel stanza, carried by the manifest's `M lib/dune` row |

Closure fixed point: `budget.ml`/`.mli` name no other `lib/` module (no
`open`, abstract `t`, three functions over a bare record), so iteration 2
adds nothing.  Kernel closure = 15 modules;  `tot_interp` = `interp`,
`json_escape`.

### Step 3 split invariants: raw outputs and triage

- `rg -n 'Str\.' <PIN_M5>/lib/*.ml`: 15 hits.  CODE:
  `interp.ml:541` (`(Str.regexp, Error.t) result`), `:542` (`Str.regexp
  pattern`), `:597` and `:607` (`Str.search_forward`), `:609`
  (`Str.matched_string`), `:613` (`Str.matched_group`).  COMMENT:
  `error.ml:59`, `interp.ml:520,524,525,526,537,574,603` (odoc prose about
  the M3 B1/C19 routing).  Invariant HOLDS: real `Str.` sites are
  interp-only.
- `rg -n 'Interp\.' <PIN_M5>/lib/*.ml`: 7 hits, ALL comments:
  `eterm.ml:6,8` and `prim.ml:2,17` (odoc `[Interp.v]`/`[Interp.globals]`
  cross-refs), `eval.ml:121` (`(* arity backstop mirroring
  Interp.run_match ... *)`), `json_escape.ml:6` (odoc), `interp.ml:20`
  (inside `interp.ml` itself, so not "outside").  Invariant HOLDS: no
  `lib/` module really references `Interp.`.
- `rg -n 'Tot_surface|Tot_kernel' <PIN_M5>/lib/*.ml`: rg exit 1, ZERO hits.
  Invariant HOLDS.
- PLAN-TEXT GAP (a note, not a gate deviation;  brief B3 amendment): the
  plan spells literal `rg` commands for the step-2 checks (M0-PLAN.md
  868-871) and for the `Str.` invariant, but spells NO literal command for
  the `Interp.` invariant anywhere in Stage B (843-1320).  The command
  above was derived from step 3's own wording and is recorded here so the
  invariant has an executable owner.

### Step 4 trusted-base record

`Totality.guard` gained the labelled `~rule` argument at M5.  Shipped
signature, `<PIN_M5>/lib/totality.ml:188`:

```
let guard ~(rule : rule) ~(recname : string) (body : Term.t) : (int, Error.t) result
```

The split is unaffected (same-library call: both `Totality` and its caller
`Check` are kernel-closure modules).  Recorded in M0-PLAN.md section 9 as
an APPEND-ONLY dated sub-note ("Stage B step 4 record, 2026-09-03");  no
existing plan line was edited.  M5's log closes on comment/doc and
dev-script fixes with "No lib/, surface/, bin/, test/*.ml or gate-oracle
change";  M6's Stage H entry closes at 371 PASS, 0 FAIL, GATE-EXIT=0,
which step 5 re-measured independently on this machine.

### Deviations

| # | deviation | why reality forced it |
|---|---|---|
| D9 | `lib/json_escape.ml` classified into `tot_interp`, applying step 2's rule as its risk-R1 intent ("a new module joins `tot_kernel` iff a KERNEL-CLOSURE module really references it, otherwise `tot_interp`") rather than by the literal wording "`interp.ml` is its only real consumer" | the literal wording is false at PIN_M5 because of ONE host-side consumer, `surface/effect.ml:44`, which would push the module into the kernel while no kernel-closure module references it in code (`lib/pp.ml:6` is a doc comment).  `surface` already links `tot_interp` after the split (it matches on `Interp.v`), so the interp placement adds no dependency, and both placements compile.  FLAGGED FOR USER RATIFICATION;  the user may overrule to `tot_kernel` |
| D10 | none needed: NO watchdog-allowlist row was added at Stage B | the PIN_M5 sweep over all 405 cells found exactly ONE exit-124 cell, the D8 row `run test/fixtures/c-regex-pathological.tot` (30043 ms), and no other cell over 5 s (census 130 x 0, 272 x 1, 2 x 2, 1 x 124).  Both reference cuts reproduce exactly that one 124 cell, so `dev/watchdog-allowlist.txt` stays at its one committed row |
| D11 | PASS-T0-PIN mutation B was planted as a THROWAWAY commit inside `vendor/tot` (the plan's own first option), not as "check out any other commit" | the alternative reddens leg 1 first: at Stage B close `PIN` is the branch tip, so every other reachable commit is an ANCESTOR, and `merge-base --is-ancestor` aborts the fail-fast gate before leg 2 is ever read.  Only a DESCENDANT of `PIN` leaves leg 1 green and lets leg 2's red be observed.  The scratch commit (`bab4d0b9fa441940a36548fa03606cdba8903f83`, one marker file) is abandoned by the restore checkout and referenced by nothing;  no tally-repo commit was made |
| D12 | the Stage B close ran as a STANDALONE runner (`tally-m0/scratch/stage-b-build/13-stage-b-gates.sh`), with no `dev/gates-tally.sh` prefix run | section 7's battery is fail-fast from entry 0, and entries 3-19 are still `exit 9` placeholders, so no prefix of it can complete at Stage B;  M0-PLAN.md 1115-1116 also names `gates-tally.sh` as "entries 0-19 only", never the stage-close freeze-logic home.  The two Stage B entries WERE brought up to the plan text: entry 1 already implemented PASS-T0-PIN's legs verbatim, and entry 2's `exit 9` placeholder was replaced by PASS-T0-BASELINE's four legs plus its marker |
| D13 | the close-out order runs step 7's `rm -rf $OUT/dryrun-*` BEFORE the two gates, not after them | PASS-T0-PIN's own dryrun-absence leg asserts that no `dryrun-*` child survives step 7's delete, so the gate is red-by-construction until the delete lands.  The plan's step-7 text mandates the same order ("Only after green delete the DRYRUN artifacts", then the gates are authored below it);  the ordering in the build brief's close-out sentence is the one that cannot be satisfied |

### D9: the `json_escape.ml` placement (user ratification ask)

Evidence, PIN_M5:

```
lib/interp.ml:466:  | VCon ("jstr", [ VLit (Literal.LString s) ]) -> Ok (Json_escape.string s)
lib/interp.ml:479:            Ok (Json_escape.string k ^ ":" ^ s))
lib/pp.ml:6:    the verdict envelope) uses [Json_escape.string] instead; see M5   <- DOC COMMENT
surface/effect.ml:44:    decision (Json_escape.string msg)
```

`surface/effect.ml` is host-side and already pattern-matches on `Interp.v`
in ~40 places, so it links `tot_interp` after the split either way.  The
consequence of the choice is mechanical and small: with `json_escape.ml`
in `tot_interp` the name-exclusion alternation shared by leg C-b and
PASS-T0-TOWER-SCOPE is `interp\.ml|json_escape\.ml|dune` and
`dev/split-manifest.txt` carries two rename rows;  with it in `tot_kernel`
the alternation is `interp\.ml|dune` and the manifest carries one.  Both
are recorded so a ratification either way is a one-line change.

### Sandbox observation (not a Stage B gate)

Battery entry 18 leg 1 ends in `| diff - dev/verdict-record.digest`.  In
this session's sandbox `diff` cannot open its `-` stdin operand:
`diff: -: Operation not permitted`, exit 2, red-by-construction and
independent of content (`printf 'x\n' | diff - /dev/null` reproduces it,
while a file-to-file `diff` and a piped `cat` both work).  The digest
equality itself was verified here with `cmp` against a temp file, exit 0.
Entry 18 is an `exit 9` placeholder until E4, so nothing at Stage B
depends on it;  recorded so E4 either runs unsandboxed or spells the leg
with a temp file.

## Stage C part 1: the carve (pre-commit)

All edits are inside `vendor/tot`, on top of PIN_M5
`66b444fe8380c82f0a74093ffaa779371d014a9b`, staged with
`git -C vendor/tot add -A` and NOT committed by the builder.

**No gate evidence is claimed by this section.**  Every run below is a
PRE-COMMIT SMOKE run of a gate SHAPE, not the gate.  PASS-T0-KERNEL-SPLIT
and every Stage C mutation cycle need the split COMMITTED in the
submodule first (M0-PLAN.md 1804-1827, R15, F119: a HEAD-form
`git checkout HEAD -- <file>` restore against an uncommitted split
silently reverts the file to PIN bytes).  Part 2 runs the five-leg gate,
the 12 cycles, `gates-tally.sh` entry 4 and `dev/inst-key-enc.golden`.

### The carve, one row per `dev/split-manifest.txt` row

`git -C vendor/tot diff --numstat -M "$(cat PIN)"`, staged tree:

| # | status | file | what changed | numstat |
|---|---|---|---|---|
| 1 | A | `interp/dune` | NEW.  The `str` comment block moved here from `lib/dune` with BOTH `lib/interp.ml` mentions retargeted to `interp/interp.ml`, then `(library (name tot_interp) (public_name tot.interp) (libraries tot_kernel str))` | 8 0 |
| 2 | A | `test/keygolden/dune` | NEW: `(executable (name keygolden) (libraries tot_kernel))`, its own directory so `test/dune`'s `(tests (names main surface))` auto-glob needs no `(modules ...)` surgery | 3 0 |
| 3 | A | `test/keygolden/keygolden.ml` | NEW, 15 lines: file-level `open Tot_kernel`, a fixed four-element `Term.t list` (`Lit (LString "tally")`, `Lit (LInt 42)`, and two structural terms, an `App` over a `Global` and a `Lam` over an `App`), printed one row per line through `Check.inst_key_enc`.  Never prints `PASS` | 15 0 |
| 4 | M | `dune-project` | appended `(package (name tot))` as the last line (R9, F88: without a declared package dune 3.24 resolves no `public_name`) | 1 0 |
| 5 | M | `lib/dune` | the four-line `str` comment LEFT for `interp/dune`;  a new comment records "the kernel names no external library;  adding one is a gate failure";  stanza is now `(library (name tot_kernel) (public_name tot.kernel))`, with `(libraries str)` dropped | 5 5 |
| 6 | M | `surface/bootstrap.ml` | ONE added line `open Tot_interp` after `open Tot_kernel` (line 14) | 1 0 |
| 7 | M | `surface/cache.ml` | ONE added line `open Tot_interp` after `open Tot_kernel` (line 78) | 1 0 |
| 8 | M | `surface/dune` | `(public_name tot.surface)` added and `tot_interp` added to the library list | 2 1 |
| 9 | M | `surface/effect.ml` | ONE added line `open Tot_interp` after `open Tot_kernel` (line 13) | 1 0 |
| 10 | M | `surface/run.ml` | ONE added line `open Tot_interp` after `open Tot_kernel` (line 6) | 1 0 |
| 11 | M | `test/dune` | ONLY the `tests` stanza's library line changed, to `tot_kernel tot_interp tot_surface unix`;  the `tot_exe_dep.ml` rule stanza and every comment are byte-identical (numstat proves it: one line in, one line out) | 1 1 |
| 12 | M | `test/main.ml` | ONE added line `open Tot_interp` after `open Tot_kernel` (line 5) | 1 0 |
| 13 | M | `test/surface.ml` | ONE added FILE-LEVEL line `open Tot_interp` at line 1;  the five scoped `let open Tot_kernel in` sites (602, 630, 1330, 1432, 1526 at PIN_M5) are untouched | 1 0 |
| 14 | R | `lib/interp.ml` -> `interp/interp.ml` | `git mv` (rename score R099) plus ONE added line `open Tot_kernel` at the top | 1 0 |
| 15 | R | `lib/json_escape.ml` -> `interp/json_escape.ml` | `git mv` only (rename score R100).  Byte-identical | 0 0 |

`bin/dune` is UNCHANGED, as M0-PLAN.md 1359-1361 predicts: the build is
green without it, so the plan's sanctioned correction was not needed and
no sixteenth manifest row exists.

### C3(c) triage: `lib/json_escape.ml` needs no `open Tot_kernel`

`rg -n 'Pp\.'` on the file returns exactly two hits, its line 1 and its
line 5, and BOTH sit inside the file's leading `(** ... *)` doc comment
(the comment opens on line 1 and the file's first code line is its
`let` below it).  A module-reference sweep over the whole file finds only
stdlib names in code: `Buffer`, `String`, `Printf`, `Char`.  The moved
file therefore names no `tot_kernel` module at all, an `open Tot_kernel`
in it would be an UNUSED open (the file names no tot_kernel module in
code, so the open would be superfluous; note that warning 33 is not
enabled here, so the zero-warning leg does not detect it), and the file
moves byte-identical exactly as the
Stage B manifest row records.  No deviation is raised: the D14 slot the
brief reserved for a code-`Pp.` outcome is not used.

### Pre-commit smoke runs (shapes only, evidence for part 2 to re-run)

| shape | command | result | artifact |
|---|---|---|---|
| manifest, leg e form | `git diff --name-status -M PIN \| sd '^R[0-9]+\t' 'R\t' \| sort` vs `dev/split-manifest.txt` | `diff` EMPTY, all 15 rows match | `tally-m0/scratch/stage-c-build/split-files.txt`, `01-carve.out` |
| build | `dunecho build -- --root vendor/tot` | `OK build: 0 errors, 0 warnings` | `scratch/stage-c-build/build.out`, `02-build-legs.out` |
| leg b form | untracked-clean, then `diff --numstat -M PIN -- lib/ \| rg -v 'interp\.ml\|json_escape\.ml\|dune' \| wc -l` | untracked-clean;  residue rows = 0 | `scratch/stage-c-build/02-build-legs.out` |
| leg d form | `rg -c 'libraries' vendor/tot/lib/dune` | exit 1 (no match), the exact "file exists, names no external library" status | `scratch/stage-c-build/02-build-legs.out` |
| retarget | `rg -n 'lib/interp\.ml' interp/dune lib/dune` | exit 1 (zero hits) | `scratch/stage-c-build/02-build-legs.out` |
| leg a form | `zsh vendor/tot/dev/gates.sh` | `GATE-EXIT=0` (attributed to `03-smoke-lega.out`, the wrapper's own capture; the token does not appear inside `split-gate.smoke.out`, which is gates.sh's redirected stdout), `rg -c '^FAIL'` exit 1, `rg -c '^PASS'` = 371 = `pass-count.txt` | `scratch/stage-c-build/split-gate.smoke.out`, `03-smoke-lega.out` |
| leg c floors | `zsh dev/gates-stage-c.sh "$OUT/base1"` | exit 0 and the `PASS-T0-SPLIT-FLOORS` marker present | `scratch/stage-c-build/floors-c.smoke.txt` |
| leg c behaviour | `zsh dev/run-matrix.sh "$WBIN" vendor/tot "$OUT/cand-smoke"` then `diff -r "$OUT/base1" "$OUT/cand-smoke"` | 405 capture dirs, `diff -r` output 0 bytes, exit census identical to base1 (130 x 0, 272 x 1, 2 x 2, 1 x 124) | `scratch/stage-c-build/behavior.smoke.diff`, `census-base1.txt`, `census-cand-smoke.txt` |
| keygolden | `vendor/tot/_build/default/test/keygolden/keygolden.exe` run DIRECTLY | exit 0, exactly 4 rows, `rg -c '^PASS'` exit 1, two runs byte-equal | `scratch/stage-c-build/keygolden.smoke.out` |

The four smoke rows are `S5:tally`, `I42;`, `AwG3:BoxI7;` and
`Lw1:xA0V0;G4:unit`.  They are NOT frozen here: `dev/inst-key-enc.golden`
is a part-2 artifact.

`$OUT/base1` and `$OUT/base2` were never written to;  the smoke candidate
cut went to `$OUT/cand-smoke`, so the close run's `$OUT/cand` is still
absent and `run-matrix.sh` will create it there.

### Standing adds

`git -C vendor/tot add -A` ran (standing add 1) and leaves the
submodule's index carrying every carve row.  `git -C tally add vendor/tot`
ran (standing add 2) and is a NO-OP until the user commits: the gitlink
still records `66b444fe8380c82f0a74093ffaa779371d014a9b`, which equals
`PIN` and equals the submodule HEAD.  The tally-side staged set for part 1
is `dev/M0-BUILD-LOG.md` alone.

### Deviations

None.  D13 remains the last deviation;  the D14 slot reserved for a
code-level `Pp.` reference in `lib/json_escape.ml` is not used, per the
triage above.

Build-runner note (not a deviation): the first execution of
`scratch/stage-c-build/01-carve.sh` died inside its line-insert helper on
BSD `head -n 0` AFTER both `git mv` calls had landed.  The helper was
given a zero-line branch, the two moves were made re-entrant with
`test -f` guards, and the runner was re-run to completion;  the carve was
never backed out and no `git checkout` restore was used.

### Artifact observation (not a gate): `dunecho build` drops a `_build/` in the tally root

Measured in part 1, three probes at
`tally-m0/scratch/stage-c-build/07-buildartifact-probe.out` and
`08-artifact-origin-cleanup.out`:

- After the leg-a smoke run, `git -C tally status --porcelain` carried a
  new `?? _build/`, absent at entry.
- `dunecho build -- --root /Users/oobi/Documents/tally/vendor/tot` does
  NOT create it.  A BARE `dunecho build` with cwd = `vendor/tot`, which
  is what `dev/gates.sh:12` runs after it `cd`s to its own `ROOT`, DOES
  create it, every time.
- The directory holds only dune's own root metadata (`.digest-db`,
  `.filesystem-clock`, `.lock`, `trace.csexp`) and no build context;  the
  real output tree stays at `vendor/tot/_build`.  The walk is unaffected:
  the same run reported 371 PASS and 0 FAIL.

It was deleted, so the tally worktree matches its entry state apart from
the staged `dev/M0-BUILD-LOG.md` and the (expected) dirty gitlink.  It
WILL come back on the next `dev/gates.sh` run, which is Stage C part 2's
leg a.  Part 1 raises it rather than fixing it: a `.gitignore` row is a
tally-repo edit no plan block or manifest row authorizes, and the tally
repo has no `.gitignore` at all today.  USER decision needed before any
tally-side untracked-clean leg is written.

## Stage C close (part 2): the five-leg gate, entry 4, the golden

Result: GREEN.  The kernel split is committed in the submodule as
`29c5b74e0df5d2aa620281057934b8310d345f90`, subject `M0 Stage C: kernel
split`, first parent `66b444fe8380c82f0a74093ffaa779371d014a9b` (`PIN`).
The `PIN` file is unchanged;  M0 never advances it.  The gitlink staged in
tally now records the new submodule HEAD.

### What ran green

The close block ran twice.  The first run is the close, the second run is
the stage-close evidence after the twelfth mutation cycle.

| run | file | result |
|---|---|---|
| close | `tally-m0/scratch/stage-c-close/01-close.out` | `PASS-T0-BUILD-LEG1`, `PASS-T0-PIN`, `PASS-T0-BASELINE`, `PASS-T0-KERNEL-SPLIT-A` to `-E`, `GATE-EXIT 0`, 121 s wall |
| final | `tally-m0/scratch/stage-c-close/13-final-close.out` | the same 8 markers, `GATE-EXIT 0`, 144 s wall, started 06:00:55Z after the last cycle closed green at 06:00:37Z |

Leg evidence, all re-read on disk at the close of this section:

| leg | evidence | reading |
|---|---|---|
| build leg 1 | `01-close.out`, `13-final-close.out` | `OK build: 0 errors, 0 warnings` |
| a | `tally-m0/gate-out/split-gate.out` | `rg -c '^PASS'` = 371 = `pass-count.txt`, `rg -c '^FAIL'` exit 1, `GATE-EXIT=0` |
| b | `tally-m0/gate-out/split-files.txt`, `scratch/stage-c-close/rows/04-red.out` and `04-green.out` | untracked-clean, filtered `--numstat` residue rows (FILTERED-ROW-COUNT 1 then 0) |
| c | `tally-m0/gate-out/behavior.diff` | 0 bytes;  `cand` 405 dirs, `base1` 405, `base2` 405, `diff -r base1 base2` empty, floors marker `PASS-T0-SPLIT-FLOORS` |
| d | `scratch/stage-c-close/rows/11-red.out` and `11-green.out` | RG-EXIT-BEFORE 1, LEG-D-EXIT 1 then 0 |
| e | `tally-m0/gate-out/split-files.txt`, `scratch/stage-c-close/rows/12-red.out` and `12-green.out` | SPLIT-FILES-ROWS 16 then 15 against MANIFEST-ROWS 15 |

The 12 mutation cycles are in `dev/MUTATION-LOG.md` (stage `C`), one row
each, with the red and the green quoted from
`tally-m0/scratch/stage-c-close/rows/`.  Every cycle restored to porcelain
empty.  State at this section: `vendor/tot` porcelain 0 lines, `base1` ==
`base2` (`diff -r` 0 bytes), tally HEAD `9b6fbe9`.  The vendor binary mtime
(22:59:20) precedes the last two source restores (lib/dune 23:00:35,
bin/tot.ml 23:00:36).  Rows 11 and 12 redden on `rg` and on `git diff`,
never on a build, and both restores put back byte-identical content, so
dune skipped the relink; a later full rebuild left the exe sha unchanged.

### The standalone runner (D12 precedent, no new number)

The close ran as a standalone zsh runner
(`tally-m0/scratch/stage-c-close/01-close.sh`), with no `dev/gates-tally.sh`
prefix run.  The shape is D12's, and its prologue is copied from Stage B's
`scratch/stage-b-build/13-stage-b-gates.sh`.  D12's reason holds unchanged:
section 7's battery is fail-fast from entry 0, and entries 3 and 5 to 19
are still `exit 9` placeholders.  No new deviation number is taken.

### `gates-tally.sh` entry 4

The entry-4 `exit 9` placeholder is replaced by leg d's three plan lines
(M0-PLAN.md 1723-1725) and its marker:

```
st=0
rg -c 'libraries' /Users/oobi/Documents/tally/vendor/tot/lib/dune || st=$?
test "$st" -eq 1    # exactly "no match"; a match (0) or a missing/unreadable file (2) is red
echo PASS-T0-KERNEL-SPLIT-D
```

Nothing else in the file changed.  Entries 0, 3 and 5 to 19 keep their
placeholders.  `zsh -n` is clean.  Evidence:
`tally-m0/scratch/stage-c-close/05-stage-verify.out`.

### `dev/inst-key-enc.golden`

Four rows, `S5:tally`, `I42;`, `AwG3:BoxI7;`, `Lw1:xA0V0;G4:unit`.  They
are byte-identical to part 1's smoke capture
`tally-m0/scratch/stage-c-build/keygolden.smoke.out`.  The file was
generated by running the built executable directly,
`vendor/tot/_build/default/test/keygolden/keygolden.exe >
dev/inst-key-enc.golden` (deviation D15).  Exit 0, `rg -c '^PASS'` exit 1.
Evidence: `tally-m0/scratch/stage-c-close/04-golden.out`.

### Staged set

`vendor/tot` (gitlink), `dev/gates-tally.sh`, `dev/inst-key-enc.golden`,
`dev/M0-BUILD-LOG.md`, `dev/MUTATION-LOG.md`.  Nothing else.

### Deviations

| # | deviation | why reality forced it |
|---|---|---|
| D14 | mutation row 9 uses `sd 'duplicate global' 'duplicate Global'` on `lib/error.ml:171`, not the plan's literal `unbound global` (M0-PLAN.md 1703-1705) | the string `unbound global` exists nowhere at PIN_M5 and no capture reaches it (`PLAN-STRING-unbound-global rg-l-exit 1 hits 0`;  `lib/error.ml:170` reads `unknown global %s`, itself reached by 0 captures).  M0-PLAN.md 1699-1700 requires a reach-guaranteed string chosen from captured output, so the neighbouring row of the same `Error.to_string` match was used, reach-proved first by `rg -l 'duplicate global ' $OUT/base1` = 8 stderr captures.  The row cites this number on disk |
| D15 | `dev/inst-key-enc.golden` was generated from the built executable directly, not through the plan's `dune exec --root ... test/keygolden/keygolden.exe` (M0-PLAN.md 3161-3162) | a PreToolUse hook denies raw `dune`, and the part-1 house rule (stage-c-brief C5) mandates the built executable.  The output is byte-identical to part 1's smoke capture, so the golden content is unaffected.  Runner `scratch/stage-c-close/04-golden.sh`, evidence `04-golden.out` |
| D16 | the close block's first marker is spelled `PASS-T0-BUILD-LEG1`, not `PASS-T0-BUILD` | only leg 1 of that gate, the vendor build, exists today.  Leg 2 is the Stage E1 `exit 9` placeholder for `bin/tally.exe` (M0-PLAN.md 3773-3774), so the whole-gate name would over-claim.  The leg itself is unweakened |
| D17 | mutation row 3's red is a LINK-time error, not the type-checker error the plan wording predicts | `let _ = Str.regexp ""` in `lib/error.ml` gives `E _none_:1:0  -  No implementations provided for the following modules: "Str" referenced from "lib/tot_kernel.cmxa(Tot_kernel__Error)"` and `FAIL build: 1 error, 1 warning (hidden)`, not `Unbound module Str`, because dune keeps the `str` `.cmi` on the load path while `lib/dune` names no library.  The invariant is still compiler-enforced and never text-enforced, which is what M0-PLAN.md 1744-1750 asserts |
| D18 | each mutation cycle's owning leg ran as its OWN zsh process (`scratch/stage-c-close/rows/lega.sh`, `legb.sh`, `legb-numstat.sh`, `legb-untracked.sh`, each the close prologue plus that leg block verbatim), invoked as `set +e; zsh <leg>; lrc=$?; set -e` | zsh suppresses `errexit` inside a `( set -e ... ) || rc=$?` subshell.  The first row-1 attempt sailed past a FAILED `dunecho build` and printed a vacuous `PASS-T0-KERNEL-SPLIT-A` with `LEG-A-EXIT 0`.  That attempt was DISCARDED, the plant cleared with `git -C vendor/tot checkout HEAD -- lib/check.ml`, and the cycle re-run;  `rows/01-red.out` is the honest re-run.  The leg text is unchanged, only the process boundary moved.  The discarded capture was overwritten by the honest re-run and has no surviving path, so `rows/01-red.out` is the only row-1 red on disk |
| D19 | the reach probe of M0-PLAN.md 1703 (`rg -oh 'unbound global [a-zA-Z_]+' ...`) was not run as written | on ripgrep 15.1.0 `-h` is `--help`, so that command prints the option list and matches nothing.  Reach was proved with `rg -l` under `$OUT/base1` plus `rg -o --no-filename`.  No gate line contains `rg -oh` |

D14 was claimed by two builders in parallel.  It is resolved in favour of
the `dev/MUTATION-LOG.md` row that already cites it on disk;  the golden
form takes D15.

### Logged, not numbered

- Marker spelling: M0-PLAN.md 1381 names ONE gate marker,
  `PASS-T0-KERNEL-SPLIT`.  The close block echoes one marker per leg,
  `PASS-T0-KERNEL-SPLIT-A` to `-E`, and entry 4 echoes
  `PASS-T0-KERNEL-SPLIT-D`.  Both weaken no leg.
- Leg b exclusion: the alternation `interp\.ml|json_escape\.ml|dune`
  (Stage B step 2, build-log line 158) replaces M0-PLAN.md 1423-1424's
  static pair.  M0-PLAN.md 1438-1444 declares the exclusion a STAGE
  PARAMETER re-derived from the committed manifest.  Residue rows = 0.
- Floor literal: M0-PLAN.md 1656 reads "264 against the frozen 265", which
  is DRYRUN arithmetic.  Stage B step 7 re-froze `ROWS_FROZEN` to 405, so
  row 6's red is 404 against 405.
- Owning-commit sha: every Stage C plan block writes the pin as `4f75130`
  (PIN_OLD).  Today's pin is PIN_M5
  `66b444fe8380c82f0a74093ffaa779371d014a9b`, and the rows cite PIN_M5.
- Porcelain preconditions: M0-PLAN.md 538-543 says they are deliberately
  NOT blanket-applied, and inside Stage C spells them only at leg d
  (1735).  Every HEAD-form cycle here runs them anyway, which is stronger.
  Rows 6, 7 and 8 are not HEAD-form (twin restore and tally index restore),
  and row 5 plants an untracked file by design.
- The compiler-enforcement mutation is authored in leg d's block
  (M0-PLAN.md 1744-1750) but reddens leg a's build.  Row 3 names both the
  authoring site and the reddening leg.
- Row 10's target arm is `let rec term`'s `Term.Univ` case at
  `lib/pp.ml:32`, reach-proved by 7749 `Type 0` occurrences over 69
  `base1` captures.  M0-PLAN.md 1709-1713 names no arm.
- Row 4's green adds an explicit rebuild after the restore.  Leg b never
  builds, so the build is evidence, not part of the leg.
- Hand-off: M0-PLAN.md 1804-1807 orders a third item, "the battery run
  that closes the stage".  It is discharged at Stage C by D12's reason, as
  no prefix of the battery can complete.  The submodule commit is on a
  detached HEAD, which advances HEAD exactly as a branch commit would.
- The stray `_build/` in the tally root came back with leg a's walk, as
  part 1 predicted.  It holds dune root metadata only.  No `.gitignore`
  row was added;  that USER decision is still open.
- Close leg a inherits a wall-clock flake from vendored tot
  dev/gates.sh:2963-2968, which runs `check --check-budget-ms 5` and
  requires exit 0 (its own FLAKE CONTROL comment sits at 2956-2958).
  Under load that leg returns 3, the walk prints
  FAIL-M6D-COLD-OUTSIDE-BUDGET, and leg a reddens through the GATE-EXIT
  check.  Observed once in four close attempts on an unmodified tree;
  three bare walks after it were 371 PASS.  A red there is an upstream
  tot flake at PIN_M5, not a split regression.
