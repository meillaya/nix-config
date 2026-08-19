# Wave 1 — authoritative Nushell integration
Observer: Librarian the 19th · 2026-07-11

## Digest
NixOS and nix-darwin require generic shell registration plus per-user shell assignment; Home Manager owns config.nu/env.nu/login.nu but does not set the OS shell. Nu is not POSIX; keep /bin/sh and interpreter-specific scripts unchanged. Ghostty detects `nu` and can inject Nushell integration for the initial shell, but tmux-created/manual shells need verification. Use the target lock revisions, not researched development heads, during implementation.

## EXPAND
- Test Ghostty integration inside new tmux panes.
- Audit POSIX-profile dependencies.
- Verify all options against this repository's locked nixpkgs/HM/darwin revisions.
