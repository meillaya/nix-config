# ULW-Research Synthesis: fastest fresh install path for Meillaya/nix-config

## Executive summary

The fastest reliable path with the current GitHub repo is still `disko-install` from a NixOS installer, because this repo already imports Disko and `disko-install` accepts a CLI disk override matching the repo's disk key `vdb`. This directly resolves the repo's `/dev/%DISK%` placeholder without editing GitHub.

The easiest path when the laptop console is awkward is `nixos-anywhere` from a second computer over SSH. However, with the current repo it needs a temporary local clone edit because `nixos-anywhere` does not expose the same `--disk vdb /dev/...` override; it expects the Disko device path to already be concrete in the flake.

## Findings by theme

### Repo constraints
- `nixosConfigurations`: `x86_64-linux`, `aarch64-linux`.
- Disko disk key: `vdb`.
- Disko device placeholder: `/dev/%DISK%`.
- User: `mei`; password is not declared and must be set before first console/GUI login.
- `nix build .#nixosConfigurations.x86_64-linux.config.system.build.toplevel --dry-run` evaluated successfully.

### Local ISO + disko-install
- Disko docs specify fresh install syntax: `sudo nix run 'github:nix-community/disko/latest#disko-install' -- --flake <flake-url>#<flake-attr> --disk <disk-name> <disk-device>`.
- Disko docs state `disko-install` combines Disko partitioning with `nixos-install`.
- This is the best match for the current repo because `--disk vdb "$DISK"` fills the placeholder safely from the command line.

### Remote nixos-anywhere
- nixos-anywhere docs describe installing NixOS over SSH and requiring a flake, disk config, and a reachable SSH target.
- Live CLI help confirms options including `--flake`, `--target-host`, `--build-on`, `--option`, `--phases`, but no direct `--disk` override.
- Use remote install only with a temp local clone where `/dev/%DISK%` is replaced with the target's real stable disk ID.

### Determinate ISO
- Determinate publishes NixOS ISOs for `x86_64-linux` and `aarch64-linux` with Determinate Nix and flakes enabled by default.
- It simplifies Nix/flakes friction but does not install this repo automatically and does not solve the repo disk placeholder by itself.

## Sources
1. Disko install docs: https://github.com/nix-community/disko/blob/master/docs/disko-install.md
2. Disko README: https://github.com/nix-community/disko
3. nixos-anywhere quickstart: https://nix-community.github.io/nixos-anywhere/quickstart.html
4. nixos-anywhere CLI help, executed locally via `nix run github:nix-community/nixos-anywhere -- --help`.
5. Determinate NixOS ISO docs: https://docs.determinate.systems/guides/nixos-isos/
6. NixOS manual stable install section: https://nixos.org/manual/nixos/stable/

## Convergence
Two research waves produced no better option than:
1. `disko-install` for direct laptop install with current GitHub repo.
2. `nixos-anywhere` for easiest ergonomics if using a second computer, with temporary local disk substitution.
