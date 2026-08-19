# Wave 1 — NixOS password option semantics

## Findings
- `initialPassword`/`initialHashedPassword` are one-time only with `users.mutableUsers = true`; with false they become persistent declarative values.
- `password` and `initialPassword` are cleartext and warned world-readable in the Nix store.
- `hashedPasswordFile` contains one crypt hash line, is read at activation, and has highest precedence.
- `passwordFile` is a deprecated alias for `hashedPasswordFile`.
- Multiple password sources warn rather than hard-fail; precedence differs by mutability.
- Missing hash file warns; invalid inline hash warns; `!` disables password login while empty string permits empty-password login.

## Primary sources
- https://github.com/NixOS/nixpkgs/blob/2f710f761a236666bcb740287a93427871db7ece/nixos/modules/config/users-groups.nix#L397-L495
- https://github.com/NixOS/nixpkgs/blob/2f710f761a236666bcb740287a93427871db7ece/nixos/modules/config/update-users-groups.pl#L220-L250
- https://github.com/NixOS/nixpkgs/blob/2f710f761a236666bcb740287a93427871db7ece/nixos/tests/password-option-override-ordering.nix#L18-L59
- https://nixos.org/manual/nixos/stable/#sec-user-management

## EXPAND
- DEAD END: Semantics cross-checked against module, activation script, manual, release notes, and integration test; no open semantic lead.
