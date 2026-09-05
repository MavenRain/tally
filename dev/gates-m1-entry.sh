#!/bin/zsh
# PASS-T1-CITATIONS: runs at M1 ENTRY, not in the M0 battery.
# Usage: gates-m1-entry.sh [ROWS]; ROWS is an rg alternation of ledger
# row ids, default 'C(1|2)'.  An M1 stage consuming further constants
# invokes this gate with its own rows, e.g. 'C(1|2|6|9)'.
ROWS="${1:-C(1|2)}"
st=0
rg -n "^\| ${ROWS} \|.*\| UNVERIFIED \|\$" \
  /Users/oobi/Documents/tally/dev/CITATION-LEDGER.md || st=$?
test "$st" -eq 1 && echo PASS-T1-CITATIONS
test "$st" -eq 1
