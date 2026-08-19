#!/usr/bin/env bash
set -euo pipefail
D=$1
TMP=$(mktemp -d -t nix-emitted-password-verify.XXXXXX)
trap 'rm -rf "$TMP"' EXIT
VALID='$y$j9T$abcdefghijklmnop$0123456789012345678901234567890123456789012'
EXPR="let f=builtins.getFlake (toString /home/mei/nix-config); in (f.nixosConfigurations.x86_64-linux.extendModules { modules=[ /home/mei/nix-config/$D/candidate-bootstrap-password.nix ]; }).config"
nix eval --raw --impure --expr "$EXPR.system.activationScripts.bootstrapPasswordHash.text" > "$TMP/emitted-validator.sh"
nix eval --raw --impure --expr "$EXPR.system.activationScripts.consumeBootstrapPassword.text" > "$TMP/emitted-consumer.sh"
cmp "$TMP/emitted-validator.sh" "$D/emitted-bootstrap-validator.sh"
cmp "$TMP/emitted-consumer.sh" "$D/emitted-bootstrap-consumer.sh"
run_case() {
  local name=$1 expected=$2 root=$3 shadow=$4 output rc verdict=FAIL
  set +e
  output=$(unshare -Ur -m bash -c '
    mount --bind "$1" /var/lib
    mount --bind "$2" /etc/shadow
    bash "$3"
  ' _ "$root" "$shadow" "$TMP/emitted-validator.sh" 2>&1)
  rc=$?
  set -e
  if { [[ $expected == pass && $rc -eq 0 ]]; } || { [[ $expected == fail && $rc -ne 0 ]]; }; then verdict=PASS; fi
  printf '%s expected=%s rc=%s verdict=%s output=%q\n' "$name" "$expected" "$rc" "$verdict" "$output"
  [[ $verdict == PASS ]]
}
mkdir -p "$TMP/valid/nixos-bootstrap"; printf '%s\n' "$VALID" > "$TMP/valid/nixos-bootstrap/mei-password.hash"; chmod 600 "$TMP/valid/nixos-bootstrap/mei-password.hash"
mkdir -p "$TMP/sentinel/nixos-bootstrap"; printf '!\n' > "$TMP/sentinel/nixos-bootstrap/mei-password.hash"; chmod 600 "$TMP/sentinel/nixos-bootstrap/mei-password.hash"
mkdir -p "$TMP/missing/nixos-bootstrap"
mkdir -p "$TMP/empty/nixos-bootstrap"; : > "$TMP/empty/nixos-bootstrap/mei-password.hash"; chmod 600 "$TMP/empty/nixos-bootstrap/mei-password.hash"
mkdir -p "$TMP/multiline/nixos-bootstrap"; printf '%s\n%s\n' "$VALID" "$VALID" > "$TMP/multiline/nixos-bootstrap/mei-password.hash"; chmod 600 "$TMP/multiline/nixos-bootstrap/mei-password.hash"
mkdir -p "$TMP/unterminated_second/nixos-bootstrap"; printf '%s\nextra' "$VALID" > "$TMP/unterminated_second/nixos-bootstrap/mei-password.hash"; chmod 600 "$TMP/unterminated_second/nixos-bootstrap/mei-password.hash"
mkdir -p "$TMP/no_final_newline/nixos-bootstrap"; printf '%s' "$VALID" > "$TMP/no_final_newline/nixos-bootstrap/mei-password.hash"; chmod 600 "$TMP/no_final_newline/nixos-bootstrap/mei-password.hash"
mkdir -p "$TMP/malformed/nixos-bootstrap"; printf 'not-a-hash\n' > "$TMP/malformed/nixos-bootstrap/mei-password.hash"; chmod 600 "$TMP/malformed/nixos-bootstrap/mei-password.hash"
mkdir -p "$TMP/wrongmode/nixos-bootstrap"; printf '%s\n' "$VALID" > "$TMP/wrongmode/nixos-bootstrap/mei-password.hash"; chmod 644 "$TMP/wrongmode/nixos-bootstrap/mei-password.hash"
printf 'root:*:1:0:99999:7:::\n' > "$TMP/shadow-fresh"
printf 'root:*:1:0:99999:7:::\nmei:%s:1:0:99999:7:::\n' "$VALID" > "$TMP/shadow-unlocked"
printf 'root:*:1:0:99999:7:::\nmei:!:1:0:99999:7:::\n' > "$TMP/shadow-locked"
run_case valid pass "$TMP/valid" "$TMP/shadow-fresh"
run_case sentinel_existing_unlocked pass "$TMP/sentinel" "$TMP/shadow-unlocked"
run_case sentinel_fresh fail "$TMP/sentinel" "$TMP/shadow-fresh"
run_case sentinel_locked fail "$TMP/sentinel" "$TMP/shadow-locked"
run_case missing fail "$TMP/missing" "$TMP/shadow-fresh"
run_case empty fail "$TMP/empty" "$TMP/shadow-fresh"
run_case multiline fail "$TMP/multiline" "$TMP/shadow-fresh"
run_case unterminated_second fail "$TMP/unterminated_second" "$TMP/shadow-fresh"
run_case no_final_newline fail "$TMP/no_final_newline" "$TMP/shadow-fresh"
run_case malformed fail "$TMP/malformed" "$TMP/shadow-fresh"
run_case wrongmode fail "$TMP/wrongmode" "$TMP/shadow-fresh"
unshare -Ur -m bash -c '
  mount --bind "$1" /var/lib
  mount --bind "$2" /etc/shadow
  bash "$3"
  bash "$4"
' _ "$TMP/valid" "$TMP/shadow-unlocked" "$TMP/emitted-validator.sh" "$TMP/emitted-consumer.sh"
printf '!\n' > "$TMP/expected-sentinel"
cmp "$TMP/expected-sentinel" "$TMP/valid/nixos-bootstrap/mei-password.hash"
unshare -Ur -m bash -c '
  mount --bind "$1" /var/lib
  mount --bind "$2" /etc/shadow
  bash "$3"
' _ "$TMP/valid" "$TMP/shadow-unlocked" "$TMP/emitted-validator.sh"
[[ $(stat -c %a "$TMP/valid/nixos-bootstrap/mei-password.hash") == 600 ]]
printf 'emitted_consumer_exact_sentinel_and_revalidation=PASS\n'
