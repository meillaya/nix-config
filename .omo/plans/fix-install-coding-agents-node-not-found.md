# fix-install-coding-agents-node-not-found - Work Plan

## TL;DR (For humans)

**What you'll get:** A Home Manager activation that no longer crashes on `node: command not found` when installing `oh-my-codex`/`oh-my-opencode`. Both standalone Linux and Darwin get the same surgical fix so the scripts stay symmetric.

**Why this approach:** Add `--ignore-scripts` ONLY to the `omx` and `omo` npm install lines — the two that actually fail. Leave the `codex` line alone (its install already succeeds in the original failure log, and its postinstall is unanalyzed). Drop the dead `nodeBin`/`curlBin`/`bashBin` PATH-prepend that was the previous "fix" attempt. Mirror the proven `--ignore-scripts` pattern in `pkgs/codex-omx.nix:27-28` and `pkgs/opencode-omo.nix:33-34`.

**What it will NOT do:** Will not convert the four `curl | bash` installs to derivations, will not flip `includeCodingAgentDerivations` on standalone, will not pin npm versions, will not change `@openai/codex`'s install behavior, will not change the fail-fast-on-install-failure behavior of the activation script, will not fix the unrelated `sublimetext4-4200` upstream warning. Those are documented in the draft as deferred follow-up.

**Effort:** Quick
**Risk:** Low — change is limited to one activation-script block in each of two files; only the two npm install lines that fail get the new flag; `@openai/codex` is left exactly as-is.

**Decisions to sanity-check:**
- `--ignore-scripts` ONLY on `omx` and `omo` (NOT on `codex`). Recommend surgical — adding the flag to a package whose postinstall we haven't inspected is a silent regression risk; the user's own log proves `codex` doesn't need it.
- Drop the `nodeBin`/`curlBin`/`bashBin` PATH-prepend entirely (vs. leave it as dead code with a comment). Recommend drop — keeping dead "fix" code invites the next reader to re-introduce a broken variant.
- NO per-install error-trapping wrap (vs. add it as a small bonus). Recommend NO wrap — user picked "Minimal fix only", and with `--ignore-scripts` removing the only known failure path, the wrap is functionally unnecessary.
- Patch Darwin in lock-step (vs. Darwin-only when the bug surfaces there). Recommend patch now — Darwin currently masks the bug only because the derivation is on PATH first; if `sessionPath` ever flips, Darwin fails identically. Patch costs nothing.

Your next move: approve (or request the high-accuracy review). Full execution detail follows below.

---

> TL;DR (machine): Quick, Low, 3 todos + final verification wave; patch 2 files + run `nix run .#home-switch`.

## Scope

### Must have

1. `modules/standalone-linux/home-manager.nix:58-89` — replace the `installCodingAgents` activation block:
   - Add `--ignore-scripts` ONLY to lines 82 (`omx` install) and 83 (`omo` install).
   - Do NOT add `--ignore-scripts` to line 81 (`codex` install) — the user's log proves `codex` installs successfully, and `@openai/codex`'s postinstall behavior is unanalyzed.
   - Drop `node` (line 60), `nodeBin`/`curlBin`/`bashBin` (lines 65-67), and the `export PATH="${nodeBin}:..."` line (line 69).
   - Do NOT wrap `eval` in if/else error trapping — preserve the original fail-fast behavior per "Minimal fix only".
   - Replace the `nodeBin` comment (lines 63-64) with a comment explaining why `--ignore-scripts` is applied to `omx` and `omo` only (cite `pkgs/codex-omx.nix:27-28` and `pkgs/opencode-omo.nix:33-34`).
2. `modules/darwin/user-home.nix:29-60` — apply the identical patch (only `omx` and `omo` get `--ignore-scripts`; same removals; same comment update).
3. Run `nix run .#home-switch` end-to-end and verify the activation log:
   - Shows "Activating installCodingAgents".
   - For each of the 7 tools (`codex`, `omx`, `omo`, `opencode`, `pi`, `hermes`, `zeroclaw`) shows either `... already present, skipping` or `... installed`.
   - Contains NO `node: command not found`.
   - Contains NO `npm error code 127`.
   - Activation exits 0.

### Must NOT have (guardrails, anti-slop, scope boundaries)

