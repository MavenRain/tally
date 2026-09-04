#!/bin/zsh
# usage: run-matrix.sh BIN TREE OUTDIR;  OUTDIR a direct child of $OUT.
# Inputs are read by ABSOLUTE $TALLY-anchored path BEFORE the cd (R7);
# the cd governs corpus argv resolution ONLY.
set -e
BIN="$1"; TREE="$2"; OUTDIR="$3"
TALLY=/Users/oobi/Documents/tally
OUT=/Users/oobi/Documents/tally-m0/gate-out
source "$TALLY/dev/run_one.sh"
CORPUS="$TALLY/dev/corpus-files.txt"
test -s "$CORPUS"
rm -rf "$OUTDIR" "$OUTDIR.cache"   # truncate-up-front, the G5 discipline (R7)
cd "$TREE"
tag="$(basename "$OUTDIR")"
while IFS= read -r f; do
  for cmd in check run; do
    run_one "$BIN" "$tag" "$OUTDIR.cache" "$cmd" "$f"
    run_one "$BIN" "$tag" "$OUTDIR.cache" "$cmd" --no-prelude "$f"
  done
done < "$CORPUS"
run_one "$BIN" "$tag" "$OUTDIR.cache" prims
