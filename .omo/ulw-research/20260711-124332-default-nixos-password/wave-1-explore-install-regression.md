# Wave 1 — Installation flow and regression surface

## Findings
- Existing config: mutable users true; sysusers/userborn false; no password; LightDM defaults to BSPWM; Niri enabled separately.
- Password insertion point is `hosts/nixos/default.nix:273-283`; documentation should change with it.
- Preserve SSH recovery keys, Home Manager's fixed `mei` identity/home, and Disko placeholder flow.
- Unrelated defect surfaced: flake exports Linux `install` and `install-with-secrets` apps whose script targets are absent. This does not block nixos-anywhere and remains out of scope.

## Evidence
- `/home/mei/nix-config/flake.nix:677-693`
- `/home/mei/nix-config/hosts/nixos/default.nix:79-120,272-302`
- `/home/mei/nix-config/modules/nixos/home-manager.nix:1-46`
- `/home/mei/nix-config/docs/service-notes/nixos-anywhere-disko-install.md:1-182`

## EXPAND
- DEAD END: No new authentication-specific lead; regression surfaces are mapped.
