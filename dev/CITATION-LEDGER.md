# tally citation ledger: M1 Stage A discharge

Created 2026-09-04 at M0 Stage E (sub-block E4), M0-PLAN.md section 10
(`plan 4382-4427`), committed as `tally/dev/CITATION-LEDGER.md`.  The gate
that reads this file is the executable `tally/dev/gates-m1-entry.sh`
(PASS-T1-CITATIONS): it runs at M1 ENTRY and never inside the M0 battery.
The M0 battery asserts only that the gate EXISTS and ECHOES its marker
(entry 17, PASS-T0-M1-GATE-DEFINED).

## Current state: M1 Stage A, 2026-09-06

The ledger has 36 rows: 33 status cells begin with `VERIFIED`, including
C11's `VERIFIED-REFUTED`, and S18, S19 and S20 remain `UNVERIFIED`.
Stage A discharged C1-C12, the three fences, S1-S17 and S21 against the
five clean source trees listed in `dev/m1-source-pins.txt`. Their HEADs and
the cited source lines were read again on 2026-09-06. Source keys below
resolve under `/Users/oobi/Documents/tally-m1/sources/`.

The exact C1-C12 and F-EMIT-SHIFT status cells come from
`tally-m1/citation-pins.md`; F-SPEC and F-EMIT use M1-PLAN.md section 10.2
under RUL-O12. C2's mainnet observation and C5's experiment remain dated
2026-09-04 evidence. No current cluster activation claim is made here.
A fresh OCaml 5.2.1 bytecode run on 2026-09-06 also returned
`div=-9223372036854775808` and `rem=0`; no native experiment was run.

Filling a cell is documentation work. The frozen live M0 fence remains
required throughout Stage A. Starting at Stage B, T1-6 and T1-7 enforce
the live M1 tree while T1-1 replays the frozen M0 tree. Numeric target
parameters remain forbidden until their consuming stage applies T1-12.

The original rows retain M0's recalled-value and obligation columns as
history; the terminal status cell records their discharge. C3 refutes raw
instruction agreement with total division, C11 refutes an acyclicity rule,
and C12 separates the deployed image cap from C10's transaction packet cap.

## M0 gate-defining paragraph (historical, M0-PLAN.md section 10, `plan 4384-4403`)

At M0 close, every row was UNVERIFIED;  gate G5 denies each NAMED value from tally
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

## Original constant rows (`plan 4405-4418`)

