#!/usr/bin/env bash
set -euo pipefail

root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
cd "$root"

if grep -R -E 'specialArgs|extraSpecialArgs' --include='*.nix' flake.nix modules/flake modules/entities modules/aspects; then
  echo 'hidden specialArgs coupling remains in the dendritic graph' >&2
  exit 1
fi

if grep -R -F 'den.batteries.user-shell "nushell"' --include='*.nix' modules; then
  echo 'Den user-shell battery cannot configure Nushell OS modules' >&2
  exit 1
fi

# nix-config must not contain nixos modules (they live in NixOS-config).
if test -d modules/nixos; then
  echo 'nix-config must not own modules/nixos/' >&2
  exit 1
fi
if [[ -e $root/../NixOS-config/modules/nixos/system.nix ]]; then
  :
else
  echo 'sibling NixOS-config repo not found at $root/../NixOS-config' >&2
  exit 1
fi

if grep -R -E 'command[[:space:]]*=[[:space:]]*/bin/(fish|zsh|bash)' modules/standalone-linux modules/aspects; then
  echo 'terminal command bypasses the declarative shell package' >&2
  exit 1
fi

if grep -R -E 'Command=.*pkgs\.(fish|zsh|bash)' --include='*.nix' modules; then
  echo 'terminal profile hardcodes a secondary shell' >&2
  exit 1
fi

if test -e hosts/nixos/default.nix || test -e hosts/darwin/default.nix; then
  echo 'legacy host composition entrypoints still exist' >&2
  exit 1
fi

if grep -R -E '^\{[^}]*\buser\b[^}]*\.\.\.' --include='*.nix' modules/aspects/hosts modules/aspects/features; then
  echo 'host-scoped class module requests the silently inert Den user argument' >&2
  exit 1
fi

if grep -Eiw 'polybar|dunst|screen-locker|i3lock|betterlockscreen|swaylock|swaybg|awww|swww|picom|rofi|waybar|mako|wlogout|bspwm|sxhkd' \
  modules/darwin/user-home.nix \
  modules/linux/config/niri/config.kdl \
  modules/linux/packages.nix \
  modules/standalone-linux/files.nix; then
  echo 'competing Niri session ownership remains configured' >&2
  exit 1
fi
if grep -R -Eiw 'swaylock|swaybg|wlogout' modules/standalone-linux/config; then
  echo 'standalone configuration retains a competing lock or wallpaper owner' >&2
  exit 1
fi

for module in \
  modules/darwin/user-home.nix \
  modules/darwin/system.nix \
  modules/darwin/base.nix \
  modules/standalone-linux/config/noctalia/config.toml
do
  if grep -Eq '"mei"|/home/mei|/Users/mei' "$module"; then
    echo "hardcoded identity remains in active module: $module" >&2
    exit 1
  fi
done

grep -Fq 'host.machine.identity' modules/darwin/system.nix
grep -Fq 'user.identity' modules/darwin/user-home.nix
grep -Fq 'host.machine.identity' modules/darwin/base.nix
grep -Fq 'config.home.homeDirectory' modules/aspects/features/noctalia.nix
grep -Fq '@HOME@' modules/standalone-linux/config/noctalia/config.toml

test ! -e modules/aspects/features/nix-core.nix

grep -Fq 'programs.noctalia = {' modules/aspects/features/noctalia.nix
grep -Fq 'systemd.enable = true;' modules/aspects/features/noctalia.nix
grep -Fq 'spawn-sh "noctalia msg screen-lock"' modules/linux/config/niri/config.kdl

printf '%s\n' 'dendritic-boundaries=PASS'
