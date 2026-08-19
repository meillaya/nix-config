# Verification — Recommended Credential Mechanism

- Candidate Nix evaluation: PASS (`verify-repo-overlay-gate-fix.md`).
- Exactly one password source: `hashedPasswordFile = "/var/lib/nixos-bootstrap/mei-password.hash"`.
- Classic mutable backend: PASS (`mutableUsers=true`, `sysusers=false`, `userborn=false`).
- Adjacent behavior: groups and configured SSH key preserved.
- Activation order after the gate fix: validator line 29, users line 67, sentinel consumer line 79 (`verify-repo-overlay-gate-fix.md`).
- Exact emitted validator/consumer: fresh yescrypt and post-install sentinel accepted; fresh/locked sentinel, missing, empty, multiline, unterminated-second-line, valid-without-newline, malformed, and wrong-mode inputs rejected; valid verifier replaced by `!` (`verify-emitted-candidate.md`).
- Candidate system build dry-run: PASS.
- Tracked source has no quoted/unquoted Nix password-option assignment, enumerated modular/PHC password hash, or private-key marker: PASS (`verify-tracked-secret-scan.md`).
- The exact `nixpkgs#mkpasswd` package exposes yescrypt: PASS (`verify-mkpasswd.md`).
- Exact documented Fish workflow: syntax, success cleanup, generator/installer-failure cleanup, status preservation, and HUP/INT/TERM cleanup PASS (`verify-exact-fish-workflow.md`).
- Pinned install/boot source chain refutes on-disk `/run` and supports persistent `/var/lib`: PASS (`verify-run-path.md`).
- Temporary verification directory cleanup: PASS (EXIT traps; no matching `/tmp/nix-emitted-password-verify.*` or `/tmp/nix-fish-workflow-verify.*` remains).
