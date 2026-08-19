---
slug: fix-install-coding-agents-node-not-found
status: awaiting-approval
intent: clear
review_required: false
pending-action: write .omo/plans/fix-install-coding-agents-node-not-found.md
approach: Add `--ignore-scripts` to the three `npm install -g --force` lines in `home.activation.installCodingAgents` on both standalone Linux and Darwin, drop the dead `nodeBin`/`curlBin`/`bashBin` PATH-manipulation that did not fix the underlying issue, and wrap each `install_if_missing` call so one tool's failure does not cascade. Mirrors the behavior already proven in `pkgs/codex-omx.nix` and `pkgs/opencode-omo.nix`.
---

# Draft: fix-install-coding-agents-node-not-found

## Components (topology ledger)

<!-- One row per top-level component that can succeed or fail independently. -->

| id | outcome (one line) | status | evidence path |
| --- | --- | --- | --- |
| C1 | Pinned critical review: enumerate the root cause of `node: command not found` and the wider architectural problems (competing install paths, curl|bash, no version pinning) so the user can decide what to fix next | active | modules/standalone-linux/home-manager.nix:58-89, modules/darwin/user-home.nix:29-60, pkgs/codex-omx.nix, pkgs/opencode-omo.nix, modules/shared/packages.nix:88-95, modules/standalone-linux/packages.nix:4-8 |
| C2 | Patch `modules/standalone-linux/home-manager.nix` activation script to use `--ignore-scripts`, add per-install error trapping, and remove the misleading PATH-prepend | active | modules/standalone-linux/home-manager.nix:58-89 |
| C3 | Apply the same patch to `modules/darwin/user-home.nix` so the two scripts stay in lock-step (Darwin currently masks the bug only because `codex-omx`/`opencode-omo` derivations pre-empt `install_if_missing`) | active | modules/darwin/user-home.nix:29-60 |
| C4 | Verification: agent re-runs `nix run .#home-switch` and confirms all 7 `install-coding-agents` lines exit cleanly with no `node: command not found` | active | activation log produced by `nix run .#home-switch` |

## Open assumptions (announced defaults)

