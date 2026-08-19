{ config, lib, pkgs, ... }:
let
  user = "mei";
  bootstrapHashFile = "/var/lib/nixos-bootstrap/mei-password.hash";
in
{
  users.mutableUsers = true;
  users.users.${user}.hashedPasswordFile = bootstrapHashFile;

  system.activationScripts.bootstrapPasswordHash = {
    deps = [ ];
    text = ''
      hash_file=${lib.escapeShellArg bootstrapHashFile}
      fail() {
        echo "bootstrap password hash validation failed: $1" >&2
        exit 1
      }
      test -f "$hash_file" || fail "missing $hash_file"
      test "$(${pkgs.coreutils}/bin/stat -c '%U:%G:%a' "$hash_file")" = "root:root:600" \
        || fail "expected root:root mode 0600"
      test -s "$hash_file" || fail "expected non-empty file"
      last_byte="$(${pkgs.coreutils}/bin/tail -c 1 "$hash_file" \
        | ${pkgs.coreutils}/bin/od -An -tuC \
        | ${pkgs.coreutils}/bin/tr -d '[:space:]')"
      test "$last_byte" = 10 || fail "expected one newline-terminated line"
      test "$(${pkgs.coreutils}/bin/wc -l < "$hash_file")" -eq 1 \
        || fail "expected exactly one newline-terminated line"
      if ${pkgs.gnugrep}/bin/grep -qx '!' "$hash_file"; then
        # A consumed sentinel is safe only after a previous activation installed
        # a real password. Reject it on a fresh machine or for a locked account.
        test -r /etc/shadow || fail "cannot verify consumed sentinel"
        ${pkgs.gawk}/bin/awk -F: -v target_user=${lib.escapeShellArg user} '
          $1 == target_user {
            found = 1
            if ($2 != "" && $2 !~ /^[!*]/) unlocked = 1
          }
          END { exit !(found && unlocked) }
        ' /etc/shadow || fail "consumed sentinel requires an existing unlocked password"
      else
        ${pkgs.gnugrep}/bin/grep -Eqx \
          '^\$y\$[./A-Za-z0-9]+\$[./A-Za-z0-9]{0,86}\$[./A-Za-z0-9]{43}$' \
          "$hash_file" || fail "expected yescrypt hash"
      fi
    '';
  };

  # First validate the staged verifier, then let the stock users fragment read it.
  system.activationScripts.users.deps = [ "bootstrapPasswordHash" ];

  # After users has updated /etc/shadow, erase the duplicate verifier. Mutable
  # user semantics preserve the real shadow password on subsequent rebuilds.
  system.activationScripts.consumeBootstrapPassword = {
    deps = [ "users" ];
    text = ''
      hash_file=${lib.escapeShellArg bootstrapHashFile}
      if ! ${pkgs.gnugrep}/bin/grep -qx '!' "$hash_file"; then
        tmp="$hash_file.tmp.$$"
        trap 'rm -f "$tmp"' EXIT
        ${pkgs.coreutils}/bin/printf '!\n' > "$tmp"
        ${pkgs.coreutils}/bin/chown root:root "$tmp"
        ${pkgs.coreutils}/bin/chmod 0600 "$tmp"
        ${pkgs.coreutils}/bin/mv -f "$tmp" "$hash_file"
        trap - EXIT
      fi
    '';
  };

  assertions = [
    {
      assertion = config.users.mutableUsers;
      message = "bootstrap password sentinel requires mutable users";
    }
    {
      assertion = !config.systemd.sysusers.enable && !config.services.userborn.enable;
      message = "bootstrap password ordering requires classic users activation";
    }
  ];
}
