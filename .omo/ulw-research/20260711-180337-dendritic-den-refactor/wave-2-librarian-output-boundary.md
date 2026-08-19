# Wave 2 — Den/flake-parts output boundary
Observer: Librarian the 26th · 2026-07-11

## Digest
Use flake-parts as the sole outer composer. Den owns NixOS/Darwin/standalone-HM configuration entities; perSystem retains packages/apps/devShells/checks; overlays remain top-level. Do not combine independent composers or turn operational scripts into aspects. A six-configuration/four-system fixture succeeded. x86_64-darwin is a separate pin-policy risk because future nixpkgs drops it; current target lock still evaluates.

## EXPAND
none