- Do NOT add `--ignore-scripts` to the `codex` install line — its install already succeeds and its postinstall is unanalyzed.
- Do NOT add error-trapping wrappers around `eval` — preserve the original fail-fast behavior.
- Do NOT create new `pkgs/*.nix` derivations in this pass.
- Do NOT remove or alter the four `curl -fsSL ... | bash` lines (opencode, pi, hermes, zeroclaw).
- Do NOT change `includeCodingAgentDerivations` / `includeOpencode` in `modules/standalone-linux/packages.nix`.
- Do NOT pin npm package versions in the activation script (would require moving to `buildNpmPackage` derivations — deferred).
- Do NOT touch `modules/shared/packages.nix`, `modules/linux/home-manager.nix`, `config/package-exceptions.json`, or any `tests/**` file.
- Do NOT add a new test — there is no existing test framework for activation-script bash, and adding one would balloon this into a refactor.
- Do NOT attempt to silence the upstream `sublimetext4-4200` broken/removal evaluation warnings at the top of the user's log — they are upstream nixpkgs noise, unrelated to this fix.
- Do NOT add a new `home.packages` entry to satisfy this fix — the activation script already uses absolute paths to `${pkgs.nodejs}/bin/npm` etc.

## Verification strategy

> Zero human intervention — all verification is agent-executed.

- Test decision: **none (manual activation is the test)**. There is no test harness for `home.activation.<name>` bash; the activation run IS the test.
- Evidence: `/tmp/activation-log-fix-install-coding-agents-node-not-found.txt` — the full `nix run .#home-switch` output captured via `tee`. The agent greps the file for `node: command not found`, `npm error code 127`, and `Activating installCodingAgents`, then reports the matched lines.
- The activation log is the contract; if any of the 7 tools' lines do not match the expected `... already present, skipping` / `... installed` pattern, the fix is incomplete.

## Execution strategy

### Parallel execution waves

- **Wave 1 (parallel)** — Todo 1 + Todo 2: two file edits, no shared state, fully independent.
- **Wave 2 (sequential)** — Todo 3: end-to-end activation; depends on both file edits landing.

### Dependency matrix

| Todo | Depends on | Blocks | Can parallelize with |
| --- | --- | --- | --- |
| 1. Patch standalone activation script | — | 3 | 2 |
| 2. Patch Darwin activation script | — | 3 | 1 |
| 3. Run `nix run .#home-switch` and verify clean activation log | 1, 2 | F1, F2, F3, F4 | — |

## Todos

> Implementation + Test = ONE todo. Never separate.
<!-- APPEND TASK BATCHES BELOW THIS LINE WITH edit/apply_patch - never rewrite the headers above. -->

