# Wave 1 — skeptical architecture counter-search
Observer: Librarian the 24th · 2026-07-11

## Contamination note
The worker inspected the wrong local cwd (`/home/mei/projects/nixos`) and therefore its repository-specific “no config” conclusion is invalid and excluded. External Den/flake-parts risk evidence remains independently source-backed.

## Digest
Den is v0.x and fast-evolving, adds a policy/resolution debugging layer, has concentrated authorship and recent routing fixes, and should be pinned deliberately. Plain flake-parts has lower conceptual burden. For this actual repo, however, cross-platform duplicated concerns and host/user/HM boundaries are demonstrated by O8/O9/O12, so the invalid defer conclusion does not control. Adopt the smallest Den subset, avoid novel policies/custom classes/quirks, and verify every entity route.

## EXPAND
- Re-check #629 and release state.
- Empirically pilot a minimal pinned Den host/user route before production migration.
