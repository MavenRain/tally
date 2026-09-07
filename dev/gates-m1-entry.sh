#!/bin/zsh
# PASS-T1-CITATIONS: runs at M1 ENTRY, not in the M0 battery.
# Usage: gates-m1-entry.sh [ROWS]; default 'C(1|2)'.
# ROWS grammar: uppercase row ids joined by '|', optionally sharing ONE
# parenthesized suffix group. No empty alternative, nested group, character
# class, quantifier, wildcard or anchor. Each '|' adds one expected row.
set -e
LEDGER=/Users/oobi/Documents/tally/dev/CITATION-LEDGER.md
ROWS="${1:-C(1|2)}"
case "$ROWS" in
  (*$'\n'*|*$'\r'*) echo "gates-m1-entry: ROWS outside the grammar: $ROWS"; exit 2 ;;
esac
ID='[A-Z][A-Z0-9-]*'
SUFFIX='[A-Z0-9][A-Z0-9-]*'
GRAMMAR="^(${ID}(\|${ID})*|(${ID}\|)*${ID}\(${SUFFIX}(\|${SUFFIX})*\)(\|${ID})*)$"
printf '%s\n' "$ROWS" | rg -qx "$GRAMMAR" || {
  echo "gates-m1-entry: ROWS outside the grammar: $ROWS"
  exit 2
}
EXPECT=$(( $(printf '%s' "$ROWS" | tr -cd '|' | wc -c) + 1 ))
st=0
FOUND=$(rg -c "^\| (${ROWS}) \|" "$LEDGER") || st=$?
test "$st" -eq 0
test "$FOUND" -eq "$EXPECT"
st=0
rg -n "^\| (${ROWS}) \|.*\| UNVERIFIED[^|]*\|\$" "$LEDGER" || st=$?
test "$st" -eq 1 && echo PASS-T1-CITATIONS
test "$st" -eq 1
