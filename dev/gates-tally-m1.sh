#!/bin/zsh
set -e
# The M1 top-level battery (M1-PLAN.md section 7): entries T1-0 to T1-21.
# dev/gates-tally.sh is FROZEN at 262d643 and is edited by nobody (R2):
# T1-0 asserts its digest, T1-1 replays it over a snapshot of that commit.
# Not-yet-landed entries are `exit 9` placeholders; a placeholder never passes.
export LC_ALL=C LANG=C TZ=UTC
export COLUMNS=80
TALLY=/Users/oobi/Documents/tally
LIBDIR=$TALLY/lib
M1=/Users/oobi/Documents/tally-m1
SRC=$M1/sources
OUT=$M1/gate-out/m1
SPEED=$M1/gate-out/m1-speed
RPL=$M1/replay
TB=$TALLY/_build/default/bin/tally.exe
LOADCHECK=$M1/rig/target/debug/loadcheck
SA=$M1/second-author
SASO=$SA/out/second_author.so
SAPV=$SA/out/provenance.txt
FROZEN=262d643
GITLINK=de61f4e094b82755478f214050d5b2258a466009
command -v gtimeout > /dev/null || { echo 'FAIL-T1-NO-WATCHDOG gtimeout absent, the frozen battery needs it'; exit 1; }
rm -rf "$OUT"
mkdir -p "$OUT" "$SPEED"
mark() {
  print -r -- "$1" | tee -a "$OUT/markers.txt"
}
: > "$OUT/markers.txt"

# T1-0. PASS-T1-M0-FROZEN
FROZEN_SHA="$(git -C "$TALLY" show "$FROZEN:dev/gates-tally.sh" | shasum -a 256 | cut -d' ' -f1)"
LIVE_SHA="$(shasum -a 256 < "$TALLY/dev/gates-tally.sh" | cut -d' ' -f1)"
test -n "$FROZEN_SHA"
test "$FROZEN_SHA" = "$LIVE_SHA"
test "$(git -C "$TALLY" show "$FROZEN:dev/gates-tally.sh" | wc -l)" -eq 275
mark PASS-T1-M0-FROZEN

# T1-1. PASS-T1-M0-REPLAY
STAMP="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
SNAP=$RPL/tree
RM0=$RPL/m0
RPIN=$RPL/pin-m5
RVERDICT=$RPL/design-verdict.md
rm -rf "$RPL"
mkdir -p "$RPL" "$RM0/gate-out" "$RPIN" "$RPL/tmp" "$RPL/cache"
# Archives need independent Git metadata for the frozen index/history legs.
# Shared local clones read existing objects and never fetch or check out files.
git clone --quiet --shared --no-checkout "$TALLY" "$SNAP"
git -C "$SNAP" update-ref --no-deref HEAD "$(git -C "$TALLY" rev-parse "$FROZEN")"
git -C "$SNAP" read-tree "$FROZEN"
git -C "$TALLY" archive "$FROZEN" | tar -x -C "$SNAP"
git clone --quiet --shared --no-checkout "$TALLY/vendor/tot" "$SNAP/vendor/tot"
git -C "$SNAP/vendor/tot" update-ref --no-deref HEAD "$GITLINK"
git -C "$SNAP/vendor/tot" read-tree "$GITLINK"
git -C "$TALLY/vendor/tot" archive "$GITLINK" | tar -x -C "$SNAP/vendor/tot"
TREEN="$(git -C "$TALLY" ls-tree -r --name-only "$FROZEN" | wc -l)"
VENDN="$(git -C "$TALLY/vendor/tot" ls-tree -r --name-only "$GITLINK" | wc -l)"
test "$TREEN" -ge 1
test "$VENDN" -ge 1
test "$(fd --type f --hidden --no-ignore -E .git . "$SNAP" | wc -l)" -ge "$(( TREEN + VENDN - 1 ))"
  # The gitlink is omitted by archive; Git metadata cannot satisfy the floor.
