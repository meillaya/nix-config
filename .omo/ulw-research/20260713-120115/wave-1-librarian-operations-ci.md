# Wave 1 — CI, operations, updates, diagnostics, disk pressure

Observer: `operations_ci_issues`; requested sources plus upstream counter-searches, pinned repo clones, and archived Reddit threads; accessed 2026-07-13.

## Findings

1. CI must distinguish format/lint, evaluation, native checks per OS, every declared host toplevel, packages/dev shells, and NixOS VM tests. A four-system flake on Ubuntu-only CI is not cross-platform validation.
2. Cache writes must be limited to trusted branches; fork PRs should read only. Actions need minimum permissions, immutable/audited pins, and concurrency cancellation.
3. Update automation should open PRs/staging changes and pass the same matrix; bot authorship and hashes alone are not correctness evidence.
4. Safe development order: targeted eval/no-build, build toplevel without activation, VM/NixOS tests, `nixos-rebuild test`, then switch. Remote changes need health checks/automatic rollback.
5. Diagnose earliest failed derivation with `nix log`; use `nix why-depends`/nix-tree for closure edges and `definitionsWithLocations` for module attribution. These are distinct questions.
6. Disk response must identify filesystem/inode/boot/store constraints, roots/generations/result links/running processes and cache misses before deletion. `nix-collect-garbage -d` destroys rollback history and is not a first diagnostic action.
7. The supplied CI template is stale and Ubuntu-only despite four systems. Fenix offers stronger Linux/macOS/update matrices but includes floating or failure-tolerant workflow choices that should not be copied blindly.
8. Nixpkgs issue #213263 is resolved by PR #465773; current XPPen module path is `programs.xppen`. Physical device coverage remains limited.
9. Trofi's bootstrap article is conceptually useful but historical; current x86 bootstrap structure changed. Sayless URLs moved. The devenv loader optimization depends on an open nixpkgs PR and is not a deployed universal fix.
10. Reddit operational advice was recovered through an archive and treated as secondary evidence, reconciled with official GC/build/rollback docs.

## Recommended project lanes

- Ubuntu format/static checks.
- Linux `nix flake check --no-build` and full checks.
- Native macOS flake checks on both supported Darwin architectures where runner availability allows.
- Every NixOS host toplevel build, including AArch64 through native or remote builder/emulation with explicit status.
- NixOS VM tests for boot/storage/networking/bootstrap/session changes.
- Packages/dev-shell checks per supported system.
- Scheduled lock/update PRs, protected-branch cache publishing, disk telemetry and result-link cleanup.

## Primary sources

- CI template `c3500781c32609e5a4d695cbccfc4b06e74b8074`
- Fenix `47acdc87db5b3aee4ec09590d16c16763711e762`
- nix-tree `4baa2a0f808bbb229a1ef4a35882d763a2b6add4`
- Sayless nix-book `044477bfb9f0192d111f22236c6d9d072c591a55`
- https://nix.dev/guides/recipes/continuous-integration-github-actions.html
- https://nixos.org/manual/nixos/stable/
- https://nixos.org/manual/nixpkgs/stable/
- https://github.com/NixOS/nixpkgs/issues/213263
- https://github.com/NixOS/nixpkgs/pull/465773
- https://github.com/NixOS/nixpkgs/pull/535735
- https://devenv.sh/
- https://trofi.github.io/posts/240-nixpkgs-bootstrap-intro.html

## Claim candidates

- Multi-system declarations require native/matrix evidence; one OS check is false coverage.
- Closure provenance, derivation failure, and module source attribution require different tools.
- Disk cleanup should follow diagnosis and root review; deleting generations is irreversible rollback loss.
- Current repo needs every declared host output and risky integration paths in CI, not only structural eval scripts.

## EXPAND
- LEAD: track nixpkgs PR #535735 before operational recommendation — WHY: performance optimization is not merged/deployed — ANGLE: merge/staging/release history.
- LEAD: benchmark devenv loader locally — WHY: article numbers are workload/hardware-specific — ANGLE: representative shells and pinned versions.
- LEAD: compare `nix-why` with nix-tree/why-depends/module definitions — WHY: improve package attribution UX — ANGLE: executed tooling matrix.
- LEAD: audit target repository workflows for pins/permissions — WHY: CI recommendation must be grounded in actual current absence/presence — ANGLE: `.github/workflows` source audit.
