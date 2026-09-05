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
dunecho build -- --root /Users/oobi/Documents/tally/vendor/tot lib   # kernel library alone
st=0
rg -c 'Prim\.|Literal\.' /Users/oobi/Documents/tally/vendor/tot/lib/word.ml || st=$?
test "$st" -eq 1        # word.ml names neither Prim nor Literal, comments included
test "$(rg -c '\{ *width|\{ *[a-z_]+ +with' /Users/oobi/Documents/tally/vendor/tot/lib/word.ml)" -eq 2
test "$(rg -c '^type order = Lt \| Eq \| Gt' /Users/oobi/Documents/tally/vendor/tot/lib/word.ml)" -eq 1
rg -q '^type order = Word\.order = Lt \| Eq \| Gt' /Users/oobi/Documents/tally/vendor/tot/lib/word_delta.ml
test "$(rg -l '^type order = Lt \| Eq \| Gt' /Users/oobi/Documents/tally/vendor/tot/lib/*.ml | wc -l)" -eq 1
test "$(rg -o '\{' /Users/oobi/Documents/tally/vendor/tot/lib/word.ml | wc -l)" -eq 2   # BRACE_FROZEN = 2, frozen at Stage D close (dev/MUTATION-LOG.md frozen-literal table); LAST leg of the D0 block (M0-PLAN.md 1881-1888, R5)
echo PASS-T0-KERNEL-LAYERING

# 4. PASS-T0-KERNEL-SPLIT leg d
st=0
rg -c 'libraries' /Users/oobi/Documents/tally/vendor/tot/lib/dune || st=$?
test "$st" -eq 1    # exactly "no match"; a match (0) or a missing/unreadable file (2) is red
echo PASS-T0-KERNEL-SPLIT-D

# 5. PASS-T0-TOWER-SCOPE
test -z "$(git -C /Users/oobi/Documents/tally/vendor/tot status --porcelain | rg '^\?\?')"
git -C /Users/oobi/Documents/tally/vendor/tot diff --name-only -M \
  "$(cat /Users/oobi/Documents/tally/PIN)" -- lib/ \
  | rg -v '^lib/(interp\.ml|json_escape\.ml|dune)$' \
  | sort | diff - /Users/oobi/Documents/tally/dev/tower-allowlist.txt
  # the alternation is a STAGE PARAMETER re-derived per R6 (M0-PLAN.md
  # 3220-3225) from the manifest's move-out rows: Stage D moves
  # lib/json_escape.ml to interp/json_escape.ml, so the three-way form
  # is what diffs empty against the nine-row allowlist (D37)
echo PASS-T0-TOWER-SCOPE

# 6. PASS-T0-KERNEL-SPLIT leg e, tower-manifest form
test -z "$(git -C /Users/oobi/Documents/tally/vendor/tot status --porcelain | rg '^\?\?')"
git -C /Users/oobi/Documents/tally/vendor/tot diff --name-status -M "$(cat /Users/oobi/Documents/tally/PIN)" \
  | sd '^R[0-9]+\t' $'R\t' | sort > "$OUT/tower-files.txt"
diff "$OUT/tower-files.txt" /Users/oobi/Documents/tally/dev/tower-manifest.txt
echo PASS-T0-KERNEL-SPLIT-E

# 7. PASS-T0-WORD-INERT
st=0
dune exec --root /Users/oobi/Documents/tally/vendor/tot test/main.exe \
  > "$OUT/main-walk.out" 2>&1 || st=$?
rg -q '^PASS m0word inert walk$' "$OUT/main-walk.out"
  # the runner's OVERALL exit is asserted at entry 13 leg a, never here
echo PASS-T0-WORD-INERT

# 8. PASS-T0-WORD-UNREACHED
st=0
rg -n '[0-9](u|i)(8|16|32|64)\b' \
  /Users/oobi/Documents/tally/vendor/tot/stdlib \
  /Users/oobi/Documents/tally/vendor/tot/examples \
  /Users/oobi/Documents/tally/vendor/tot/test \
  -g '!m0word-*' -g '!prelude.tot' -g '!surface.ml' || st=$?
test "$st" -eq 1
  # leg 1: no word syntax outside the seeded files; a hit (0) or a bad
  # path (2) is red
rg -n --sort path '[0-9](u|i)(8|16|32|64)\b' \
  /Users/oobi/Documents/tally/vendor/tot/stdlib/prelude.tot \
  /Users/oobi/Documents/tally/vendor/tot/test/surface.ml \
  | diff - /Users/oobi/Documents/tally/dev/word-syntax-allowed.golden
  # leg 2: the excluded files' word-syntax rows are EXACTLY the seeded set
echo PASS-T0-WORD-UNREACHED

