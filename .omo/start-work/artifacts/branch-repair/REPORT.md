# Branch repair report

Date: 2026-07-16 (America/Toronto)

## Scope

Repaired the task-owned branch after the concurrent Task19 amend landed on the
Task23 commit. No new product behavior was implemented. The repair was limited
to restoring commit boundaries and retaining the already-requested Task19
UnknownFixture assertion as its own follow-up commit.

Target worktree: `/home/mei/nix-config-machine-readiness-worktree`
Target branch: `work/nix-config-machine-readiness`

## Recovery and final history

- Pre-repair tip: `86b4d3e03330daea1c6122e4287a171da4d2371d`
  (`fix(darwin): make Nix the single application authority`, accidental amend).
- Durable recovery ref: `refs/branch-repair/pre-amend-86b4d3e`.
- Recovered Task19 commit: `84649cf415290d6109e08aa4ef978811f308c857`
  (`fix(desktop): make capture and portal claims executable`).
- Recovered Task23 commit: `3dfd8d8e1a3a1cff130f2885a572a8e94315eeb0`
  (`fix(darwin): make Nix the single application authority`), now with only
  the Task23 manifest paths.
- New intentional Task19 follow-up: `b2760561b87b4182b69901fedf59d5007d2decfe`
  (`fix(desktop): keep unknown portal interfaces on GTK`), one line in
  `tests/readiness/task19/portal_runtime.py`.
- Branch-repair tip: `b2760561b87b4182b69901fedf59d5007d2decfe`.

The final chain is linear: Task19 `84649cf` -> Task23 `3dfd8d8` -> Task19
follow-up `b276056`. The final tree ID is
`dc672852d627e17d8e69dfc948642b0c4669bd8d`, equal to the pre-repair tree of
`86b4d3e`; only history boundaries changed.

Earlier completed Task9, Task13, Task18, and Task21 commits remain unchanged:

- Task9: `71d6ed0`, `1075b40`
- Task13: `48b39e7`, `5bcef71`
- Task18: `30e0768`
- Task21: `990a95a`, `f76a12d`

## Manifest checks

- Task19 manifest (`.omo/start-work/artifacts/task-19/changed-files.txt`)
  matches the eight paths in `84649cf`; the one-line follow-up is isolated to
  the same owned `portal_runtime.py` path.
- Task23 manifest (`.omo/start-work/artifacts/task-23/changed-files.txt`)
  matches the ten paths in `3dfd8d8`; no Task19 path is present in that commit.
- `git diff 86b4d3e b276056` is empty in the target worktree, proving no product
  bytes were lost or added by the repair. The later Task15 integration commit
  `859c6ba` is intentionally outside this repair delta.

## Uncommitted ownership preserved

Task15 and Task22 detached executor worktrees were not reset, staged, cleaned,
or otherwise modified. Their current status/path snapshots are retained in:

- `task15-preserved-status.txt`
- `task22-preserved-status.txt`

Those files list all tracked modifications and untracked paths still owned by
the executors. Any Python cache files that appeared while Task15 was running
were left untouched; the repair did not remove or rewrite them.

## Cleanup and verification

- Target branch/index/worktree was clean immediately after the repair commit;
  a later Task15 integrator intentionally staged its owned paths (see the
  concurrent ownership update below).
- Original accidental commit remains recoverable through the durable backup ref
  and reflog.
- No external systems, remotes, resets of other worktrees, or product tests
  were run; only lightweight history/tree/manifest/status checks were needed.

## Concurrent post-repair ownership update

After the history repair and its clean-status check, a separate Task15
integrator staged and then committed its 19 owned paths as `859c6ba`
(`feat(hardware): route firmware and microcode by enrolled host`), then amended
that Task15 commit to `8b05545` while this report was being finalized. The
current branch tip is `8b05545`; repair commits remain directly below it. The
staged intermediate status is retained in `target-post-repair-concurrent-status.txt`,
and current clean target status is in `target-final-status-current.txt`.
Task15's detached executor worktree remains dirty and untouched; Task22 remains
in its detached executor worktree with its uncommitted paths (including its
README change). Current detached statuses are `task15-final-status-current.txt`
and `task22-final-status-current.txt`.
