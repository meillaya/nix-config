# Wave 1 — Adversarial authentication design

## Findings
- Recommends SSH-only bootstrap followed by `passwd` as the safest public-repo default when a matching key and offline recovery are guaranteed.
- Recommends encrypted `hashedPasswordFile` only when immediate console login is required and the decryption identity exists before user creation.
- Rejects committed `initialPassword` (plaintext/store exposure), committed `hashedPassword` (offline cracking/history exposure), and an unprovisioned secret-manager bootstrap loop.
- Reports missing `hashedPasswordFile` is warned about rather than hard-failed in nixpkgs user activation; malformed hash is not validated there.
- Reports sops-nix `neededForUsers = true` provides pre-user-creation ordering; agenix requires a readable target identity.

## Sources
- https://github.com/NixOS/nixpkgs/blob/2f710f761a236666bcb740287a93427871db7ece/nixos/modules/config/users-groups.nix#L633-L660
- https://github.com/NixOS/nixpkgs/blob/2f710f761a236666bcb740287a93427871db7ece/nixos/modules/config/update-users-groups.pl#L241-L249
- https://github.com/Mic92/sops-nix/blob/f1406619a3884cd5c47992a70b8b35c9c0fcb4c9/modules/sops/default.nix#L168-L175
- https://github.com/Mic92/sops-nix/blob/f1406619a3884cd5c47992a70b8b35c9c0fcb4c9/README.md#L572-L608
- https://github.com/ryantm/agenix/blob/b027ee29d959fda4b60b57566d64c98a202e0feb/modules/age.nix#L75-L94
- https://pages.nist.gov/800-63-3/sp800-63b.html

## CLAIMS
- Candidate C1/C2/C3/C5 support, pending independent convergence and pinned-revision verification.

## EXPAND
- LEAD: Determine whether this install flow can provision a durable age/SSH decryption identity before activation — WHY: encrypted hash otherwise creates a bootstrap loop — ANGLE: nixos-anywhere extra-files and agenix identity lifecycle.
- LEAD: Assess current Disko full-disk encryption and recovery custody — WHY: encrypted secret does not protect an unencrypted stolen disk — ANGLE: repo disk-config and laptop threat model.
