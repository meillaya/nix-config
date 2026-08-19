# Final Gate Review — bootstrap-password

## recommendation

REJECT

## blockers

1. **The staged validator does not reject every file symlink as required.**
   - `modules/nixos/bootstrap-password.nix:52-55` tests `-e` before `-L`. A dangling `mei-password.hash` symlink is therefore treated as a missing file; on an existing unlocked installation, `write_sentinel` replaces it before the symlink rejection at `modules/nixos/bootstrap-password.nix:57` is reached.
   - `tests/bootstrap-password-lifecycle.sh:53-132` has no regular-file-symlink or dangling-file-symlink scenario, so this branch is neither caught nor proven.
   - Required fix: reject `-L "$hash_file"` before missing-file migration, add both resolving and dangling file-symlink cases, capture RED before the fix and GREEN afterward, then rerun the full gate.

2. **Mandatory lifecycle boundary coverage is incomplete.**
   - `tests/bootstrap-password-lifecycle.sh:53-132` covers wrong modes and an empty salt, but has no parent-symlink case, no file-symlink case, no accepted maximum salt-length case, and no over-maximum salt-length rejection. The required `{1,86}` boundaries are therefore not proven mutation-sensitive.
   - Required fix: execute the exact Nix-emitted validator against parent/file symlinks and salt lengths 1, 86, and 87; include exact expected outcomes and mutation evidence that removing each guard makes its named test fail.

3. **Mandatory Fish-helper surface coverage is incomplete.**
   - `tests/bootstrap-password-install-helper.sh:80-132` tests only an explicit flake, a mocked tmpfs success, nested directory/file modes, installer status, and signals.
   - It does not test the default flake at `bin/nixos-anywhere-bootstrap-password.fish:14-17`, missing `XDG_RUNTIME_DIR` at `:19-23`, non-tmpfs rejection at `:24-27`, usage/target arity at `:8-11`, or the staging-root mode created at `:29`.
   - Signal cases assert only runtime-directory emptiness at `tests/bootstrap-password-install-helper.sh:125-127`; they do not prove the mocked `sleep 300` child is gone after HUP/INT/TERM.
   - Required fix: add the missing exact-helper scenarios and assert both staging-root removal and child-process termination for success, installer failure, HUP, INT, and TERM; capture RED/GREEN and mutation sensitivity.

4. **The secret guard's fail-closed and coverage claims are under-proven.**
   - `tests/bootstrap-password-secret-scan.sh:132-154` proves unreadable-file and Perl/password-option failures only.
   - There is no adversarial proof for failure of `git ls-files` at `:14`, hash scanning at `:40-49`, or private-key scanning at `:51-61`, and no manifest assertion proving every tracked production path under `hosts`, `modules`, `bin`, `docs`, `flake.nix`, and `overlays` was actually enumerated.
   - Required fix: add fail-closed cases for each enumerator/scanner and an independently derived production-manifest comparison; do not describe broader coverage than the manifest proves.

5. **No current mutation-sensitivity artifact exists.**
   - The evidence directory contains RED/GREEN and aggregate run output, but no mutant run proving that the tests fail when validator ordering, exact `!\n`, shadow equality, symlink rejection, salt bounds, `--extra-files`, cleanup, or secret detection is broken.
   - This is especially material because the missing dangling-symlink test permits a real production regression.
   - Required fix: record named production mutants and the exact test/assertion that kills each, with an unmodified GREEN control and cleanup receipts.

6. **The claimed post-fix reviewer APPROVE and architect CLEAR are unsupported.**
   - The only current-task claims are prose in `/tmp/ulw-20260711-154935.Exse9c.md:128-131`.
   - No raw reviewer report, architect report, reviewer identity, round linkage, or immutable binding to current index tree `e135962a934243e8e7e052f096b86582747b418c` / cached-patch SHA-256 `c9ad2fb4f3451d3118fa8247e171d8077e8cf9893ddbcea186940499a7cf40a8` was supplied or found.
   - `.omo/evidence/default-nixos-password-gate-review.md` reviews an earlier research candidate, not this eight-file staged implementation, and itself recommends REJECT.
   - Required fix: preserve the actual same-reviewer and architect round artifacts, bind them to the final index identity and fresh QA evidence, and require unconditional `APPROVE` / `CLEAR` after all fixes.

7. **The mandatory code-review anti-slop/programming coverage is absent.**
   - `/tmp/ulw-20260711-154935.Exse9c.md:40` explicitly says the programming perspective was not used.
   - No current code-review report documents a `remove-ai-slops` perspective or covers excessive/useless tests, deletion-only tests, tests that merely verify requested removal, tautologies, implementation mirroring, dead code, unnecessary production extraction/parsing/normalization, scope drift, and maintenance burden.
   - Direct gate pass: the staged tests execute production-emitted scripts and no deletion-only test, dead production branch, speculative dependency, or oversized new file was found; however, missing adversarial cases and mutation evidence create false confidence, and report coverage remains mandatory independently of this direct pass.
   - Required fix: produce a current, identity-bound code-review report explicitly covering every required overfit/slop class and the applicable programming criteria; mark language-specific Python/Rust/TypeScript/Go rules N/A rather than silently skipping the perspective.

