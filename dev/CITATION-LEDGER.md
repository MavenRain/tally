# tally citation ledger: UNVERIFIED constants deferred, with obligations

Created 2026-09-04 at M0 Stage E (sub-block E4), M0-PLAN.md section 10
(`plan 4382-4427`), committed as `tally/dev/CITATION-LEDGER.md`.  The gate
that reads this file is the executable `tally/dev/gates-m1-entry.sh`
(PASS-T1-CITATIONS): it runs at M1 ENTRY and never inside the M0 battery.
The M0 battery asserts only that the gate EXISTS and ECHOES its marker
(entry 17, PASS-T0-M1-GATE-DEFINED).

## The gate-defining paragraph (M0-PLAN.md section 10, `plan 4384-4403`)

Every row is UNVERIFIED at M0;  gate G5 denies each NAMED value from tally
sources (C1's bare `5` and C2's bare `9` via their name spellings plus the
numeric-literal review, per section 2.2);  a row's obligation must be
discharged with a source citation (repo file plus line or SIMD document)
BEFORE the value enters any M1+ code.  The Q4 amendment places rows C1-C2
under this M0 sub-gate, interpreted per section 4 item 12: M0's obligation
is to RECORD and BLOCK them (done here);  filling them is documentation
work permitted in M0 and MANDATORY before any M1 stage consumes `MAX` in
the emitter, enforced by the named gate PASS-T1-CITATIONS at M1 entry
(committed as the executable `tally/dev/gates-m1-entry.sh`, E4), which
fails while row C1 or C2 carries the `UNVERIFIED` token in the status
column below and blocks all emitter work until both are filled;  an M1
stage consuming any other row (C3-C11) invokes the same gate with that row
in its argument list, so "blocks all emitter work" is implemented per
consumed constant, not just for C1/C2 (R3 finding).  The status column is
the gate's key (R2 finding: without a per-row token the gate had nothing to
match and was green over an unfilled ledger);  discharging a row rewrites
its status to `VERIFIED <source file:line or SIMD doc>`.

Filling a row is documentation only and never admits the constant into
code: G5 (battery entry 15, PASS-T0-NO-EMITTER) keeps denying every named
value in the tally source globs, and this ledger is a `.md` document
outside that glob set by design.

## The rows (`plan 4405-4418`)

| id | constant / fact | recalled value (do not trust) | citation obligation | status |
|---|---|---|---|---|
| C1 | `MAX_INSTRUCTION_STACK_DEPTH` (Q4's MAX;  per-cluster compiler parameter, default 5, never baked into the kernel) | 5 | Agave source file:line | UNVERIFIED |
| C2 | SIMD-0268 feature gate raising MAX to 9 | 9 | SIMD-0268 text plus the Agave feature-gate site | UNVERIFIED |
| C3 | sBPF div/mod-by-zero semantics (memo 1 U1;  classic eBPF `dst = 0`/unchanged vs recalled solana_rbpf `DivideByZero`) | disagree | rbpf/Agave source per SBPF version;  until then fence F-EMIT stands | UNVERIFIED |
| C4 | ALU32 zero- vs sign-extension into 64-bit registers (memo 1 U2) | unknown | rbpf/Agave source | UNVERIFIED |
| C5 | `Int64.div Int64.min_int (-1L)` behavior (memo 1 U3, UNVERIFIED-OCAML;  why signed division is M1) | unspecified | OCaml manual or a pinned toolchain experiment, recorded | UNVERIFIED |
| C6 | account-input serialization layout (field order, padding, realloc slack) | n/a | Agave loader source | UNVERIFIED |
| C7 | 4 KiB stack frame and 64-deep call limit | 4096 / 64 | Agave/rbpf source | UNVERIFIED |
| C8 | 32 KiB default heap, 256 KiB expansion | 32768 / 262144 | Agave source | UNVERIFIED |
| C9 | default per-instruction CU budget | 200000 | Agave source | UNVERIFIED |
| C10 | transaction byte cap (drives the M1+ deploy pipeline) | n/a | Agave source | UNVERIFIED |
| C11 | acyclic call-graph verifier rule (the recursion-to-trampoline strategy depends on it) | believed | rbpf verifier source | UNVERIFIED |

## The M1 fence rows (`plan 2118-2124`, `plan 2138-2144`, Stage D probe O-7)

The same status column and the same terminal-cell shape, so an M1 stage
consuming one of these fences invokes `gates-m1-entry.sh` with its id in
the ROWS argument, exactly as it does for C1-C11.

| id | fence | recalled value (do not trust) | citation obligation | status |
|---|---|---|---|---|
| F-SPEC | division by zero is DEFINED-TOTAL (Lean's discipline): `x / 0 = 0`, `x % 0 = x`;  tally's spec states it as normative and marks the sBPF correspondence UNVERIFIED, pointing at this ledger | x / 0 = 0, x % 0 = x | the C3 obligation discharges it | UNVERIFIED |
| F-EMIT | recorded M1 debt: the emitter lowers div/mod as a GUARDED sequence UNLESS M1 cites Agave/rbpf source proving the raw instruction agrees | guarded lowering | Agave/rbpf source for the emitted width | UNVERIFIED |
| F-EMIT-SHIFT | recorded M1 debt (D2): `shl`/`shr` with `s >= W` return 0 at the family's width (saturate-to-zero), while BPF-family ALUs MASK the shift amount, so the emitter lowers shifts as a GUARDED sequence UNLESS M1 cites rbpf/Agave source proving the raw instruction's amount handling agrees on the emitted width | saturate-to-zero vs amount-masking | rbpf/Agave source for the emitted width | UNVERIFIED |

`F-ERGO` is NOT a ledger row and carries no citation obligation: the
prelude ships `u64DivChecked : U64 -> U64 -> Option U64` as a plain
reducing `def`, no axiom, and it is delivered at M0.

## Debt appendix (`plan 4419-4427`)

Not constants;  named M1 decisions recorded at M0:

- signed div/mod/asr/compare semantics (H2/S-DIV);
- a separate `stdlib/prelude.tal` and the POSIX prim-name scope leak
  (section 4, item 5);
- `u64OfInt : Int -> Option U64` as the only permitted bridge shape;
- F-EMIT's guarded div/mod lowering obligation;
- F-EMIT-SHIFT's guarded shl/shr lowering obligation (D2: saturate-to-zero
  at `s >= W` vs the BPF family's amount-masking;  the emitter lowers
  shifts guarded UNLESS M1 cites rbpf/Agave source proving agreement on
  the emitted width).

## How a row is discharged

1. Obtain the citation (repo file plus line, or the SIMD document).
2. Rewrite that row's status cell to `VERIFIED <source file:line or SIMD doc>`.
3. Re-run `zsh /Users/oobi/Documents/tally/dev/gates-m1-entry.sh 'C(1|2)'`
   (or the invoking stage's own row alternation).  The gate prints
   `PASS-T1-CITATIONS` only when NO row in its argument still carries the
   `UNVERIFIED` token.
