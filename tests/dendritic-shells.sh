#!/usr/bin/env bash
set -euo pipefail

root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
flake="path:$root"
config_root=

init_config_root() {
  if [[ -n "$config_root" ]]; then
    return
  fi

  # nix-config declares only aarch64-darwin; route shells tests there.
  local target_system=${DENDRITIC_TARGET_SYSTEM:-aarch64-darwin}
  case "$target_system" in
    aarch64-darwin)
      config_root="f.darwinConfigurations.\"$target_system\""
      ;;
    *)
      printf >&2 'unsupported nix-config dendritic shell target system: %s\n' "$target_system"
      exit 1
      ;;
  esac
}

eval_bin() {
  local package=$1
  local bin=$2
  init_config_root
  nix build --impure --no-link --expr \
    "let f = builtins.getFlake \"$flake\"; in $config_root.pkgs.$package" \
    >/dev/null
  nix eval --impure --raw --expr \
    "let f = builtins.getFlake \"$flake\"; in \"\${$config_root.pkgs.$package}/bin/$bin\""
}

resolve_bin() {
  local env_name=$1
  local package=$2
  local bin=$3
  local direct=${!env_name-}

  if [[ -n "$direct" ]]; then
    printf '%s\n' "$direct"
    return
  fi

  eval_bin "$package" "$bin"
}

nu=$(resolve_bin DENDRITIC_NU_BIN nushell nu)
bash_bin=$(resolve_bin DENDRITIC_BASH_BIN bashInteractive bash)
zsh=$(resolve_bin DENDRITIC_ZSH_BIN zsh zsh)
fish=$(resolve_bin DENDRITIC_FISH_BIN fish fish)

# The Darwin-resolved binaries are aarch64-darwin. Running them on a
# non-Darwin host (e.g. x86_64-linux build host) requires emulation. If
# the user wants to run this test from Linux, point DENDRITIC_*_BIN at
# native shells already on PATH (or skip the test on non-Darwin hosts).
if [[ "$(uname -m)" != "arm64" && -z "${DENDRITIC_NU_BIN:-}${DENDRITIC_BASH_BIN:-}${DENDRITIC_ZSH_BIN:-}${DENDRITIC_FISH_BIN:-}" ]]; then
  printf 'dendritic-shells=SKIP (host arch %s cannot run aarch64-darwin shells without emulation)\n' "$(uname -m)"
  exit 0
fi

test "$("$nu" -c 'print nu-ok')" = nu-ok
test "$("$bash_bin" -c 'printf bash-ok')" = bash-ok
test "$("$zsh" -fc 'printf zsh-ok')" = zsh-ok
test "$("$fish" -c 'printf fish-ok')" = fish-ok

printf '%s\n' 'dendritic-shells=PASS'