- [x] 1. Patch `modules/standalone-linux/home-manager.nix` to add `--ignore-scripts` to `omx` and `omo` install lines and drop the dead PATH manipulation
  What to do / Must NOT do: Surgically edit the `installCodingAgents` activation block at lines 58-89. Add `--ignore-scripts` ONLY to line 82 (`omx` install) and line 83 (`omo` install). Do NOT add `--ignore-scripts` to line 81 (`codex` install) — its install succeeds in the original failure log and its postinstall is unanalyzed. Delete `node` (line 60), `nodeBin`/`curlBin`/`bashBin` (lines 65-67), and the `export PATH="${nodeBin}:..."` line (line 69). Do NOT wrap `eval` in error-trapping if/else — preserve the original fail-fast behavior per "Minimal fix only". Replace the `nodeBin` comment (lines 63-64) with a comment explaining why `--ignore-scripts` is applied to `omx` and `omo` only (cite `pkgs/codex-omx.nix:27-28` and `pkgs/opencode-omo.nix:33-34`). Do NOT remove the four `curl | bash` lines (85-88). Do NOT touch any other part of the file.
  Parallelization: Wave 1 | Blocked by: — | Blocks: 3
  References (executor has NO interview context - be exhaustive):
    - `modules/standalone-linux/home-manager.nix:58-89` — the entire block to edit.
    - `modules/standalone-linux/home-manager.nix:81` — `codex` install line; MUST NOT be touched.
    - `modules/standalone-linux/home-manager.nix:82` — `omx` install line; add `--ignore-scripts` here.
    - `modules/standalone-linux/home-manager.nix:83` — `omo` install line; add `--ignore-scripts` here.
    - `pkgs/codex-omx.nix:27-28` — `dontNpmBuild = true; npmFlags = [ "--ignore-scripts" ];` with the comment "The postinstall script downloads native Rust binaries — skip it."
    - `pkgs/opencode-omo.nix:33-34` — same pattern for `oh-my-opencode`.
    - `.omo/drafts/fix-install-coding-agents-node-not-found.md` Findings F1-F3 — root cause analysis and the architectural issues NOT in scope.
  Acceptance criteria (agent-executable):
    - `grep -nE 'ignore-scripts' modules/standalone-linux/home-manager.nix` returns exactly 2 matches (lines 82 and 83).
    - `grep -nE 'nodeBin|curlBin|bashBin|lib.getBin pkgs.nodejs' modules/standalone-linux/home-manager.nix` returns 0 matches (dead PATH manipulation fully removed).
    - `grep -nE 'export PATH=' modules/standalone-linux/home-manager.nix` returns 0 matches inside the `home.activation.installCodingAgents` block (run from `cd /home/mei/nix-config`).
    - `grep -nF 'install -g --ignore-scripts --force oh-my-' modules/standalone-linux/home-manager.nix` returns 2 matches (one for `oh-my-codex`, one for `oh-my-opencode`) — proves both packages got the flag and `codex` did not.
    - Reading the file back, the `let` block has only `npm`, `curl`, `bash` (no `node`, no `*Bin`).
    - `nix-instantiate --parse modules/standalone-linux/home-manager.nix` exits 0 (cheap Nix syntax check, run from `cd /home/mei/nix-config`).
  QA scenarios (name the exact tool + invocation): happy + failure, Evidence `/tmp/activation-log-fix-install-coding-agents-node-not-found.txt`:
    - Happy path: `nix run .#home-switch` (from `/home/mei/nix-config`) completes with `Activating installCodingAgents` and per-tool `... already present, skipping` / `... installed` lines for all 7 tools; exit 0.
    - Failure-path repro (verify the regression does NOT reappear): same command, `grep -cE 'node: command not found|npm error code 127' /tmp/activation-log-fix-install-coding-agents-node-not-found.txt` returns 0.
    - Idempotency: run `nix run .#home-switch` a second time; all 7 tools should report `already present, skipping` without re-fetching from the npm registry.
  Commit: Y | fix(home-manager): prevent install-coding-agents activation failure from npm postinstall

