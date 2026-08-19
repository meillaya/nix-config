# Wave 1 — flake output map
Observer: Explorer the 14th · 2026-07-11

## Digest
Public outputs: devShells/packages/apps across four systems, standalone-linux HM outputs, Darwin outputs by architecture, and NixOS outputs by architecture. Inputs/specialArgs and overlay paths were mapped. Important hazards: impure standalone identity, channel-dependent helpers, divergent nixpkgs locks, missing runtime targets behind structurally valid app wrappers, and generic architecture-keyed hosts rather than machine entities.

## EXPAND
- Runtime-test non-destructive app wrappers and missing targets.
- Replace channel-dependent `<nixpkgs>` helpers.
- Evaluate whether input-follow divergence is intentional.