PINSHA="$(cat "$SNAP/PIN")"
cp -R "/Users/oobi/Documents/tally-m0/baseline-$PINSHA" "$RM0/"
cp -R /Users/oobi/Documents/tally-m0/gate-out/base1 "$RM0/gate-out/"
test "$(fd --type f . "$RM0/gate-out/base1" | wc -l)" -gt 0
cp -R /Users/oobi/Documents/tally-m0-pin-m5/stdlib /Users/oobi/Documents/tally-m0-pin-m5/examples "$RPIN/"
cp /Users/oobi/Documents/solana-lang-design-verdict.md "$RVERDICT"
RS="$SNAP/dev/gates-tally-replay.sh"
cp "$SNAP/dev/gates-tally.sh" "$RS"
rebind() {
  sd -s /Users/oobi/Documents/tally-m0-pin-m5 @@PINM5@@ "$1"
  sd -s /Users/oobi/Documents/tally-m0 @@M0@@ "$1"
  sd -s /Users/oobi/Documents/tally @@TALLY@@ "$1"
  sd -s /Users/oobi/Documents/solana-lang-design-verdict.md @@VERDICT@@ "$1"
  sd -s @@PINM5@@ "$RPIN" "$1"
  sd -s @@M0@@ "$RM0" "$1"
  sd -s @@TALLY@@ "$SNAP" "$1"
  sd -s @@VERDICT@@ "$RVERDICT" "$1"
}
unrebind() {
  sd -s "$RPIN" @@PINM5@@ "$1"
  sd -s "$RM0" @@M0@@ "$1"
  sd -s "$SNAP" @@TALLY@@ "$1"
  sd -s "$RVERDICT" @@VERDICT@@ "$1"
  sd -s @@PINM5@@ /Users/oobi/Documents/tally-m0-pin-m5 "$1"
  sd -s @@M0@@ /Users/oobi/Documents/tally-m0 "$1"
  sd -s @@TALLY@@ /Users/oobi/Documents/tally "$1"
  sd -s @@VERDICT@@ /Users/oobi/Documents/solana-lang-design-verdict.md "$1"
}
rebind "$RS"
cp "$RS" "$OUT/roundtrip.sh"
unrebind "$OUT/roundtrip.sh"
git -C "$TALLY" show "$FROZEN:dev/gates-tally.sh" > "$OUT/frozen.sh"
cmp "$OUT/roundtrip.sh" "$OUT/frozen.sh"
# Called helpers and the path-bearing golden need the identical reversible map.
for rel in dev/run-matrix.sh dev/run_one.sh dev/word-syntax-allowed.golden; do
  rebind "$SNAP/$rel"
  cp "$SNAP/$rel" "$OUT/helper-roundtrip.txt"
  unrebind "$OUT/helper-roundtrip.txt"
  git -C "$TALLY" show "$FROZEN:$rel" > "$OUT/helper-frozen.txt"
  cmp "$OUT/helper-roundtrip.txt" "$OUT/helper-frozen.txt"
done
rst=0
TMPDIR="$RPL/tmp" TOT_CACHE_DIR="$RPL/cache" TOT_GATE_LOG="$OUT/tot-gate-measure.log" \
  gtimeout 3600 zsh "$RS" > "$OUT/m0-replay.log" 2>&1 || rst=$?
test "$rst" -eq 0
test "$(rg -o '^PASS-T0-[A-Z0-9-]+' "$OUT/m0-replay.log" | sort -u | wc -l)" -eq 20
test "$(rg -c '^PASS-T0-' "$OUT/m0-replay.log")" -eq 20
fst=0; rg -c '^FAIL' "$OUT/m0-replay.log" || fst=$?
test "$fst" -eq 1
test -z "$(fd -HI -t f --changed-after "$STAMP" . "$TALLY" -E _build -E .git)"
test -z "$(fd -HI -t f --changed-after "$STAMP" . /Users/oobi/Documents/tally-m0/gate-out)"
mark PASS-T1-M0-REPLAY

