# Ultrawork durable notepad

## Applicable skills
- omo:ultrawork — binding durable execution/evidence loop
- omo:ulw-research — exhaustive multi-wave research and cited synthesis
- omo:teammode — MultiAgentV2 six-member research team
- omo:debugging — hypothesis-driven RED/GREEN/runtime proof
- omo:review-work — HEAVY final independent verification gate

## Tier
HEAVY: permissions/security boundary, destructive external installer, and explicit exhaustive research.

## Plan
1. Lock the empty-target-NSS bug with a formal failing lifecycle regression.
2. Replace name-based early ownership predicates/operations with numeric invariants and actionable metadata diagnostics.
3. Prove GREEN across happy, hostile, regression, generated-activation, evaluation and build surfaces.
4. Update operator guidance for safe diagnostics and non-destructive install-only recovery.
5. Run adversarial reviewer convergence, produce cited synthesis/report, clean debug/team state.

## Success criteria and exact scenarios
1. Happy path: correctly owned 0:0 directory/file at 0700/0600 passes with passwd/group absent. Command: valid expected=pass rc=0 verdict=PASS output=''
sentinel-existing-unlocked expected=pass rc=0 verdict=PASS output=''
sentinel-fresh expected=fail rc=1 verdict=PASS output=bootstrap\ password\ hash\ validation\ failed:\ consumed\ sentinel\ requires\ an\ existing\ unlocked\ password
sentinel-locked expected=fail rc=1 verdict=PASS output=bootstrap\ password\ hash\ validation\ failed:\ consumed\ sentinel\ requires\ an\ existing\ unlocked\ password
missing-existing-unlocked expected=pass rc=0 verdict=PASS output=''
missing-existing-unlocked-migrated=PASS
missing expected=fail rc=1 verdict=PASS output=bootstrap\ password\ hash\ validation\ failed:\ missing\ /var/lib/nixos-bootstrap/mei-password.hash
missing-locked expected=fail rc=1 verdict=PASS output=bootstrap\ password\ hash\ validation\ failed:\ missing\ /var/lib/nixos-bootstrap/mei-password.hash
empty expected=fail rc=1 verdict=PASS output=bootstrap\ password\ hash\ validation\ failed:\ expected\ non-empty\ file
multiline expected=fail rc=1 verdict=PASS output=bootstrap\ password\ hash\ validation\ failed:\ expected\ exactly\ one\ newline-terminated\ line
unterminated-second expected=fail rc=1 verdict=PASS output=bootstrap\ password\ hash\ validation\ failed:\ expected\ one\ newline-terminated\ line
no-final-newline expected=fail rc=1 verdict=PASS output=bootstrap\ password\ hash\ validation\ failed:\ expected\ one\ newline-terminated\ line
malformed expected=fail rc=1 verdict=PASS output=bootstrap\ password\ hash\ validation\ failed:\ expected\ yescrypt\ hash
wrong-mode expected=fail rc=1 verdict=PASS output=bootstrap\ password\ hash\ validation\ failed:\ expected\ root:root\ mode\ 0600
wrong-parent expected=fail rc=1 verdict=PASS output=bootstrap\ password\ hash\ validation\ failed:\ expected\ root:root\ mode\ 0700\ on\ /var/lib/nixos-bootstrap
empty-salt expected=fail rc=1 verdict=PASS output=bootstrap\ password\ hash\ validation\ failed:\ expected\ yescrypt\ hash
salt-1 expected=pass rc=0 verdict=PASS output=''
salt-86 expected=pass rc=0 verdict=PASS output=''
salt-87 expected=fail rc=1 verdict=PASS output=bootstrap\ password\ hash\ validation\ failed:\ expected\ yescrypt\ hash
file-symlink expected=fail rc=1 verdict=PASS output=bootstrap\ password\ hash\ validation\ failed:\ expected\ a\ regular\ file\ at\ /var/lib/nixos-bootstrap/mei-password.hash
file-dangling-symlink expected=fail rc=1 verdict=PASS output=bootstrap\ password\ hash\ validation\ failed:\ expected\ a\ regular\ file\ at\ /var/lib/nixos-bootstrap/mei-password.hash
parent-symlink expected=fail rc=1 verdict=PASS output=bootstrap\ password\ hash\ validation\ failed:\ expected\ a\ real\ directory\ at\ /var/lib/nixos-bootstrap
parent-dangling-symlink expected=fail rc=1 verdict=PASS output=bootstrap\ password\ hash\ validation\ failed:\ expected\ a\ real\ directory\ at\ /var/lib/nixos-bootstrap
consumer-mismatch-preserves-verifier=PASS rc=1
consumer-exact-sentinel-and-revalidation=PASS
cleanup=/tmp/nix-bootstrap-password-lifecycle.iyRIu9. Observable: empty-NSS case PASS; current code first captured RED with exact ownership error.
2. Security edge: wrong UID/GID/mode, symlinks, malformed hash and sentinel misuse remain rejected without printing secret bytes. Commands: lifecycle + mutation + secret scan. Observable: all negative cases PASS and no hash appears in outputs/repo.
3. Regression: helper retains exact numeric --chown, no destination substitution, PTY/agent/signal cleanup behavior. Commands: helper/mutation/shellcheck tests. Observable: zero failures.
4. Runtime surface: generated validator in an empty-NSS target namespace returns 0 for 0:0/700+600 and nonzero for wrong metadata. Observable stored in research verification artifact.
5. Build/eval: flake checks evaluate all systems and x86_64 system builds. Observable:  and system build exit 0.
6. Recovery guidance: commands distinguish ISO-vs-chroot name lookup and explicitly warn default Disko rerun is destructive; install-only path documented and syntax-checked.

