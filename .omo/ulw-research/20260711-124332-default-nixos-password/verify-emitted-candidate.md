# Verification — Exact Emitted Candidate Activation

## Artifact identity

```text
2f371c11bf897b2302e8e4a4cf27f11c0f409859aedb2d7dac6a71be36e4f2f5  .omo/ulw-research/20260711-124332-default-nixos-password/candidate-bootstrap-password.nix
a40041920dc9c954657908f57845a944df7d10978def2075dfecb8eabe60bb4b  .omo/ulw-research/20260711-124332-default-nixos-password/emitted-bootstrap-validator.sh
1b0264a8d76717032d5f503d9678356e4c536521fe8bcafaeaa38026d59d62e4  .omo/ulw-research/20260711-124332-default-nixos-password/emitted-bootstrap-consumer.sh
d1303e3a22582469b1d4023521cdc4087b93e1336344750f7aa1f9458878bd31  .omo/ulw-research/20260711-124332-default-nixos-password/run-emitted-candidate-verification.sh
```

## Self-binding guarantee

The harness evaluates the current candidate module into temporary validator and consumer scripts on every run, compares them byte-for-byte with the recorded emitted scripts, then executes the freshly evaluated temporary scripts. Candidate/emitted drift therefore fails before any fixture case.

## Recorded emitted validator

```bash
hash_file=/var/lib/nixos-bootstrap/mei-password.hash
fail() {
  echo "bootstrap password hash validation failed: $1" >&2
  exit 1
}
test -f "$hash_file" || fail "missing $hash_file"
test "$(/nix/store/sr26flm2nkfa12dkrwj2630kqsfakky4-coreutils-9.11/bin/stat -c '%U:%G:%a' "$hash_file")" = "root:root:600" \
  || fail "expected root:root mode 0600"
test -s "$hash_file" || fail "expected non-empty file"
last_byte="$(/nix/store/sr26flm2nkfa12dkrwj2630kqsfakky4-coreutils-9.11/bin/tail -c 1 "$hash_file" \
  | /nix/store/sr26flm2nkfa12dkrwj2630kqsfakky4-coreutils-9.11/bin/od -An -tuC \
  | /nix/store/sr26flm2nkfa12dkrwj2630kqsfakky4-coreutils-9.11/bin/tr -d '[:space:]')"
test "$last_byte" = 10 || fail "expected one newline-terminated line"
test "$(/nix/store/sr26flm2nkfa12dkrwj2630kqsfakky4-coreutils-9.11/bin/wc -l < "$hash_file")" -eq 1 \
  || fail "expected exactly one newline-terminated line"
if /nix/store/w8xlvapzxcz23ba312q119p57bnc7200-gnugrep-3.12/bin/grep -qx '!' "$hash_file"; then
  # A consumed sentinel is safe only after a previous activation installed
  # a real password. Reject it on a fresh machine or for a locked account.
  test -r /etc/shadow || fail "cannot verify consumed sentinel"
  /nix/store/cdd73p8qiphg0scs02i6lrg1sjsdvbkx-gawk-5.4.0/bin/awk -F: -v target_user=mei '
    $1 == target_user {
      found = 1
      if ($2 != "" && $2 !~ /^[!*]/) unlocked = 1
    }
    END { exit !(found && unlocked) }
  ' /etc/shadow || fail "consumed sentinel requires an existing unlocked password"
else
  /nix/store/w8xlvapzxcz23ba312q119p57bnc7200-gnugrep-3.12/bin/grep -Eqx \
    '^\$y\$[./A-Za-z0-9]+\$[./A-Za-z0-9]{0,86}\$[./A-Za-z0-9]{43}$' \
    "$hash_file" || fail "expected yescrypt hash"
fi
```

## Recorded emitted consumer

