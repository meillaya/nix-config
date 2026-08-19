# Final Same-Reviewer Gate — bootstrap-password

## recommendation

APPROVE

## blockers

None.

## originalIntent

Provide a safe unique per-install NixOS bootstrap password from external `/var/lib/nixos-bootstrap/mei-password.hash`, validate it before users activation, consume it to exact `!\n` only after exact shadow installation, preserve existing unlocked systems and adjacent host/Disko state, and use a private tmpfs Fish workflow with `nixos-anywhere --extra-files` without committing a password or reusable verifier.

## desiredOutcome

A frozen staged implementation whose production behavior, adversarial boundaries, mutation sensitivity, pinned integrations, secret guard, static/full-suite checks, reviewer reports, and cleanup all independently support unconditional completion.

## userOutcomeReview

The frozen staged tree satisfies the requested outcome. The external verifier is the sole password source; validator → users → consumer ordering is evaluated; fresh, locked, sentinel, existing-unlocked migration, exact-shadow mismatch, exact sentinel bytes, parent/file symlinks, modes, newline/multiline, and salt boundaries are exercised through exact emitted scripts. The Fish surface uses tmpfs, private modes, SHA-pinned tools, exact `--extra-files`, status preservation, process-group cleanup, default/explicit flake handling, and helper-specific salt bounds. The scoped secret guard is fail-closed and detects all named synthetic classes. Groups, authorized key, and Disko remain unchanged.

## direct remove-ai-slops / programming pass

- Excessive/useless tests: none; cases map to distinct observable security boundaries.
- Deletion-only/requested-removal tests: none.
- Tautology/implementation mirroring: no unresolved issue; exact production surfaces execute and every security-critical guard has a reason-bound mutant.
- Dead/test-only production code: none.
- Unnecessary extraction/parsing/normalization: none; the Fish wrapper, Bash supervisor, and Nix module have bounded responsibilities.
- Scope drift/maintenance burden: none; no dependency manifest changed, pins are documented and resolved, and every new file remains below 250 pure LOC.
- Failure behavior: strict syntax/ShellCheck gates, fail-closed scanning, deterministic signal cleanup, and exact-index mutation controls pass.

## checked artifact paths

- Entire cached diff at tree `cb907dc1c4332c2e2579bd8fdca7bbfb72c9fd32`
- `/tmp/ulw-20260711-154935.Exse9c.md`
- Every `.omx/evidence/bootstrap-password/*.txt`
- `.omx/evidence/bootstrap-password/final-identity-suite.txt`
- `.omx/evidence/bootstrap-password/pinned-tool-revisions.txt`
- `.omx/evidence/bootstrap-password/code-review-final.txt`
- `.omx/evidence/bootstrap-password/architecture-review-final.txt`
- `.omx/evidence/bootstrap-password/anti-slop-final.txt`
- `.omx/evidence/bootstrap-password/cleanup.txt`

## independent verification

- HEAD/tree/diff identity: exact match before and after; no unstaged or untracked files.
- Exact-index rerun: diff check, Bash/Fish syntax, ShellCheck, both Nix parses, lifecycle, helper, secret scan, mutation suite, and config projection PASS.
- Former surviving mutants: parent-symlink guard and helper lower/upper salt guards are killed for their named reasons.
- Full suite: current identity-bound flake check and production dry-run PASS.
- Pins: recorded revisions match production and both resolve exactly.
- Evidence hygiene: failed mislabeled GREEN files are absent; remaining GREEN evidence has no unresolved failure markers.
- Reviews: same anti-slop reviewer provides criterion-level UNCONDITIONAL APPROVAL; code review APPROVE and architecture CLEAR match the frozen identity.
- Cleanup: no matching temporary paths, signal-test processes, unstaged files, untracked files, or secret fixtures remain.

## exact evidence gaps

None.