# T1-2. PASS-T1-LEDGER
ROWS='C1|C2|C3|C4|C5|C6|C7|C8|C9|C10|C11|C12|F-SPEC|F-EMIT|F-EMIT-SHIFT|S1|S2|S3|S4|S5|S6|S7|S15|S16|S17'
lst=0
zsh "$TALLY/dev/gates-m1-entry.sh" "$ROWS" > "$OUT/ledger.out" 2>&1 || lst=$?
test "$lst" -eq 0
rg -qx 'PASS-T1-CITATIONS' "$OUT/ledger.out"
test "$(rg -c "^\| (F-SPEC|F-EMIT) \|.*\| VERIFIED[^|]*\|\$" "$TALLY/dev/CITATION-LEDGER.md")" -eq 2 || { mark 'OPEN-T1-LEDGER F-SPEC and F-EMIT carry no VERIFIED status cell on disk (10.4, RUL-O12)'; exit 1; }
test "$(rg -c "^\| (${ROWS}) \|.*\| VERIFIED[^|]*\|\$" "$TALLY/dev/CITATION-LEDGER.md")" -eq 25
test "$(rg -c '^\| (C[0-9]+|F-[A-Z-]+|S[0-9]+) \|.*\| UNVERIFIED[^|]*\|$' "$TALLY/dev/CITATION-LEDGER.md")" -eq 3
mark PASS-T1-LEDGER

# T1-3. PASS-T1-PIN
PINSHA="$(cat "$TALLY/PIN")"
test "$PINSHA" = 66b444fe8380c82f0a74093ffaa779371d014a9b
LINK="$(git -C "$TALLY" ls-files -s vendor/tot | cut -d' ' -f2)"
test "$LINK" = de61f4e094b82755478f214050d5b2258a466009
test "$LINK" = "$(git -C "$TALLY/vendor/tot" rev-parse HEAD)"
mark PASS-T1-PIN

# T1-4. PASS-T1-SOURCES
PINS="$TALLY/dev/m1-source-pins.txt"
test -s "$PINS"
n=0
REFERENCE=''
while IFS=$'\t' read -r key sha; do
  printf '%s\n' "$key" | rg -qx '[a-z][a-z0-9-]*'
  printf '%s\n' "$sha" | rg -qx '[0-9a-f]{40}'
  test "$(git -C "$SRC/$key" rev-parse --show-toplevel)" = "$SRC/$key"
  test "$(git -C "$SRC/$key" rev-parse HEAD)" = "$sha"
  if test "$sha" = e7e515291244ecd1903b18fee08444676f767620; then
    test -z "$REFERENCE"
    REFERENCE="$SRC/$key"
  fi
  n=$(( n + 1 ))
done < "$PINS"
test "$n" -eq 5
test "$(wc -l < "$PINS")" -eq 5
test "$(cut -f1 "$PINS" | sort -u | wc -l)" -eq 5
test -n "$REFERENCE"
test -f "$REFERENCE/tests/elfs/strict_header.so"
test -f "$REFERENCE/tests/elfs/syscall_static.so"
mark PASS-T1-SOURCES

# T1-5. PASS-T1-BUILD
export TOT_PRELUDE="$TALLY/vendor/tot/stdlib/prelude.tot"
BD=$OUT/cold-build
rm -rf "$BD"
test ! -e "$BD"
dune build --root "$TALLY/vendor/tot"
dune build --root "$TALLY" --build-dir "$BD" bin/tally.exe
test -x "$BD/default/bin/tally.exe"
dune build --root "$TALLY" bin/tally.exe
test -x "$TB"
hst=0
"$TB" --help > "$OUT/help-stdout.txt" 2> "$OUT/help.txt" || hst=$?
test "$hst" -eq 2       # D144: a usage request is a usage error, never a decision
test ! -s "$OUT/help-stdout.txt"   # stdout carries only a rendered decision
rg -q '\bcheck\b' "$OUT/help.txt"
rg -q '\bbuild\b' "$OUT/help.txt"
mark PASS-T1-BUILD

