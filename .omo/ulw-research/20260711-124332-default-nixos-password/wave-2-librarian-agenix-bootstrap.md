# Wave 2 — agenix identity bootstrap

## Findings
- Agenix requires a readable target identity and orders decryption before classic users activation.
- Preferred declarative bootstrap is a pre-generated per-host SSH host key transferred with `--extra-files`, then encrypt password hash to that host recipient.
- `--copy-host-keys` cannot solve a missing greenfield identity; transferring the operator private key broadens secret access.
- Current repo uses classic backend, so agenix users dependency is applicable; sysusers caveat is irrelevant today but version-sensitive.

## Sources
- https://github.com/ryantm/agenix/blob/b027ee29d959fda4b60b57566d64c98a202e0feb/modules/age.nix#L75-L96
- https://github.com/ryantm/agenix/blob/b027ee29d959fda4b60b57566d64c98a202e0feb/modules/age.nix#L303-L335
- https://github.com/nix-community/nixos-anywhere/blob/4dfb813db065afb0aba1f61658ef77993d382db1/src/nixos-anywhere.sh#L876-L916

## EXPAND
- LEAD: Compare complexity of pre-generated host-key agenix versus direct per-install hash file for this repo — WHY: user seeks safe default, not necessarily maximum secret-manager machinery — ANGLE: operational simplicity.
- CLOSED: sysusers/userborn ordering not applicable to current evaluated config.
