# Task 22 verification receipt

Commit under test: `787e84f`

| Surface | Command | Result |
|---|---|---|
| Fixture harness | `timeout 900 tests/readiness/run-task.sh 22 fixture` | `TASK 22 FIXTURE PASS` |
| Negative harness | `timeout 900 tests/readiness/run-task.sh 22 negative` | `TASK 22 NEGATIVE PASS` |
| Direct fixture F01 | `bash tests/readiness/task22/run.sh fixture F01-two-disposable-homes` | exit 0 |
| Direct collision F02 | `bash tests/readiness/task22/run.sh fixture F02-collision-backup` | exit 0; repeat-after-collision and stale backup checks |
| Direct idempotence F03 | `bash tests/readiness/task22/run.sh fixture F03-idempotent-activation` | exit 0; full managed snapshot includes MIME cache |
| Direct preflight F04 | `bash tests/readiness/task22/run.sh fixture F04-satisfied-prerequisites` | exit 0 |
| Direct interruption F05 | `bash tests/readiness/task22/run.sh fixture F05-signal-after-backup-mv` | exit 0; backup/install/temp/source-loss recovery |
| Direct missing N01 | `bash tests/readiness/task22/run.sh negative N01-missing-prerequisite` | exit 1 |
| Direct embedded-home N02 | `bash tests/readiness/task22/run.sh negative N02-embedded-mei-home` | exit 1 |
| Nix parse | `nix-instantiate --parse` for all changed `.nix` files | pass |
| Python lint | `ruff check tests/readiness/task22/preflight.py` | pass |
| Python typecheck | `basedpyright tests/readiness/task22/preflight.py` | 0 errors (stdlib JSON boundary warnings only) |
| Shell lint | `shellcheck tests/readiness/task22/run.sh tests/readiness/adapters/task-22.sh` | pass |
| Nix app QA | `nix run --offline .#home-switch -- --help` | exit 0; fixed `hm-backup` shown |
| Compatibility app QA | `nix run --offline .#home-news -- --help` and invalid `--target` | help exit 0; invalid target exit 2 |
| App rejection QA | `nix run --offline .#home-switch -- --target invalid --dry-run` and unsafe `--backup-ext` | exit 2 |
| Packaged preflight QA | offline `nix build` of `nix-config-home-preflight`, then its `--fixture` reports | satisfied fixture exit 0; missing fixture exit 1 |
| Task 13 isolation | `env PYTHONPATH=. python3 tests/readiness/task13/test_task13.py fixture F04-runtime-consumer-isolation` | exit 0 |

Harness evidence is stored at:

- `.omo/evidence/nix-config-machine-readiness/task-22/fixture.json`
- `.omo/evidence/nix-config-machine-readiness/task-22/negative.json`

The Nix full home-file evaluation without unfree allowance remains an existing
repository limitation (`copilot-language-server`); fixture builds use the
repository's offline package policy and pass.

The strict capture harness was retried at the final SHA; ptrace startup races (exit 125, “No such process”) occurred on F01/F03/F05 while concurrent worktrees ran the same capture. Direct exact-SHA cases pass; rerun strict capture with concurrent capture sessions paused. See `FIX-TRANSACTION.md`.
