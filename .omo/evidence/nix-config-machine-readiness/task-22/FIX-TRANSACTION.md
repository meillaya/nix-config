# Task22 interruption-recovery fix

- **Final follow-up commit:** `787e84f2abac1647eefbaa43ead2f5bf5d1cd006`
  (`fix(home-manager): recover pending secret transactions`)
- **Parent commits:** `441011875126ccb427bc070ae8652f47ade44df3` (initial
  recovery + F05) and `f17239501a225cd544c7297688776d7333af5c15` (transactional
  temp/rename + collision and install-stage regressions).

## Root cause

`consumeRuntimeSecrets` previously moved an existing target to its deterministic
backup and then installed the projected source. SIGTERM between those operations
left no target and a backup that a retry refused to reuse. The same shape could
leave a partial temporary transaction or a stale marker when the projection
vanished.

## Fix

`modules/standalone-linux/home-manager.nix` now stages each projected secret in
a unique mode-0600 pending file in the target directory, fsyncs it, moves the
old target with no-clobber semantics to the deterministic `.hm-backup`, then
renames the pending file into place and fsyncs the directory. Pending filenames
are recoverable markers. Retries validate/resume a pending marker, preserve
existing backups, clean/recreate a partial mode-0600 marker, and fail closed
when a projected source disappears instead of accumulating markers.

## Red -> green evidence

The new `F05-signal-after-backup-mv` regression failed against
`f172395` (which had transactional backup/install but rejected a truncated
pending marker):

```
rc=1
consumeRuntimeSecrets: refusing invalid pending transaction .../.appsettings.json.hm-backup.pending.*
task22: retry after signal-during-temp-install failed
```

At `787e84f`, direct F05 passes with all four interruption stages:
backup move, final install rename, partial temp install, and source
 disappearance/recovery. F02 also includes repeat-after-collision and stale
backup no-overwrite checks.

## Direct verification at final SHA

```
F01-two-disposable-homes       exit 0
F02-collision-backup           exit 0
F03-idempotent-activation      exit 0
F04-satisfied-prerequisites    exit 0
F05-signal-after-backup-mv     exit 0
N01-missing-prerequisite       exit 1
N02-embedded-mei-home          exit 1
shellcheck tests/readiness/task22/run.sh tests/readiness/adapters/task-22.sh  pass
nix-instantiate --parse modules/standalone-linux/home-manager.nix              pass
```

The strict capture harness was retried at the exact SHA. F02/F04 consistently
matched; F01/F03/F05 were observed as exit 125 from the capture tool's ptrace
startup (`ptrace syscall info: No such process`) while other worktrees were
running the same harness. The underlying direct cases above pass and the
harness must be rerun with concurrent capture sessions paused.
