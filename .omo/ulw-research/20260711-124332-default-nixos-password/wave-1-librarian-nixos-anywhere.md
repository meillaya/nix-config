# Wave 1 — nixos-anywhere credential flow

## Findings
- Supported composition: `--extra-files` copies a staged tree into `/mnt` before `nixos-install`; pair with `users.users.mei.hashedPasswordFile = "/run/nixos-anywhere/mei-password-hash"` and mutable users.
- A one-shot `/run` hash is consumed when the fresh account is created; subsequent mutable-user activations preserve the existing shadow hash even if the runtime file is gone, but emit a missing-file warning.
- `--env-password` authenticates to the pre-install machine only; it does not set the installed account password.
- Disko encryption keys and SSH host-key copying are unrelated to Unix account credentials.
- No native nixos-anywhere password-hash or post-install hook was found.

## Sources
- https://github.com/nix-community/nixos-anywhere/blob/4dfb813db065afb0aba1f61658ef77993d382db1/src/nixos-anywhere.sh#L876-L917
- https://github.com/nix-community/nixos-anywhere/blob/4dfb813db065afb0aba1f61658ef77993d382db1/src/nixos-anywhere.sh#L543-L571
- https://github.com/NixOS/nixpkgs/blob/2f710f761a236666bcb740287a93427871db7ece/nixos/modules/config/update-users-groups.pl#L241-L317

## EXPAND
- LEAD: Verify repo does not enable sysusers/userborn — WHY: one-shot mutable behavior depends on classic backend — ANGLE: flake evaluation.
- LEAD: Decide post-install policy (console password, SSH password, SSH key-only) — WHY: daemon policy and local PAM are separate — ANGLE: explicit recommendation.
- LEAD: Determine whether persistent or one-shot file is better — WHY: one-shot causes later missing-file warnings — ANGLE: operational tradeoff.
