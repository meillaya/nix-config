# Verification — Tracked Credential Pattern Scan

This targeted guard first requires every tracked path to be readable. It then scans tracked Nix files as whole documents for quoted or unquoted plaintext, initial, hashed, initial-hashed, and file-backed password-option assignments, including whitespace, line comments, block comments, and newlines before `=`. It scans all tracked text paths for enumerated modular-crypt and PHC verifier prefixes (including yescrypt, SHA-crypt, bcrypt, scrypt, PBKDF2, and Argon2) and for generic, algorithm-specific, encrypted, PGP, OpenSSH, and age private-key markers. File-list, read, Perl-process, and Git-search errors fail closed. It does not prove absence of unknown encodings or steganographic secrets.

## Repository scan harness

```bash
#!/usr/bin/env bash
set -euo pipefail

matches=
tracked_list=$(mktemp -t nix-tracked-files.XXXXXX)
trap 'rm -f "$tracked_list"' EXIT
git ls-files -z > "$tracked_list"

while IFS= read -r -d '' path; do
  [[ -r $path ]] || {
    printf 'cannot read tracked path: %s\n' "$path" >&2
    exit 2
  }
done < "$tracked_list"

set +e
password_options=$(
  while IFS= read -r -d '' path; do
    [[ $path == *.nix ]] || continue
    perl -0777 -ne '
      while (/"?(initialPassword|password|hashedPassword|initialHashedPassword|hashedPasswordFile)"?(?:(?:\s+)|(?:\#[^\n]*(?:\n|\z))|(?:\/\*.*?\*\/))*=/sg) {
        print "$ARGV:$1\n";
      }
    ' "$path" || exit
  done < "$tracked_list"
)
rc=$?
set -e
if (( rc != 0 )); then
  printf '%s\n' 'password-option scan failed' >&2
  exit 2
fi
matches+="$password_options"

set +e
password_hashes=$(git grep -nE \
  '\$(1|2[abxy]?|5|6|7|y|gy|sm3|sm3_yescrypt|gost_yescrypt|scrypt|yescrypt|sha(256|512)crypt|bcrypt|pbkdf2(-sha(256|512))?|argon2(id|i|d))\$[./A-Za-z0-9]')
rc=$?
set -e
if (( rc > 1 )); then
  printf '%s\n' 'password-hash scan failed' >&2
  exit 2
fi
matches+="$password_hashes"

set +e
private_keys=$(git grep -nE \
  'BEGIN ([A-Z0-9]+[[:space:]]+)*PRIVATE KEY|BEGIN PGP PRIVATE KEY BLOCK|AGE-SECRET-KEY-1')
rc=$?
set -e
if (( rc > 1 )); then
  printf '%s\n' 'private-key scan failed' >&2
  exit 2
fi
matches+="$private_keys"

if [[ -n $matches ]]; then
  printf '%s\n' "$matches"
  exit 1
fi

printf '%s\n' 'tracked_nix_password_assignments=0' \
  'tracked_modular_password_hashes=0' \
  'tracked_private_key_markers=0'
```

## Repository scan transcript