## Now
Create formal RED regression before any production edit.

## Todo
- [ ] Formal RED lifecycle case with empty target passwd/group
- [ ] Numeric validator/consumer and numeric pre-users ownership operations
- [ ] Actionable actual numeric metadata diagnostics
- [ ] Wave 2 independent implementation/test/recovery/countersearch reviews
- [ ] Full verification matrix and generated activation namespace proof
- [ ] Temp checkout sync for user retry
- [ ] Cited synthesis + HTML/PDF report
- [ ] HEAVY reviewer PASS
- [ ] Debug/team cleanup

## Findings
- Exact current validator fails with numeric 0:0/700 when target passwd/group are absent because %U/%G render UNKNOWN.
- Validator precedes users and etc in generated activation; nixos-install does not seed passwd/group.
- Pinned extra-files pipeline plus short explicit chown produces 0:0 at 0700/0600; transfer cause refuted.
- Early abort prevents /run/current-system creation; ignored activation status then surfaces switch path ENOENT.
- Existing lifecycle test kept host NSS mounted and masked the bug.

## Learnings
- Validate inode ownership with numeric IDs at pre-users boundaries; names are presentation only.
- Hard-coded expectation-only errors can misdirect debugging; report observed metadata, never secret contents.
- A default nixos-anywhere rerun re-enters Disko/destructive phases; recovery of an intact target should use install-only/mount mode.

## Correction — literal command rendering
The initial notepad heredoc accidentally shell-expanded backtick command text. The resulting lifecycle and flake evaluation ran successfully but are baseline-only evidence, not post-fix proof. The authoritative criteria are:
- `bash tests/bootstrap-password-lifecycle.sh`
- `nix flake check --all-systems --no-build`
- `nix build .#nixosConfigurations.x86_64-linux.config.system.build.toplevel --no-link`
No production file had been edited when these baseline commands ran. The lifecycle lacked an empty-NSS case, so it did not satisfy the new regression criterion.

## Progress — formal RED and Wave 2
- Added only a lifecycle regression seam that bind-mounts empty passwd/group into the validator namespace.
- RED captured: `valid-empty-target-nss expected=pass rc=1`, exact current error `expected root:root mode 0700`.
- Production remained unchanged during RED.
- Wave 2 launched across transfer-test, NSS-boundary, activation-runtime, upstream-recovery, docs-recovery and skeptical-security lanes.

## Now
Implement the smallest numeric ownership fix and metadata-only diagnostics, then run lifecycle GREEN.

## Wave 2 convergence
- Production uses numeric stat predicates, numeric pre-users ownership operations, and observed numeric metadata diagnostics.
- Empty-NSS existing and migration branches pass; wrong UID/GID matrix rejects independently.
- Hostile NSS proves numeric validation is strictly stronger than name validation.
- Recovery documentation has syntax-checked Bash/Nushell and distinguishes safe mount/install modes from destructive default rerun.
- Next: mutation gate with intended staged tree, then full verification/build matrix.

## Full verification complete
- Helper, lifecycle, secret, config, syntax and ShellCheck gates pass.
- Mutation suite passed against the intended temporarily staged tree; new name/creation mutants killed.
- Flake evaluation across all systems and full x86_64 system build pass.
- Generated activation order/tokens verified in built closure.
- Active temporary installer checkout synchronized byte-for-byte for all changed operational files while preserving the selected Micron disk path.
- Cited `SYNTHESIS.md`, `REPORT.html`, and `REPORT.pdf` generated in the active research session.

## Now
Blocking five-lane final review is running. After all PASS, archive/delete team state, remove debug journal/exclusion, and close the goal.

## HEAVY final review
All five blocking lanes PASS on the current diff: goal, hands-on QA, code quality, security, and context mining. Review-found Nushell, mutation-index, recovery chown/fallback, dependency-ordering, activation wording, and secret-display defects were fixed and affected lanes rerun.