```bash
hash_file=/var/lib/nixos-bootstrap/mei-password.hash
if ! /nix/store/w8xlvapzxcz23ba312q119p57bnc7200-gnugrep-3.12/bin/grep -qx '!' "$hash_file"; then
  tmp="$hash_file.tmp.$$"
  trap 'rm -f "$tmp"' EXIT
  /nix/store/sr26flm2nkfa12dkrwj2630kqsfakky4-coreutils-9.11/bin/printf '!\n' > "$tmp"
  /nix/store/sr26flm2nkfa12dkrwj2630kqsfakky4-coreutils-9.11/bin/chown root:root "$tmp"
  /nix/store/sr26flm2nkfa12dkrwj2630kqsfakky4-coreutils-9.11/bin/chmod 0600 "$tmp"
  /nix/store/sr26flm2nkfa12dkrwj2630kqsfakky4-coreutils-9.11/bin/mv -f "$tmp" "$hash_file"
  trap - EXIT
fi
```

## Self-binding harness

User and mount namespaces bind isolated fixtures at the real candidate paths, including `/var/lib` and `/etc/shadow`. Consumer output is byte-compared to exact `!\n` and revalidated with the exact freshly emitted validator.

```bash
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
```

## Transcript

```text
+ set -euo pipefail
+ D=.omo/ulw-research/20260711-124332-default-nixos-password
++ mktemp -d -t nix-emitted-password-verify.XXXXXX
+ TMP=/tmp/nix-emitted-password-verify.xqJ5ea
+ trap 'rm -rf "$TMP"' EXIT
+ VALID='$y$j9T$abcdefghijklmnop$0123456789012345678901234567890123456789012'
+ EXPR='let f=builtins.getFlake (toString /home/mei/nix-config); in (f.nixosConfigurations.x86_64-linux.extendModules { modules=[ /home/mei/nix-config/.omo/ulw-research/20260711-124332-default-nixos-password/candidate-bootstrap-password.nix ]; }).config'
+ nix eval --raw --impure --expr 'let f=builtins.getFlake (toString /home/mei/nix-config); in (f.nixosConfigurations.x86_64-linux.extendModules { modules=[ /home/mei/nix-config/.omo/ulw-research/20260711-124332-default-nixos-password/candidate-bootstrap-password.nix ]; }).config.system.activationScripts.bootstrapPasswordHash.text'
warning: Nix search path entry '/home/mei/.nix-defexpr/channels' does not exist, ignoring
+ nix eval --raw --impure --expr 'let f=builtins.getFlake (toString /home/mei/nix-config); in (f.nixosConfigurations.x86_64-linux.extendModules { modules=[ /home/mei/nix-config/.omo/ulw-research/20260711-124332-default-nixos-password/candidate-bootstrap-password.nix ]; }).config.system.activationScripts.consumeBootstrapPassword.text'
warning: Nix search path entry '/home/mei/.nix-defexpr/channels' does not exist, ignoring
+ cmp /tmp/nix-emitted-password-verify.xqJ5ea/emitted-validator.sh .omo/ulw-research/20260711-124332-default-nixos-password/emitted-bootstrap-validator.sh
+ cmp /tmp/nix-emitted-password-verify.xqJ5ea/emitted-consumer.sh .omo/ulw-research/20260711-124332-default-nixos-password/emitted-bootstrap-consumer.sh
+ mkdir -p /tmp/nix-emitted-password-verify.xqJ5ea/valid/nixos-bootstrap
+ printf '%s\n' '$y$j9T$abcdefghijklmnop$0123456789012345678901234567890123456789012'
+ chmod 600 /tmp/nix-emitted-password-verify.xqJ5ea/valid/nixos-bootstrap/mei-password.hash
+ mkdir -p /tmp/nix-emitted-password-verify.xqJ5ea/sentinel/nixos-bootstrap
+ printf '!\n'
+ chmod 600 /tmp/nix-emitted-password-verify.xqJ5ea/sentinel/nixos-bootstrap/mei-password.hash
+ mkdir -p /tmp/nix-emitted-password-verify.xqJ5ea/missing/nixos-bootstrap
+ mkdir -p /tmp/nix-emitted-password-verify.xqJ5ea/empty/nixos-bootstrap
+ :
+ chmod 600 /tmp/nix-emitted-password-verify.xqJ5ea/empty/nixos-bootstrap/mei-password.hash
+ mkdir -p /tmp/nix-emitted-password-verify.xqJ5ea/multiline/nixos-bootstrap
+ printf '%s\n%s\n' '$y$j9T$abcdefghijklmnop$0123456789012345678901234567890123456789012' '$y$j9T$abcdefghijklmnop$0123456789012345678901234567890123456789012'
+ chmod 600 /tmp/nix-emitted-password-verify.xqJ5ea/multiline/nixos-bootstrap/mei-password.hash
+ mkdir -p /tmp/nix-emitted-password-verify.xqJ5ea/unterminated_second/nixos-bootstrap
+ printf '%s\nextra' '$y$j9T$abcdefghijklmnop$0123456789012345678901234567890123456789012'
+ chmod 600 /tmp/nix-emitted-password-verify.xqJ5ea/unterminated_second/nixos-bootstrap/mei-password.hash
+ mkdir -p /tmp/nix-emitted-password-verify.xqJ5ea/no_final_newline/nixos-bootstrap
+ printf %s '$y$j9T$abcdefghijklmnop$0123456789012345678901234567890123456789012'
+ chmod 600 /tmp/nix-emitted-password-verify.xqJ5ea/no_final_newline/nixos-bootstrap/mei-password.hash
+ mkdir -p /tmp/nix-emitted-password-verify.xqJ5ea/malformed/nixos-bootstrap
+ printf 'not-a-hash\n'
+ chmod 600 /tmp/nix-emitted-password-verify.xqJ5ea/malformed/nixos-bootstrap/mei-password.hash
+ mkdir -p /tmp/nix-emitted-password-verify.xqJ5ea/wrongmode/nixos-bootstrap
+ printf '%s\n' '$y$j9T$abcdefghijklmnop$0123456789012345678901234567890123456789012'
+ chmod 644 /tmp/nix-emitted-password-verify.xqJ5ea/wrongmode/nixos-bootstrap/mei-password.hash
+ printf 'root:*:1:0:99999:7:::\n'
+ printf 'root:*:1:0:99999:7:::\nmei:%s:1:0:99999:7:::\n' '$y$j9T$abcdefghijklmnop$0123456789012345678901234567890123456789012'
+ printf 'root:*:1:0:99999:7:::\nmei:!:1:0:99999:7:::\n'
+ run_case valid pass /tmp/nix-emitted-password-verify.xqJ5ea/valid /tmp/nix-emitted-password-verify.xqJ5ea/shadow-fresh
+ local name=valid expected=pass root=/tmp/nix-emitted-password-verify.xqJ5ea/valid shadow=/tmp/nix-emitted-password-verify.xqJ5ea/shadow-fresh output rc verdict=FAIL
+ set +e
++ unshare -Ur -m bash -c $'\n    mount --bind "$1" /var/lib\n    mount --bind "$2" /etc/shadow\n    bash "$3"\n  ' _ /tmp/nix-emitted-password-verify.xqJ5ea/valid /tmp/nix-emitted-password-verify.xqJ5ea/shadow-fresh /tmp/nix-emitted-password-verify.xqJ5ea/emitted-validator.sh
+ output=
+ rc=0
+ set -e
+ [[ pass == pass ]]
+ [[ 0 -eq 0 ]]
+ verdict=PASS
+ printf '%s expected=%s rc=%s verdict=%s output=%q\n' valid pass 0 PASS ''
valid expected=pass rc=0 verdict=PASS output=''
+ [[ PASS == PASS ]]
+ run_case sentinel_existing_unlocked pass /tmp/nix-emitted-password-verify.xqJ5ea/sentinel /tmp/nix-emitted-password-verify.xqJ5ea/shadow-unlocked
+ local name=sentinel_existing_unlocked expected=pass root=/tmp/nix-emitted-password-verify.xqJ5ea/sentinel shadow=/tmp/nix-emitted-password-verify.xqJ5ea/shadow-unlocked output rc verdict=FAIL
+ set +e
++ unshare -Ur -m bash -c $'\n    mount --bind "$1" /var/lib\n    mount --bind "$2" /etc/shadow\n    bash "$3"\n  ' _ /tmp/nix-emitted-password-verify.xqJ5ea/sentinel /tmp/nix-emitted-password-verify.xqJ5ea/shadow-unlocked /tmp/nix-emitted-password-verify.xqJ5ea/emitted-validator.sh
+ output=
+ rc=0
+ set -e
+ [[ pass == pass ]]
+ [[ 0 -eq 0 ]]
+ verdict=PASS
+ printf '%s expected=%s rc=%s verdict=%s output=%q\n' sentinel_existing_unlocked pass 0 PASS ''
sentinel_existing_unlocked expected=pass rc=0 verdict=PASS output=''
+ [[ PASS == PASS ]]
+ run_case sentinel_fresh fail /tmp/nix-emitted-password-verify.xqJ5ea/sentinel /tmp/nix-emitted-password-verify.xqJ5ea/shadow-fresh
+ local name=sentinel_fresh expected=fail root=/tmp/nix-emitted-password-verify.xqJ5ea/sentinel shadow=/tmp/nix-emitted-password-verify.xqJ5ea/shadow-fresh output rc verdict=FAIL
+ set +e
++ unshare -Ur -m bash -c $'\n    mount --bind "$1" /var/lib\n    mount --bind "$2" /etc/shadow\n    bash "$3"\n  ' _ /tmp/nix-emitted-password-verify.xqJ5ea/sentinel /tmp/nix-emitted-password-verify.xqJ5ea/shadow-fresh /tmp/nix-emitted-password-verify.xqJ5ea/emitted-validator.sh
+ output='bootstrap password hash validation failed: consumed sentinel requires an existing unlocked password'
+ rc=1
+ set -e
+ [[ fail == pass ]]
+ [[ fail == fail ]]
+ [[ 1 -ne 0 ]]
+ verdict=PASS
+ printf '%s expected=%s rc=%s verdict=%s output=%q\n' sentinel_fresh fail 1 PASS 'bootstrap password hash validation failed: consumed sentinel requires an existing unlocked password'
sentinel_fresh expected=fail rc=1 verdict=PASS output=bootstrap\ password\ hash\ validation\ failed:\ consumed\ sentinel\ requires\ an\ existing\ unlocked\ password
+ [[ PASS == PASS ]]
+ run_case sentinel_locked fail /tmp/nix-emitted-password-verify.xqJ5ea/sentinel /tmp/nix-emitted-password-verify.xqJ5ea/shadow-locked
+ local name=sentinel_locked expected=fail root=/tmp/nix-emitted-password-verify.xqJ5ea/sentinel shadow=/tmp/nix-emitted-password-verify.xqJ5ea/shadow-locked output rc verdict=FAIL
+ set +e
++ unshare -Ur -m bash -c $'\n    mount --bind "$1" /var/lib\n    mount --bind "$2" /etc/shadow\n    bash "$3"\n  ' _ /tmp/nix-emitted-password-verify.xqJ5ea/sentinel /tmp/nix-emitted-password-verify.xqJ5ea/shadow-locked /tmp/nix-emitted-password-verify.xqJ5ea/emitted-validator.sh
+ output='bootstrap password hash validation failed: consumed sentinel requires an existing unlocked password'
+ rc=1
+ set -e
+ [[ fail == pass ]]
+ [[ fail == fail ]]
+ [[ 1 -ne 0 ]]
+ verdict=PASS
+ printf '%s expected=%s rc=%s verdict=%s output=%q\n' sentinel_locked fail 1 PASS 'bootstrap password hash validation failed: consumed sentinel requires an existing unlocked password'
sentinel_locked expected=fail rc=1 verdict=PASS output=bootstrap\ password\ hash\ validation\ failed:\ consumed\ sentinel\ requires\ an\ existing\ unlocked\ password
+ [[ PASS == PASS ]]
+ run_case missing fail /tmp/nix-emitted-password-verify.xqJ5ea/missing /tmp/nix-emitted-password-verify.xqJ5ea/shadow-fresh
+ local name=missing expected=fail root=/tmp/nix-emitted-password-verify.xqJ5ea/missing shadow=/tmp/nix-emitted-password-verify.xqJ5ea/shadow-fresh output rc verdict=FAIL
+ set +e
++ unshare -Ur -m bash -c $'\n    mount --bind "$1" /var/lib\n    mount --bind "$2" /etc/shadow\n    bash "$3"\n  ' _ /tmp/nix-emitted-password-verify.xqJ5ea/missing /tmp/nix-emitted-password-verify.xqJ5ea/shadow-fresh /tmp/nix-emitted-password-verify.xqJ5ea/emitted-validator.sh
+ output='bootstrap password hash validation failed: missing /var/lib/nixos-bootstrap/mei-password.hash'
+ rc=1
+ set -e
+ [[ fail == pass ]]
+ [[ fail == fail ]]
+ [[ 1 -ne 0 ]]
+ verdict=PASS
+ printf '%s expected=%s rc=%s verdict=%s output=%q\n' missing fail 1 PASS 'bootstrap password hash validation failed: missing /var/lib/nixos-bootstrap/mei-password.hash'
missing expected=fail rc=1 verdict=PASS output=bootstrap\ password\ hash\ validation\ failed:\ missing\ /var/lib/nixos-bootstrap/mei-password.hash
+ [[ PASS == PASS ]]
+ run_case empty fail /tmp/nix-emitted-password-verify.xqJ5ea/empty /tmp/nix-emitted-password-verify.xqJ5ea/shadow-fresh
+ local name=empty expected=fail root=/tmp/nix-emitted-password-verify.xqJ5ea/empty shadow=/tmp/nix-emitted-password-verify.xqJ5ea/shadow-fresh output rc verdict=FAIL
+ set +e
++ unshare -Ur -m bash -c $'\n    mount --bind "$1" /var/lib\n    mount --bind "$2" /etc/shadow\n    bash "$3"\n  ' _ /tmp/nix-emitted-password-verify.xqJ5ea/empty /tmp/nix-emitted-password-verify.xqJ5ea/shadow-fresh /tmp/nix-emitted-password-verify.xqJ5ea/emitted-validator.sh
+ output='bootstrap password hash validation failed: expected non-empty file'
+ rc=1
+ set -e
+ [[ fail == pass ]]
+ [[ fail == fail ]]
+ [[ 1 -ne 0 ]]
+ verdict=PASS
+ printf '%s expected=%s rc=%s verdict=%s output=%q\n' empty fail 1 PASS 'bootstrap password hash validation failed: expected non-empty file'
empty expected=fail rc=1 verdict=PASS output=bootstrap\ password\ hash\ validation\ failed:\ expected\ non-empty\ file
+ [[ PASS == PASS ]]
+ run_case multiline fail /tmp/nix-emitted-password-verify.xqJ5ea/multiline /tmp/nix-emitted-password-verify.xqJ5ea/shadow-fresh
+ local name=multiline expected=fail root=/tmp/nix-emitted-password-verify.xqJ5ea/multiline shadow=/tmp/nix-emitted-password-verify.xqJ5ea/shadow-fresh output rc verdict=FAIL
+ set +e
++ unshare -Ur -m bash -c $'\n    mount --bind "$1" /var/lib\n    mount --bind "$2" /etc/shadow\n    bash "$3"\n  ' _ /tmp/nix-emitted-password-verify.xqJ5ea/multiline /tmp/nix-emitted-password-verify.xqJ5ea/shadow-fresh /tmp/nix-emitted-password-verify.xqJ5ea/emitted-validator.sh
+ output='bootstrap password hash validation failed: expected exactly one newline-terminated line'
+ rc=1
+ set -e
+ [[ fail == pass ]]
+ [[ fail == fail ]]
+ [[ 1 -ne 0 ]]
+ verdict=PASS
+ printf '%s expected=%s rc=%s verdict=%s output=%q\n' multiline fail 1 PASS 'bootstrap password hash validation failed: expected exactly one newline-terminated line'
multiline expected=fail rc=1 verdict=PASS output=bootstrap\ password\ hash\ validation\ failed:\ expected\ exactly\ one\ newline-terminated\ line
+ [[ PASS == PASS ]]
+ run_case unterminated_second fail /tmp/nix-emitted-password-verify.xqJ5ea/unterminated_second /tmp/nix-emitted-password-verify.xqJ5ea/shadow-fresh
+ local name=unterminated_second expected=fail root=/tmp/nix-emitted-password-verify.xqJ5ea/unterminated_second shadow=/tmp/nix-emitted-password-verify.xqJ5ea/shadow-fresh output rc verdict=FAIL
+ set +e
++ unshare -Ur -m bash -c $'\n    mount --bind "$1" /var/lib\n    mount --bind "$2" /etc/shadow\n    bash "$3"\n  ' _ /tmp/nix-emitted-password-verify.xqJ5ea/unterminated_second /tmp/nix-emitted-password-verify.xqJ5ea/shadow-fresh /tmp/nix-emitted-password-verify.xqJ5ea/emitted-validator.sh
+ output='bootstrap password hash validation failed: expected one newline-terminated line'
+ rc=1
+ set -e
+ [[ fail == pass ]]
+ [[ fail == fail ]]
+ [[ 1 -ne 0 ]]
+ verdict=PASS
+ printf '%s expected=%s rc=%s verdict=%s output=%q\n' unterminated_second fail 1 PASS 'bootstrap password hash validation failed: expected one newline-terminated line'
unterminated_second expected=fail rc=1 verdict=PASS output=bootstrap\ password\ hash\ validation\ failed:\ expected\ one\ newline-terminated\ line
+ [[ PASS == PASS ]]
+ run_case no_final_newline fail /tmp/nix-emitted-password-verify.xqJ5ea/no_final_newline /tmp/nix-emitted-password-verify.xqJ5ea/shadow-fresh
+ local name=no_final_newline expected=fail root=/tmp/nix-emitted-password-verify.xqJ5ea/no_final_newline shadow=/tmp/nix-emitted-password-verify.xqJ5ea/shadow-fresh output rc verdict=FAIL
+ set +e
++ unshare -Ur -m bash -c $'\n    mount --bind "$1" /var/lib\n    mount --bind "$2" /etc/shadow\n    bash "$3"\n  ' _ /tmp/nix-emitted-password-verify.xqJ5ea/no_final_newline /tmp/nix-emitted-password-verify.xqJ5ea/shadow-fresh /tmp/nix-emitted-password-verify.xqJ5ea/emitted-validator.sh
+ output='bootstrap password hash validation failed: expected one newline-terminated line'
+ rc=1
+ set -e
+ [[ fail == pass ]]
+ [[ fail == fail ]]
+ [[ 1 -ne 0 ]]
+ verdict=PASS
+ printf '%s expected=%s rc=%s verdict=%s output=%q\n' no_final_newline fail 1 PASS 'bootstrap password hash validation failed: expected one newline-terminated line'
no_final_newline expected=fail rc=1 verdict=PASS output=bootstrap\ password\ hash\ validation\ failed:\ expected\ one\ newline-terminated\ line
+ [[ PASS == PASS ]]
+ run_case malformed fail /tmp/nix-emitted-password-verify.xqJ5ea/malformed /tmp/nix-emitted-password-verify.xqJ5ea/shadow-fresh
+ local name=malformed expected=fail root=/tmp/nix-emitted-password-verify.xqJ5ea/malformed shadow=/tmp/nix-emitted-password-verify.xqJ5ea/shadow-fresh output rc verdict=FAIL
+ set +e
++ unshare -Ur -m bash -c $'\n    mount --bind "$1" /var/lib\n    mount --bind "$2" /etc/shadow\n    bash "$3"\n  ' _ /tmp/nix-emitted-password-verify.xqJ5ea/malformed /tmp/nix-emitted-password-verify.xqJ5ea/shadow-fresh /tmp/nix-emitted-password-verify.xqJ5ea/emitted-validator.sh
+ output='bootstrap password hash validation failed: expected yescrypt hash'
+ rc=1
+ set -e
+ [[ fail == pass ]]
+ [[ fail == fail ]]
+ [[ 1 -ne 0 ]]
+ verdict=PASS
+ printf '%s expected=%s rc=%s verdict=%s output=%q\n' malformed fail 1 PASS 'bootstrap password hash validation failed: expected yescrypt hash'
malformed expected=fail rc=1 verdict=PASS output=bootstrap\ password\ hash\ validation\ failed:\ expected\ yescrypt\ hash
+ [[ PASS == PASS ]]
+ run_case wrongmode fail /tmp/nix-emitted-password-verify.xqJ5ea/wrongmode /tmp/nix-emitted-password-verify.xqJ5ea/shadow-fresh
+ local name=wrongmode expected=fail root=/tmp/nix-emitted-password-verify.xqJ5ea/wrongmode shadow=/tmp/nix-emitted-password-verify.xqJ5ea/shadow-fresh output rc verdict=FAIL
+ set +e
++ unshare -Ur -m bash -c $'\n    mount --bind "$1" /var/lib\n    mount --bind "$2" /etc/shadow\n    bash "$3"\n  ' _ /tmp/nix-emitted-password-verify.xqJ5ea/wrongmode /tmp/nix-emitted-password-verify.xqJ5ea/shadow-fresh /tmp/nix-emitted-password-verify.xqJ5ea/emitted-validator.sh
+ output='bootstrap password hash validation failed: expected root:root mode 0600'
+ rc=1
+ set -e
+ [[ fail == pass ]]
+ [[ fail == fail ]]
+ [[ 1 -ne 0 ]]
+ verdict=PASS
+ printf '%s expected=%s rc=%s verdict=%s output=%q\n' wrongmode fail 1 PASS 'bootstrap password hash validation failed: expected root:root mode 0600'
wrongmode expected=fail rc=1 verdict=PASS output=bootstrap\ password\ hash\ validation\ failed:\ expected\ root:root\ mode\ 0600
+ [[ PASS == PASS ]]
+ unshare -Ur -m bash -c $'\n  mount --bind "$1" /var/lib\n  mount --bind "$2" /etc/shadow\n  bash "$3"\n  bash "$4"\n' _ /tmp/nix-emitted-password-verify.xqJ5ea/valid /tmp/nix-emitted-password-verify.xqJ5ea/shadow-unlocked /tmp/nix-emitted-password-verify.xqJ5ea/emitted-validator.sh /tmp/nix-emitted-password-verify.xqJ5ea/emitted-consumer.sh
+ printf '!\n'
+ cmp /tmp/nix-emitted-password-verify.xqJ5ea/expected-sentinel /tmp/nix-emitted-password-verify.xqJ5ea/valid/nixos-bootstrap/mei-password.hash
+ unshare -Ur -m bash -c $'\n  mount --bind "$1" /var/lib\n  mount --bind "$2" /etc/shadow\n  bash "$3"\n' _ /tmp/nix-emitted-password-verify.xqJ5ea/valid /tmp/nix-emitted-password-verify.xqJ5ea/shadow-unlocked /tmp/nix-emitted-password-verify.xqJ5ea/emitted-validator.sh
++ stat -c %a /tmp/nix-emitted-password-verify.xqJ5ea/valid/nixos-bootstrap/mei-password.hash
+ [[ 600 == 600 ]]
+ printf 'emitted_consumer_exact_sentinel_and_revalidation=PASS\n'
emitted_consumer_exact_sentinel_and_revalidation=PASS
+ rm -rf /tmp/nix-emitted-password-verify.xqJ5ea
```

## Verdict

- Candidate-to-emitted byte comparison: PASS.
- Fresh yescrypt verifier: PASS.
- Consumed sentinel with an existing unlocked shadow password: PASS.
- Sentinel on a fresh machine or locked account: correctly rejected.
- Missing, empty, multiline, unterminated, malformed, and wrong-mode inputs: correctly rejected.
- Post-users consumer: exact `!\n`, mode 0600, and exact-validator revalidation PASS.
- Temporary fixture directory: removed by trap.
