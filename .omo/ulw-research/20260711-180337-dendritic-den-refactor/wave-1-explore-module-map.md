# Wave 1 — current module/capability map
Observer: Explorer the 15th · 2026-07-11

## Digest
Current seams: flake/output assembly; shared nixpkgs/overlay policy; shared user baseline; Linux desktop; Niri runtime + system prerequisites; NixOS legacy X11; standalone Codex/Home Manager; Darwin workstation; secrets; bootstrap installation. Hidden couplings include duplicated overlay policy, evaluator-HOME-dependent NixOS files, literal mei paths, Niri runtime dependencies spread across layers, and imperative user-state activation.

## EXPAND
- Niri command closure per Linux target.
- Niri versus BSPWM default-session intent.
- HOME impurity in modules/nixos/files.nix.
- Overlay policy drift.
- Standalone activation idempotence.
- SSH matchBlocks deprecation.