# T1-6. PASS-T1-WORD-SCOPE
G1GLOBS=(-g '*.ml' -g '*.mli' -g '*.tot' -g '*.tal' -g '*.sh' -g '*.py' -g 'dune*' -g '!**/vendor/**' -g '!**/_build/**')
test "$(wc -l < "$TALLY/dev/g5-deny.txt")" -eq 7
test "$(wc -l < "$TALLY/dev/g1-deny.txt")" -eq 4
test "$(wc -l < "$TALLY/dev/g1-scope.txt")" -eq 4
SHAPE=$(rg -c '^[^\t]+\t(lib|bin|test|dev)/' "$TALLY/dev/g1-scope.txt") || SHAPE=0
test "$SHAPE" -eq 4     # every PREFIX is tree-relative, so '/' and '' red
test "$(wc -l < "$TALLY/dev/g5-allowlist.txt")" -eq 1
rg -qx 'lib/target/target_params\.ml' "$TALLY/dev/g5-allowlist.txt"   # the one reasoned row, not a Cterm file
test "$(rg --files --no-ignore "${G1GLOBS[@]}" "$TALLY" | wc -l)" -ge 10
test -z "$(rg --files --no-ignore "${G1GLOBS[@]}" "$TALLY" | rg '/vendor/|/_build/')"
: > "$OUT/g1-hits.txt"
while IFS=$'\t' read -r flag pat; do
  case "$flag" in I) iflag=(-i);; S) iflag=();; *) exit 1;; esac
  st=0
  rg -n "${iflag[@]}" --no-ignore "${G1GLOBS[@]}" "$pat" "$TALLY" >> "$OUT/g1-hits.txt" || st=$?
  test "$st" -le 1        # exit 2 (bad path or pattern) is red, never zero hits
done < "$TALLY/dev/g1-deny.txt"
sort -u "$OUT/g1-hits.txt" > "$OUT/g1-hits-sorted.txt"
rg -o '^[^:]+' "$OUT/g1-hits-sorted.txt" | sd -s "$TALLY/" '' | sort -u > "$OUT/g1-hit-paths.txt"
comm -23 "$OUT/g1-hit-paths.txt" <(sort "$TALLY/dev/g5-allowlist.txt") > "$OUT/g1-path-residual.txt"
test ! -s "$OUT/g1-path-residual.txt"
: > "$OUT/g1-scope-residual.txt"
: > "$OUT/g1-scope-all.txt"
while IFS=$'\t' read -r pat prefix; do
  st=0
  rg -l --no-ignore "${G1GLOBS[@]}" "$pat" "$TALLY" > "$OUT/g1-scope-abs.txt" || st=$?
  test "$st" -le 1
  sd -s "$TALLY/" '' < "$OUT/g1-scope-abs.txt" | sort > "$OUT/g1-scope-hits.txt"
  cat "$OUT/g1-scope-hits.txt" >> "$OUT/g1-scope-all.txt"
  st=0
  rg -v "^($prefix)" "$OUT/g1-scope-hits.txt" >> "$OUT/g1-scope-residual.txt" || st=$?
  test "$st" -le 1
done < "$TALLY/dev/g1-scope.txt"
test "$(wc -l < "$OUT/g1-scope-all.txt")" -ge 5
test ! -s "$OUT/g1-scope-residual.txt"
mark PASS-T1-WORD-SCOPE

# T1-7. PASS-T1-SOURCE-MANIFEST
fd -e ml -e mli --no-ignore . "$TALLY" -E vendor -E _build -E bin -E test \
  | sd -s "$TALLY/" '' | sort > "$OUT/m1-sources-now.txt"
test -s "$OUT/m1-sources-now.txt"
test -s "$TALLY/dev/m1-source-manifest.txt"
diff "$OUT/m1-sources-now.txt" "$TALLY/dev/m1-source-manifest.txt"
mark PASS-T1-SOURCE-MANIFEST

