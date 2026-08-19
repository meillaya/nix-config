# Wave 1B — Darwin/Home Manager identity, lifecycle, fonts and theming

Observer: `darwin_hm_theme`; exact pin/source/eval plus official upstream/current issues; observed 2026-07-13.

## Readiness

- Both Darwin outputs and both standalone HM outputs evaluate; `nix flake check --all-systems --no-build` exited 0. Native build/activation remains unverified.
- AArch64 Darwin is evaluation-ready/conditionally activation-ready.
- x86_64 Darwin is time-bounded: Nixpkgs 26.05 is the final supported Intel-Darwin release, with end-of-support at end of 2026.
- Standalone outputs are ready only for fixed `mei`, not advertised arbitrary users.

## Exact pins

- nixpkgs `d407951447dcd00442e97087bf374aad70c04cea`
- Home Manager `a1645f40777620c4bd2b6d854b290c2fc354a266`
- HM's extra nixpkgs node `9e92285f211dad236540fd617d7e30e0b99bc0e1`
- nix-darwin `a1fa429e945becaf60468600daf649be4ba0350c`
- Den `1614f6f8ed435c5bb257408bf91fd662f9aac43e`

## Findings

1. Root HM does not follow root nixpkgs, creating an avoidable additional lock node; integrated configs still use root packages via global/explicit package construction.
2. Darwin identity is internally consistent for existing `/Users/mei`; nix-darwin deliberately does not create/own the macOS account, and HM activation validates runtime identity/home.
3. Standalone has conflicting identity owners: Den fixes `mei`/`/home/mei`, while module environment overrides attempt arbitrary identity. Pure eval ignores env; impure alternate identity fails due conflicting definitions. README portability claim is false.
4. Kitty Sweet config is shared. FiraCode Nerd Font Mono exact family exists in HM packages and HM copies it into user Fonts on macOS, even though nix-darwin system fonts omit it. Physical CoreText/Kitty result needs native verification.
5. Cross-platform GTK4 assignment is inert because GTK is disabled/null; it is redundant and Linux GTK policy should remain Linux-scoped.
6. Darwin GUI packages are projected by both nix-darwin system apps and HM linkApps; internal package duplication obscures ownership and may duplicate LaunchServices/Spotlight entries. Recommended single owner: nix-darwin for system GUI apps, HM for dotfiles/user CLI.
7. State-version changes can alter HM app projection behavior; do not bump casually.
8. Intel Darwin should be pinned to 26.05-compatible inputs, tested on real Intel Mac/builder, and given a migration/archive deadline by end-2026. `allowUnsupportedSystem` cannot restore removed definitions/support.

## Primary sources

- https://github.com/nix-community/home-manager/blob/a1645f40777620c4bd2b6d854b290c2fc354a266/nix-darwin/default.nix
- https://github.com/nix-community/home-manager/blob/a1645f40777620c4bd2b6d854b290c2fc354a266/modules/home-environment.nix
- https://github.com/nix-community/home-manager/blob/a1645f40777620c4bd2b6d854b290c2fc354a266/modules/targets/darwin/fonts.nix
- https://github.com/nix-darwin/nix-darwin/blob/a1fa429e945becaf60468600daf649be4ba0350c/modules/fonts/default.nix
- https://github.com/nix-darwin/nix-darwin/blob/a1fa429e945becaf60468600daf649be4ba0350c/modules/system/applications.nix
- https://nixos.org/manual/nixpkgs/unstable/release-notes#x86_64-darwin-26.05
- https://nixos.org/blog/announcements/2026/nixos-2605/
- https://sw.kovidgoyal.net/kitty/kittens/choose-fonts/

## Claims

- All four outputs evaluate but native activation is unproven.
- Darwin identity is coherent for existing `mei`; standalone arbitrary-user portability is broken.
- HM provides Fira as a user font; nix-darwin does not register it system-wide.
- GUI app projection has two owners.
- Intel Darwin is transitional, not a durable rolling output.

## EXPAND
- LEAD: native ARM/Intel Mac activation/rollback drills — WHY: evaluation cannot prove lifecycle — ANGLE: build/switch/dscl/rollback on hardware.
- LEAD: LaunchServices/Spotlight before/after single app owner — WHY: duplicate projection impact is inferred — ANGLE: mdfind/lsregister.
- LEAD: arbitrary-identity mutation checks — WHY: lock repaired genericity later — ANGLE: pure/impure eval/build for two users.
- LEAD: closure-size delta from HM follows/root and dedup — WHY: quantify simplification — ANGLE: lock/closure comparison.
