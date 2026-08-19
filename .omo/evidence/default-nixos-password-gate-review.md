# Final Gate Review — default-nixos-password

## recommendation

REJECT

## blockers

1. **The cited anti-slop/programming approval is stale and is not bound to the current reviewed artifacts.**
   - `SYNTHESIS.md:230` cites `anti-slop-programming-review.md` as the independent rejection/fix/approval record.
   - `anti-slop-programming-review.md:26-40` approves and claims the emitted/Fish harnesses passed, but that report has no artifact identity or hashes. Its filesystem timestamp is `2026-07-11 14:26:30 -0400`, while the current emitted and Fish harnesses are timestamped `14:35:23` and the current synthesis/recommended summary are timestamped `14:36:46`.
   - The report therefore cannot support the post-review harness and summary revisions now under gate. This is an evidence-freshness blocker even though the current harnesses independently pass.

2. **The required code-review report coverage is incomplete.**
   - `anti-slop-programming-review.md:42-52` is the entire anti-slop criteria section. It addresses implementation-mirroring validator tests, one tautological assertion, boundary parsing, activation-fragment count, abstraction/dependency additions, and scope expansion.
   - It does not explicitly show a `remove-ai-slops` skill-perspective pass or cover excessive/useless tests, deletion-only tests, tests that merely verify a requested removal, dead code, or unnecessary extraction/normalization. Those required criteria are absent rather than supported.

3. **The emitted-consumer assertion gives false confidence about the sentinel format required by the next activation.**
   - `run-emitted-candidate-verification.sh:55` uses `[[ $(cat file) == '!' ]]`. Bash command substitution strips trailing newlines, so this assertion passes for both the required `!\n` and the invalid unterminated `!`.
   - `run-emitted-candidate-verification.sh:56` checks only mode. The harness never checks the produced sentinel's last byte/line count or reruns the freshly emitted validator against the consumer-produced file.
   - Independent sensitivity proof: the line-55 assertion returned PASS for a two-byte `!\n` file and a one-byte unterminated `!` file. The latter had last byte 33 and would fail the validator's newline contract. The current candidate itself passed an added reviewer-only consumer-to-validator round trip (`last_byte=10`, `lines=1`, `mode=600`), but the committed harness would not catch this plausible regression.

## originalIntent

Research a safe NixOS fresh-install credential mechanism without committing a plaintext password or reusable verifier, and provide a repo-specific candidate plus a safe Fish installation workflow and trustworthy verification evidence.

## desiredOutcome

A current, self-bound candidate/harness package that proves the per-install yescrypt file is validated before user activation, consumed into a newline-terminated locked sentinel afterward, accepted safely on later mutable-user activations, and staged/cleaned correctly by the exact documented Fish workflow, with fresh anti-slop/programming approval covering all required overfit criteria.

## userOutcomeReview

The current implementation behavior is substantially correct: the candidate evaluates, the emitted scripts are freshly extracted and compared, all 11 validator cases pass, the consumer works in a reviewer-added round trip, the exact documented Fish workflow passes all requested edge/signal cases, and cleanup succeeds. The research scope also honestly discloses that no destructive install/full VM/PAM login occurred.

The shipped evidence package still does not satisfy the user's expected trustworthy final outcome. Its cited independent approval predates the current fixes and lacks required anti-overfit criterion coverage, while the consumer test cannot detect a lifecycle-breaking newline regression. These are current blockers, not residual risks.

## direct anti-slop/programming review

- Dead code: no unused fixture helper or unreachable scoped helper found; both defined Bash helpers are called.
- Excessive/useless tests: the 11 validator cases and 9 Fish markers represent distinct boundary, malformed-input, status, and signal classes; no excessive case was found.
- Deletion-only/requested-removal tests: no cosmetic deletion-only test found. The consumer check targets a real security lifecycle outcome, but its assertion is under-sensitive as described above.
- Tautology/mirroring: validator cases execute freshly evaluated Nix output against external fixtures and are not implementation mirrors. The consumer assertion is mutation-insensitive to newline format and is blocking.
- Production extraction/normalization/abstraction: no unnecessary production helper, parser, normalization layer, dependency, or generic abstraction found in the scoped candidate.
- Scope drift: no production configuration was changed; SSH/FDE remain explicitly separate and the Fish harness is correctly described as unit-style rather than a live install.
- Size/maintainability: primary pure-LOC counts are 69, 56, 94, 193, and 12; no applicable oversized source module.