# T1-8. PASS-T1-CTERM-FIRSTORDER
VERIFY=(--emit-none --verify --dump-cterm)
mkdir -p "$OUT/cterm-firstorder"
: > "$OUT/cterm-verify.out"
: > "$OUT/cterm-positives.txt"
n=0
while IFS= read -r fx; do
  "$TB" build "${VERIFY[@]}" "$TALLY/test/fixtures/$fx" > "$OUT/cterm-firstorder/${fx%.tot}.txt" 2>&1
  cat "$OUT/cterm-firstorder/${fx%.tot}.txt" >> "$OUT/cterm-verify.out"
  n=$(( n + 1 ))
  printf '%s\n' "$fx" >> "$OUT/cterm-positives.txt"
done <<'POS'
cterm-id.tot
cterm-capture.tot
cterm-nested-capture.tot
cterm-known-call.tot
cterm-selfrec.tot
cterm-mutual.tot
cterm-match-kept.tot
cterm-word-tower.tot
cterm-div-zero.tot
cterm-shift-wide.tot
POS
test "$n" -eq 10
test "$(rg -c '^verify: ok ' "$OUT/cterm-verify.out")" -eq 10
for fx in cterm-known-call cterm-selfrec cterm-mutual; do
  test "$(rg '^VERIFY-OK ' "$OUT/cterm-firstorder/$fx.txt" | rg -o 'callknown-edges=[0-9]+' | cut -d= -f2)" -ge 1
done
# D145: ANF copies the continuation into every match arm, so switch blocks
# grow as 2^N-1 in the number of let-bound matches, with frame slots in step.
# Both bounds are pinned on the ten positives, so any regrowth reds.
test "$(rg -o 'switch-defaults=[0-9]+' "$OUT/cterm-verify.out" | cut -d= -f2 | sort -rn | head -1)" -le 4
test "$(rg -o 'frame-slots=[0-9]+' "$OUT/cterm-verify.out" | cut -d= -f2 | sort -rn | head -1)" -le 42
mark PASS-T1-CTERM-FIRSTORDER

# T1-9. PASS-T1-CTERM-DIFF
rm -rf "$OUT/cterm-diff"
dune exec --root "$TALLY" test/cterm_ref.exe -- "$OUT/cterm-diff"
test -s "$OUT/cterm-diff/interp.txt"
test -s "$OUT/cterm-diff/pipeline.txt"
test "$(wc -l < "$OUT/cterm-diff/interp.txt")" -eq 10
test "$(wc -l < "$OUT/cterm-diff/pipeline.txt")" -eq 10
diff "$OUT/cterm-diff/interp.txt" "$OUT/cterm-diff/pipeline.txt"
sort -u "$OUT/cterm-diff/constructors.txt" > "$OUT/cterm-diff/constructors-sorted.txt"
test "$(wc -l < "$OUT/cterm-diff/constructors-sorted.txt")" -eq 8
for ctor in EVar ELam EApp ELet EGlobal EErased EMatch ELit; do
  rg -qx "$ctor" "$OUT/cterm-diff/constructors-sorted.txt"
done
mark PASS-T1-CTERM-DIFF

# T1-10. PASS-T1-CTERM-REJECTS
: > "$OUT/cterm-rej-ctors.txt"
n=0
while IFS= read -r fx; do
  st=0
  LIMIT=()
  if test "$fx" = cterm-arena-over.tot; then LIMIT=(--arena-limit 0); fi
  "$TB" build --emit-none "${LIMIT[@]}" "$TALLY/test/fixtures/$fx" > "$OUT/cterm-rej.out" 2>&1 || st=$?
  test "$st" -eq 2        # RUL-R6-1: a typed Cerror.t rejection
  rg -o 'Cerror\.[A-Z][A-Za-z0-9_]*' "$OUT/cterm-rej.out" | head -1 >> "$OUT/cterm-rej-ctors.txt"
  n=$(( n + 1 ))
