# Wave 1 — Credential secret threat model

## Findings
- Nix store is not a secret store; plaintext Nix values and direct password options can be world-readable and reach builders/caches.
- A password hash remains a confidential verifier because it permits offline guessing.
- Safe generation: interactive `mkpasswd --method=yescrypt`; never put plaintext in argv/env/heredoc/history.
- Safe declarative delivery: runtime path via `hashedPasswordFile`, backed by agenix or sops-nix; never `builtins.readFile` decrypted content.
- Runtime secret should be root-owned `0400`; encrypted blobs may be public but recipient/key lifecycle remains critical.

## Sources
- https://releases.nixos.org/nix/nix-2.33.1/manual/store/secrets.html
- https://github.com/NixOS/nixpkgs/blob/2f710f761a236666bcb740287a93427871db7ece/nixos/modules/config/users-groups.nix#L363-L387
- https://pages.nist.gov/800-63-3/sp800-63b.html
- https://cheatsheetseries.owasp.org/cheatsheets/Password_Storage_Cheat_Sheet.html
- https://github.com/ryantm/agenix/blob/b027ee29d959fda4b60b57566d64c98a202e0feb/doc/reference.md#L23-L64

## EXPAND
- LEAD: Verify sysusers/userborn state — WHY: backend changes option behavior — ANGLE: pinned config evaluation.
- LEAD: Audit any historical plaintext exposure — WHY: removal does not revoke leaked credentials — ANGLE: Git/store/cache scan.
- DEAD END: Non-default yescrypt cost tuning not needed for recommendation; use defaults unless benchmarked.
