# Wave 1 — Kitty on Darwin through Nix

## Findings
- Correct attribute is `pkgs.kitty`; both local pinned Darwin package sets support it. kitty-bin does not exist.
- Default output contains `Applications/kitty.app`, `bin/kitty`, and architecture-correct Mach-O binaries.
- nix-darwin includes `/Applications` from environment.systemPackages in system.build.applications and copies bundles to `/Applications/Nix Apps`.
- Local pinned config supports x86_64-darwin today, with an upstream deprecation warning; later 26.11-era nixpkgs removes Intel Darwin globally.

## Sources
- pinned nixpkgs `pkgs/by-name/ki/kitty/package.nix`
- https://sw.kovidgoyal.net/kitty/binary/
- pinned nix-darwin `modules/system/applications.nix`
- https://nix-darwin.github.io/nix-darwin/manual/

## EXPAND
- DEAD END: local lock compatibility — direct local evaluation already proves Kitty metadata for both configured Darwin systems.
- DEAD END: custom app-copy module — pinned nix-darwin already copies application bundles.
- LEAD: after adding Kitty, verify both package membership and system.build.applications input closure — WHY: locks CLI and GUI delivery — ANGLE: RED/GREEN Nix evaluation.
