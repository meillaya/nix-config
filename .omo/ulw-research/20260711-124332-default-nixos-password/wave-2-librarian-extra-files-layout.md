# Wave 2 — extra-files path lifecycle

## Findings
- Contradicts wave-1 `/run` recommendation: staged `/mnt/run` is masked by `/run` tmpfs at first boot, while nixos-install `boot` action does not run normal user activation.
- Recommends persistent `/var/lib/nixos-bootstrap/mei-password.hash`, root-owned 0600, if config keeps `hashedPasswordFile`.
- Removing a referenced file after first boot causes warnings on later activation; normal service is too late to supply it.
- `/var/lib` persistence is covered by nixos-anywhere integration tests.

## Sources
- https://github.com/NixOS/nixpkgs/blob/2f710f761a236666bcb740287a93427871db7ece/nixos/modules/tasks/filesystems.nix#L577-L585
- https://github.com/NixOS/nixpkgs/blob/2f710f761a236666bcb740287a93427871db7ece/pkgs/by-name/ni/nixos-install/nixos-install.sh#L302-L325
- https://github.com/nix-community/nixos-anywhere/blob/4dfb813db065afb0aba1f61658ef77993d382db1/tests/from-nixos.nix#L30-L62

## CONTRADICTION
- Wave 1 claimed `/run/nixos-anywhere/...` would be consumed during install activation.
- Wave 2 shows `nixos-install` uses boot action and `/run` is later masked by tmpfs.
- Status: contested; requires direct source/runtime verification in Phase 3.

## EXPAND
- LEAD: Execute path-lifecycle verification against pinned scripts or minimal VM — WHY: resolves contradiction — ANGLE: proof artifact.
- LEAD: Decide persistent hashedPasswordFile vs true one-shot guarded activation — WHY: warning/secret-retention tradeoff — ANGLE: smallest safe design.
