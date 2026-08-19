# Verification — Bootstrap Validator Anti-Overfit Matrix

## Artifact digests
802695f5e3183c014de98e3080059629c2c9eada0aff11905f5f617583b5ae7c  .omo/ulw-research/20260711-124332-default-nixos-password/candidate-bootstrap-password.nix
e491176991483a8241bbe34be990bc4bd52b910658afc193a1e815b3232ebda3  .omo/ulw-research/20260711-124332-default-nixos-password/verify-bootstrap-validator.sh
62a943098374f7817f642a1066c3e46fad289cedce9c3b4b2a6565049269c7a2  .omo/ulw-research/20260711-124332-default-nixos-password/run-validator-verification.sh
471d0d4641a732381e5f94688c25039d40fd8d3cd5e68ccdc668b4300b0a1e61  .omo/ulw-research/20260711-124332-default-nixos-password/SYNTHESIS.md

## Exact harness
```bash
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
```

## Exact execution transcript
```text
+ set -euo pipefail
+ D=.omo/ulw-research/20260711-124332-default-nixos-password
++ mktemp -d -t nix-password-verify.XXXXXX
+ TMP=/tmp/nix-password-verify.UVbH2F
+ trap 'rm -rf "$TMP"' EXIT
+ VALID='$y$j9T$abcdefghijklmnop$0123456789012345678901234567890123456789012'
+ printf '%s\n' '$y$j9T$abcdefghijklmnop$0123456789012345678901234567890123456789012'
+ chmod 600 /tmp/nix-password-verify.UVbH2F/valid
+ printf '!\n'
+ chmod 600 /tmp/nix-password-verify.UVbH2F/sentinel
+ :
+ chmod 600 /tmp/nix-password-verify.UVbH2F/empty
+ printf '%s\n%s\n' '$y$j9T$abcdefghijklmnop$0123456789012345678901234567890123456789012' '$y$j9T$abcdefghijklmnop$0123456789012345678901234567890123456789012'
+ chmod 600 /tmp/nix-password-verify.UVbH2F/multiline
+ printf '%s\nextra-without-final-newline' '$y$j9T$abcdefghijklmnop$0123456789012345678901234567890123456789012'
+ chmod 600 /tmp/nix-password-verify.UVbH2F/unterminated_second
+ printf %s '$y$j9T$abcdefghijklmnop$0123456789012345678901234567890123456789012'
+ chmod 600 /tmp/nix-password-verify.UVbH2F/valid_without_newline
+ printf 'not-a-hash\n'
+ chmod 600 /tmp/nix-password-verify.UVbH2F/malformed
+ printf '%s\n' '$y$j9T$abcdefghijklmnop$0123456789012345678901234567890123456789012'
+ chmod 644 /tmp/nix-password-verify.UVbH2F/wrongmode
+ run_case valid pass /tmp/nix-password-verify.UVbH2F/valid
+ local name=valid expected=pass file=/tmp/nix-password-verify.UVbH2F/valid output rc verdict=FAIL
+ set +e
+++ id -un
+++ id -gn
++ EXPECTED_OWNER=mei:mei
++ .omo/ulw-research/20260711-124332-default-nixos-password/verify-bootstrap-validator.sh /tmp/nix-password-verify.UVbH2F/valid
+ output=PASS
+ rc=0
+ set -e
+ [[ pass == pass ]]
+ [[ 0 -eq 0 ]]
+ verdict=PASS
+ printf '%s expected=%s rc=%s verdict=%s output=%s\n' valid pass 0 PASS PASS
valid expected=pass rc=0 verdict=PASS output=PASS
+ [[ PASS == PASS ]]
+ run_case sentinel pass /tmp/nix-password-verify.UVbH2F/sentinel
+ local name=sentinel expected=pass file=/tmp/nix-password-verify.UVbH2F/sentinel output rc verdict=FAIL
+ set +e
+++ id -un
+++ id -gn
++ EXPECTED_OWNER=mei:mei
++ .omo/ulw-research/20260711-124332-default-nixos-password/verify-bootstrap-validator.sh /tmp/nix-password-verify.UVbH2F/sentinel
+ output=PASS
+ rc=0
+ set -e
+ [[ pass == pass ]]
+ [[ 0 -eq 0 ]]
+ verdict=PASS
+ printf '%s expected=%s rc=%s verdict=%s output=%s\n' sentinel pass 0 PASS PASS
sentinel expected=pass rc=0 verdict=PASS output=PASS
+ [[ PASS == PASS ]]
+ run_case missing fail /tmp/nix-password-verify.UVbH2F/missing
+ local name=missing expected=fail file=/tmp/nix-password-verify.UVbH2F/missing output rc verdict=FAIL
+ set +e
+++ id -un
+++ id -gn
++ EXPECTED_OWNER=mei:mei
++ .omo/ulw-research/20260711-124332-default-nixos-password/verify-bootstrap-validator.sh /tmp/nix-password-verify.UVbH2F/missing
+ output='FAIL: missing'
+ rc=1
+ set -e
+ [[ fail == pass ]]
+ [[ fail == fail ]]
+ [[ 1 -ne 0 ]]
+ verdict=PASS
+ printf '%s expected=%s rc=%s verdict=%s output=%s\n' missing fail 1 PASS 'FAIL: missing'
missing expected=fail rc=1 verdict=PASS output=FAIL: missing
+ [[ PASS == PASS ]]
+ run_case empty fail /tmp/nix-password-verify.UVbH2F/empty
+ local name=empty expected=fail file=/tmp/nix-password-verify.UVbH2F/empty output rc verdict=FAIL
+ set +e
+++ id -un
+++ id -gn
++ EXPECTED_OWNER=mei:mei
++ .omo/ulw-research/20260711-124332-default-nixos-password/verify-bootstrap-validator.sh /tmp/nix-password-verify.UVbH2F/empty
+ output='FAIL: empty'
+ rc=1
+ set -e
+ [[ fail == pass ]]
+ [[ fail == fail ]]
+ [[ 1 -ne 0 ]]
+ verdict=PASS
+ printf '%s expected=%s rc=%s verdict=%s output=%s\n' empty fail 1 PASS 'FAIL: empty'
empty expected=fail rc=1 verdict=PASS output=FAIL: empty
+ [[ PASS == PASS ]]
+ run_case multiline fail /tmp/nix-password-verify.UVbH2F/multiline
+ local name=multiline expected=fail file=/tmp/nix-password-verify.UVbH2F/multiline output rc verdict=FAIL
+ set +e
+++ id -un
+++ id -gn
++ EXPECTED_OWNER=mei:mei
++ .omo/ulw-research/20260711-124332-default-nixos-password/verify-bootstrap-validator.sh /tmp/nix-password-verify.UVbH2F/multiline
+ output='FAIL: line_count'
+ rc=1
+ set -e
+ [[ fail == pass ]]
+ [[ fail == fail ]]
+ [[ 1 -ne 0 ]]
+ verdict=PASS
+ printf '%s expected=%s rc=%s verdict=%s output=%s\n' multiline fail 1 PASS 'FAIL: line_count'
multiline expected=fail rc=1 verdict=PASS output=FAIL: line_count
+ [[ PASS == PASS ]]
+ run_case unterminated_second fail /tmp/nix-password-verify.UVbH2F/unterminated_second
+ local name=unterminated_second expected=fail file=/tmp/nix-password-verify.UVbH2F/unterminated_second output rc verdict=FAIL
+ set +e
+++ id -un
+++ id -gn
++ EXPECTED_OWNER=mei:mei
++ .omo/ulw-research/20260711-124332-default-nixos-password/verify-bootstrap-validator.sh /tmp/nix-password-verify.UVbH2F/unterminated_second
+ output='FAIL: missing_final_newline'
+ rc=1
+ set -e
+ [[ fail == pass ]]
+ [[ fail == fail ]]
+ [[ 1 -ne 0 ]]
+ verdict=PASS
+ printf '%s expected=%s rc=%s verdict=%s output=%s\n' unterminated_second fail 1 PASS 'FAIL: missing_final_newline'
unterminated_second expected=fail rc=1 verdict=PASS output=FAIL: missing_final_newline
+ [[ PASS == PASS ]]
+ run_case valid_without_newline fail /tmp/nix-password-verify.UVbH2F/valid_without_newline
+ local name=valid_without_newline expected=fail file=/tmp/nix-password-verify.UVbH2F/valid_without_newline output rc verdict=FAIL
+ set +e
+++ id -un
+++ id -gn
++ EXPECTED_OWNER=mei:mei
++ .omo/ulw-research/20260711-124332-default-nixos-password/verify-bootstrap-validator.sh /tmp/nix-password-verify.UVbH2F/valid_without_newline
+ output='FAIL: missing_final_newline'
+ rc=1
+ set -e
+ [[ fail == pass ]]
+ [[ fail == fail ]]
+ [[ 1 -ne 0 ]]
+ verdict=PASS
+ printf '%s expected=%s rc=%s verdict=%s output=%s\n' valid_without_newline fail 1 PASS 'FAIL: missing_final_newline'
valid_without_newline expected=fail rc=1 verdict=PASS output=FAIL: missing_final_newline
+ [[ PASS == PASS ]]
+ run_case malformed fail /tmp/nix-password-verify.UVbH2F/malformed
+ local name=malformed expected=fail file=/tmp/nix-password-verify.UVbH2F/malformed output rc verdict=FAIL
+ set +e
+++ id -un
+++ id -gn
++ EXPECTED_OWNER=mei:mei
++ .omo/ulw-research/20260711-124332-default-nixos-password/verify-bootstrap-validator.sh /tmp/nix-password-verify.UVbH2F/malformed
+ output='FAIL: format'
+ rc=1
+ set -e
+ [[ fail == pass ]]
+ [[ fail == fail ]]
+ [[ 1 -ne 0 ]]
+ verdict=PASS
+ printf '%s expected=%s rc=%s verdict=%s output=%s\n' malformed fail 1 PASS 'FAIL: format'
malformed expected=fail rc=1 verdict=PASS output=FAIL: format
+ [[ PASS == PASS ]]
+ run_case wrongmode fail /tmp/nix-password-verify.UVbH2F/wrongmode
+ local name=wrongmode expected=fail file=/tmp/nix-password-verify.UVbH2F/wrongmode output rc verdict=FAIL
+ set +e
+++ id -un
+++ id -gn
++ EXPECTED_OWNER=mei:mei
++ .omo/ulw-research/20260711-124332-default-nixos-password/verify-bootstrap-validator.sh /tmp/nix-password-verify.UVbH2F/wrongmode
+ output='FAIL: mode_or_owner'
+ rc=1
+ set -e
+ [[ fail == pass ]]
+ [[ fail == fail ]]
+ [[ 1 -ne 0 ]]
+ verdict=PASS
+ printf '%s expected=%s rc=%s verdict=%s output=%s\n' wrongmode fail 1 PASS 'FAIL: mode_or_owner'
wrongmode expected=fail rc=1 verdict=PASS output=FAIL: mode_or_owner
+ [[ PASS == PASS ]]
+ printf 'cleanup_registered=%s\n' /tmp/nix-password-verify.UVbH2F
cleanup_registered=/tmp/nix-password-verify.UVbH2F
+ rm -rf /tmp/nix-password-verify.UVbH2F
```

temporary_directory_cleanup=PASS
