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
