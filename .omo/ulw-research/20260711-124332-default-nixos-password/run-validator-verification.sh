#!/usr/bin/env bash
set -euo pipefail
D=$1
TMP=$(mktemp -d -t nix-password-verify.XXXXXX)
trap 'rm -rf "$TMP"' EXIT
VALID='$y$j9T$abcdefghijklmnop$0123456789012345678901234567890123456789012'
run_case() {
  local name=$1 expected=$2 file=$3 output rc verdict=FAIL
  set +e
  output=$(EXPECTED_OWNER="$(id -un):$(id -gn)" "$D/verify-bootstrap-validator.sh" "$file" 2>&1)
  rc=$?
  set -e
  if { [[ $expected == pass && $rc -eq 0 ]]; } || { [[ $expected == fail && $rc -ne 0 ]]; }; then
    verdict=PASS
  fi
  printf '%s expected=%s rc=%s verdict=%s output=%s\n' "$name" "$expected" "$rc" "$verdict" "$output"
  [[ $verdict == PASS ]]
}
printf '%s\n' "$VALID" > "$TMP/valid"; chmod 600 "$TMP/valid"
printf '!\n' > "$TMP/sentinel"; chmod 600 "$TMP/sentinel"
: > "$TMP/empty"; chmod 600 "$TMP/empty"
printf '%s\n%s\n' "$VALID" "$VALID" > "$TMP/multiline"; chmod 600 "$TMP/multiline"
printf '%s\nextra-without-final-newline' "$VALID" > "$TMP/unterminated_second"; chmod 600 "$TMP/unterminated_second"
printf '%s' "$VALID" > "$TMP/valid_without_newline"; chmod 600 "$TMP/valid_without_newline"
printf 'not-a-hash\n' > "$TMP/malformed"; chmod 600 "$TMP/malformed"
printf '%s\n' "$VALID" > "$TMP/wrongmode"; chmod 644 "$TMP/wrongmode"
run_case valid pass "$TMP/valid"
run_case sentinel pass "$TMP/sentinel"
run_case missing fail "$TMP/missing"
run_case empty fail "$TMP/empty"
run_case multiline fail "$TMP/multiline"
run_case unterminated_second fail "$TMP/unterminated_second"
run_case valid_without_newline fail "$TMP/valid_without_newline"
run_case malformed fail "$TMP/malformed"
run_case wrongmode fail "$TMP/wrongmode"
printf 'cleanup_registered=%s\n' "$TMP"
