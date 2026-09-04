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
