#!/bin/zsh
set -e
O="${0:A:h}/corpus-a.tot"
{
  print -r -- '-- corpus-a: deterministic timing corpus; pin-era syntax only; prelude globals via TOT_PRELUDE'
  print -r -- 'def c0 : Nat := zero'
  for i in {1..297}; do print -r -- "def c$i : Nat := succ c$((i-1))"; done
  print -r -- 'eval c297'
} > "$O"
exit 0
