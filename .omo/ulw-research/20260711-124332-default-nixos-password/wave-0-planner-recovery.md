# Wave 0 — Planner recovery

The narrower planner returned seven axes: NixOS option semantics, Git/store exposure, nixos-anywhere bootstrap, Disko boundary, SSH-only viability, secret-manager integration, and first-boot rotation. It flagged plaintext exposure, reusable-hash disclosure, missing secret files, SSH-only recovery failure, and unrotated bootstrap credentials.

## EXPAND
- Compare option docs to the repository's pinned nixpkgs.
- Trace user/SSH/sudo/secrets imports.
- Prototype selected options by evaluation.
- Cover login, sudo, rebuild, rescue, and missing-secret acceptance paths.
