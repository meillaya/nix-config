# Verification: flake and command feasibility

Commands run:
- `nix eval --json .#nixosConfigurations --apply 'builtins.attrNames'`
- `nix run github:nix-community/nixos-anywhere -- --help`
- `nix build .#nixosConfigurations.x86_64-linux.config.system.build.toplevel --no-link --dry-run --extra-experimental-features 'nix-command flakes'`

Expected evidence:
- flake outputs include `x86_64-linux` and `aarch64-linux`.
- nixos-anywhere help includes `--flake`, `--target-host`, `--build-on`, `--option`, `--phases`; no direct `--disk` override.
- dry-run should evaluate/build-plan the current x86_64 NixOS system or expose config errors.

Result:
- Current x86_64 NixOS config dry-runs successfully.
- Warnings observed: GTK legacy default, `options.json` context warning, xorg package rename warnings, deprecated Home Manager SSH matchBlocks. These are not install-command blockers.
