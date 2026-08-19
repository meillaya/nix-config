# Wave 2 — Local backend, disk, keys, and agenix

## Findings
- Evaluated: classic backend, mutableUsers=true, sysusers=false, userborn=false; no password for `mei` or root.
- Disko layout is plaintext GPT/vfat/ext4 with no LUKS/FDE.
- Sole configured SSH key fingerprint `SHA256:QMzHpX...` does not match this workstation's local keys (`SHA256:NnlZq...`, `SHA256:AM8m...`).
- Agenix identity `/home/mei/.ssh/id_ed25519` exists only on this workstation; no Linux install/provisioning path and no active age secrets.

## Evidence
- `hosts/nixos/default.nix:4,119,272-287`
- `modules/nixos/secrets.nix:5-7,20-27`
- `modules/nixos/disk-config.nix:4-33`

## EXPAND
- LEAD: Actual target runtime validation — WHY: evaluated config cannot prove current installed shadow/key/block state — ANGLE: post-recovery commands.
- LEAD: First-boot agenix identity custody remains unresolved — WHY: target cannot decrypt before key exists — ANGLE: extra-files/host-key route.
- CLOSED: sysusers/userborn, FDE, matching key, active secrets all empirically resolved for current repo.