- [x] 2. Patch `modules/darwin/user-home.nix` identically so the two scripts stay symmetric
  What to do / Must NOT do: Apply the EXACT same surgical edit to `modules/darwin/user-home.nix:29-60` as in Todo 1. Add `--ignore-scripts` only to lines 53 (`omx`) and 54 (`omo`); do NOT touch line 52 (`codex`). Delete `node` (line 31), `nodeBin`/`curlBin`/`bashBin` (lines 36-38), and the `export PATH="${nodeBin}:..."` line (line 40). Update the comment (lines 34-35) to point to the same precedent derivations. Darwin currently masks the bug only because the `codex-omx` / `opencode-omo` derivations in `modules/shared/packages.nix:88-95` pre-empt `install_if_missing omx`/`omo` (the derivation's binary is on PATH first). If `sessionPath` ever changes order, Darwin would fail identically — patching now removes the latent bug. Do NOT touch any other part of the file. Do NOT remove the `pi-wrapped`/`hermes-wrapped`/`zeroclaw-wrapped` shell-script wrappers at lines 9-26 (they are separate from `installCodingAgents`).
  Parallelization: Wave 1 | Blocked by: — | Blocks: 3
  References (executor has NO interview context - be exhaustive):
    - `modules/darwin/user-home.nix:29-60` — the entire `installCodingAgents` block to edit (mirror image of the standalone file).
    - `modules/darwin/user-home.nix:52` — `codex` install line; MUST NOT be touched.
    - `modules/darwin/user-home.nix:53` — `omx` install line; add `--ignore-scripts` here.
    - `modules/darwin/user-home.nix:54` — `omo` install line; add `--ignore-scripts` here.
    - `modules/darwin/user-home.nix:1-27` — DO NOT TOUCH this region (the `home.packages` shell wrappers and `pkgs.nodejs` declaration).
    - `modules/shared/packages.nix:88-95` — explains WHY Darwin's `install_if_missing omx`/`omo` currently skip (the derivation is on PATH first).
    - `pkgs/codex-omx.nix:27-28`, `pkgs/opencode-omo.nix:33-34` — the proven `--ignore-scripts` pattern.
  Acceptance criteria (agent-executable):
    - `grep -nE 'ignore-scripts' modules/darwin/user-home.nix` returns exactly 2 matches (lines 53 and 54).
    - `grep -nE 'nodeBin|curlBin|bashBin|lib.getBin pkgs.nodejs' modules/darwin/user-home.nix` returns 0 matches.
    - `grep -nF 'install -g --ignore-scripts --force oh-my-' modules/darwin/user-home.nix` returns 2 matches (one for `oh-my-codex`, one for `oh-my-opencode`).
    - `nix-instantiate --parse modules/darwin/user-home.nix` exits 0 (cheap Nix syntax check, run from `cd /home/mei/nix-config`).
    - **Symmetry check** (the actual structural test): extract the `installCodingAgents` block from both files using `awk '/home.activation.installCodingAgents/,/^  '';/'`, strip the file-specific Nix interpolation paths (`${config.home.homeDirectory}` from standalone, `${user.identity.home}` from Darwin), and `diff` them. The diff must be empty (or show only whitespace) — proves both blocks are byte-identical after the patch. Note: do NOT use `sed -n '58,89p'` for standalone (that range is wrong — it includes the bottom of `home.packages`); use the `awk` extraction to be range-independent.
  QA scenarios (name the exact tool + invocation): happy + failure:
    - Happy path: `git diff --stat modules/darwin/user-home.nix` shows the file changed by roughly the same number of lines as the standalone patch.
    - Failure-path repro: `grep -nE 'nodeBin|lib.getBin' modules/darwin/user-home.nix` returns no matches (proves dead PATH manipulation is fully gone, no future contributor can re-introduce a broken variant).
    - Symmetry check (real): the `awk` extraction + `diff` above returns empty output.
  Evidence: structural verification (Darwin activation is theoretical — the user is on standalone Linux; verification of Darwin is via `nix-instantiate --parse` + the symmetry `diff`, not a runtime activation). The activation log in Todo 3 covers runtime behavior on standalone.
  Commit: Y | fix(home-manager): prevent install-coding-agents activation failure from npm postinstall (bundled with Todo 1 in one commit)

- [x] 3. Run `nix run .#home-switch` end-to-end and verify the activation log has no `node: command not found`
  What to do / Must NOT do: Run `nix run .#home-switch` (from `cd /home/mei/nix-config`) and capture the full stdout+stderr to `/tmp/activation-log-fix-install-coding-agents-node-not-found.txt`. Grep the log for `Activating installCodingAgents`, the 7 tool names, `node: command not found`, and `npm error code 127`. Report each match as either PASS or FAIL. Do NOT skip the run even if a previous activation succeeded — the entire point is to exercise the patched script. Do NOT redirect output through a pager. Do NOT modify the activation script between run and grep — the run must reflect the patched files exactly.
  Parallelization: Wave 2 | Blocked by: 1, 2 | Blocks: F1, F2, F3, F4
  References (executor has NO interview context - be exhaustive):
    - `README.md` (root) "Existing Linux installs" section documents `nix run .#home-switch` as the canonical command for this target.
    - `.omo/drafts/fix-install-coding-agents-node-not-found.md` Findings F1 — the original failure signature: `npm error code 127`, `npm error path /home/mei/.local/lib/node_modules/oh-my-codex`, `npm error command sh -c node -e "..."`, `npm error sh: line 1: node: command not found`.
    - `tests/dendritic-config-eval.nix:312-353` — the existing config-eval checks that already assert `standalone.home.username == "mei"`, `standalone.home.stateVersion == "25.11"`, and `assertHm standalone`. These are not affected by this fix but prove the config evaluates.
  Acceptance criteria (agent-executable):
    - `nix run .#home-switch` (run from `cd /home/mei/nix-config`) exits 0 OR exits non-zero ONLY for the `sublimetext4-4200` upstream evaluation warning listed in draft §Scope-OUT. Any other non-zero exit is a failure.
    - `grep -c 'Activating installCodingAgents' /tmp/activation-log-fix-install-coding-agents-node-not-found.txt` ≥ 1.
    - For each of `codex`, `omx`, `omo`, `opencode`, `pi`, `hermes`, `zeroclaw`, `grep -c 'install-coding-agents: \(already present\|installing\|installed\|WARNING\)' /tmp/activation-log-fix-install-coding-agents-node-not-found.txt` ≥ 1 match mentioning that name (proves each tool's line fired).
    - `grep -cE 'node: command not found|npm error code 127' /tmp/activation-log-fix-install-coding-agents-node-not-found.txt` = 0.
    - `tail -20 /tmp/activation-log-fix-install-coding-agents-node-not-found.txt` shows Home Manager reporting success (e.g. "Activating checkFilesChanged" downstream without an early-exit error).
    - `codex --version` and `omx --version` (run from a fresh shell AFTER activation) both exit 0 with a version string — proves `@openai/codex` (whose install we left unchanged) still works and that `oh-my-codex` produces a working binary even without its native-binary-downloading postinstall.
  QA scenarios (name the exact tool + invocation): happy + failure:
    - Happy: activation log shows `install-coding-agents: codex already present, skipping` (or `installed`) followed by similar lines for the other 6 tools; no `node: command not found`.
    - Failure-regression: if the patch were rolled back, the original failure signature (`npm error code 127`, `node: command not found`) would re-appear in the log. The agent must NOT roll back the patch — instead, the agent reports the current state and stops if any acceptance criterion fails.
    - Idempotency: run the activation a second time; all 7 tools should report `already present, skipping` (or `installed`) without npm re-fetching from the registry.
  Evidence: `/tmp/activation-log-fix-install-coding-agents-node-not-found.txt` (full capture of `nix run .#home-switch` output).
  Commit: N (verification only)

## Final verification wave

> Runs in parallel after ALL todos. ALL must APPROVE. Surface results and wait for the user's explicit okay before declaring complete.

- [x] F1. Plan compliance audit
- [x] F2. Code quality review
- [x] F3. Real manual QA
- [x] F4. Scope fidelity

## Commit strategy

Single commit after Todos 1 + 2 land (Todo 3 is verification-only and produces no commit). Subject: `fix(home-manager): prevent install-coding-agents activation failure from npm postinstall`. Body references both files changed, specifies that `--ignore-scripts` is applied to the `omx` and `omo` lines only (not `codex`), cites `pkgs/codex-omx.nix:27-28` and `pkgs/opencode-omo.nix:33-34` as the precedent. Deferred follow-up (curl|bash refactor, standalone derivation enablement, version pinning, error-trapping wrap) is mentioned in the draft at `.omo/drafts/fix-install-coding-agents-node-not-found.md` Findings F3 and Open assumptions — not in this commit.

## Success criteria

- Both `modules/standalone-linux/home-manager.nix:58-89` and `modules/darwin/user-home.nix:29-60` contain the patched activation block.
- `grep ignore-scripts modules/{standalone-linux,darwin}/{home-manager,user-home}.nix` shows exactly 2 matches per file (4 total) — proves the flag is on `omx` and `omo` only.
- `grep -E 'nodeBin|lib.getBin pkgs.nodejs' modules/{standalone-linux,darwin}/{home-manager,user-home}.nix` shows 0 matches — dead PATH manipulation fully removed.
- `nix run .#home-switch` exits 0 (or non-zero only for the unrelated `sublimetext4-4200` upstream warning) and the activation log shows zero `node: command not found` and zero `npm error code 127`.
- All 7 `install-coding-agents: ...` lines report success or skip for every tool.
- The two patched files' `installCodingAgents` blocks differ ONLY in Nix interpolation paths (`${config.home.homeDirectory}` vs `${user.identity.home}`), not in bash logic (verified by `awk` extraction + `diff`).
- `codex --version` and `omx --version` both exit 0 post-activation — proves `codex`'s unanalyzed postinstall still works and `omx`'s missing native-binary postinstall does not break the binary.
- The final verification wave (F1-F4) all APPROVE.