## checked artifact paths

### Primary targets

- `.omo/ulw-research/20260711-124332-default-nixos-password/candidate-bootstrap-password.nix`
- `.omo/ulw-research/20260711-124332-default-nixos-password/run-emitted-candidate-verification.sh`
- `.omo/ulw-research/20260711-124332-default-nixos-password/run-fish-workflow-verification.sh`
- `.omo/ulw-research/20260711-124332-default-nixos-password/SYNTHESIS.md`
- `.omo/ulw-research/20260711-124332-default-nixos-password/verify-recommended-option.md`

### Referenced evidence inspected

- `.omo/ulw-research/20260711-124332-default-nixos-password/anti-slop-programming-review.md`
- `.omo/ulw-research/20260711-124332-default-nixos-password/verify-emitted-candidate.md`
- `.omo/ulw-research/20260711-124332-default-nixos-password/verify-exact-fish-workflow.md`
- `.omo/ulw-research/20260711-124332-default-nixos-password/verify-repo-overlay-gate-fix.md`
- `.omo/ulw-research/20260711-124332-default-nixos-password/verify-tracked-secret-scan.md`
- `.omo/ulw-research/20260711-124332-default-nixos-password/run-tracked-secret-scan.sh`
- `.omo/ulw-research/20260711-124332-default-nixos-password/verify-fish-workflow.fish`
- `.omo/ulw-research/20260711-124332-default-nixos-password/emitted-bootstrap-validator.sh`
- `.omo/ulw-research/20260711-124332-default-nixos-password/emitted-bootstrap-consumer.sh`

## verified evidence

- Scoped working-tree diff and `HEAD^` diff: empty.
- `bash -n`: PASS for both scoped Bash harnesses.
- `shellcheck -S warning`: PASS.
- `nix-instantiate --parse`: PASS.
- `fish --no-execute`: PASS.
- Emitted harness: exit 0; 11 validator cases plus consumer marker PASS; no matching temporary residue.
- Fish harness: exit 0; success, generator failure, multiline, no-final-newline, unterminated trailing content, installer rc 42, HUP 129, INT 130, and TERM 143 markers PASS; no matching temporary residue.
- The Fish block extracted from `SYNTHESIS.md:104-172` is byte-identical to `verify-fish-workflow.fish` (SHA-256 `a856308af7491054ef6cfa5b34ad79d2412d8b85570ecd6510ee6c639f8ad989`).
- All hashes declared by `verify-emitted-candidate.md`, `verify-exact-fish-workflow.md`, and `verify-repo-overlay-gate-fix.md` match current referenced artifacts.
- Current activation markers independently re-evaluated at validator line 29, users line 67, consumer line 79.
- Current tracked-secret scan: exit 0 with `tracked_password_or_private_key_patterns=0`; its stated scope is accurately limited to tracked Nix/Markdown/shell files.
- Current candidate consumer-to-validator reviewer round trip: PASS with newline byte 10, one line, and mode 600.

## exact evidence gaps

1. A fresh code-review artifact bound to the current candidate, both current harnesses, `SYNTHESIS.md`, and `verify-recommended-option.md` by hashes or an equivalent immutable identity.
2. Explicit report evidence for every required anti-slop/overfit class: excessive/useless tests, deletion-only tests, tests merely verifying requested removal, tautologies, implementation mirroring, dead code, and unnecessary production extraction/parsing/normalization/abstraction, plus the programming perspective.
3. A consumer assertion that distinguishes `!\n` from invalid sentinel encodings, preferably by rerunning the freshly emitted validator on the consumer-produced sentinel with an unlocked shadow fixture; alternatively assert final byte 10 and exactly one line in addition to content and mode.