done <<'NEG'
cterm-arena-over.tot
cterm-io-neg.tot
cterm-string-neg.tot
cterm-nat-neg.tot
NEG
test "$n" -eq 4
test "$(wc -l < "$OUT/cterm-rej-ctors.txt")" -eq 4
test "$(sort -u "$OUT/cterm-rej-ctors.txt" | wc -l)" -eq 4
p=0
while IFS= read -r fx; do
  "$TB" build --emit-none "$TALLY/test/fixtures/$fx" > /dev/null 2>&1
  p=$(( p + 1 ))
done < <(rg -o '^cterm-[a-z-]+\.tot$' "$OUT/cterm-positives.txt")
test "$p" -eq 10
mark PASS-T1-CTERM-REJECTS

# T1-11. PASS-T1-RIG
test -f "$M1/rig/Cargo.toml" || { mark 'OPEN-T1-RIG tally-m1/rig absent'; exit 1; }
test -f "$M1/rig/Cargo.lock" || { mark 'OPEN-T1-RIG provisioning line 1 (cargo fetch) not run'; exit 1; }
rg -q 'path = "\.\./sources/sbpf"' "$M1/rig/Cargo.toml"
rg -q 'path = "\.\./sources/solana-sdk/program-entrypoint"' "$M1/rig/Cargo.toml"
test "$(git -C "$SRC/sbpf" rev-parse HEAD)" = e7e515291244ecd1903b18fee08444676f767620
test "$(git -C "$SRC/solana-sdk" rev-parse HEAD)" = 1c1d667f161666f12f5a43ebef8eda9470a8c6ee
if rg -q '^litesvm' "$M1/rig/Cargo.toml"; then
  rg -q '^name = "litesvm"' "$M1/rig/Cargo.lock" || { mark 'OPEN-T1-RIG provisioning line 3 (litesvm) not run, rig manifest names it'; exit 1; }
fi
bst=0
cargo --offline build -j 2 --manifest-path "$M1/rig/Cargo.toml" > "$OUT/rig-build.log" 2>&1 || bst=$?
if test "$bst" -ne 0; then
  rg -q 'error\[E0599\].*(compute_budget|ComputeBudget|max_instruction_stack_depth)|no method named `(compute_budget|max_instruction_stack_depth)`' "$OUT/rig-build.log" && { mark 'OPEN-T1-LITESVM no compute-budget getter on the provisioned litesvm'; exit 1; }
  exit "$bst"
fi
nst=0; rg -c 'Updating .* index|Downloading ' "$OUT/rig-build.log" || nst=$?
test "$nst" -eq 1
test -x "$LOADCHECK"
"$LOADCHECK" --version > "$OUT/rig-version.txt"
rg -q '^loadcheck 0\.' "$OUT/rig-version.txt"
rg -qx 'RIG-DEP solana-sbpf 0\.11\.1' "$OUT/rig-version.txt"
rg -qx 'RIG-DEP solana-program-entrypoint 2\.2\.1' "$OUT/rig-version.txt"
test "$(rg -c '^RIG-DEP ' "$OUT/rig-version.txt")" -eq 2
mark PASS-T1-RIG

# T1-12. PASS-T1-PARAMS-LEDGER
P=$TALLY/lib/target/target_params.ml
test -s "$P"
rg -o 'ledger: [A-Za-z0-9-]+' "$P" | cut -d' ' -f2 | sort -u > "$OUT/params-rows.txt"
test -s "$OUT/params-rows.txt"
m=0
while IFS= read -r row; do
  rg -q "^\| ${row} \|.*\| VERIFIED[^|]*\|\$" "$TALLY/dev/CITATION-LEDGER.md"
  m=$(( m + 1 ))
