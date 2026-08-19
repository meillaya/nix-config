# Task 22 baseline and failing-first proof

## Baseline

The parent commit `1075b40` shipped the Task 22 adapter as an explicit
not-implemented baseline. Replaying that adapter from the parent commit gives
exit 126:

```text
git show 1075b40:tests/readiness/adapters/task-22.sh | bash -s fixture F04-satisfied-prerequisites ''
exit=126
```

The replay was independently rerun after the final commit and returned
`baseline_rc=126`.

## Failing-first red proof

The first implementation commit (`b9e2f46`) exercised all negative cases, but
`N01-missing-prerequisite` did not propagate the expected nonzero result. The
clean historical worktree run was:

```text
git worktree add --detach /tmp/nix-config-task22-red b9e2f46
timeout 300 /tmp/nix-config-task22-red/tests/readiness/run-task.sh 22 negative
exit=1
TASK 22 NEGATIVE INVALID
```

Captured result before the fix:

```json
{"cases":[{"actualExit":{"code":0,"kind":"exit"},"caseId":"N01-missing-prerequisite","expectedExitClass":"exit-nonzero","result":"mismatched"},{"actualExit":{"code":1,"kind":"exit"},"caseId":"N02-embedded-mei-home","expectedExitClass":"exit-nonzero","result":"matched"}],"exitCode":1,"marker":"TASK 22 NEGATIVE INVALID","outcome":"INVALID"}
```

The fix explicitly returns exit 1 after validating the missing-prerequisite
report; the final clean harness run is `TASK 22 NEGATIVE PASS`.