# 9. PASS-T0-WORD-ORACLE
"$WBIN" check /Users/oobi/Documents/tally/vendor/tot/test/fixtures/m0word-model.tal
test "$(fd 'm0word-model-neg' /Users/oobi/Documents/tally/vendor/tot/test/fixtures | wc -l)" -ge 2
fd 'm0word-model-neg' /Users/oobi/Documents/tally/vendor/tot/test/fixtures | while IFS= read -r f; do
  st=0; "$WBIN" check "$f" > /dev/null 2>&1 || st=$?
  test "$st" -eq 1        # each negative REJECTS; exit 0 or 2 is red
done
echo PASS-T0-WORD-ORACLE

# 10. PASS-T0-WORD-BOUNDARY
"$WBIN" check /Users/oobi/Documents/tally/vendor/tot/test/fixtures/m0word-boundary.tot \
  > "$OUT/wb-boundary.out" 2>&1
rg -q '\b18446744073709551615u64\b' "$OUT/wb-boundary.out"   # pp printed the canonical suffixed form
lit="$(rg 'topSelf' "$OUT/wb-boundary.out" | rg -o '\b[0-9]+u64\b' | head -1)"
printf 'reducible def t : U64 := %s\ndef okRelex : Eq U64 t 18446744073709551615u64 := refl U64 t\n' "$lit" \
  > "$OUT/wb-relex.tot"
  # the def is named okRelex, not the plan's `ok` (M0-PLAN.md 2676): `ok`
  # is the prelude Result constructor (stdlib/prelude.tot:5) and the
  # generated file died with `wb-relex.tot:2:1: duplicate global ok` (D42)
"$WBIN" check "$OUT/wb-relex.tot"                            # the printed form re-lexes and checks
st=0
"$WBIN" check /Users/oobi/Documents/tally/vendor/tot/test/fixtures/m0word-neg-u8-range.tot \
  > "$OUT/wb-w4.out" 2>&1 || st=$?
test "$st" -eq 1
rg -q 'lex error: u8 literal out of range: 256 > 255' "$OUT/wb-w4.out"
echo PASS-T0-WORD-BOUNDARY

# 11. PASS-T0-WORD-QUANTITY
rg -q '^PASS m0word quantity walk$' "$OUT/main-walk.out"
  # the marker is read from entry 7's one runner invocation, so entry 7
  # runs FIRST (M0-PLAN.md 3815-3823, D39)
st=0
"$WBIN" run /Users/oobi/Documents/tally/vendor/tot/test/fixtures/m0word-erased-neg.tot \
  > "$OUT/wq-out.txt" 2>&1 || st=$?
test "$st" -eq 1
rg -qi 'mismatch' "$OUT/wq-out.txt"
echo PASS-T0-WORD-QUANTITY

# 12. PASS-T0-NO-NEW-AXIOM
test "$(fd -e tot -e tal 'm0word-' /Users/oobi/Documents/tally/vendor/tot/test/fixtures | wc -l)" -ge 8
fd -e tot -e tal 'm0word-' /Users/oobi/Documents/tally/vendor/tot/test/fixtures | while IFS= read -r f; do
  st=0; "$WBIN" check --no-axioms "$f" > "$OUT/na-out.txt" 2>&1 || st=$?
  test "$st" -le 1        # exit 2 (missing file or binary) is red
  test -z "$(rg -i 'axiom' "$OUT/na-out.txt")"
done
test "$(rg -c '^axiom' /Users/oobi/Documents/tally/vendor/tot/stdlib/prelude.tot)" -eq 3   # AXIOM_ROWS_FROZEN; re-frozen ONLY by Stage B step 2 (d) (R7)
rg -o '^axiom [A-Za-z0-9_]+' /Users/oobi/Documents/tally/vendor/tot/stdlib/prelude.tot \
  | diff - /Users/oobi/Documents/tally/dev/prelude-axioms.golden
git -C /Users/oobi/Documents/tally/vendor/tot diff -M "$(cat /Users/oobi/Documents/tally/PIN)" \
  -- ':(exclude)_build' ':(exclude)vendor' \
  | rg -v '^\+\+\+ ' | rg '^\+' > "$OUT/na-added.txt"
test -s "$OUT/na-added.txt"
ast=0; rg -n '\b(axiom|define_axiom)\b' "$OUT/na-added.txt" || ast=$?
test "$ast" -eq 1        # any axiom spelling in an M0-added vendor line is red
echo PASS-T0-NO-NEW-AXIOM

