run_one() {   # $1 = binary, $2 = tag, $3 = cache dir, rest = argv
  local bin="$1" tag="$2" cache="$3"; shift 3
  local d="$OUT/$tag/$(printf '%s' "$*" | md5)"
  mkdir -p "$d"
  printf '%s\n' "$*" > "$d/argv"
  local st=0
  TOT_CACHE_DIR="$cache" HOME=/nonexistent TOT_PRELUDE="$PWD/stdlib/prelude.tot" \
    gtimeout 30 "$bin" "$@" < /dev/null > "$d/stdout" 2> "$d/stderr" || st=$?
  printf '%d\n' "$st" > "$d/exit"
  local allow=/Users/oobi/Documents/tally/dev/watchdog-allowlist.txt
  test "$st" -ne 124 || rg -qxF -- "$*" "$allow"
}