```text
+ set -euo pipefail
+ matches=
++ mktemp -t nix-tracked-files.XXXXXX
+ tracked_list=/tmp/nix-tracked-files.oVLyhS
+ trap 'rm -f "$tracked_list"' EXIT
+ git ls-files -z
+ IFS=
+ read -r -d '' path
+ [[ -r .gitignore ]]
+ IFS=
+ read -r -d '' path
+ [[ -r README.md ]]
+ IFS=
+ read -r -d '' path
+ [[ -r apps/aarch64-darwin/apply ]]
+ IFS=
+ read -r -d '' path
+ [[ -r apps/aarch64-darwin/build ]]
+ IFS=
+ read -r -d '' path
+ [[ -r apps/aarch64-darwin/build-switch ]]
+ IFS=
+ read -r -d '' path
+ [[ -r apps/aarch64-darwin/check-keys ]]
+ IFS=
+ read -r -d '' path
+ [[ -r apps/aarch64-darwin/clean ]]
+ IFS=
+ read -r -d '' path
+ [[ -r apps/aarch64-darwin/copy-keys ]]
+ IFS=
+ read -r -d '' path
+ [[ -r apps/aarch64-darwin/create-keys ]]
+ IFS=
+ read -r -d '' path
+ [[ -r apps/aarch64-darwin/rollback ]]
+ IFS=
+ read -r -d '' path
+ [[ -r apps/aarch64-linux ]]
+ IFS=
+ read -r -d '' path
+ [[ -r apps/x86_64-darwin/apply ]]
+ IFS=
+ read -r -d '' path
+ [[ -r apps/x86_64-darwin/build ]]
+ IFS=
+ read -r -d '' path
+ [[ -r apps/x86_64-darwin/build-switch ]]
+ IFS=
+ read -r -d '' path
+ [[ -r apps/x86_64-darwin/check-keys ]]
+ IFS=
+ read -r -d '' path
+ [[ -r apps/x86_64-darwin/clean ]]
+ IFS=
+ read -r -d '' path
+ [[ -r apps/x86_64-darwin/copy-keys ]]
+ IFS=
+ read -r -d '' path
+ [[ -r apps/x86_64-darwin/create-keys ]]
+ IFS=
+ read -r -d '' path
+ [[ -r apps/x86_64-linux/apply ]]
+ IFS=
+ read -r -d '' path
+ [[ -r apps/x86_64-linux/build-switch ]]
+ IFS=
+ read -r -d '' path
+ [[ -r apps/x86_64-linux/clean ]]
+ IFS=
+ read -r -d '' path
+ [[ -r docs/machine-audits/entropyos-cachyos-migration-audit-2026-04-24.md ]]
+ IFS=
+ read -r -d '' path
+ [[ -r docs/service-notes/ai-sidecars.md ]]
+ IFS=
+ read -r -d '' path
+ [[ -r docs/service-notes/ai-tooling-boundaries.md ]]
+ IFS=
+ read -r -d '' path
+ [[ -r docs/service-notes/browser-choices.md ]]
+ IFS=
+ read -r -d '' path
+ [[ -r docs/service-notes/calibre.md ]]
+ IFS=
+ read -r -d '' path
+ [[ -r docs/service-notes/homebrew-free-migration.md ]]
+ IFS=
+ read -r -d '' path
+ [[ -r docs/service-notes/nixos-anywhere-disko-install.md ]]
+ IFS=
+ read -r -d '' path
+ [[ -r docs/service-notes/noctalia-ddc-brightness.md ]]
+ IFS=
+ read -r -d '' path
+ [[ -r docs/service-notes/tailscale-kavita.md ]]
+ IFS=
+ read -r -d '' path
+ [[ -r docs/service-notes/zen-helium.md ]]
+ IFS=
+ read -r -d '' path
+ [[ -r flake.lock ]]
+ IFS=
+ read -r -d '' path
+ [[ -r flake.nix ]]
+ IFS=
+ read -r -d '' path
+ [[ -r hosts/darwin/default.nix ]]
+ IFS=
+ read -r -d '' path
+ [[ -r hosts/nixos/default.nix ]]
+ IFS=
+ read -r -d '' path
+ [[ -r modules/darwin/README.md ]]
+ IFS=
+ read -r -d '' path
+ [[ -r modules/darwin/dock/default.nix ]]
+ IFS=
+ read -r -d '' path
+ [[ -r modules/darwin/files.nix ]]
+ IFS=
+ read -r -d '' path
+ [[ -r modules/darwin/home-manager.nix ]]
+ IFS=
+ read -r -d '' path
+ [[ -r modules/darwin/packages.nix ]]
+ IFS=
+ read -r -d '' path
+ [[ -r modules/darwin/secrets.nix ]]
+ IFS=
+ read -r -d '' path
+ [[ -r modules/linux/config/niri/config.kdl ]]
+ IFS=
+ read -r -d '' path
+ [[ -r modules/linux/home-manager.nix ]]
+ IFS=
+ read -r -d '' path
+ [[ -r modules/nixos/README.md ]]
+ IFS=
+ read -r -d '' path
+ [[ -r modules/nixos/config/login-wallpaper.png ]]
+ IFS=
+ read -r -d '' path
+ [[ -r modules/nixos/config/polybar/bars.ini ]]
+ IFS=
+ read -r -d '' path
+ [[ -r modules/nixos/config/polybar/colors.ini ]]
+ IFS=
+ read -r -d '' path
+ [[ -r modules/nixos/config/polybar/config.ini ]]
+ IFS=
+ read -r -d '' path
+ [[ -r modules/nixos/config/polybar/modules.ini ]]
+ IFS=
+ read -r -d '' path
+ [[ -r modules/nixos/config/polybar/user_modules.ini ]]
+ IFS=
+ read -r -d '' path
+ [[ -r modules/nixos/config/rofi/colors.rasi ]]
+ IFS=
+ read -r -d '' path
+ [[ -r modules/nixos/config/rofi/confirm.rasi ]]
+ IFS=
+ read -r -d '' path
+ [[ -r modules/nixos/config/rofi/launcher.rasi ]]
+ IFS=
+ read -r -d '' path
+ [[ -r modules/nixos/config/rofi/message.rasi ]]
+ IFS=
+ read -r -d '' path
+ [[ -r modules/nixos/config/rofi/networkmenu.rasi ]]
+ IFS=
+ read -r -d '' path
+ [[ -r modules/nixos/config/rofi/powermenu.rasi ]]
+ IFS=
+ read -r -d '' path
+ [[ -r modules/nixos/config/rofi/styles.rasi ]]
+ IFS=
+ read -r -d '' path
+ [[ -r modules/nixos/disk-config.nix ]]
+ IFS=
+ read -r -d '' path
+ [[ -r modules/nixos/files.nix ]]
+ IFS=
+ read -r -d '' path
+ [[ -r modules/nixos/home-manager.nix ]]
+ IFS=
+ read -r -d '' path
+ [[ -r modules/nixos/niri.nix ]]
+ IFS=
+ read -r -d '' path
+ [[ -r modules/nixos/packages.nix ]]
+ IFS=
+ read -r -d '' path
+ [[ -r modules/nixos/secrets.nix ]]
+ IFS=
+ read -r -d '' path
+ [[ -r modules/shared/README.md ]]
+ IFS=
+ read -r -d '' path
+ [[ -r modules/shared/config/emacs/config.org ]]
+ IFS=
+ read -r -d '' path
+ [[ -r modules/shared/config/emacs/init.el ]]
+ IFS=
+ read -r -d '' path
+ [[ -r modules/shared/config/fastfetch/config.jsonc ]]
+ IFS=
+ read -r -d '' path
+ [[ -r modules/shared/config/fastfetch/logo/nixos_logo_1.png ]]
+ IFS=
+ read -r -d '' path
+ [[ -r modules/shared/config/fastfetch/logo/nixos_logo_1.webp ]]
+ IFS=
+ read -r -d '' path
+ [[ -r modules/shared/config/fastfetch/logo/nixos_logo_2.ansi ]]
+ IFS=
+ read -r -d '' path
+ [[ -r modules/shared/config/fastfetch/logo/nixos_logo_2.png ]]
+ IFS=
+ read -r -d '' path
+ [[ -r modules/shared/config/fastfetch/logo/nixos_logo_2.webp ]]
+ IFS=
+ read -r -d '' path
+ [[ -r modules/shared/config/fastfetch/nixos-01.jsonc ]]
+ IFS=
+ read -r -d '' path
+ [[ -r modules/shared/config/fastfetch/nixos-02.jsonc ]]
+ IFS=
+ read -r -d '' path
+ [[ -r modules/shared/config/p10k.zsh ]]
+ IFS=
+ read -r -d '' path
+ [[ -r modules/shared/default.nix ]]
+ IFS=
+ read -r -d '' path
+ [[ -r modules/shared/files.nix ]]
+ IFS=
+ read -r -d '' path
+ [[ -r modules/shared/home-manager.nix ]]
+ IFS=
+ read -r -d '' path
+ [[ -r modules/shared/packages.nix ]]
+ IFS=
+ read -r -d '' path
+ [[ -r modules/standalone-linux/config/calibre-metadata-sources-global.json ]]
+ IFS=
+ read -r -d '' path
+ [[ -r modules/standalone-linux/config/calibre/conversion/page_setup.py ]]
+ IFS=
+ read -r -d '' path
+ [[ -r modules/standalone-linux/config/calibre/gui.json ]]
+ IFS=
+ read -r -d '' path
+ [[ -r modules/standalone-linux/config/calibre/save_to_disk.py.json ]]
+ IFS=
+ read -r -d '' path
+ [[ -r modules/standalone-linux/config/calibre/tweaks.json ]]
+ IFS=
+ read -r -d '' path
+ [[ -r modules/standalone-linux/config/claude/CLAUDE.md ]]
+ IFS=
+ read -r -d '' path
+ [[ -r modules/standalone-linux/config/claude/omc-config.json ]]
+ IFS=
+ read -r -d '' path
+ [[ -r modules/standalone-linux/config/claude/settings.json ]]
+ IFS=
+ read -r -d '' path
+ [[ -r modules/standalone-linux/config/codex/AGENTS.md ]]
+ IFS=
+ read -r -d '' path
+ [[ -r modules/standalone-linux/config/codex/config.toml ]]
+ IFS=
+ read -r -d '' path
+ [[ -r modules/standalone-linux/config/codex/hooks.json ]]
+ IFS=
+ read -r -d '' path
+ [[ -r modules/standalone-linux/config/fastfetch/ghostty.jsonc ]]
+ IFS=
+ read -r -d '' path
+ [[ -r modules/standalone-linux/config/fastfetch/snoopy-mugiwara.png ]]
+ IFS=
+ read -r -d '' path
+ [[ -r modules/standalone-linux/config/ghostty/config.ghostty ]]
+ IFS=
+ read -r -d '' path
+ [[ -r modules/standalone-linux/config/mako/config ]]
+ IFS=
+ read -r -d '' path
+ [[ -r modules/standalone-linux/config/noctalia/config.toml ]]
+ IFS=
+ read -r -d '' path
+ [[ -r modules/standalone-linux/config/noctalia/settings.json ]]
+ IFS=
+ read -r -d '' path
+ [[ -r modules/standalone-linux/config/omx/hud-config.json ]]
+ IFS=
+ read -r -d '' path
+ [[ -r modules/standalone-linux/config/waybar/config ]]
+ IFS=
+ read -r -d '' path
+ [[ -r modules/standalone-linux/config/waybar/modules.json ]]
+ IFS=
+ read -r -d '' path
+ [[ -r modules/standalone-linux/config/waybar/scripts/power-menu.sh ]]
+ IFS=
+ read -r -d '' path
+ [[ -r modules/standalone-linux/config/waybar/scripts/waybar-restart.sh ]]
+ IFS=
+ read -r -d '' path
+ [[ -r modules/standalone-linux/config/waybar/style.css ]]
+ IFS=
+ read -r -d '' path
+ [[ -r modules/standalone-linux/config/waybar/waybar.sh ]]
+ IFS=
+ read -r -d '' path
+ [[ -r modules/standalone-linux/config/wlogout/layout ]]
+ IFS=
+ read -r -d '' path
+ [[ -r modules/standalone-linux/config/wlogout/style.css ]]
+ IFS=
+ read -r -d '' path
+ [[ -r modules/standalone-linux/config/zed/settings.json ]]
+ IFS=
+ read -r -d '' path
+ [[ -r modules/standalone-linux/files.nix ]]
+ IFS=
+ read -r -d '' path
+ [[ -r modules/standalone-linux/home-manager.nix ]]
+ IFS=
+ read -r -d '' path
+ [[ -r modules/standalone-linux/packages.nix ]]
+ IFS=
+ read -r -d '' path
+ [[ -r modules/standalone-linux/templates/calibre/customize.py.example.json ]]
+ IFS=
+ read -r -d '' path
+ [[ -r modules/standalone-linux/templates/calibre/global.py.example.json ]]
+ IFS=
+ read -r -d '' path
+ [[ -r modules/standalone-linux/templates/calibre/gui.py.example.json ]]
+ IFS=
+ read -r -d '' path
+ [[ -r modules/standalone-linux/templates/kavita-appsettings.example.json ]]
+ IFS=
+ read -r -d '' path
+ [[ -r overlays/10-feather-font.nix ]]
+ IFS=
+ read -r -d '' path
+ [[ -r overlays/20-helium.nix ]]
+ IFS=
+ read -r -d '' path
+ [[ -r overlays/30-ai-sidecars.nix ]]
+ IFS=
+ read -r -d '' path
+ [[ -r overlays/40-bun.nix ]]
+ IFS=
+ read -r -d '' path
+ [[ -r overlays/40-raycast.nix ]]
+ IFS=
+ read -r -d '' path
+ [[ -r overlays/README.md ]]
+ IFS=
+ read -r -d '' path
+ [[ -r secrets/README.md ]]
+ IFS=
+ read -r -d '' path
+ set +e
++ IFS=
++ read -r -d '' path
++ [[ .gitignore == *.nix ]]
++ continue
++ IFS=
++ read -r -d '' path
++ [[ README.md == *.nix ]]
++ continue
++ IFS=
++ read -r -d '' path
++ [[ apps/aarch64-darwin/apply == *.nix ]]
++ continue
++ IFS=
++ read -r -d '' path
++ [[ apps/aarch64-darwin/build == *.nix ]]
++ continue
++ IFS=
++ read -r -d '' path
++ [[ apps/aarch64-darwin/build-switch == *.nix ]]
++ continue
++ IFS=
++ read -r -d '' path
++ [[ apps/aarch64-darwin/check-keys == *.nix ]]
++ continue
++ IFS=
++ read -r -d '' path
++ [[ apps/aarch64-darwin/clean == *.nix ]]
++ continue
++ IFS=
++ read -r -d '' path
++ [[ apps/aarch64-darwin/copy-keys == *.nix ]]
++ continue
++ IFS=
++ read -r -d '' path
++ [[ apps/aarch64-darwin/create-keys == *.nix ]]
++ continue
++ IFS=
++ read -r -d '' path
++ [[ apps/aarch64-darwin/rollback == *.nix ]]
++ continue
++ IFS=
++ read -r -d '' path
++ [[ apps/aarch64-linux == *.nix ]]
++ continue
++ IFS=
++ read -r -d '' path
++ [[ apps/x86_64-darwin/apply == *.nix ]]
++ continue
++ IFS=
++ read -r -d '' path
++ [[ apps/x86_64-darwin/build == *.nix ]]
++ continue
++ IFS=
++ read -r -d '' path
++ [[ apps/x86_64-darwin/build-switch == *.nix ]]
++ continue
++ IFS=
++ read -r -d '' path
++ [[ apps/x86_64-darwin/check-keys == *.nix ]]
++ continue
++ IFS=
++ read -r -d '' path
++ [[ apps/x86_64-darwin/clean == *.nix ]]
++ continue
++ IFS=
++ read -r -d '' path
++ [[ apps/x86_64-darwin/copy-keys == *.nix ]]
++ continue
++ IFS=
++ read -r -d '' path
++ [[ apps/x86_64-darwin/create-keys == *.nix ]]
++ continue
++ IFS=
++ read -r -d '' path
++ [[ apps/x86_64-linux/apply == *.nix ]]
++ continue
++ IFS=
++ read -r -d '' path
++ [[ apps/x86_64-linux/build-switch == *.nix ]]
++ continue
++ IFS=
++ read -r -d '' path
++ [[ apps/x86_64-linux/clean == *.nix ]]
++ continue
++ IFS=
++ read -r -d '' path
++ [[ docs/machine-audits/entropyos-cachyos-migration-audit-2026-04-24.md == *.nix ]]
++ continue
++ IFS=
++ read -r -d '' path
++ [[ docs/service-notes/ai-sidecars.md == *.nix ]]
++ continue
++ IFS=
++ read -r -d '' path
++ [[ docs/service-notes/ai-tooling-boundaries.md == *.nix ]]
++ continue
++ IFS=
++ read -r -d '' path
++ [[ docs/service-notes/browser-choices.md == *.nix ]]
++ continue
++ IFS=
++ read -r -d '' path
++ [[ docs/service-notes/calibre.md == *.nix ]]
++ continue
++ IFS=
++ read -r -d '' path
++ [[ docs/service-notes/homebrew-free-migration.md == *.nix ]]
++ continue
++ IFS=
++ read -r -d '' path
++ [[ docs/service-notes/nixos-anywhere-disko-install.md == *.nix ]]
++ continue
++ IFS=
++ read -r -d '' path
++ [[ docs/service-notes/noctalia-ddc-brightness.md == *.nix ]]
++ continue
++ IFS=
++ read -r -d '' path
++ [[ docs/service-notes/tailscale-kavita.md == *.nix ]]
++ continue
++ IFS=
++ read -r -d '' path
++ [[ docs/service-notes/zen-helium.md == *.nix ]]
++ continue
++ IFS=
++ read -r -d '' path
++ [[ flake.lock == *.nix ]]
++ continue
++ IFS=
++ read -r -d '' path
++ [[ flake.nix == *.nix ]]
++ perl -0777 -ne $'\n      while (/"?(initialPassword|password|hashedPassword|initialHashedPassword|hashedPasswordFile)"?(?:(?:\\s+)|(?:\\#[^\\n]*(?:\\n|\\z))|(?:\\/\\*.*?\\*\\/))*=/sg) {\n        print "$ARGV:$1\\n";\n      }\n    ' flake.nix
++ IFS=
++ read -r -d '' path
++ [[ hosts/darwin/default.nix == *.nix ]]
++ perl -0777 -ne $'\n      while (/"?(initialPassword|password|hashedPassword|initialHashedPassword|hashedPasswordFile)"?(?:(?:\\s+)|(?:\\#[^\\n]*(?:\\n|\\z))|(?:\\/\\*.*?\\*\\/))*=/sg) {\n        print "$ARGV:$1\\n";\n      }\n    ' hosts/darwin/default.nix
++ IFS=
++ read -r -d '' path
++ [[ hosts/nixos/default.nix == *.nix ]]
++ perl -0777 -ne $'\n      while (/"?(initialPassword|password|hashedPassword|initialHashedPassword|hashedPasswordFile)"?(?:(?:\\s+)|(?:\\#[^\\n]*(?:\\n|\\z))|(?:\\/\\*.*?\\*\\/))*=/sg) {\n        print "$ARGV:$1\\n";\n      }\n    ' hosts/nixos/default.nix
++ IFS=
++ read -r -d '' path
++ [[ modules/darwin/README.md == *.nix ]]
++ continue
++ IFS=
++ read -r -d '' path
++ [[ modules/darwin/dock/default.nix == *.nix ]]
++ perl -0777 -ne $'\n      while (/"?(initialPassword|password|hashedPassword|initialHashedPassword|hashedPasswordFile)"?(?:(?:\\s+)|(?:\\#[^\\n]*(?:\\n|\\z))|(?:\\/\\*.*?\\*\\/))*=/sg) {\n        print "$ARGV:$1\\n";\n      }\n    ' modules/darwin/dock/default.nix
++ IFS=
++ read -r -d '' path
++ [[ modules/darwin/files.nix == *.nix ]]
++ perl -0777 -ne $'\n      while (/"?(initialPassword|password|hashedPassword|initialHashedPassword|hashedPasswordFile)"?(?:(?:\\s+)|(?:\\#[^\\n]*(?:\\n|\\z))|(?:\\/\\*.*?\\*\\/))*=/sg) {\n        print "$ARGV:$1\\n";\n      }\n    ' modules/darwin/files.nix
++ IFS=
++ read -r -d '' path
++ [[ modules/darwin/home-manager.nix == *.nix ]]
++ perl -0777 -ne $'\n      while (/"?(initialPassword|password|hashedPassword|initialHashedPassword|hashedPasswordFile)"?(?:(?:\\s+)|(?:\\#[^\\n]*(?:\\n|\\z))|(?:\\/\\*.*?\\*\\/))*=/sg) {\n        print "$ARGV:$1\\n";\n      }\n    ' modules/darwin/home-manager.nix
++ IFS=
++ read -r -d '' path
++ [[ modules/darwin/packages.nix == *.nix ]]
++ perl -0777 -ne $'\n      while (/"?(initialPassword|password|hashedPassword|initialHashedPassword|hashedPasswordFile)"?(?:(?:\\s+)|(?:\\#[^\\n]*(?:\\n|\\z))|(?:\\/\\*.*?\\*\\/))*=/sg) {\n        print "$ARGV:$1\\n";\n      }\n    ' modules/darwin/packages.nix
++ IFS=
++ read -r -d '' path
++ [[ modules/darwin/secrets.nix == *.nix ]]
++ perl -0777 -ne $'\n      while (/"?(initialPassword|password|hashedPassword|initialHashedPassword|hashedPasswordFile)"?(?:(?:\\s+)|(?:\\#[^\\n]*(?:\\n|\\z))|(?:\\/\\*.*?\\*\\/))*=/sg) {\n        print "$ARGV:$1\\n";\n      }\n    ' modules/darwin/secrets.nix
++ IFS=
++ read -r -d '' path
++ [[ modules/linux/config/niri/config.kdl == *.nix ]]
++ continue
++ IFS=
++ read -r -d '' path
++ [[ modules/linux/home-manager.nix == *.nix ]]
++ perl -0777 -ne $'\n      while (/"?(initialPassword|password|hashedPassword|initialHashedPassword|hashedPasswordFile)"?(?:(?:\\s+)|(?:\\#[^\\n]*(?:\\n|\\z))|(?:\\/\\*.*?\\*\\/))*=/sg) {\n        print "$ARGV:$1\\n";\n      }\n    ' modules/linux/home-manager.nix
++ IFS=
++ read -r -d '' path
++ [[ modules/nixos/README.md == *.nix ]]
++ continue
++ IFS=
++ read -r -d '' path
++ [[ modules/nixos/config/login-wallpaper.png == *.nix ]]
++ continue
++ IFS=
++ read -r -d '' path
++ [[ modules/nixos/config/polybar/bars.ini == *.nix ]]
++ continue
++ IFS=
++ read -r -d '' path
++ [[ modules/nixos/config/polybar/colors.ini == *.nix ]]
++ continue
++ IFS=
++ read -r -d '' path
++ [[ modules/nixos/config/polybar/config.ini == *.nix ]]
++ continue
++ IFS=
++ read -r -d '' path
++ [[ modules/nixos/config/polybar/modules.ini == *.nix ]]
++ continue
++ IFS=
++ read -r -d '' path
++ [[ modules/nixos/config/polybar/user_modules.ini == *.nix ]]
++ continue
++ IFS=
++ read -r -d '' path
++ [[ modules/nixos/config/rofi/colors.rasi == *.nix ]]
++ continue
++ IFS=
++ read -r -d '' path
++ [[ modules/nixos/config/rofi/confirm.rasi == *.nix ]]
++ continue
++ IFS=
++ read -r -d '' path
++ [[ modules/nixos/config/rofi/launcher.rasi == *.nix ]]
++ continue
++ IFS=
++ read -r -d '' path
++ [[ modules/nixos/config/rofi/message.rasi == *.nix ]]
++ continue
++ IFS=
++ read -r -d '' path
++ [[ modules/nixos/config/rofi/networkmenu.rasi == *.nix ]]
++ continue
++ IFS=
++ read -r -d '' path
++ [[ modules/nixos/config/rofi/powermenu.rasi == *.nix ]]
++ continue
++ IFS=
++ read -r -d '' path
++ [[ modules/nixos/config/rofi/styles.rasi == *.nix ]]
++ continue
++ IFS=
++ read -r -d '' path
++ [[ modules/nixos/disk-config.nix == *.nix ]]
++ perl -0777 -ne $'\n      while (/"?(initialPassword|password|hashedPassword|initialHashedPassword|hashedPasswordFile)"?(?:(?:\\s+)|(?:\\#[^\\n]*(?:\\n|\\z))|(?:\\/\\*.*?\\*\\/))*=/sg) {\n        print "$ARGV:$1\\n";\n      }\n    ' modules/nixos/disk-config.nix
++ IFS=
++ read -r -d '' path
++ [[ modules/nixos/files.nix == *.nix ]]
++ perl -0777 -ne $'\n      while (/"?(initialPassword|password|hashedPassword|initialHashedPassword|hashedPasswordFile)"?(?:(?:\\s+)|(?:\\#[^\\n]*(?:\\n|\\z))|(?:\\/\\*.*?\\*\\/))*=/sg) {\n        print "$ARGV:$1\\n";\n      }\n    ' modules/nixos/files.nix
++ IFS=
++ read -r -d '' path
++ [[ modules/nixos/home-manager.nix == *.nix ]]
++ perl -0777 -ne $'\n      while (/"?(initialPassword|password|hashedPassword|initialHashedPassword|hashedPasswordFile)"?(?:(?:\\s+)|(?:\\#[^\\n]*(?:\\n|\\z))|(?:\\/\\*.*?\\*\\/))*=/sg) {\n        print "$ARGV:$1\\n";\n      }\n    ' modules/nixos/home-manager.nix
++ IFS=
++ read -r -d '' path
++ [[ modules/nixos/niri.nix == *.nix ]]
++ perl -0777 -ne $'\n      while (/"?(initialPassword|password|hashedPassword|initialHashedPassword|hashedPasswordFile)"?(?:(?:\\s+)|(?:\\#[^\\n]*(?:\\n|\\z))|(?:\\/\\*.*?\\*\\/))*=/sg) {\n        print "$ARGV:$1\\n";\n      }\n    ' modules/nixos/niri.nix
++ IFS=
++ read -r -d '' path
++ [[ modules/nixos/packages.nix == *.nix ]]
++ perl -0777 -ne $'\n      while (/"?(initialPassword|password|hashedPassword|initialHashedPassword|hashedPasswordFile)"?(?:(?:\\s+)|(?:\\#[^\\n]*(?:\\n|\\z))|(?:\\/\\*.*?\\*\\/))*=/sg) {\n        print "$ARGV:$1\\n";\n      }\n    ' modules/nixos/packages.nix
++ IFS=
++ read -r -d '' path
++ [[ modules/nixos/secrets.nix == *.nix ]]
++ perl -0777 -ne $'\n      while (/"?(initialPassword|password|hashedPassword|initialHashedPassword|hashedPasswordFile)"?(?:(?:\\s+)|(?:\\#[^\\n]*(?:\\n|\\z))|(?:\\/\\*.*?\\*\\/))*=/sg) {\n        print "$ARGV:$1\\n";\n      }\n    ' modules/nixos/secrets.nix
++ IFS=
++ read -r -d '' path
++ [[ modules/shared/README.md == *.nix ]]
++ continue
++ IFS=
++ read -r -d '' path
++ [[ modules/shared/config/emacs/config.org == *.nix ]]
++ continue
++ IFS=
++ read -r -d '' path
++ [[ modules/shared/config/emacs/init.el == *.nix ]]
++ continue
++ IFS=
++ read -r -d '' path
++ [[ modules/shared/config/fastfetch/config.jsonc == *.nix ]]
++ continue
++ IFS=
++ read -r -d '' path
++ [[ modules/shared/config/fastfetch/logo/nixos_logo_1.png == *.nix ]]
++ continue
++ IFS=
++ read -r -d '' path
++ [[ modules/shared/config/fastfetch/logo/nixos_logo_1.webp == *.nix ]]
++ continue
++ IFS=
++ read -r -d '' path
++ [[ modules/shared/config/fastfetch/logo/nixos_logo_2.ansi == *.nix ]]
++ continue
++ IFS=
++ read -r -d '' path
++ [[ modules/shared/config/fastfetch/logo/nixos_logo_2.png == *.nix ]]
++ continue
++ IFS=
++ read -r -d '' path
++ [[ modules/shared/config/fastfetch/logo/nixos_logo_2.webp == *.nix ]]
++ continue
++ IFS=
++ read -r -d '' path
++ [[ modules/shared/config/fastfetch/nixos-01.jsonc == *.nix ]]
++ continue
++ IFS=
++ read -r -d '' path
++ [[ modules/shared/config/fastfetch/nixos-02.jsonc == *.nix ]]
++ continue
++ IFS=
++ read -r -d '' path
++ [[ modules/shared/config/p10k.zsh == *.nix ]]
++ continue
++ IFS=
++ read -r -d '' path
++ [[ modules/shared/default.nix == *.nix ]]
++ perl -0777 -ne $'\n      while (/"?(initialPassword|password|hashedPassword|initialHashedPassword|hashedPasswordFile)"?(?:(?:\\s+)|(?:\\#[^\\n]*(?:\\n|\\z))|(?:\\/\\*.*?\\*\\/))*=/sg) {\n        print "$ARGV:$1\\n";\n      }\n    ' modules/shared/default.nix
++ IFS=
++ read -r -d '' path
++ [[ modules/shared/files.nix == *.nix ]]
++ perl -0777 -ne $'\n      while (/"?(initialPassword|password|hashedPassword|initialHashedPassword|hashedPasswordFile)"?(?:(?:\\s+)|(?:\\#[^\\n]*(?:\\n|\\z))|(?:\\/\\*.*?\\*\\/))*=/sg) {\n        print "$ARGV:$1\\n";\n      }\n    ' modules/shared/files.nix
++ IFS=
++ read -r -d '' path
++ [[ modules/shared/home-manager.nix == *.nix ]]
++ perl -0777 -ne $'\n      while (/"?(initialPassword|password|hashedPassword|initialHashedPassword|hashedPasswordFile)"?(?:(?:\\s+)|(?:\\#[^\\n]*(?:\\n|\\z))|(?:\\/\\*.*?\\*\\/))*=/sg) {\n        print "$ARGV:$1\\n";\n      }\n    ' modules/shared/home-manager.nix
++ IFS=
++ read -r -d '' path
++ [[ modules/shared/packages.nix == *.nix ]]
++ perl -0777 -ne $'\n      while (/"?(initialPassword|password|hashedPassword|initialHashedPassword|hashedPasswordFile)"?(?:(?:\\s+)|(?:\\#[^\\n]*(?:\\n|\\z))|(?:\\/\\*.*?\\*\\/))*=/sg) {\n        print "$ARGV:$1\\n";\n      }\n    ' modules/shared/packages.nix
++ IFS=
++ read -r -d '' path
++ [[ modules/standalone-linux/config/calibre-metadata-sources-global.json == *.nix ]]
++ continue
++ IFS=
++ read -r -d '' path
++ [[ modules/standalone-linux/config/calibre/conversion/page_setup.py == *.nix ]]
++ continue
++ IFS=
++ read -r -d '' path
++ [[ modules/standalone-linux/config/calibre/gui.json == *.nix ]]
++ continue
++ IFS=
++ read -r -d '' path
++ [[ modules/standalone-linux/config/calibre/save_to_disk.py.json == *.nix ]]
++ continue
++ IFS=
++ read -r -d '' path
++ [[ modules/standalone-linux/config/calibre/tweaks.json == *.nix ]]
++ continue
++ IFS=
++ read -r -d '' path
++ [[ modules/standalone-linux/config/claude/CLAUDE.md == *.nix ]]
++ continue
++ IFS=
++ read -r -d '' path
++ [[ modules/standalone-linux/config/claude/omc-config.json == *.nix ]]
++ continue
++ IFS=
++ read -r -d '' path
++ [[ modules/standalone-linux/config/claude/settings.json == *.nix ]]
++ continue
++ IFS=
++ read -r -d '' path
++ [[ modules/standalone-linux/config/codex/AGENTS.md == *.nix ]]
++ continue
++ IFS=
++ read -r -d '' path
++ [[ modules/standalone-linux/config/codex/config.toml == *.nix ]]
++ continue
++ IFS=
++ read -r -d '' path
++ [[ modules/standalone-linux/config/codex/hooks.json == *.nix ]]
++ continue
++ IFS=
++ read -r -d '' path
++ [[ modules/standalone-linux/config/fastfetch/ghostty.jsonc == *.nix ]]
++ continue
++ IFS=
++ read -r -d '' path
++ [[ modules/standalone-linux/config/fastfetch/snoopy-mugiwara.png == *.nix ]]
++ continue
++ IFS=
++ read -r -d '' path
++ [[ modules/standalone-linux/config/ghostty/config.ghostty == *.nix ]]
++ continue
++ IFS=
++ read -r -d '' path
++ [[ modules/standalone-linux/config/mako/config == *.nix ]]
++ continue
++ IFS=
++ read -r -d '' path
++ [[ modules/standalone-linux/config/noctalia/config.toml == *.nix ]]
++ continue
++ IFS=
++ read -r -d '' path
++ [[ modules/standalone-linux/config/noctalia/settings.json == *.nix ]]
++ continue
++ IFS=
++ read -r -d '' path
++ [[ modules/standalone-linux/config/omx/hud-config.json == *.nix ]]
++ continue
++ IFS=
++ read -r -d '' path
++ [[ modules/standalone-linux/config/waybar/config == *.nix ]]
++ continue
++ IFS=
++ read -r -d '' path
++ [[ modules/standalone-linux/config/waybar/modules.json == *.nix ]]
++ continue
++ IFS=
++ read -r -d '' path
++ [[ modules/standalone-linux/config/waybar/scripts/power-menu.sh == *.nix ]]
++ continue
++ IFS=
++ read -r -d '' path
++ [[ modules/standalone-linux/config/waybar/scripts/waybar-restart.sh == *.nix ]]
++ continue
++ IFS=
++ read -r -d '' path
++ [[ modules/standalone-linux/config/waybar/style.css == *.nix ]]
++ continue
++ IFS=
++ read -r -d '' path
++ [[ modules/standalone-linux/config/waybar/waybar.sh == *.nix ]]
++ continue
++ IFS=
++ read -r -d '' path
++ [[ modules/standalone-linux/config/wlogout/layout == *.nix ]]
++ continue
++ IFS=
++ read -r -d '' path
++ [[ modules/standalone-linux/config/wlogout/style.css == *.nix ]]
++ continue
++ IFS=
++ read -r -d '' path
++ [[ modules/standalone-linux/config/zed/settings.json == *.nix ]]
++ continue
++ IFS=
++ read -r -d '' path
++ [[ modules/standalone-linux/files.nix == *.nix ]]
++ perl -0777 -ne $'\n      while (/"?(initialPassword|password|hashedPassword|initialHashedPassword|hashedPasswordFile)"?(?:(?:\\s+)|(?:\\#[^\\n]*(?:\\n|\\z))|(?:\\/\\*.*?\\*\\/))*=/sg) {\n        print "$ARGV:$1\\n";\n      }\n    ' modules/standalone-linux/files.nix
++ IFS=
++ read -r -d '' path
++ [[ modules/standalone-linux/home-manager.nix == *.nix ]]
++ perl -0777 -ne $'\n      while (/"?(initialPassword|password|hashedPassword|initialHashedPassword|hashedPasswordFile)"?(?:(?:\\s+)|(?:\\#[^\\n]*(?:\\n|\\z))|(?:\\/\\*.*?\\*\\/))*=/sg) {\n        print "$ARGV:$1\\n";\n      }\n    ' modules/standalone-linux/home-manager.nix
++ IFS=
++ read -r -d '' path
++ [[ modules/standalone-linux/packages.nix == *.nix ]]
++ perl -0777 -ne $'\n      while (/"?(initialPassword|password|hashedPassword|initialHashedPassword|hashedPasswordFile)"?(?:(?:\\s+)|(?:\\#[^\\n]*(?:\\n|\\z))|(?:\\/\\*.*?\\*\\/))*=/sg) {\n        print "$ARGV:$1\\n";\n      }\n    ' modules/standalone-linux/packages.nix
++ IFS=
++ read -r -d '' path
++ [[ modules/standalone-linux/templates/calibre/customize.py.example.json == *.nix ]]
++ continue
++ IFS=
++ read -r -d '' path
++ [[ modules/standalone-linux/templates/calibre/global.py.example.json == *.nix ]]
++ continue
++ IFS=
++ read -r -d '' path
++ [[ modules/standalone-linux/templates/calibre/gui.py.example.json == *.nix ]]
++ continue
++ IFS=
++ read -r -d '' path
++ [[ modules/standalone-linux/templates/kavita-appsettings.example.json == *.nix ]]
++ continue
++ IFS=
++ read -r -d '' path
++ [[ overlays/10-feather-font.nix == *.nix ]]
++ perl -0777 -ne $'\n      while (/"?(initialPassword|password|hashedPassword|initialHashedPassword|hashedPasswordFile)"?(?:(?:\\s+)|(?:\\#[^\\n]*(?:\\n|\\z))|(?:\\/\\*.*?\\*\\/))*=/sg) {\n        print "$ARGV:$1\\n";\n      }\n    ' overlays/10-feather-font.nix
++ IFS=
++ read -r -d '' path
++ [[ overlays/20-helium.nix == *.nix ]]
++ perl -0777 -ne $'\n      while (/"?(initialPassword|password|hashedPassword|initialHashedPassword|hashedPasswordFile)"?(?:(?:\\s+)|(?:\\#[^\\n]*(?:\\n|\\z))|(?:\\/\\*.*?\\*\\/))*=/sg) {\n        print "$ARGV:$1\\n";\n      }\n    ' overlays/20-helium.nix
++ IFS=
++ read -r -d '' path
++ [[ overlays/30-ai-sidecars.nix == *.nix ]]
++ perl -0777 -ne $'\n      while (/"?(initialPassword|password|hashedPassword|initialHashedPassword|hashedPasswordFile)"?(?:(?:\\s+)|(?:\\#[^\\n]*(?:\\n|\\z))|(?:\\/\\*.*?\\*\\/))*=/sg) {\n        print "$ARGV:$1\\n";\n      }\n    ' overlays/30-ai-sidecars.nix
++ IFS=
++ read -r -d '' path
++ [[ overlays/40-bun.nix == *.nix ]]
++ perl -0777 -ne $'\n      while (/"?(initialPassword|password|hashedPassword|initialHashedPassword|hashedPasswordFile)"?(?:(?:\\s+)|(?:\\#[^\\n]*(?:\\n|\\z))|(?:\\/\\*.*?\\*\\/))*=/sg) {\n        print "$ARGV:$1\\n";\n      }\n    ' overlays/40-bun.nix
++ IFS=
++ read -r -d '' path
++ [[ overlays/40-raycast.nix == *.nix ]]
++ perl -0777 -ne $'\n      while (/"?(initialPassword|password|hashedPassword|initialHashedPassword|hashedPasswordFile)"?(?:(?:\\s+)|(?:\\#[^\\n]*(?:\\n|\\z))|(?:\\/\\*.*?\\*\\/))*=/sg) {\n        print "$ARGV:$1\\n";\n      }\n    ' overlays/40-raycast.nix
++ IFS=
++ read -r -d '' path
++ [[ overlays/README.md == *.nix ]]
++ continue
++ IFS=
++ read -r -d '' path
++ [[ secrets/README.md == *.nix ]]
++ continue
++ IFS=
++ read -r -d '' path
+ password_options=
+ rc=0
+ set -e
+ ((  rc != 0  ))
+ matches+=
+ set +e
++ git grep -nE '\$(1|2[abxy]?|5|6|7|y|gy|sm3|sm3_yescrypt|gost_yescrypt|scrypt|yescrypt|sha(256|512)crypt|bcrypt|pbkdf2(-sha(256|512))?|argon2(id|i|d))\$[./A-Za-z0-9]'
+ password_hashes=
+ rc=1
+ set -e
+ ((  rc > 1  ))
+ matches+=
+ set +e
++ git grep -nE 'BEGIN ([A-Z0-9]+[[:space:]]+)*PRIVATE KEY|BEGIN PGP PRIVATE KEY BLOCK|AGE-SECRET-KEY-1'
+ private_keys=
+ rc=1
+ set -e
+ ((  rc > 1  ))
+ matches+=
+ [[ -n '' ]]
+ printf '%s\n' tracked_nix_password_assignments=0 tracked_modular_password_hashes=0 tracked_private_key_markers=0
tracked_nix_password_assignments=0
tracked_modular_password_hashes=0
tracked_private_key_markers=0
+ rm -f /tmp/nix-tracked-files.oVLyhS
```

