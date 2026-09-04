#!/bin/zsh
set -e
command -v gtimeout > /dev/null || { echo FAIL-T0-FLOORS-NO-WATCHDOG; exit 1; }   # the house watchdog rule: absence is itself a failure (R10)
D="$1"; test -d "$D"
test "$(ls "$D" | wc -l)" -eq 405   # ROWS_FROZEN, a literal; re-frozen at Stage B step 7 from the PIN_M5 corpus (101 rows x 4 + 1 = 405), never derived at gate time (R13)
test "$(cat "$D"/*/exit | rg -c '^0$')" -ge 40
test "$(cat "$D"/*/exit | rg -cv '^0$')" -ge 20
test "$(cat "$D"/*/stdout | wc -c)" -ge 20000
test "$(cat "$D"/*/stderr | wc -c)" -ge 5000
echo PASS-T0-SPLIT-FLOORS
exit 0
