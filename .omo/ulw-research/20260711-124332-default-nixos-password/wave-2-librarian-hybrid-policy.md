# Wave 2 — Laptop bootstrap policy

## Findings
- For a single-owner laptop/public repo, recommends a unique per-install local password plus key-only SSH, not a shared default and not SSH-only.
- Local password is needed for LightDM/TTY and normal passworded sudo; SSH-only fails when key/network/client assumptions fail.
- Explicit SSH hardening should disable password auth and root login; retain rescue media and backup key.
- Current repo lacks FDE, increasing physical-theft impact.

## Sources
- https://pages.nist.gov/800-63-4/sp800-63b/passwords/
- https://github.com/NixOS/nixpkgs/blob/2f710f761a236666bcb740287a93427871db7ece/nixos/modules/services/networking/ssh/sshd.nix#L543-L563
- https://github.com/NixOS/nixpkgs/blob/2f710f761a236666bcb740287a93427871db7ece/nixos/modules/security/sudo.nix#L57-L64
- https://man.openbsd.org/ssh_config#IdentitiesOnly

## EXPAND
- LEAD: Verify exact injection avoids logs/store/history — WHY: chosen hybrid depends on out-of-band secrecy — ANGLE: empirical artifact scan.
- LEAD: Produce first-boot/recovery test matrix — WHY: operational safety must be observable — ANGLE: final recommendation.
- CLOSED: Shared/static default password rejected; SSH-only conditional only.