## Pattern/error regression harness

This executes the exact scanner in isolated temporary Git repositories containing fake single-line, multiline, line-comment-separated, and block-comment-separated quoted/unquoted Nix password options; SHA-512-crypt, bcrypt, PHC scrypt, PKCS#8, encrypted PKCS#8, PGP, and age fixtures; an unreadable tracked secret fixture; an injected Perl-process failure; and an ordinary shell-variable negative control.

```bash
#!/usr/bin/env bash
set -euo pipefail

scanner=$(readlink -f "$1")
tmp=$(mktemp -d -t nix-secret-scan-verify.XXXXXX)
trap 'rm -rf "$tmp"' EXIT
cd "$tmp"
git init -q
git config user.email verifier@example.invalid
git config user.name verifier

run_detected_case() {
  local name=$1 path=$2 content=$3 output rc
  git rm -qrf --ignore-unmatch .
  printf '%s\n' "$content" > "$path"
  git add "$path"
  set +e
  output=$(bash "$scanner" 2>&1)
  rc=$?
  set -e
  [[ $rc -eq 1 ]]
  [[ $output == *"$path:"* ]]
  printf '%s_detection=PASS\n' "$name"
}

run_detected_case plaintext_password config.nix \
  'users.users.mei.password = "fixture-only";'
run_detected_case quoted_password config.nix \
  'users.users.mei."password" = "fixture-only";'
run_detected_case quoted_initial_password config.nix \
  'users.users.mei."initialPassword" = "fixture-only";'
run_detected_case quoted_hashed_password config.nix \
  'users.users.mei."hashedPassword" = "$6$fixture$not-a-real-verifier";'
run_detected_case quoted_initial_hashed_password config.nix \
  'users.users.mei."initialHashedPassword" = "$6$fixture$not-a-real-verifier";'
run_detected_case quoted_hashed_password_file config.nix \
  'users.users.mei."hashedPasswordFile" = "/fixture-only";'
run_detected_case multiline_quoted_password config.nix \
  'users.users.mei."password"
    = "fixture-only";'
run_detected_case line_comment_password config.nix \
  'users.users.mei."password" # legal separator
    = "fixture-only";'
run_detected_case block_comment_password config.nix \
  'users.users.mei."password" /* legal separator */ = "fixture-only";'
run_detected_case initial_sha512_hash config.nix \
  'users.users.mei.initialHashedPassword = "$6$fixture$not-a-real-verifier";'
run_detected_case bcrypt_hash fixture.txt \
  '$2b$12$fixturefixturefixturefixturefixturefixturefixturefixture'
run_detected_case phc_scrypt_hash fixture.txt \
  '$scrypt$ln=16,r=8,p=1$fixture$not-a-real-verifier'
run_detected_case generic_pkcs8 fixture.pem \
  '-----BEGIN PRIVATE KEY-----'
run_detected_case encrypted_pkcs8 fixture.pem \
  '-----BEGIN ENCRYPTED PRIVATE KEY-----'
run_detected_case pgp_private fixture.asc \
  '-----BEGIN PGP PRIVATE KEY BLOCK-----'
run_detected_case age_private fixture.txt \
  'AGE-SECRET-KEY-1FIXTUREONLY'

git rm -qrf --ignore-unmatch .
printf '%s\n' 'users.users.mei.password = "fixture-only";' > unreadable.nix
git add unreadable.nix
chmod 000 unreadable.nix
set +e
unreadable_output=$(bash "$scanner" 2>&1)
unreadable_rc=$?
set -e
chmod 600 unreadable.nix
[[ $unreadable_rc -gt 1 ]]
[[ $unreadable_output == *'cannot read tracked path: unreadable.nix'* ]]
[[ $unreadable_output != *'tracked_nix_password_assignments=0'* ]]
printf '%s\n' 'unreadable_tracked_file_fails_closed=PASS'

git rm -qrf --ignore-unmatch .
printf '%s\n' '{ clean = true; }' > clean.nix
git add clean.nix
mkdir -p mock-bin
cat > mock-bin/perl <<'EOF'
#!/usr/bin/env sh
exit 1
EOF
chmod +x mock-bin/perl
set +e
search_error_output=$(PATH="$PWD/mock-bin:$PATH" bash "$scanner" 2>&1)
search_error_rc=$?
set -e
[[ $search_error_rc -eq 2 ]]
[[ $search_error_output == *'password-option scan failed'* ]]
[[ $search_error_output != *'tracked_nix_password_assignments=0'* ]]
printf '%s\n' 'password_search_process_error_fails_closed=PASS'
rm -rf mock-bin

git rm -qrf --ignore-unmatch .
printf '%s\n' 'url="https://example.invalid/$version/archive-$version.tar.gz"' > clean.sh
git add clean.sh
bash "$scanner" >/dev/null
printf '%s\n' 'ordinary_shell_variables_clean=PASS'
```