done < "$OUT/params-rows.txt"
test "$m" -eq "$(wc -l < "$OUT/params-rows.txt")"
st=0
rg -n '[^_A-Za-z0-9][0-9]' "$P" > "$OUT/params-raw.txt" || st=$?
test "$st" -le 1        # 0 hits or 1 no-match; a status of 2 is a bad regex or an unreadable file
vst=0
rg -v '\(\* ledger: ' "$OUT/params-raw.txt" > "$OUT/params-unmarked.txt" || vst=$?
test "$vst" -le 1
test ! -s "$OUT/params-unmarked.txt"
test "$(rg -c '\(\* ledger: ' "$P")" -ge 1
for module in region_map syscall_table; do
  st=0
  rg -n '[^_A-Za-z0-9][0-9]' "$TALLY/lib/target/$module.ml" > "$OUT/$module-literals.txt" || st=$?
  test "$st" -eq 1
done
# D160. Entry fact 3 keeps every S18 and S20 constant out of Stage C source.
# The marked-row loop above only checks that a MARKED row is VERIFIED, so it is
# blind to a line marked with the WRONG row; this leg reads the constants that
# only the undischarged convention could justify, whatever marker they carry.
# The forms are the binding and the qualified use, so the prose that records
# the absence of these constants is not itself a hit.
sst=0
rg -n 'ledger: S18|ledger: S20|\b(let|val)\s+(entry_input_register|syscall_argument_registers)\b|\.(entry_input_register|syscall_argument_registers)\b' \
  "$LIBDIR" > "$OUT/params-s18.txt" || sst=$?
test "$sst" -eq 1
mark PASS-T1-PARAMS-LEDGER

# T1-13. PASS-T1-EMIT
test "$(rg -c "^\| S18 \|.*\| VERIFIED[^|]*\|\$" "$TALLY/dev/CITATION-LEDGER.md")" -eq 1 || { mark 'OPEN-T1-EMIT row S18 register convention UNVERIFIED, spine section 7 item 3'; exit 1; }
test -x "$LOADCHECK" || { mark 'OPEN-T1-EMIT loader oracle absent, T1-11 not green'; exit 1; }
n=0
while IFS= read -r fx; do
  fxe=$TALLY/test/fixtures/$fx.expected
  test -s "$fxe"
  rg -qx '[0-9]{1,20}' "$fxe"
  exp="$(cat "$fxe")"
  "$TB" build -o "$OUT/$fx.so" "$TALLY/test/fixtures/$fx.tot"
  test -s "$OUT/$fx.so"
  "$LOADCHECK" --run --expect "$exp" "$OUT/$fx.so" > "$OUT/emit-$fx.txt" 2>&1
  rg -q '^loadcheck: strict-parse ok$' "$OUT/emit-$fx.txt"
  rg -qx "loadcheck: return $exp" "$OUT/emit-$fx.txt"
  n=$(( n + 1 ))
done <<'FIX'
smoke-log
smoke-ret
emit-div-zero
emit-mod-zero
emit-sdiv-min-neg1
emit-srem-min-neg1
emit-shift-width
FIX
test "$n" -eq 7
# D159. While row S18 is UNVERIFIED the native fixture is a typed-rejection
# leg, not a run leg: the build exits 2, names the row, and writes no image.
# dev/check-stage-c.py carries the same contract for the same fixture.
rst=0
"$TB" build -o "$OUT/emit-frame-call.so" "$TALLY/test/fixtures/emit-frame-call.tot" \
  > "$OUT/emit-frame-call-reject.txt" 2>&1 || rst=$?
test "$rst" -eq 2
rg -q '^Row_unverified S18: ' "$OUT/emit-frame-call-reject.txt"
test ! -e "$OUT/emit-frame-call.so"
xst=0
"$LOADCHECK" --run --expect 1 "$OUT/smoke-ret.so" > "$OUT/emit-negctl.txt" 2>&1 || xst=$?
test "$xst" -eq 1
IMGCAP="$(rg -o -r '$1' '^let image_cap_bytes = ([0-9]+) ' "$TALLY/lib/target/target_params.ml")"
printf '%s' "$IMGCAP" | rg -qx '[0-9]{1,20}'
test "$(wc -c < "$OUT/smoke-log.so")" -le "$IMGCAP"
"$LOADCHECK" --syscall-keys > "$OUT/oracle-keys.txt"
"$TB" build --print-syscall-keys > "$OUT/tally-keys.txt"
test "$(wc -l < "$OUT/oracle-keys.txt")" -eq 3
test "$(wc -l < "$OUT/tally-keys.txt")" -eq 3
diff "$OUT/oracle-keys.txt" "$OUT/tally-keys.txt"
mark PASS-T1-EMIT