| id | constant / fact | recalled value (do not trust) | citation obligation | status |
|---|---|---|---|---|
| C1 | `MAX_INSTRUCTION_STACK_DEPTH` (Q4's MAX;  per-cluster compiler parameter, default 5, never baked into the kernel) | 5 | Agave source file:line | VERIFIED agave@5466f459 program-runtime/src/execution_budget.rs:7 |
| C2 | SIMD-0268 feature gate raising MAX to 9 | 9 | SIMD-0268 text plus the Agave feature-gate site | VERIFIED SIMD-0268 (simd@4828b2dd proposals/0268-raise-cpi-nesting-limit.md:29-30) plus agave-master@f46e7976 program-runtime/src/execution_budget.rs:10 and feature-set/src/lib.rs:1311; not active on mainnet 2026-09-04 |
| C3 | sBPF div/mod-by-zero semantics (memo 1 U1;  classic eBPF `dst = 0`/unchanged vs recalled solana_rbpf `DivideByZero`) | disagree | rbpf/Agave source per SBPF version;  until then fence F-EMIT stands | VERIFIED sbpf@e7e51529 src/interpreter.rs:54-56,417-470 (runtime DivideByZero/DivideOverflow) and src/verifier.rs:115; F-EMIT guard stands |
| C4 | ALU32 zero- vs sign-extension into 64-bit registers (memo 1 U2) | unknown | rbpf/Agave source | VERIFIED sbpf@e7e51529 src/program.rs:37-39, src/interpreter.rs:159-169,257-264,280-287,305-309: V2+ ALU32 results zero-extend, MOV32_REG sign-extends |
| C5 | `Int64.div Int64.min_int (-1L)` behavior (memo 1 U3, UNVERIFIED-OCAML;  why signed division is M1) | unspecified | OCaml manual or a pinned toolchain experiment, recorded | VERIFIED pinned experiment OCaml 5.2.1 arm64 2026-09-04: div = min_int (wraps), rem = 0; bytecode toplevel only |
| C6 | account-input serialization layout (field order, padding, realloc slack) | n/a | Agave loader source | VERIFIED agave@5466f459 program-runtime/src/serialization.rs:23,121-133,236,461,492-493,497 and solana-sdk@1c1d667f program-entrypoint/src/lib.rs:40,43,316,406-458 |
| C7 | 4 KiB stack frame and 64-deep call limit | 4096 / 64 | Agave/rbpf source | VERIFIED agave@5466f459 program-runtime/src/execution_budget.rs:10,13 and sbpf@e7e51529 src/vm.rs:85-86,93-94, src/interpreter.rs:145-146,149-153, src/program.rs:28-30 |
| C8 | 32 KiB default heap, 256 KiB expansion | 32768 / 262144 | Agave source | VERIFIED agave@5466f459 program-runtime/src/execution_budget.rs:24-25 and solana-sdk@1c1d667f program-entrypoint/src/lib.rs:40 |
| C9 | default per-instruction CU budget | 200000 | Agave source | VERIFIED agave@5466f459 program-runtime/src/execution_budget.rs:20 |
| C10 | transaction byte cap (drives the M1+ deploy pipeline) | n/a | Agave source | VERIFIED solana-sdk@1c1d667f packet/src/lib.rs:27,32 (1232 bytes) |
| C11 | acyclic call-graph verifier rule (the recursion-to-trampoline strategy depends on it) | believed | rbpf verifier source | VERIFIED-REFUTED sbpf@e7e51529 src/verifier.rs:411-419 (target-exists only), src/interpreter.rs:145-146 (runtime depth 64): no acyclicity rule |

## The M1 fence rows (`plan 2118-2124`, `plan 2138-2144`, Stage D probe O-7)

The same status column and the same terminal-cell shape, so an M1 stage
consuming one of these fences invokes `gates-m1-entry.sh` with its id in
the ROWS argument, exactly as it does for C1-C11.

| id | fence | recalled value (do not trust) | citation obligation | status |
|---|---|---|---|---|
| F-SPEC | division by zero is DEFINED-TOTAL (Lean's discipline): `x / 0 = 0`, `x % 0 = x`;  tally's spec states it as normative; M0 marked the sBPF correspondence UNVERIFIED and deferred it to this ledger | x / 0 = 0, x % 0 = x | the C3 obligation discharges it | VERIFIED sbpf@e7e51529 src/interpreter.rs:54-56,417-470 (runtime DivideByZero/DivideOverflow) and src/verifier.rs:115: the raw instruction aborts, so F-SPEC's total division needs F-EMIT's guard |
| F-EMIT | recorded M1 debt: the emitter lowers div/mod as a GUARDED sequence UNLESS M1 cites Agave/rbpf source proving the raw instruction agrees | guarded lowering | Agave/rbpf source for the emitted width | VERIFIED sbpf@e7e51529 src/interpreter.rs:54-56,417-470 and src/verifier.rs:115: guarded lowering stands; signed div/rem also guard min / -1 (DivideOverflow) |
| F-EMIT-SHIFT | recorded M1 debt (D2): `shl`/`shr` with `s >= W` return 0 at the family's width (saturate-to-zero), while BPF-family ALUs MASK the shift amount, so the emitter lowers shifts as a GUARDED sequence UNLESS M1 cites rbpf/Agave source proving the raw instruction's amount handling agrees on the emitted width | saturate-to-zero vs amount-masking | rbpf/Agave source for the emitted width | VERIFIED sbpf@e7e51529 src/interpreter.rs:284-287,369-372 (register amount masked) and src/verifier.rs:209-216 (immediate >= width rejected); guarded lowering stands, never emit an immediate shift >= width |

`F-ERGO` is NOT a ledger row and carries no citation obligation: the
prelude ships `u64DivChecked : U64 -> U64 -> Option U64` as a plain
reducing `def`, no axiom, and it is delivered at M0.

## M0 debt appendix (historical, `plan 4419-4427`)

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

## M1 rows: image cap and target facts

These rows use the same five columns and terminal status cell as the
original ledger. VERIFIED pins name the frozen source tree revision.
S18-S20 are obligations, and no constant from them enters code yet.

| id | constant / fact | value or scope | citation obligation | status |
|---|---|---|---|---|
| C12 | deployable program image cap, `MAX_PERMITTED_DATA_LENGTH` | 10 * 1024 * 1024 bytes | Pinned SDK constant, consumed by the Stage C linker as `image_cap_bytes` | VERIFIED solana-sdk@1c1d667f transaction-context/src/lib.rs:27 (MAX_PERMITTED_DATA_LENGTH = 10 * 1024 * 1024 bytes) |
| S1 | V3 static syscalls: `imm` is the murmur3 key, opcode SYSCALL; `sol_log_`, `sol_get_stack_height`, `sol_invoke_signed_rust` registered | Stage C | agave programs/bpf_loader/src/syscalls/mod.rs:379,470,478; sbpf src/verifier.rs:423-427, src/interpreter.rs:548-556 | VERIFIED agave@5466f459 programs/bpf_loader/src/syscalls/mod.rs:379,470,478; sbpf@e7e51529 src/verifier.rs:423-427, src/interpreter.rs:548-556 |
| S2 | region bases MM_REGION_SIZE 1<<32, MM_BYTECODE_START 0, MM_RODATA_START 1<<32, MM_STACK_START 2<<32, MM_HEAP_START 3<<32, MM_INPUT_START 4<<32 | Stage C | sbpf src/ebpf.rs:43,45,47,49,51,53 | VERIFIED sbpf@e7e51529 src/ebpf.rs:43,45,47,49,51,53 |
| S3 | verifier register legality: src r0-r10, dst r0-r9, r10 writable only as a store base or aligned ADD64_IMM, CALLX target r0-r9 | Stage C | sbpf src/verifier.rs:190-206,220-234 | VERIFIED sbpf@e7e51529 src/verifier.rs:190-206,220-234 |
| S4 | V3 file header: `e_flags = 3` at byte 48, ET_DYN 3, EM_SBPF 263, ELFCLASS64, ELFDATA2LSB, e_phoff = 64 | Stage C | sbpf src/elf.rs:373-390,431-450 | VERIFIED sbpf@e7e51529 src/elf.rs:373-390,431-450 |
| S5 | five expected program headers in order: PT_LOAD PF_X at 0, PT_LOAD PF_R at 1<<32, PT_GNU_STACK PF_R+PF_W at 2<<32, PT_LOAD PF_R+PF_W at 3<<32, PT_NULL at 0xFFFFFFFF00000000 | Stage C | sbpf src/elf.rs:456-482 | VERIFIED sbpf@e7e51529 src/elf.rs:456-482 |
| S6 | opcode bytes MOV64_IMM 0xb7, RETURN 0x9d, EXIT 0x95, SYSCALL 0x95, CALL_IMM 0x85, CALL_REG 0x8d | Stage C | sbpf src/ebpf.rs:394,487,485,489,481,483 | VERIFIED sbpf@e7e51529 src/ebpf.rs:394,487,485,489,481,483 |
| S7 | murmur3 symbol hashing produces the function and syscall keys | Stage C | sbpf src/program.rs:138-165 (legacy helper); key use at src/interpreter.rs:548-556 | VERIFIED sbpf@e7e51529 src/program.rs:138-165 (legacy helper); key use at src/interpreter.rs:548-556 |
| S8 | NON_DUP_MARKER = 255, MAX_INSTRUCTION_ACCOUNTS = NON_DUP_MARKER | Stage D | solana-sdk program-entrypoint/src/lib.rs:43; agave program-runtime/src/serialization.rs:23 | VERIFIED solana-sdk@1c1d667f program-entrypoint/src/lib.rs:43; agave@5466f459 program-runtime/src/serialization.rs:23 |
| S9 | 88-byte per-account fixed prefix and its field order | Stage D | agave program-runtime/src/serialization.rs:460-481; solana-sdk program-entrypoint/src/lib.rs:332-395 | VERIFIED agave@5466f459 program-runtime/src/serialization.rs:460-481; solana-sdk@1c1d667f program-entrypoint/src/lib.rs:332-395 |
| S10 | MAX_PERMITTED_DATA_INCREASE = 10240, BPF_ALIGN_OF_U128 = 8, padding rule | Stage D | solana-sdk account-info/src/lib.rs:17; solana-sdk program-entrypoint/src/lib.rs:316,376-377 | VERIFIED solana-sdk@1c1d667f account-info/src/lib.rs:17; solana-sdk@1c1d667f program-entrypoint/src/lib.rs:316,376-377 |
| S11 | TRANSACTION_LEVEL_STACK_HEIGHT = 1, top-level programs see height 1 | Stage E | solana-sdk instruction/src/lib.rs:290; agave program-runtime/src/invoke_context.rs:297-301 | VERIFIED solana-sdk@1c1d667f instruction/src/lib.rs:290; agave@5466f459 program-runtime/src/invoke_context.rs:297-301 |
| S12 | `InstructionError::CallDepth` is the depth-overflow payload | Stage E | solana-sdk instruction/src/error.rs:166, display text `:335-337` | VERIFIED solana-sdk@1c1d667f instruction/src/error.rs:166, display text `:335-337` |
| S13 | the depth check site returns CallDepth on the push that would exceed MAX | Stage E | solana-sdk transaction-context/src/lib.rs:398 | VERIFIED solana-sdk@1c1d667f transaction-context/src/lib.rs:398 |
| S14 | max_instruction_trace_length default 64, a DIFFERENT limit with its own error | Stage E (negative discriminator) | agave program-runtime/src/execution_budget.rs:62; solana-sdk transaction-context/src/lib.rs:394 | VERIFIED agave@5466f459 program-runtime/src/execution_budget.rs:62; solana-sdk@1c1d667f transaction-context/src/lib.rs:394 |
| S15 | syscall costs: syscall_base_cost 100, invoke_units 1000, cpi_bytes_per_unit 250, sol_log charged max(base, len) | Stage C (cost report) | agave program-runtime/src/execution_budget.rs:174,167,171; agave programs/bpf_loader/src/syscalls/logging.rs:15-18 | VERIFIED agave@5466f459 program-runtime/src/execution_budget.rs:174,167,171; agave@5466f459 programs/bpf_loader/src/syscalls/logging.rs:15-18 |
| S16 | V3 entry resolution is positional through `e_entry`; the name "entrypoint" is a toolchain convention, not a loader requirement | Stage C | sbpf src/elf.rs:412-608; sbpf tests/elf.rs:33-45 | VERIFIED sbpf@e7e51529 src/elf.rs:412-608; sbpf@e7e51529 tests/elf.rs:33-45 |
| S17 | minimal legal V3 function: `mov64 r0, 0` then `return`, 16 bytes, last instruction RETURN | Stage C | sbpf src/ebpf.rs:394,487; src/verifier.rs:253-262 | VERIFIED sbpf@e7e51529 src/ebpf.rs:394,487; src/verifier.rs:253-262 |
| S18 | bpf-to-bpf argument register convention; the syscall half is pinned | Stage C; the candidate convention is not ratified | User's ratified OQ-3 answer, recorded by Stage C with the exact M1-PLAN.md 10.1 cell; source evidence establishes only the VM-enforced half | UNVERIFIED |
| S19 | the litesvm version whose sbpf executes V3 | Stage E | OBLIGATION: pin a runtime version whose V3 execution works and whose raise_cpi_nesting_limit_to_8 feature is deactivatable; Stage E records the lockfile line after provisioning line 3 | UNVERIFIED |
| S20 | platform-tools v1.48 contents and the `cargo-build-sbf --arch v3` output header set | Stage E | OBLIGATION: record the platform-tools v1.48 contents and second-author build provenance after provisioning line 2; the dangling symlink is an observation dated 2026-09-04 | UNVERIFIED |
| S21 | re-entry is refused unless the caller is calling itself: `if contains && !is_last {` returns `InstructionError::ReentrancyNotAllowed`, under the comment "Reentrancy not allowed unless caller is calling itself" | Stage E (the CPI driver of RUL-R2-3) | agave program-runtime/src/invoke_context.rs:279-281, comment `:280` | VERIFIED agave@5466f459 program-runtime/src/invoke_context.rs:279-281, comment `:280` |
S15's citation order follows its value order: `syscall_base_cost = 100` at
`execution_budget.rs:174`, `invoke_units = 1000` at `:167`, and
`cpi_bytes_per_unit = 250` at `:171`; logging charges `max(base, len)` at
`programs/bpf_loader/src/syscalls/logging.rs:15-18`.
Fresh supplementary checks also read the Murmur3 implementation at
`sbpf src/ebpf.rs:654-657`, the V3 selector at `src/elf.rs:390-394`, the
header constants at `src/elf_parser/consts.rs:9,12,19,24`, the positional
entry resolution at `src/elf.rs:574-585`, and the opcode component
constants at `src/ebpf.rs:70,74,123,125,151,196,198,200`.
The pinned loader fixtures remain `strict_header.so` (1856 bytes) and
`syscall_static.so` (1648 bytes) under the source tree's `tests/elfs/`.

## How a row is discharged

1. Obtain the pinned source citation, or the row's explicitly permitted
   evidence. S18 requires the user's ratified OQ-3 answer, recorded by
   Stage C. S19 and S20 require Stage E's lockfile or provenance evidence.
2. Rewrite the terminal status cell to `VERIFIED <evidence>`. C11 alone
   uses `VERIFIED-REFUTED`; no implementation consumes its refuted claim.
3. Re-run `zsh /Users/oobi/Documents/tally/dev/gates-m1-entry.sh 'C1|C2'`
   or the invoking stage's flat pipe list. The grouped row selector checks
   exact row boundaries and the expected row count, and rejects selected
   terminal cells beginning with `UNVERIFIED` before it prints
   `PASS-T1-CITATIONS`. T1-2 separately checks the fence cells and requires
   its positive VERIFIED status count before printing `PASS-T1-LEDGER`;
   a blank status cell cannot pass that battery entry.
4. When a later stage discharges an obligation row, add its id to that
   stage's T1-2 `ROWS` string and increase T1-2's count literal in the same
   change (RUL-O11). A partial discharge cannot pass the count check.

Stage A's own T1-2 string has 15 ids, despite its 33 discharged cells:

```
A_ROWS='C1|C2|C3|C4|C5|C6|C7|C8|C9|C10|C11|C12|F-SPEC|F-EMIT|F-EMIT-SHIFT'
```

The succession strings and per-stage counts are normative in
`tally-m1/M1-PLAN.md` section 10.6. Stage B reuses `A_ROWS`; later stages
append their target rows. S18 stays out until the user's answer is
ratified, and S19-S20 stay out until provisioning discharges them.
