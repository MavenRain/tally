#!/bin/zsh
set -e
# The M0 top-level battery (M0-PLAN.md section 7): entries 0-19 exactly.
# Not-yet-built legs are `exit 9` placeholders; a placeholder never passes.
# This script holds NO stage-close floor block: those live in
# dev/gates-stage-a.sh and dev/gates-stage-c.sh (R9, F91).
export LC_ALL=C LANG=C TZ=UTC
export COLUMNS=80
TALLY=/Users/oobi/Documents/tally
BASEDIR=/Users/oobi/Documents/tally-m0/baseline-$(cat "$TALLY/PIN")
BASE="$BASEDIR/tot-baseline.exe"
OUT=/Users/oobi/Documents/tally-m0/gate-out
WBIN="$TALLY/vendor/tot/_build/default/bin/tot.exe"
command -v gtimeout > /dev/null || { echo FAIL-T0-NO-WATCHDOG; exit 1; }

# 0. PASS-T0-BUILD
dunecho build -- --root /Users/oobi/Documents/tally/vendor/tot
echo FAIL-T0-BUILD-PLACEHOLDER-LEG2; exit 9   # leg 2 needs Stage E1's bin/tally.ml
dunecho build -- --root /Users/oobi/Documents/tally bin/tally.exe
echo PASS-T0-BUILD

# 1. PASS-T0-PIN
PINSHA="$(cat /Users/oobi/Documents/tally/PIN)"
git -C /Users/oobi/Documents/tally/vendor/tot merge-base --is-ancestor \
  "$PINSHA" HEAD                                     # leg 1: HEAD descends from PIN
test "$(git -C /Users/oobi/Documents/tally ls-files -s vendor/tot | cut -d' ' -f2)" \
   = "$(git -C /Users/oobi/Documents/tally/vendor/tot rev-parse HEAD)"   # leg 2: gitlink records HEAD
test "$(cat "$BASEDIR/pin.txt")" = "$PINSHA"         # pin-record leg: the SHA recorded at step 5, not a re-derivation of the same file (R10)
test -s "$BASEDIR/pass-count.txt"
test -d "$OUT"                                       # absence legs read a real parent, never a vacuous missing one (R9)
dst=0; ls "$OUT" | rg -q '^dryrun-' || dst=$?
test "$dst" -eq 1        # NO dryrun-* child survives step 7's delete; a hit (0) is red (R9)
echo PASS-T0-PIN

# 2. PASS-T0-BASELINE
test -s "$BASEDIR/gate-exit.txt"
test "$(cat "$BASEDIR/gate-exit.txt")" -eq 0
test -s "$BASEDIR/fail-count.txt"
test "$(cat "$BASEDIR/fail-count.txt")" -eq 0
echo PASS-T0-BASELINE

# 3. PASS-T0-KERNEL-LAYERING
echo FAIL-T0-KERNEL-LAYERING-PLACEHOLDER; exit 9   # Stage D0

# 4. PASS-T0-KERNEL-SPLIT leg d
st=0
rg -c 'libraries' /Users/oobi/Documents/tally/vendor/tot/lib/dune || st=$?
test "$st" -eq 1    # exactly "no match"; a match (0) or a missing/unreadable file (2) is red
echo PASS-T0-KERNEL-SPLIT-D

# 5. PASS-T0-TOWER-SCOPE
echo FAIL-T0-TOWER-SCOPE-PLACEHOLDER; exit 9   # Stage D

# 6. PASS-T0-KERNEL-SPLIT leg e, tower-manifest form
echo FAIL-T0-KERNEL-SPLIT-E-PLACEHOLDER; exit 9   # Stage D close

# 7. PASS-T0-WORD-INERT
echo FAIL-T0-WORD-INERT-PLACEHOLDER; exit 9   # Stage D

# 8. PASS-T0-WORD-UNREACHED
echo FAIL-T0-WORD-UNREACHED-PLACEHOLDER; exit 9   # Stage D

# 9. PASS-T0-WORD-ORACLE
echo FAIL-T0-WORD-ORACLE-PLACEHOLDER; exit 9   # Stage D

# 10. PASS-T0-WORD-BOUNDARY
echo FAIL-T0-WORD-BOUNDARY-PLACEHOLDER; exit 9   # Stage D

# 11. PASS-T0-WORD-QUANTITY
echo FAIL-T0-WORD-QUANTITY-PLACEHOLDER; exit 9   # Stage D

# 12. PASS-T0-NO-NEW-AXIOM
echo FAIL-T0-NO-NEW-AXIOM-PLACEHOLDER; exit 9   # Stage D

# 13. PASS-T0-WORD-TOWER legs a-e
echo FAIL-T0-WORD-TOWER-PLACEHOLDER; exit 9   # Stage D close

# 14. PASS-T0-SPEED
echo FAIL-T0-SPEED-PLACEHOLDER; exit 9   # Stage E2

# 15. PASS-T0-NO-EMITTER
echo FAIL-T0-NO-EMITTER-PLACEHOLDER; exit 9   # Stage E3

# 16. PASS-T0-NO-SURFACE-TAL
echo FAIL-T0-NO-SURFACE-TAL-PLACEHOLDER; exit 9   # Stage E3

# 17. PASS-T0-M1-GATE-DEFINED
echo FAIL-T0-M1-GATE-DEFINED-PLACEHOLDER; exit 9   # Stage E4

# 18. PASS-T0-RECORD-INTACT
echo FAIL-T0-RECORD-INTACT-PLACEHOLDER; exit 9   # Stage B step 8 + E4

# 19. PASS-T0-EXIT-RATIFIED
echo FAIL-T0-EXIT-RATIFIED-PLACEHOLDER; exit 9   # the user's section 12 item 1 stamp

exit 0
