# Task 22 DoneClaim

- **Task:** Standalone Home Manager explicit incremental adoption.
- **Commit chain:** `89eaead` -> `4410118` -> `f172395` -> `787e84f` (transactional interruption recovery).
- **Changed files:** `changed-files.txt` in this directory.
- **Behavior delivered:** explicit disposable `alice`/`bob` users and homes;
  dynamic Noctalia/Codex home paths; runtime-secret consumption from the Task 13
  projection with mode-0600 and deterministic collision backups; read-only
  host-prerequisite preflight; deterministic `home-switch` backup extension and
  compatibility app names; idempotent activation (the inherited desktop-cache step now runs after generation links).
- **Automated evidence:** `verification.md`, `FIX-TRANSACTION.md`, and the two readiness harness JSON
  results under `.omo/evidence/nix-config-machine-readiness/task-22/`.
- **Baseline/red evidence:** `baseline-failing-first.md` and `FIX-TRANSACTION.md`.
- **Manual QA:** offline `home-switch --help`, invalid target/backup rejection,
  and real Home Manager activation in two disposable homes are recorded in
  `verification.md`.
- **Cleanup:** temporary fixtures, runtime roots, historical red worktree, and
  generated Python caches were removed; `git status --short` is clean.
- **Known risk:** broader repository eval still needs its pre-existing unfree
  Copilot allowance; this does not affect the offline Task 22 fixture harness.
