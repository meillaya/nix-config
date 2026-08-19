#!/usr/bin/env bash
set -euo pipefail

root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
tmpdir=$(mktemp -d "${TMPDIR:-/tmp}/dendritic-apps.XXXXXX")
trap 'rm -rf "$tmpdir"' EXIT

grep -Fq 'exec ${self}/apps/${system}/${scriptName} "$@"' \
  "$root/modules/flake/apps.nix"

for app in build build-switch clean; do
  test -x "$root/apps/aarch64-darwin/$app"
done

darwin_apps=$(nix eval --impure --json --expr \
  "builtins.attrNames (builtins.getFlake \"path:$root\").apps.aarch64-darwin")
python3 - "$darwin_apps" <<'PY'
import json
import sys

assert json.loads(sys.argv[1]) == ["build", "build-switch", "clean", "search-pkgs", "update"]
PY

test ! -e "$root/apps/x86_64-darwin"
test ! -e "$root/apps/x86_64-linux"
test ! -e "$root/apps/aarch64-linux"

# nix-config declares only aarch64-darwin as a system, so flake.apps has
# exactly that one entry.
app_systems=$(nix eval --impure --json --expr \
  "builtins.attrNames (builtins.getFlake \"path:$root\").apps")
python3 - "$app_systems" <<'PY'
import json
import sys

systems = json.loads(sys.argv[1])
assert "aarch64-darwin" in systems
assert "x86_64-darwin" not in systems
assert "x86_64-linux" not in systems
assert "aarch64-linux" not in systems
PY

# Standalone Linux Home Manager checks still apply.
if grep -F -- '--impure' \
  "$root/modules/standalone-linux/home-manager.nix" \
  "$root/README.md"
then
  echo 'production standalone Home Manager path still requests impure evaluation' >&2
  exit 1
fi

if grep -E 'NIXOS_CONFIG_(USER|HOME)|builtins\.getEnv' \
  "$root/modules/standalone-linux/home-manager.nix" \
  "$root/README.md"
then
  echo 'production standalone path still accepts ambient identity' >&2
  exit 1
fi

printf '%s\n' 'dendritic-apps=PASS'