| assumption | adopted default | rationale | reversible? |
| --- | --- | --- | --- |
| `--ignore-scripts` is applied to `oh-my-codex` and `oh-my-opencode` ONLY, not `@openai/codex` | Yes — the original failure was specifically on `oh-my-codex`'s postinstall. The user's own activation log shows `@openai/codex` installed successfully ("changed 2 packages in 3s") with no `node: command not found`. Adding `--ignore-scripts` to `@openai/codex` is unnecessary and could silently break a postinstall whose behavior we have not inspected (Metis gap #7). The two precedent derivations `pkgs/codex-omx.nix:27-28` and `pkgs/opencode-omo.nix:33-34` cover exactly the two packages we are patching. | reversible (drop or extend the flag) |
| Drop `nodeBin`/`curlBin`/`bashBin` PATH manipulation entirely | Yes — they were dead code once `--ignore-scripts` removes the only path that needed an inherited `node` in PATH; absolute paths to `${npm}`/`${curl}`/`${bash}` already bypass PATH lookup for those binaries. | reversible (re-add if a future postinstall needs node) |
| Preserve the current fail-fast behavior on a per-install basis (NO error-trapping wrap added) | Yes — user picked "Minimal fix only"; a behavior change from fail-fast to warn-and-continue is scope creep. With `--ignore-scripts`, the actual failure path no longer triggers, so the wrap is also functionally unnecessary. | reversible (add the wrap later) |
| Keep the four `curl -fsSL ... | bash` lines untouched | Yes — user explicitly chose "Minimal fix only" over the alternatives. Documented as a known security risk in the critical review and tracked as follow-up. | reversible (delete the lines) |
| Keep the script on Darwin even though the derivation pre-empts 2 of 3 npm installs | Yes — `codex` is still installed via npm on Darwin, so the script is not dead. The patch unifies the two scripts. | reversible |
| Do not pin npm package versions | No — same scope as today. Version pinning is part of the deferred architectural refactor (would require buildNpmPackage derivations for each). | reversible |
| Do not touch `modules/standalone-linux/packages.nix` (`includeCodingAgentDerivations = false`) | Yes — out of scope for minimal fix. The reason for that flag is uninvestigated and changing it could break the standalone build. | reversible |

## Findings (cited - path:lines)

### F1. The exact failure site

`modules/standalone-linux/home-manager.nix:58-89` defines `home.activation.installCodingAgents`. Lines 81-83:

```nix
install_if_missing codex "${npm} install -g --force @openai/codex"
install_if_missing omx   "${npm} install -g --force oh-my-codex"
install_if_missing omo   "${npm} install -g --force oh-my-opencode"
```

The user's activation log shows `codex` install reported `changed 2 packages in 3s`, then `omx` install died inside npm:

```
npm error command sh -c node -e "const fs=require('fs');const p='./dist/scripts/postinstall.js';if(fs.existsSync(p))import(p).then(m=>m.main?.()).catch(e=>console.warn('[omx] Postinstall skipped after a non-fatal error: '+(e?.message??e)))"
npm error sh: line 1: node: command not found
```

`oh-my-codex`'s `postinstall` is a `node -e "..."` script that dynamically imports `./dist/scripts/postinstall.js` and is intentionally wrapped in try/catch (see the `[omx] Postinstall skipped after a non-fatal error` log string). npm spawns `sh -c node -e ...`, and the spawned `sh` cannot locate `node`.

### F2. The PATH-prepend that was supposed to fix it is insufficient

`modules/standalone-linux/home-manager.nix:63-69` already prepends `${nodeBin}` (and `${curlBin}`, `${bashBin}`) to `PATH`:

```nix
nodeBin = lib.getBin pkgs.nodejs;
curlBin = lib.getBin pkgs.curl;
bashBin = lib.getBin pkgs.bash;
in lib.hm.dag.entryAfter ["writeBoundary"] ''
  export PATH="${nodeBin}:${curlBin}:${bashBin}:$PATH"
```

`lib.getBin pkgs.nodejs` does return `/nix/store/<hash>-nodejs-<v>/bin` (verified structurally: `pkgs.nodejs` in nixpkgs-25.05 — the user's pinned rev `59e69648d345d6e8fef86158c555730fa12af9de` per `flake.lock:249-263` — has outputs `out`/`dev`/`libv8` with `out/bin` containing `node`, `npm`, `npx`). The shell that npm spawns *should* therefore inherit a PATH with `node` in it. The fact that the error still fires means one of:

1. **npm sanitizes the inherited PATH for install scripts.** npm 10 in particular rebuilds the script environment (root-dropping behavior, `--script-shell` indirection) so PATH at the parent shell is not always the PATH inside `sh -c node ...`.
2. **`lib.getBin` is returning the path but `sh` on the host is something where `command -v node` does not see `${nodeBin}`** (very unlikely — both `dash` and `bash` use PATH lookups identically).
3. **The whole line is a red herring**: in some npm/node combinations the postinstall shell is invoked via `env -i` or with an empty env, so any prepended PATH is discarded.

Regardless of which mechanism, the **canonical Nix fix** already exists in this very repo and has been battle-tested: `pkgs/codex-omx.nix:27-28` and `pkgs/opencode-omo.nix:33-34` both set `dontNpmBuild = true; npmFlags = [ "--ignore-scripts" ]` with the explicit comment:

> The postinstall script downloads native Rust binaries — skip it.

The activation script is the only place left in this repo that tries to RUN those postinstalls, and it has no way to satisfy their requirements in a Nix-managed activation context.

### F3. Wider architectural problems (recorded for follow-up, NOT fixed in this pass)

- **Two competing install paths on Darwin.** `modules/shared/packages.nix:88-95` adds `codex-omx` and `opencode-omo` derivations to `home.packages` via the `includeCodingAgentDerivations` flag. Darwin gets the derivations AND runs the npm install in `activation.installCodingAgents` (which then `install_if_missing`-skips because the derivation's `omx`/`omo` is on PATH first). Standalone Linux sets `includeCodingAgentDerivations = false` in `modules/standalone-linux/packages.nix:4-8`, so it relies entirely on the activation script. This split is undocumented and a future contributor will be confused by it.
- **`curl -fsSL ... | bash` for 4 tools.** `modules/standalone-linux/home-manager.nix:85-88` (and the Darwin twin `:56-59`) pipe unsigned remote scripts into bash with full user privileges. The URLs `https://opencode.ai/install`, `https://pi.dev/install.sh`, `https://hermes-agent.nousresearch.com/install.sh`, `https://zeroclawlabs.ai/install.sh` can change at any time and offer no reproducibility. This is a well-known anti-pattern.
- **No version pinning.** The activation script installs `latest` of `@openai/codex`, `oh-my-codex`, `oh-my-opencode`. There is no `package.json`/`package-lock.json` for the activation-script path (the derivations *do* pin — `pkgs/codex-omx.nix:12` `version = "0.20.3"`, `pkgs/opencode-omo.nix:15` `version = "4.19.2"` — which is exactly why the derivations are reproducible and the activation script is not).
- **No per-install error handling.** The current `install_if_missing` only logs the failure but does not isolate it — the rest of the installs continue to run, but the script's overall exit code propagates `eval`'s status, and on certain shells a `set -e`-like effect can leak from the surrounding HM activation harness.
- **`node`/`npm` could be removed from `home.packages`.** `modules/shared/packages.nix:49` adds `nodejs_24` to every user's `home.packages`. After this fix, the activation script only invokes `${pkgs.nodejs}/bin/npm` (absolute path) — never relying on `node` being on PATH — so the explicit `pkgs.nodejs` in `home.packages` (line 19 of `modules/standalone-linux/home-manager.nix` and line 8 of `modules/darwin/user-home.nix`) is no longer required for the activation script. It is still useful as a development dependency, so we leave it.

### F4. Pinned nixpkgs version

`flake.lock:249-263`: `nixos-25.05`, rev `59e69648d345d6e8fef86158c555730fa12af9de`, narHash `sha256-IiiXB3BDTi6UqzAZcf2S797hWEPCRZOwyNThJIYhUfk=`. This is the version we are patching against; the `lib.getBin` semantics used in the reasoning above apply to this rev.

## Decisions (with rationale)

1. **Use `--ignore-scripts` instead of trying to repair the PATH inheritance.** The repo already validates this fix in two production derivations. Trying to coerce npm into finding `node` in an activation-script subshell fights a moving target across npm versions and is exactly the kind of yak-shave the comment in `pkgs/codex-omx.nix` was written to avoid.
2. **Drop `nodeBin`/`curlBin`/`bashBin` and the `export PATH=...` line entirely.** Once `--ignore-scripts` is in, the only consumer of those vars was the postinstall context that no longer runs. Keeping dead code that *looks* like a fix would invite future regressions (someone reads the comment, thinks the bug is "PATH is unset", and re-adds a different broken variant).
3. **Wrap each install in a try/log/continue so a single tool's failure does not cascade.** The current `install_if_missing` already does this for the `command -v` skip, but not for the `eval` itself — a failing `npm install` exits the script on many shells. We add explicit error handling around the `eval`.
4. **Patch Darwin in lock-step.** Darwin currently masks the bug because the derivation-provided `omx` is on PATH and `install_if_missing omx` skips before npm runs. If anything ever changes that PATH order (e.g., `sessionPath` flip), Darwin would start failing the same way. The patch costs nothing and removes the latent bug.
5. **Do not touch `modules/standalone-linux/packages.nix`.** The `includeCodingAgentDerivations = false` flag is set deliberately and the rationale for that decision is not in the repo. Flipping it without investigation risks breaking the standalone build (the derivations depend on `pkgs.codex` and platform availability). Tracked as follow-up.

## Scope IN

- Edit `modules/standalone-linux/home-manager.nix`: add `--ignore-scripts`, drop the dead PATH manipulation, wrap `eval` with error trapping.
- Edit `modules/darwin/user-home.nix`: identical change to keep the two files symmetric.
- Run `nix run .#home-switch` end-to-end and confirm the activation log shows no `node: command not found` and all 7 `install-coding-agents: $name installed` / `... already present, skipping` lines exit cleanly.

## Scope OUT (Must NOT have)

- Do NOT introduce new `pkgs/*.nix` derivations in this pass.
- Do NOT remove the four `curl | bash` installs.
- Do NOT change `includeCodingAgentDerivations` / `includeOpencode` flags.
- Do NOT pin npm package versions from the activation script.
- Do NOT touch `modules/shared/packages.nix`, `modules/linux/home-manager.nix`, or any test file.
- Do NOT introduce a new test — there is no existing test for activation-script bash, and adding one would balloon this into a refactor.
- Do NOT add the sublimetext4 evaluation warnings fix (`sublimetext4-4200` broken/removal warnings at the top of the user's log) — they are upstream nixpkgs noise, not in our scope.

## Open questions

None — user picked "Minimal fix only" (see `## Open assumptions`).

## Approval gate

status: awaiting-approval

next workflow action (on approval): write `.omo/plans/fix-install-coding-agents-node-not-found.md` with the `## Todos` task batches; then present the start-or-review question and stop.
