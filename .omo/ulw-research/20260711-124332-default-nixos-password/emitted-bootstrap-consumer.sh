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
