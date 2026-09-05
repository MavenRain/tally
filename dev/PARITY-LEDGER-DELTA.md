# tally parity-ledger delta (M0, written at Stage E sub-block E4)

Created 2026-09-04, M0-PLAN.md `plan 3671-3686`.  This file is the DELTA
against the parity ledger the design verdict carries: it relabels the rows
M0 changed and adds the rows M0 discovered.  Each row's status token is
load-bearing.  Battery entry 18 leg 3 (PASS-T0-RECORD-INTACT,
`plan 3867-3868`) reads the cumulativity row's parenthesised stamp token,
so the stamp of M0-PLAN.md section 12 item 2 cannot be silently dropped
after close-out.

## Relabelled rows

- `Nat/Int: REPLACED`.  Normative text: "Nat/Int: REPLACED for contract
  arithmetic by the machine-word tower;  `Nat` remains a proof-side unary
  inductive;  `Int` remains the 63-bit host int used by the string prims;
  no coercion between the towers exists, by design;  a total
  `u64OfInt : Int -> Option U64` is the only non-laundering bridge shape
  and is DEFERRED to M1+".
- `String logging-only: NOT M0-DELIVERED`.  The row previously read as a
  delivered logging-only parity item;  it is relabelled NOT M0-delivered.
  The string prims that do ship at M0 are the ones the prims golden
  (`dev/prims-appended.golden`) pins, and no logging surface is claimed.
- `cumulativity: NEVER (RATIFY per Q5, 2026-09-03)`.  Universe
  cumulativity is never added to the kernel: the tower and the M0 surface
  are built without it, and no later milestone may introduce it as a
  compatibility shim.  Ratified per Q5 in chat 2026-09-03 and recorded in
  `/Users/oobi/Documents/tally-m0/RATIFICATIONS.md` item 2;  the token
  spelling here is the parenthesised form battery entry 18 leg 3 accepts,
  which is Stage E deviation D95 against the item's own dash spelling.

## Added rows

- `implicit arguments: M3`.  Implicit-argument elaboration is not in M0's
  surface and is not a parity claim before M3.
- `Prop impredicativity / proof irrelevance: OPEN, M3`.  Neither is
  decided at M0.  The M0 kernel has no `Prop` sort of its own, so nothing
  in the tower depends on the answer;  the row exists so the question is
  not silently inherited from another system's defaults.
- `decidable word equality: BOOLEAN ONLY in M0`.  Normative text:
  "decidable word equality: BOOLEAN ONLY in M0;  closed instances decide
  by conv;  the open propositional bridge is DEFERRED to M2, and is
  deliberately not an axiom".

## Reading order

This delta is read WITH the verdict's parity ledger, never instead of it.
A row absent here is unchanged by M0.  `dev/CITATION-LEDGER.md` carries
the separate UNVERIFIED-constant obligations, and the two files share no
rows.
