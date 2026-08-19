# Wave 2 — exact migration matrix
Observer: Explorer the 28th · 2026-07-11

## Digest
Every tracked Nix unit was classified. Safe order: preserve flake factories/overlays; migrate shared policy/packages/files/programs; Linux desktop; NixOS classes; Darwin classes; host facts; user facts; only then split legacy X11 payload and standalone mutable bridges. `modules/darwin/files.nix` is graph-unreachable but deletion is deferred until final parity. Bootstrap ordering, Darwin Dock (8 entries), standalone Niri files, and writable Codex semantics were empirically projected.

## EXPAND
- Asset-level map for apps/bin/config payloads and unused files.