# 13. PASS-T0-WORD-TOWER legs a-e
# leg a, walk arithmetic, RE-RUN here, never read from a pre-existing file
: > "$OUT/word-gate.out"
dunecho build -- --root /Users/oobi/Documents/tally/vendor/tot
wst=0
zsh /Users/oobi/Documents/tally/vendor/tot/dev/gates.sh > "$OUT/word-gate.out" 2>&1 || wst=$?
test "$wst" -eq 0
fst=0; rg -c '^FAIL' "$OUT/word-gate.out" || fst=$?
test "$fst" -eq 1        # zero FAIL rows; a match (0) or unreadable file (2) is red
PASS_now=$(rg -c '^PASS' "$OUT/word-gate.out")
test "$PASS_now" -eq $(( $(cat "$BASEDIR/pass-count.txt") + 27 ))   # NEW_FROZEN = 27, frozen at Stage D close; never re-derived at gate time
rg -o 'PASS-M0WORD-[A-Z0-9_-]+' "$OUT/word-gate.out" | sort -u \
  | diff - /Users/oobi/Documents/tally/dev/m0word-markers.golden
# leg b, old corpus byte-identical
zsh /Users/oobi/Documents/tally/dev/run-matrix.sh "$WBIN" /Users/oobi/Documents/tally/vendor/tot "$OUT/cand"
PRIMSDIR="$(printf '%s' prims | md5)"    # run_one's own dir-naming rule, so the exclusion tracks it
diff -r -x "$PRIMSDIR" "$OUT/base1" "$OUT/cand" > "$OUT/behavior.diff" 2>&1
test ! -s "$OUT/behavior.diff"
head -n "$(wc -l < "$OUT/base1/$PRIMSDIR/stdout")" "$OUT/cand/$PRIMSDIR/stdout" \
  | diff - "$OUT/base1/$PRIMSDIR/stdout"                      # prefix byte-identical
tail -n +"$(( $(wc -l < "$OUT/base1/$PRIMSDIR/stdout") + 1 ))" "$OUT/cand/$PRIMSDIR/stdout" \
  | diff - /Users/oobi/Documents/tally/dev/prims-appended.golden  # appended lines pinned
test "$(wc -l < /Users/oobi/Documents/tally/dev/prims-appended.golden)" -eq 92
# leg c, epoch discipline plus the cross-version blob block
rg -n 'let epoch : int = 1' /Users/oobi/Documents/tally/vendor/tot/lib/kernel_format.ml
rg -n '10 \+ Kernel_format\.epoch' /Users/oobi/Documents/tally/vendor/tot/surface/cache.ml
XC="$OUT/xver-cache"; rm -rf "$XC"; mkdir -p "$XC"     # truncate up front, the G5 discipline
xst=0
TOT_CACHE_DIR="$XC" HOME=/nonexistent TOT_PRELUDE=/Users/oobi/Documents/tally-m0-pin-m5/stdlib/prelude.tot \
  "$BASE" check /Users/oobi/Documents/tally-m0-pin-m5/examples/literals.tot > "$OUT/xver-out.txt" 2>&1 || xst=$?
test "$xst" -eq 0
test "$(ls "$XC" | rg -c '^prelude-.*\.bin$')" -eq 1   # the version-10-era blob is planted (writer: $BASE, the PIN_M5 binary)
v10blob="$XC/$(ls "$XC" | rg '^prelude-.*\.bin$')"
cp "$v10blob" "$OUT/xver-v10.copy"
xst=0
TOT_CACHE_DIR="$XC" HOME=/nonexistent TOT_PRELUDE="$TALLY/vendor/tot/stdlib/prelude.tot" \
  "$WBIN" check "$TALLY/vendor/tot/examples/literals.tot" >> "$OUT/xver-out.txt" 2>&1 || xst=$?
test "$xst" -eq 0                                      # silent miss: exit 0, never a crash
test "$(ls "$XC" | rg -c '^prelude-.*\.bin$')" -eq 2   # the candidate went COLD: its own blob, keyed apart
cmp "$v10blob" "$OUT/xver-v10.copy"                    # the planted v10 blob is byte-untouched
# leg d, encoding tags appended, never renumbered
dune exec --root /Users/oobi/Documents/tally/vendor/tot test/keygolden/keygolden.exe \
  | diff - /Users/oobi/Documents/tally/dev/inst-key-enc.golden
# leg e, the logged one-time compile experiment's row exists
rg -q 'PASS-T0-WORD-TOWER-e' /Users/oobi/Documents/tally/dev/MUTATION-LOG.md
echo PASS-T0-WORD-TOWER

# 14. PASS-T0-SPEED
sst=0
python3 -P /Users/oobi/Documents/tally/dev/timing_harness2.py \
  "$BASE" /Users/oobi/Documents/tally/_build/default/bin/tally.exe \
  /Users/oobi/Documents/tally/dev/corpus/corpus-a.tot "$OUT/speed" \
  /Users/oobi/Documents/tally-m0-pin-m5/stdlib/prelude.tot \
  /Users/oobi/Documents/tally/vendor/tot/stdlib/prelude.tot || sst=$?
