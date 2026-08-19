# Wave 1 — regression, staged work, and history
Observer: Explorer the 17th (019f5335-f3f3-7cd2-b1bc-85434f855f30)
Observed: 2026-07-11

## Digest
- Current index contains 10 staged bootstrap-password files on top of HEAD/origin main 20a8ef9; there were no unstaged changes when observed.
- Bespoke config projection, helper, lifecycle, mutation, and secret-scan tests are the principal protected regression surface; the flake has no checks output or CI wiring for them.
- Preserve bootstrap activation ordering, tmpfs staging, full-SHA tool pins, Disko placeholder workflow, Niri text materialization, overlay dynamic discovery, and user-owned Dolphin state.
- Recommended baselines: all-systems flake check, x86_64 toplevel build, ARM drvPath eval, Home Manager activation build, and all bootstrap scripts.

## Observation candidates
- O4 staged bootstrap lifecycle and test inventory: hosts/nixos/default.nix:6-10; modules/nixos/bootstrap-password.nix:7-115; tests/bootstrap-password-*.sh.
- O5 dynamic overlay discovery is behaviorally significant: flake.nix:87-100.
- O6 current cross-platform output construction: flake.nix:657-694.
- O7 generated/mutable boundaries: .gitignore:1-7; modules/nixos/files.nix:10; modules/linux/home-manager.nix:865-875.

## Claim candidates
- Preserve bootstrap-password lifecycle and mutation suite through migration (high risk).
- Flake check alone is insufficient; bespoke tests and a real toplevel build remain required.
- No repository-native CI currently executes these tests.

## EXPAND
none — all tracked tests, documentation surfaces, staged files, flake output wiring, Git history leads, generated/vendor boundaries, secret boundaries, mutable-state comments, and available parity commands were mapped.