# T1-14. PASS-T1-ARCH-V3
"$LOADCHECK" --headers "$OUT/smoke-log.so" > "$OUT/hdr-ours.txt"
"$LOADCHECK" --headers "$SRC/sbpf/tests/elfs/strict_header.so" > "$OUT/hdr-strict.txt"
"$LOADCHECK" --headers "$SRC/sbpf/tests/elfs/syscall_static.so" > "$OUT/hdr-syscall.txt"
test -s "$OUT/hdr-ours.txt"
test -s "$OUT/hdr-strict.txt"
test -s "$OUT/hdr-syscall.txt"
rg -qx 'e_flags 3' "$OUT/hdr-ours.txt"
rg -qx 'e_type 3' "$OUT/hdr-ours.txt"
rg -qx 'e_machine 263' "$OUT/hdr-ours.txt"
rg -qx 'e_phoff 64' "$OUT/hdr-ours.txt"
test "$(rg -c '^ph ' "$OUT/hdr-ours.txt")" -eq 5
for f in ours strict syscall; do
  rg -o '^[a-z_]+' "$OUT/hdr-$f.txt" | sort -u > "$OUT/hdr-$f.fields"
  test -s "$OUT/hdr-$f.fields"
done
diff "$OUT/hdr-ours.fields" "$OUT/hdr-strict.fields"
diff "$OUT/hdr-ours.fields" "$OUT/hdr-syscall.fields"
rg '^ph ' "$OUT/hdr-ours.txt" | cut -d' ' -f2,3,4 > "$OUT/ph-ours.txt"
# Both pinned upstream fixtures append a sixth PT_NULL header. The required
# five-header prefix remains positional, and the extra header is checked.
for f in strict syscall; do
  test "$(rg -c '^ph ' "$OUT/hdr-$f.txt")" -eq 6
  test "$(rg '^ph ' "$OUT/hdr-$f.txt" | tail -1)" = 'ph 0 0 0'
done
rg '^ph ' "$OUT/hdr-strict.txt" | head -5 | cut -d' ' -f2,3,4 > "$OUT/ph-strict.txt"
test -s "$OUT/ph-strict.txt"
diff "$OUT/ph-ours.txt" "$OUT/ph-strict.txt"
mark PASS-T1-ARCH-V3

# T1-15. PASS-T1-SECOND-AUTHOR
test -f "$SAPV" || { mark 'OPEN-T1-SECOND-AUTHOR provisioning line 2 (platform-tools, --arch v3) not run'; exit 1; }
rg -q 'cargo-build-sbf .*--arch v3' "$SAPV"
rg -q '^platform-tools ' "$SAPV"
test -s "$SASO" || { mark 'OPEN-T1-SECOND-AUTHOR image absent, provisioning line 2 not run'; exit 1; }
"$LOADCHECK" --headers "$SASO" > "$OUT/hdr-sa.txt"
test -s "$OUT/hdr-sa.txt"
rg -qx 'e_flags 3' "$OUT/hdr-sa.txt"
rg -o '^[a-z_]+' "$OUT/hdr-sa.txt" | sort -u > "$OUT/hdr-sa.fields"
diff "$OUT/hdr-sa.fields" "$OUT/hdr-ours.fields"
mark PASS-T1-SECOND-AUTHOR

# T1-16 placeholder, Stage D
exit 9
# T1-17 placeholder, Stage E
exit 9
# T1-18 placeholder, Stage E
exit 9
# T1-19 placeholder, Stage E
exit 9
# T1-20 placeholder, Stage F
exit 9
# T1-21 placeholder, Stage F
exit 9