8. **Fresh post-fix static verification is not proven.**
   - `.omx/evidence/bootstrap-password/regression-green.txt:1-6` names shellcheck, Bash/Fish syntax, Nix parse, flake check, and dry-run, but it predates the review fixes recorded at `/tmp/ulw-20260711-154935.Exse9c.md:118-123`.
   - `.omx/evidence/bootstrap-password/post-review-full-green.txt` contains focused script output, flake output, and dry-run output, but no command transcript or explicit post-fix results for `git diff --cached --check`, shellcheck, Bash syntax, Fish syntax, or both Nix parses.
   - Required fix: run and capture every required static command against the final frozen index with command lines, statuses, and identity metadata.

9. **Evidence freshness and cleanup are not gate-grade.**
   - None of `.omx/evidence/bootstrap-password/*.txt` records the current HEAD/index tree/cached-patch identity. `post-review-full-green.txt` has no command lines or per-command exit statuses, so its output cannot prove which exact staged tree was exercised.
   - The promised `.omx/evidence/bootstrap-password/cleanup.txt` from `/tmp/ulw-20260711-154935.Exse9c.md:22` is absent, and the notepad never records completion of transition 9 (`:133-134`).
   - Required fix: generate one final identity-bound evidence set from an exact-index checkout, record cleanup of all temporary directories/processes, and recheck that the index identity is unchanged after review.

## originalIntent

Ship a safe, unique per-install NixOS bootstrap password flow using an external `/var/lib/nixos-bootstrap/mei-password.hash`, validated before users activation and consumed to exact `!\n` only after the same hash reaches `/etc/shadow`, while preserving existing unlocked installations, credentials, groups, SSH keys, and Disko behavior.

## desiredOutcome

An eight-file staged implementation whose Nix activation, Fish installer helper, documentation, secret guard, adversarial tests, RED→GREEN history, current static checks, cleanup, code review, and architecture review all independently prove the requested user-visible installation and migration behavior without a committed password or reusable verifier.

## userOutcomeReview

The implementation substantially establishes the intended architecture: the config uses the external hash file and classic mutable users; the validator precedes users; the consumer compares the staged hash with `/etc/shadow` before writing exact `!\n`; the helper uses runtime tmpfs and `--extra-files`; the staged host diff preserves the existing group/key declarations, and Disko is outside the staged diff. Current focused evidence also shows fresh, sentinel, locked, existing-unlocked migration, malformed input, wrong modes, consumer mismatch, status propagation, signals, and the principal secret patterns.

The user cannot safely rely on the staged result yet. A dangling verifier symlink bypasses the promised symlink rejection on existing unlocked systems, multiple mandatory boundaries are untested, mutation sensitivity is absent, static evidence is partly stale, cleanup is undocumented, and reviewer/architect approval plus mandatory anti-slop/programming report coverage are unsupported prose rather than inspectable artifacts.

## direct remove-ai-slops / programming review

- Excessive/useless tests: no clearly excessive existing case; the problem is missing adversarial coverage, not test count.
- Deletion-only/requested-removal tests: none found.
- Tautology/implementation mirroring: lifecycle tests execute Nix-emitted production scripts and helper tests execute the tracked Fish helper, which is the correct surface. The guard's self-invocation is useful, but its error-path matrix is incomplete.
- Dead code/test-only implementation: no explicit production branch conditioned on tests and no unreachable new helper found.
- Extraction/parsing/normalization: no unnecessary dependency or generic abstraction found; boundary regex duplication between Nix, Fish, and test mocks is intentional contract duplication, but requires mutation proof.
- Maintenance/scope: new source files are below the 250 pure-LOC ceiling. The report/evidence omissions and under-sensitive matrices create false confidence and are blocking under the programming criteria.

## checked artifact paths

- `/tmp/ulw-20260711-154935.Exse9c.md`
- `.omx/evidence/bootstrap-password/config-red.txt`
- `.omx/evidence/bootstrap-password/config-green.txt`
- `.omx/evidence/bootstrap-password/lifecycle-red.txt`
- `.omx/evidence/bootstrap-password/lifecycle-green.txt`
- `.omx/evidence/bootstrap-password/helper-red.txt`
- `.omx/evidence/bootstrap-password/helper-green.txt`
- `.omx/evidence/bootstrap-password/secret-scan-red.txt`
- `.omx/evidence/bootstrap-password/secret-scan-green.txt`
- `.omx/evidence/bootstrap-password/regression-green.txt`
- `.omx/evidence/bootstrap-password/review-fixes-red.txt`
- `.omx/evidence/bootstrap-password/review-fixes-green.txt`
- `.omx/evidence/bootstrap-password/post-review-full-green.txt`
- `.omo/evidence/default-nixos-password-gate-review.md`
- all eight staged paths in `git diff --cached`

## exact evidence gaps

1. RED/GREEN for resolving and dangling parent/file symlinks and salt lengths 1/86/87.
2. Helper default-flake, arity, unset-runtime, non-tmpfs, stage-root-mode, and child-cleanup proof.
3. Fail-closed guard proof for manifest, hash-scan, and private-key-scan failures plus manifest completeness.
4. Named mutant-kill evidence for every security-critical production guard.
5. Final-index command/status transcripts for shellcheck, syntax, Nix parse, flake check, and dry-run.
6. Raw same-reviewer APPROVE and architect CLEAR artifacts bound to the final index and fresh evidence.
7. A current code-review report with explicit remove-ai-slops, programming, and every overfit/slop criterion.
8. Final cleanup receipt and before/after identity equality.