test "$sst" -eq 0        # exit 3 = missing binary or failed check, red before any number is read
jst=0; rg -qx 'JITTER-OK' "$OUT/speed/jitter.txt" || jst=$?
test "$jst" -eq 0 || { echo FAIL-T0-SPEED-INVALID; exit 1; }
BASEM=$(cat "$OUT/speed/base-warm-median.txt")
CANDM=$(cat "$OUT/speed/cand-warm-median.txt")
test "$BASEM" -gt 0
test "$CANDM" -le $(( BASEM * 2 ))       # integer microseconds; Q6's 2.0x threshold
echo PASS-T0-SPEED

# 15. PASS-T0-NO-EMITTER
T=/Users/oobi/Documents/tally
V=/Users/oobi/Documents/tally/vendor/tot
G5GLOBS=(-g '*.ml' -g '*.mli' -g '*.tot' -g '*.tal' -g '*.sh' -g '*.py' -g 'dune*' -g '!**/vendor/**' -g '!**/_build/**')
: > "$OUT/g5-hits.txt"
: > "$OUT/g5-residual.txt"
test "$(rg --files --no-ignore "${G5GLOBS[@]}" "$T" | wc -l)" -ge 10
test -z "$(rg --files --no-ignore "${G5GLOBS[@]}" "$T" | rg '/vendor/|/_build/')"
test "$(wc -l < "$T/dev/g5-deny.txt")" -eq 7
git -C "$V" diff -M "$(cat "$T/PIN")" -- ':(exclude)_build' ':(exclude)vendor' '*.ml' '*.mli' '*.tot' '*.tal' '*.sh' '*.py' '*dune*' \
  | rg -v '^\+\+\+ ' | rg '^\+' > "$OUT/g5-vendor-added.txt"
test -s "$OUT/g5-vendor-added.txt"
git -C "$V" diff --name-only -M "$(cat "$T/PIN")" -- ':(exclude)_build' ':(exclude)vendor' | rg -q '^lib/word\.ml$'
while IFS=$'\t' read -r flag pat; do
  case "$flag" in I) iflag=(-i);; S) iflag=();; *) exit 1;; esac
  st=0
  rg -n "${iflag[@]}" --no-ignore "${G5GLOBS[@]}" "$pat" "$T" >> "$OUT/g5-hits.txt" || st=$?
  test "$st" -le 1        # exit 2 (bad path/pattern) is a gate failure, never zero hits
  st=0
  rg -n "${iflag[@]}" "$pat" "$OUT/g5-vendor-added.txt" >> "$OUT/g5-hits.txt" || st=$?
  test "$st" -le 1
done < "$T/dev/g5-deny.txt"
sort -u "$OUT/g5-hits.txt" > "$OUT/g5-hits-sorted.txt"
comm -23 "$OUT/g5-hits-sorted.txt" "$T/dev/g5-allowlist.txt" > "$OUT/g5-residual.txt"
wc -l < "$T/dev/g5-allowlist.txt"        # allow-list size, printed per section 2.2
test ! -s "$OUT/g5-residual.txt"
echo PASS-T0-NO-EMITTER

# 16. PASS-T0-NO-SURFACE-TAL
test "$(fd -e ml --no-ignore . /Users/oobi/Documents/tally -E vendor -E _build \
  | rg -v '/bin/tally\.ml$' | rg -v '/test/' | wc -l)" -eq 0
echo PASS-T0-NO-SURFACE-TAL

# 17. PASS-T0-M1-GATE-DEFINED
test -x /Users/oobi/Documents/tally/dev/gates-m1-entry.sh
rg -q 'echo PASS-T1-CITATIONS' /Users/oobi/Documents/tally/dev/gates-m1-entry.sh
echo PASS-T0-M1-GATE-DEFINED

# 18. PASS-T0-RECORD-INTACT
awk '/^## Ratification record/,/^---$/' \
  /Users/oobi/Documents/solana-lang-design-verdict.md \
  | shasum -a 256 | cut -d' ' -f1 \
  | diff - /Users/oobi/Documents/tally/dev/verdict-record.digest
rg -q '^## Re-pin log \(builder-appended, not ratified\)' \
  /Users/oobi/Documents/solana-lang-design-verdict.md
rg -q 'cumulativity.*NEVER \((RATIFY|PENDING-USER-RATIFY)' \
  /Users/oobi/Documents/tally/dev/PARITY-LEDGER-DELTA.md
echo PASS-T0-RECORD-INTACT

# 19. PASS-T0-EXIT-RATIFIED
rg -q 'M0-EXIT-SUBSTITUTION \(RATIFY [0-9]{4}-[0-9]{2}-[0-9]{2}\)' /Users/oobi/Documents/tally/dev/M0-BUILD-LOG.md
echo PASS-T0-EXIT-RATIFIED

exit 0
