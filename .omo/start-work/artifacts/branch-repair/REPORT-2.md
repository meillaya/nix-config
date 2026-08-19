# Branch repair report 2: mixed Task15/Task19 commit split

Date: 2026-07-16 (America/Toronto)
Target worktree: `/home/mei/nix-config-machine-readiness-worktree`
Target branch: `work/nix-config-machine-readiness`

## Incident and recovery anchor

The pre-repair tip was `1efda9e7d530ae41072dd7907c1b7b00eb2296c6`,
`fix(desktop): make portal VM readiness deterministic`, whose 20-path delta
mixed Task15 hardware/Task5 graph updates with Task19 portal updates. The
original object remains recoverable at
`refs/branch-repair/second-pre-split-1efda9e`.

No reset, discard, checkout, staging, or cleanup was performed in the target
worktree. A temporary index was used to construct the split commit trees, and
the branch ref was atomically advanced with an expected-old-value check. The
pre-repair tree (`a7105f94ad8f78c2c1c39c836cd036c907e83e3f`) equals the final
split tree.

## Recovered logical commits

1. `7646fb8f6bc73edd8e4b374ea04ce6b80de2eec7`
   `feat(hardware): route firmware and microcode by enrolled host`
   Parent: `8b055456bc7e79882d46aef4ebef14b08c55a47b`.
   This commit contains only the 15 Task15/Task5 paths:
   - `modules/aspects/hardware/x86-vendor-routing.nix`
   - `scripts/hardware/cli.py`
   - `scripts/hardware/collector.py`
   - `scripts/hardware/contracts.py`
   - `scripts/hardware/intake.py`
   - `scripts/hardware/primitives.py`
   - `tests/readiness/adapters/task-15.sh`
   - `tests/readiness/cases/task-15.json`
   - `tests/readiness/task15/extended_negatives.py`
   - `tests/readiness/task15/test_task15.py`
   - `tests/readiness/task5/architecture/boundaries.sh`
   - `tests/readiness/task5/architecture/boundary-model.nix`
   - `tests/readiness/task5/architecture/graph.nix`
   - `tests/readiness/task5/architecture/owner-manifest.json`
   - `tests/readiness/task5/compat/run.sh`

2. `eaa998583067bdba705a7345e7f68ab0ad614e55`
   `fix(desktop): make capture and portal claims executable`
   Parent: `7646fb8f6bc73edd8e4b374ea04ce6b80de2eec7`.
   This commit contains only the five Task19 portal paths:
   - `modules/nixos/niri.nix`
   - `tests/readiness/task19/adversarial.sh`
   - `tests/readiness/task19/portal-vm.nix`
   - `tests/readiness/task19/portal_runtime.py`
   - `tests/readiness/task19/vm-contract.sh`

Current branch tip is `eaa9985`; the branch is linear through the preserved
Task15 baseline `8b05545`, recovered Task15 follow-up `7646fb8`, and recovered
Task19 commit `eaa9985`.

## Evidence

- `git diff 1efda9e eaa9985` is empty: all product bytes are preserved.
- `git diff-tree` manifests match the explicit 15-path Task15 and 5-path
  Task19 partitions above; no path appears in both commits.
- Proposed parents and final tree were checked before the atomic ref update.
- Target status after the split is recorded in `target-status-after-split.txt`.

## Task22 preservation

The detached Task22 executor worktree was not touched, reset, staged, cleaned,
or otherwise modified. Its live post-split HEAD/tree/status are recorded in
`task22-status-after-split.txt`; any concurrent Task22 processes were left
running under their owner.

## Cleanup

Temporary index and patch files used for the split were disposable `/tmp`
artifacts only; no repository product paths were changed outside the two
intentional commits. Existing earlier recovery refs, including
`refs/branch-repair/pre-amend-86b4d3e`, remain intact.
