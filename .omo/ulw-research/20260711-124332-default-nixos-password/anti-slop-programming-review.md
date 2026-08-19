# Independent anti-slop and programming review

Reviewers: OMX `code-reviewer` agents `019f525f-0a4f-7270-9ef0-8a43b2dacc9c`
and `019f5277-e895-7b81-ba7b-0fdc0fb69ad7`

## Initial verdict: REJECT

The reviewer identified six concrete issues: a fresh-machine sentinel bypass, `mkForce`
masking policy drift, inconsistent Fish preflight parsing, overstatement of mocked
workflow evidence, missing installer/INT/TERM cases, and under-documented activation
coupling.

## Fixes applied

1. The sentinel branch now reads `/etc/shadow` and accepts `!` only for an existing
   target user with a nonempty, nonlocked password.
2. `lib.mkForce true` was replaced with the normal `users.mutableUsers = true`
   declaration so conflicting policy fails instead of being silently overridden.
3. Fish preflight now requires a final newline, exactly one line, and a full-line
   yescrypt match.
4. The workflow artifact explicitly classifies its mocked-boundary run as unit-style,
   not a live install.
5. Installer status 42 and HUP/INT/TERM statuses 129/130/143 are executed and checked.
6. Ordering and lifecycle invariants are documented next to the three activation
   fragments; no general-purpose abstraction or dependency was added.

## First correction verdict: APPROVE

No current blocking findings.

Evidence cited by the reviewer:
- Sentinel invariant: `candidate-bootstrap-password.nix:28-42`
- Sentinel pass/rejection matrix: `verify-emitted-candidate.md`
- No `mkForce`: `candidate-bootstrap-password.nix:7`
- Exact Fish preflight: `verify-fish-workflow.fish:46-54`
- Honest harness scope: `verify-exact-fish-workflow.md`
- Installer and signal cases: `run-fish-workflow-verification.sh`
- Ordering comments: `candidate-bootstrap-password.nix:47-53`

Reviewer checks: `nixd` clean; Nix parse, Bash syntax, and Fish syntax passed; emitted
candidate and Fish workflow harnesses passed.

## Second review: REJECT, then corrected

After the gate required the harness to become self-binding, a fresh reviewer found
that this document's approval was stale and that the consumer assertion could not
distinguish `!` from `!\n`. The harness now:

1. Evaluates the current Nix candidate into temporary scripts on every run.
2. Byte-compares those scripts with the recorded emitted artifacts.
3. Executes the freshly evaluated scripts, not copied validation logic.
4. Compares consumer output byte-for-byte with `!\n`.
5. Reruns the exact validator against the consumed output with an unlocked shadow
   fixture.

## Final verdict: APPROVE

The second reviewer re-read the regenerated, digest-bound emitted evidence after the
exact sentinel comparison and validator rerun were added, then returned `APPROVE`
with no remaining blocker.

## Credential-scan review: REJECT, then APPROVE

A third independent code reviewer rejected the first tracked-source scanner for
missing quoted Nix attributes and PHC scrypt. The scanner and executable pattern
matrix now cover quoted and unquoted forms of every Nix password option, enumerated
modular/PHC password hashes, generic/encrypted/algorithm-specific/PGP/OpenSSH/age
private-key markers, and an ordinary shell-variable negative control. Claims are
explicitly limited to those enumerated patterns and caveat unknown encodings. The
same reviewer reran the current artifacts and returned `APPROVE`.

## Multiline/error-path review: REJECT, then APPROVE

The final gate then found that line-oriented `git grep` missed an ordinary legal Nix
assignment when whitespace/newlines separated the attribute from `=`. Password-option
scanning now reads each tracked Nix file as a whole document; the exact regression
matrix includes multiline and comment-separated quoted assignments. The reviewer then
found an unreadable tracked file could be reported as a clean no-match. The final
scanner preflights a checked NUL file manifest, fails with status 2 on unreadable
tracked paths, and the regression matrix proves that path cannot emit zero counters.
The same reviewer reran the corrected artifacts and returned `APPROVE`.

## Search-process error review: REJECT, then APPROVE

The gate then identified that the whole-document Perl stage used success/no-match
semantics different from `git grep`: Perl returns zero for both matches and no matches,
so accepting status 1 could hide a process failure. The scanner now requires exactly
zero for that stage and exits 2 with an explicit error otherwise. The regression
matrix injects a Perl process that exits 1 and proves no zero counters are emitted.
A fresh independent reviewer reran the current error paths and returned `APPROVE`.

## Anti-slop criteria

- No implementation-mirroring validator test: evaluated Nix emits the scripts that
  are executed unchanged, and byte comparison rejects recorded-artifact drift.
- No tautological assertion added; mutable users is declared normally and the
  assertion documents the lifecycle requirement.
- No excessive or useless tests: each case maps to a distinct authentication boundary
  (existence, ownership/mode, termination/count, grammar, lifecycle, consumption,
  installer status, or signal cleanup).
- No deletion-only or removal-only tests: every test observes executable behavior;
  the tracked-secret scan is separately labeled as a targeted guard.
- No dead code: the unused fixture helper identified by the gate was removed; all
  remaining helpers are called by the recorded harnesses.
- No unnecessary extraction or normalization: Nix extraction is required to bind
  tests to the candidate; whitespace normalization is limited to parsing numeric
  `tail`, `wc`, and `od` boundary outputs.
- Parsing occurs only at untrusted file/process boundaries and is required to fail
  closed.
- Three activation fragments are the minimum for validate-before-read and
  erase-after-read ordering.
- No production edit, dependency addition, generic abstraction, or SSH/FDE scope
  expansion occurred.
