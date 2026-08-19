# Task 22 standalone Home Manager functional review

**Overall verdict: FAIL pending a cross-task Task 5 repair; Task 22 behavior itself: PASS.**

## Target and safety boundary

- Review target is current integrated HEAD `e2e7b2d5182053ded61051e417b0849915437e72`. The Task 22 transactional fix is integrated as `039605f` (source `787e84f`). The parent worktree has only the unrelated unstaged Task 19 VM file, so strict captures ran in a clean linked worktree at the exact HEAD and recorded that commit in the evidence JSON.
- All activation runs used disposable `/tmp` homes and runtime directories with fixture bytes. No sudo, reboot, service enablement, network access, secret decryption, signing, external publish, or real-host activation was performed.

## Task 22 passing evidence

| Surface | Result |
| --- | --- |
| Strict fixtures | `tests/readiness/run-task.sh 22 fixture` → `TASK 22 FIXTURE PASS`; F01–F04 all matched exit 0. Evidence: `evidence/current-fixed-final/strict-fixture.json` (`testedGitCommit=e2e7b2d`). |
| Strict negatives | `tests/readiness/run-task.sh 22 negative` → `TASK 22 NEGATIVE PASS`; N01/N02 matched exit 1. Evidence: `evidence/current-fixed-final/strict-negative.json`. |
| Explicit homes and portability | F01 built separate disposable `alice`/`bob` homes, consumed mode-0600 Task 13 projections, and found no `/home/mei` in generated alternate-home output. |
| Collision and stale backups | F02 preserved host bytes at deterministic `.hm-backup` paths, rejected stale backup overwrite, and retried idempotently. |
| Idempotence | F03 repeated activation and compared the managed snapshot without drift. |
| Preflight | F04 satisfied the canonical host fixture; missing/malformed/noncanonical/duplicate/symlink/directory mutants reject. Fake live commands were only discovered (`executed=0`). Evidence: `evidence/current-fixed-final/preflight-mutants.txt`. |
| Interruption/recovery | Direct F05 (`run.sh fixture F05-signal-after-backup-mv`) exits 0. It exercises signal-after-backup, signal-after-install, interruption during pending temp install, source disappearance fail-closed cleanup, and successful source restoration. Evidence: `evidence/current-fixed-final/direct-F05.log`. |
| Task 13 boundary | Fixture shape exposes `runtimeSecrets.mode=user-projection`, `consumeRuntimeSecrets`, and excludes all four secret paths from `home.file`; no decryption or privilege escalation is in this activation. |
| App compatibility | Offline `home-switch --help` exits 0; unsupported target and unsafe backup extension exit 2. x86 exposes `home-switch`; aarch64-linux intentionally omits deployment apps and Darwin uses its separate app set. Evidence: `evidence/current-fixed-final/app-compat.log`. |
| Static checks | ShellCheck, Python compile, Nix parse, ambient-environment lookup scan, and generated fixture portability checks pass. Evidence: `evidence/current-fixed-final/static.log`. |
| Capture safety | Strict evidence records zero protected actions, `complete=true`, and zero unexpected secret matches. An earlier concurrent capture attempt reported ptrace `No such process`/exit 125; after stale capture sessions were terminated, the clean rerun passed and is the accepted evidence. |

## Cross-task regression blocker

Fresh Task 5 checks on the current `e2e7b2d` target fail before any Task 22 code is exercised:

- `tests/readiness/adapters/task-5.sh fixture F01-single-option-owners` fails in `tests/readiness/task5/architecture/graph.nix` because the newly integrated Task 17 `modules/aspects/hardware/device-capability-routing.nix` defines `den.aspects.aarch64-darwin-device-capability-routing` (and sibling device-routing aspects) that Task 5's graph/model/owner manifest does not register.
- This is unrelated to Task 22 and is being repaired in the integration branch. Until that repair lands, the requested Task 5 regression gate is not green, so this overall report remains FAIL despite all Task 22-specific gates passing.
- Task 17 review also reports an I2C ownership gap: `modules/nixos/system.nix` still unconditionally grants nested `hardware.i2c.enable`/`i2c` group membership, while the new projection only masks enablement. Evidence: `../task-17-review/FINAL-REPORT.md` and `final/i2c-projection-all.log`. This remains a separate cross-task blocker.

Other affected-regression probes on the same integration lineage passed: Task 6 fixture/negative probes, Task 13 runtime/cleanup probes, Task 15 fixture/model-parity probes, and Task 19 portal mapping/OBS/picker/secret fixtures plus negative mutants. Evidence is under `evidence/current-fixed-final/regressions-e2e7.log`, `regression-task5-e2e7.log` (failure above), and prior focused logs.

## Cleanup

Reviewer-created linked worktrees, disposable homes, runtime roots, generated Python caches, and capture sessions were removed. No protected action occurred. Re-run Task 5 after the metadata repair and update this report/verdict before final acceptance.
