# Wave 1 — Repository auth wiring

## Findings
- Authoritative declaration: `hosts/nixos/default.nix:272-302`; user `mei`, wheel/docker/i2c/video, Zsh, same hard-coded key for `mei` and root.
- `services.openssh.enable = true`; effective defaults reported as password and keyboard-interactive enabled, root `prohibit-password`.
- No password option in current source or Git history; `users.mutableUsers` evaluates to default `true`.
- Agenix is imported and identity path is `/home/mei/.ssh/id_ed25519`, but no active `age.secrets` entry exists.
- Local `secrets/` payloads are ignored and may be synced from a private repository.
- Disko and nixos-anywhere flow is independent; service note documents manual password recovery.

## Evidence
- `/home/mei/nix-config/hosts/nixos/default.nix:3-12,119,272-302`
- `/home/mei/nix-config/modules/nixos/secrets.nix:3-27`
- `/home/mei/nix-config/flake.nix:333-382,677-692`
- `/home/mei/nix-config/docs/service-notes/nixos-anywhere-disko-install.md:134-175`

## EXPAND
- LEAD: Establish first-boot source for `/home/mei/.ssh/id_ed25519` — WHY: active agenix identity is not provisioned declaratively — ANGLE: sync-secrets/install flow.
- LEAD: Decide whether root key login is intentional — WHY: same key is authorized for root and user — ANGLE: SSH policy/recovery.
- LEAD: Pin SSH settings rather than inherited defaults — WHY: current password-auth posture is implicit — ANGLE: option evaluation/security policy.
- DEAD END: No current or historical password declaration.