## Pattern/error regression transcript

```text
+ set -euo pipefail
++ readlink -f .omo/ulw-research/20260711-124332-default-nixos-password/run-tracked-secret-scan.sh
+ scanner=/home/mei/nix-config/.omo/ulw-research/20260711-124332-default-nixos-password/run-tracked-secret-scan.sh
++ mktemp -d -t nix-secret-scan-verify.XXXXXX
+ tmp=/tmp/nix-secret-scan-verify.Ctr6TN
+ trap 'rm -rf "$tmp"' EXIT
+ cd /tmp/nix-secret-scan-verify.Ctr6TN
+ git init -q
+ git config user.email verifier@example.invalid
+ git config user.name verifier
+ run_detected_case plaintext_password config.nix 'users.users.mei.password = "fixture-only";'
+ local name=plaintext_password path=config.nix 'content=users.users.mei.password = "fixture-only";' output rc
+ git rm -qrf --ignore-unmatch .
+ printf '%s\n' 'users.users.mei.password = "fixture-only";'
+ git add config.nix
+ set +e
++ bash /home/mei/nix-config/.omo/ulw-research/20260711-124332-default-nixos-password/run-tracked-secret-scan.sh
+ output=config.nix:password
+ rc=1
+ set -e
+ [[ 1 -eq 1 ]]
+ [[ config.nix:password == *config\.nix\:* ]]
+ printf '%s_detection=PASS\n' plaintext_password
plaintext_password_detection=PASS
+ run_detected_case quoted_password config.nix 'users.users.mei."password" = "fixture-only";'
+ local name=quoted_password path=config.nix 'content=users.users.mei."password" = "fixture-only";' output rc
+ git rm -qrf --ignore-unmatch .
+ printf '%s\n' 'users.users.mei."password" = "fixture-only";'
+ git add config.nix
+ set +e
++ bash /home/mei/nix-config/.omo/ulw-research/20260711-124332-default-nixos-password/run-tracked-secret-scan.sh
+ output=config.nix:password
+ rc=1
+ set -e
+ [[ 1 -eq 1 ]]
+ [[ config.nix:password == *config\.nix\:* ]]
+ printf '%s_detection=PASS\n' quoted_password
quoted_password_detection=PASS
+ run_detected_case quoted_initial_password config.nix 'users.users.mei."initialPassword" = "fixture-only";'
+ local name=quoted_initial_password path=config.nix 'content=users.users.mei."initialPassword" = "fixture-only";' output rc
+ git rm -qrf --ignore-unmatch .
+ printf '%s\n' 'users.users.mei."initialPassword" = "fixture-only";'
+ git add config.nix
+ set +e
++ bash /home/mei/nix-config/.omo/ulw-research/20260711-124332-default-nixos-password/run-tracked-secret-scan.sh
+ output=config.nix:initialPassword
+ rc=1
+ set -e
+ [[ 1 -eq 1 ]]
+ [[ config.nix:initialPassword == *config\.nix\:* ]]
+ printf '%s_detection=PASS\n' quoted_initial_password
quoted_initial_password_detection=PASS
+ run_detected_case quoted_hashed_password config.nix 'users.users.mei."hashedPassword" = "$6$fixture$not-a-real-verifier";'
+ local name=quoted_hashed_password path=config.nix 'content=users.users.mei."hashedPassword" = "$6$fixture$not-a-real-verifier";' output rc
+ git rm -qrf --ignore-unmatch .
+ printf '%s\n' 'users.users.mei."hashedPassword" = "$6$fixture$not-a-real-verifier";'
+ git add config.nix
+ set +e
++ bash /home/mei/nix-config/.omo/ulw-research/20260711-124332-default-nixos-password/run-tracked-secret-scan.sh
+ output='config.nix:hashedPasswordconfig.nix:1:users.users.mei."hashedPassword" = "$6$fixture$not-a-real-verifier";'
+ rc=1
+ set -e
+ [[ 1 -eq 1 ]]
+ [[ config.nix:hashedPasswordconfig.nix:1:users.users.mei."hashedPassword" = "$6$fixture$not-a-real-verifier"; == *config\.nix\:* ]]
+ printf '%s_detection=PASS\n' quoted_hashed_password
quoted_hashed_password_detection=PASS
+ run_detected_case quoted_initial_hashed_password config.nix 'users.users.mei."initialHashedPassword" = "$6$fixture$not-a-real-verifier";'
+ local name=quoted_initial_hashed_password path=config.nix 'content=users.users.mei."initialHashedPassword" = "$6$fixture$not-a-real-verifier";' output rc
+ git rm -qrf --ignore-unmatch .
+ printf '%s\n' 'users.users.mei."initialHashedPassword" = "$6$fixture$not-a-real-verifier";'
+ git add config.nix
+ set +e
++ bash /home/mei/nix-config/.omo/ulw-research/20260711-124332-default-nixos-password/run-tracked-secret-scan.sh
+ output='config.nix:initialHashedPasswordconfig.nix:1:users.users.mei."initialHashedPassword" = "$6$fixture$not-a-real-verifier";'
+ rc=1
+ set -e
+ [[ 1 -eq 1 ]]
+ [[ config.nix:initialHashedPasswordconfig.nix:1:users.users.mei."initialHashedPassword" = "$6$fixture$not-a-real-verifier"; == *config\.nix\:* ]]
+ printf '%s_detection=PASS\n' quoted_initial_hashed_password
quoted_initial_hashed_password_detection=PASS
+ run_detected_case quoted_hashed_password_file config.nix 'users.users.mei."hashedPasswordFile" = "/fixture-only";'
+ local name=quoted_hashed_password_file path=config.nix 'content=users.users.mei."hashedPasswordFile" = "/fixture-only";' output rc
+ git rm -qrf --ignore-unmatch .
+ printf '%s\n' 'users.users.mei."hashedPasswordFile" = "/fixture-only";'
+ git add config.nix
+ set +e
++ bash /home/mei/nix-config/.omo/ulw-research/20260711-124332-default-nixos-password/run-tracked-secret-scan.sh
+ output=config.nix:hashedPasswordFile
+ rc=1
+ set -e
+ [[ 1 -eq 1 ]]
+ [[ config.nix:hashedPasswordFile == *config\.nix\:* ]]
+ printf '%s_detection=PASS\n' quoted_hashed_password_file
quoted_hashed_password_file_detection=PASS
+ run_detected_case multiline_quoted_password config.nix $'users.users.mei."password"\n    = "fixture-only";'
+ local name=multiline_quoted_password path=config.nix $'content=users.users.mei."password"\n    = "fixture-only";' output rc
+ git rm -qrf --ignore-unmatch .
+ printf '%s\n' $'users.users.mei."password"\n    = "fixture-only";'
+ git add config.nix
+ set +e
++ bash /home/mei/nix-config/.omo/ulw-research/20260711-124332-default-nixos-password/run-tracked-secret-scan.sh
+ output=config.nix:password
+ rc=1
+ set -e
+ [[ 1 -eq 1 ]]
+ [[ config.nix:password == *config\.nix\:* ]]
+ printf '%s_detection=PASS\n' multiline_quoted_password
multiline_quoted_password_detection=PASS
+ run_detected_case line_comment_password config.nix $'users.users.mei."password" # legal separator\n    = "fixture-only";'
+ local name=line_comment_password path=config.nix $'content=users.users.mei."password" # legal separator\n    = "fixture-only";' output rc
+ git rm -qrf --ignore-unmatch .
+ printf '%s\n' $'users.users.mei."password" # legal separator\n    = "fixture-only";'
+ git add config.nix
+ set +e
++ bash /home/mei/nix-config/.omo/ulw-research/20260711-124332-default-nixos-password/run-tracked-secret-scan.sh
+ output=config.nix:password
+ rc=1
+ set -e
+ [[ 1 -eq 1 ]]
+ [[ config.nix:password == *config\.nix\:* ]]
+ printf '%s_detection=PASS\n' line_comment_password
line_comment_password_detection=PASS
+ run_detected_case block_comment_password config.nix 'users.users.mei."password" /* legal separator */ = "fixture-only";'
+ local name=block_comment_password path=config.nix 'content=users.users.mei."password" /* legal separator */ = "fixture-only";' output rc
+ git rm -qrf --ignore-unmatch .
+ printf '%s\n' 'users.users.mei."password" /* legal separator */ = "fixture-only";'
+ git add config.nix
+ set +e
++ bash /home/mei/nix-config/.omo/ulw-research/20260711-124332-default-nixos-password/run-tracked-secret-scan.sh
+ output=config.nix:password
+ rc=1
+ set -e
+ [[ 1 -eq 1 ]]
+ [[ config.nix:password == *config\.nix\:* ]]
+ printf '%s_detection=PASS\n' block_comment_password
block_comment_password_detection=PASS
+ run_detected_case initial_sha512_hash config.nix 'users.users.mei.initialHashedPassword = "$6$fixture$not-a-real-verifier";'
+ local name=initial_sha512_hash path=config.nix 'content=users.users.mei.initialHashedPassword = "$6$fixture$not-a-real-verifier";' output rc
+ git rm -qrf --ignore-unmatch .
+ printf '%s\n' 'users.users.mei.initialHashedPassword = "$6$fixture$not-a-real-verifier";'
+ git add config.nix
+ set +e
++ bash /home/mei/nix-config/.omo/ulw-research/20260711-124332-default-nixos-password/run-tracked-secret-scan.sh
+ output='config.nix:initialHashedPasswordconfig.nix:1:users.users.mei.initialHashedPassword = "$6$fixture$not-a-real-verifier";'
+ rc=1
+ set -e
+ [[ 1 -eq 1 ]]
+ [[ config.nix:initialHashedPasswordconfig.nix:1:users.users.mei.initialHashedPassword = "$6$fixture$not-a-real-verifier"; == *config\.nix\:* ]]
+ printf '%s_detection=PASS\n' initial_sha512_hash
initial_sha512_hash_detection=PASS
+ run_detected_case bcrypt_hash fixture.txt '$2b$12$fixturefixturefixturefixturefixturefixturefixturefixture'
+ local name=bcrypt_hash path=fixture.txt 'content=$2b$12$fixturefixturefixturefixturefixturefixturefixturefixture' output rc
+ git rm -qrf --ignore-unmatch .
+ printf '%s\n' '$2b$12$fixturefixturefixturefixturefixturefixturefixturefixture'
+ git add fixture.txt
+ set +e
++ bash /home/mei/nix-config/.omo/ulw-research/20260711-124332-default-nixos-password/run-tracked-secret-scan.sh
+ output='fixture.txt:1:$2b$12$fixturefixturefixturefixturefixturefixturefixturefixture'
+ rc=1
+ set -e
+ [[ 1 -eq 1 ]]
+ [[ fixture.txt:1:$2b$12$fixturefixturefixturefixturefixturefixturefixturefixture == *fixture\.txt\:* ]]
+ printf '%s_detection=PASS\n' bcrypt_hash
bcrypt_hash_detection=PASS
+ run_detected_case phc_scrypt_hash fixture.txt '$scrypt$ln=16,r=8,p=1$fixture$not-a-real-verifier'
+ local name=phc_scrypt_hash path=fixture.txt 'content=$scrypt$ln=16,r=8,p=1$fixture$not-a-real-verifier' output rc
+ git rm -qrf --ignore-unmatch .
+ printf '%s\n' '$scrypt$ln=16,r=8,p=1$fixture$not-a-real-verifier'
+ git add fixture.txt
+ set +e
++ bash /home/mei/nix-config/.omo/ulw-research/20260711-124332-default-nixos-password/run-tracked-secret-scan.sh
+ output='fixture.txt:1:$scrypt$ln=16,r=8,p=1$fixture$not-a-real-verifier'
+ rc=1
+ set -e
+ [[ 1 -eq 1 ]]
+ [[ fixture.txt:1:$scrypt$ln=16,r=8,p=1$fixture$not-a-real-verifier == *fixture\.txt\:* ]]
+ printf '%s_detection=PASS\n' phc_scrypt_hash
phc_scrypt_hash_detection=PASS
+ run_detected_case generic_pkcs8 fixture.pem '-----BEGIN PRIVATE KEY-----'
+ local name=generic_pkcs8 path=fixture.pem 'content=-----BEGIN PRIVATE KEY-----' output rc
+ git rm -qrf --ignore-unmatch .
+ printf '%s\n' '-----BEGIN PRIVATE KEY-----'
+ git add fixture.pem
+ set +e
++ bash /home/mei/nix-config/.omo/ulw-research/20260711-124332-default-nixos-password/run-tracked-secret-scan.sh
+ output='fixture.pem:1:-----BEGIN PRIVATE KEY-----'
+ rc=1
+ set -e
+ [[ 1 -eq 1 ]]
+ [[ fixture.pem:1:-----BEGIN PRIVATE KEY----- == *fixture\.pem\:* ]]
+ printf '%s_detection=PASS\n' generic_pkcs8
generic_pkcs8_detection=PASS
+ run_detected_case encrypted_pkcs8 fixture.pem '-----BEGIN ENCRYPTED PRIVATE KEY-----'
+ local name=encrypted_pkcs8 path=fixture.pem 'content=-----BEGIN ENCRYPTED PRIVATE KEY-----' output rc
+ git rm -qrf --ignore-unmatch .
+ printf '%s\n' '-----BEGIN ENCRYPTED PRIVATE KEY-----'
+ git add fixture.pem
+ set +e
++ bash /home/mei/nix-config/.omo/ulw-research/20260711-124332-default-nixos-password/run-tracked-secret-scan.sh
+ output='fixture.pem:1:-----BEGIN ENCRYPTED PRIVATE KEY-----'
+ rc=1
+ set -e
+ [[ 1 -eq 1 ]]
+ [[ fixture.pem:1:-----BEGIN ENCRYPTED PRIVATE KEY----- == *fixture\.pem\:* ]]
+ printf '%s_detection=PASS\n' encrypted_pkcs8
encrypted_pkcs8_detection=PASS
+ run_detected_case pgp_private fixture.asc '-----BEGIN PGP PRIVATE KEY BLOCK-----'
+ local name=pgp_private path=fixture.asc 'content=-----BEGIN PGP PRIVATE KEY BLOCK-----' output rc
+ git rm -qrf --ignore-unmatch .
+ printf '%s\n' '-----BEGIN PGP PRIVATE KEY BLOCK-----'
+ git add fixture.asc
+ set +e
++ bash /home/mei/nix-config/.omo/ulw-research/20260711-124332-default-nixos-password/run-tracked-secret-scan.sh
+ output='fixture.asc:1:-----BEGIN PGP PRIVATE KEY BLOCK-----'
+ rc=1
+ set -e
+ [[ 1 -eq 1 ]]
+ [[ fixture.asc:1:-----BEGIN PGP PRIVATE KEY BLOCK----- == *fixture\.asc\:* ]]
+ printf '%s_detection=PASS\n' pgp_private
pgp_private_detection=PASS
+ run_detected_case age_private fixture.txt AGE-SECRET-KEY-1FIXTUREONLY
+ local name=age_private path=fixture.txt content=AGE-SECRET-KEY-1FIXTUREONLY output rc
+ git rm -qrf --ignore-unmatch .
+ printf '%s\n' AGE-SECRET-KEY-1FIXTUREONLY
+ git add fixture.txt
+ set +e
++ bash /home/mei/nix-config/.omo/ulw-research/20260711-124332-default-nixos-password/run-tracked-secret-scan.sh
+ output=fixture.txt:1:AGE-SECRET-KEY-1FIXTUREONLY
+ rc=1
+ set -e
+ [[ 1 -eq 1 ]]
+ [[ fixture.txt:1:AGE-SECRET-KEY-1FIXTUREONLY == *fixture\.txt\:* ]]
+ printf '%s_detection=PASS\n' age_private
age_private_detection=PASS
+ git rm -qrf --ignore-unmatch .
+ printf '%s\n' 'users.users.mei.password = "fixture-only";'
+ git add unreadable.nix
+ chmod 000 unreadable.nix
+ set +e
++ bash /home/mei/nix-config/.omo/ulw-research/20260711-124332-default-nixos-password/run-tracked-secret-scan.sh
+ unreadable_output='cannot read tracked path: unreadable.nix'
+ unreadable_rc=2
+ set -e
+ chmod 600 unreadable.nix
+ [[ 2 -gt 1 ]]
+ [[ cannot read tracked path: unreadable.nix == *cannot read tracked path\: unreadable\.nix* ]]
+ [[ cannot read tracked path: unreadable.nix != *tracked_nix_password_assignments\=0* ]]
+ printf '%s\n' unreadable_tracked_file_fails_closed=PASS
unreadable_tracked_file_fails_closed=PASS
+ git rm -qrf --ignore-unmatch .
+ printf '%s\n' '{ clean = true; }'
+ git add clean.nix
+ mkdir -p mock-bin
+ cat
+ chmod +x mock-bin/perl
+ set +e
++ PATH=/tmp/nix-secret-scan-verify.Ctr6TN/mock-bin:/home/mei/.local/lib/node_modules/@openai/codex/node_modules/@openai/codex-linux-x64/vendor/x86_64-unknown-linux-musl/codex-path:/home/mei/.codex/tmp/arg0/codex-arg0D719H2:/home/mei/.cargo/bin:/home/mei/.cache/.bun/bin:/home/mei/Android/Sdk/platform-tools:/home/mei/.ghcup/bin:/home/mei/.local/bin:/home/mei/.dx:/home/mei/go/bin:/home/mei/.bun/bin:/home/mei/.spicetify:/home/mei/.omx-runs/run-20260711153534-ce5a/.omx/runtime/bin:/home/mei/.opam/default/bin:/home/mei/.nix-profile/bin:/home/mei/.cabal/bin:/home/mei/.nix-profile/bin:/nix/var/nix/profiles/default/bin:/usr/local/sbin:/usr/local/bin:/usr/bin:/usr/lib/jvm/default/bin:/usr/bin/site_perl:/usr/bin/vendor_perl:/usr/bin/core_perl:/usr/lib/rustup/bin
++ bash /home/mei/nix-config/.omo/ulw-research/20260711-124332-default-nixos-password/run-tracked-secret-scan.sh
+ search_error_output='password-option scan failed'
+ search_error_rc=2
+ set -e
+ [[ 2 -eq 2 ]]
+ [[ password-option scan failed == *password\-option scan failed* ]]
+ [[ password-option scan failed != *tracked_nix_password_assignments\=0* ]]
+ printf '%s\n' password_search_process_error_fails_closed=PASS
password_search_process_error_fails_closed=PASS
+ rm -rf mock-bin
+ git rm -qrf --ignore-unmatch .
+ printf '%s\n' 'url="https://example.invalid/$version/archive-$version.tar.gz"'
+ git add clean.sh
+ bash /home/mei/nix-config/.omo/ulw-research/20260711-124332-default-nixos-password/run-tracked-secret-scan.sh
+ printf '%s\n' ordinary_shell_variables_clean=PASS
ordinary_shell_variables_clean=PASS
+ rm -rf /tmp/nix-secret-scan-verify.Ctr6TN
```

## Verdict

PASS: zero tracked Nix password-option assignments, enumerated modular/PHC password hashes, or private-key markers matched in the repository. All sixteen fake credential classes were detected, including legal multiline and comment-separated Nix assignments. Unreadable tracked content and an injected Perl search-process failure both exited 2 without zero counters. The ordinary shell-variable negative control remained clean. Unknown encodings remain outside this targeted guard.
