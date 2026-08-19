#!/usr/bin/env bash
set -eu
file=$1
expected_owner=${EXPECTED_OWNER:-root:root}
fail() { printf 'FAIL: %s\n' "$1" >&2; exit 1; }
[ -f "$file" ] || fail missing
[ "$(stat -c '%U:%G:%a' "$file")" = "$expected_owner:600" ] || fail mode_or_owner
[ -s "$file" ] || fail empty
last_byte=$(tail -c 1 "$file" | od -An -tuC | tr -d '[:space:]')
[ "$last_byte" = 10 ] || fail missing_final_newline
[ "$(wc -l < "$file")" -eq 1 ] || fail line_count
grep -Eqx '^(!|\$y\$[./A-Za-z0-9]+\$[./A-Za-z0-9]{0,86}\$[./A-Za-z0-9]{43})$' "$file" || fail format
printf 'PASS\n'
