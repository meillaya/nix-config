# Plan: Coding agents update — drop omx, add lazycodex/kimi/hermes/zeroclaw, pin oh-my-openagent

Status: DRAFT (research complete; Momus review pending)
Date: 2026-08-11

## 1. Requested changes

1. **Remove omx** (oh-my-codex, Yeachan-Heo/oh-my-codex — NOT code-yeongyu) as a codex agent.
2. **Add lazycodex** (code-yeongyu/lazycodex) as the codex harness — the "Light edition" of
   oh-my-openagent, installed into codex as a plugin (marketplace `sisyphuslabs`, plugin `omo`).
3. **Add kimi cli** (@moonshot-ai/kimi-code, Moonshot AI) — standalone TUI agent, binary `kimi`.
4. **Add hermes cli** (NousResearch/hermes-agent) — standalone agent, binary `hermes`.
5. **Add zeroclaw** (zeroclaw-labs/zeroclaw) — standalone Rust agent runtime, binary `zeroclaw`,
   installed per the repo's own rules (prebuilt release tarball, checksum-verified).
6. **oh-my-openagent must be included as the opencode harness** — already satisfied by
   `pkgs/opencode-omo.nix` (npm `oh-my-opencode` = oh-my-openagent mid-rename; the derivation's
   description literally reads "Oh-my-openagent harness for Opencode"); action = bump pin.

Machines in scope: **Mac mini (aarch64-darwin)** + **this PC / ThinkPad (standalone-linux)** —
the same platforms where the existing `installCodingAgents` activation and `*-wrapped` wrappers
live. NixOS hosts are evaluation-only; unchanged.

## 2. Research findings (librarian, verified Aug 2026)

| Tool | What it is | Official install | Repo license | Config/state |
|---|---|---|---|---|
| **omx** (oh-my-codex) | Codex workflow layer; **different author** (Yeachan-Heo, npm `bellman_04`) | `npm i -g oh-my-codex` | MIT | `.omx/` per project |
| **lazycodex** | Codex plugin harness (OmO Light). Not a standalone CLI — `$command`s inside codex | `npx lazycodex-ai install` (TUI; Node LTS + codex logged in) | MIT repo / SUL-1.0 npm | `~/.codex/config.toml`, `~/.codex/plugins/cache/sisyphuslabs/omo/`, `~/.codex/agents/`, CLIs symlinked to `~/.local/bin` |
| **kimi** | Standalone TUI coding agent (like codex) | `npm i -g @moonshot-ai/kimi-code` (needs node ≥ 22.19) or official curl script → `~/.kimi-code` | MIT | `~/.kimi-code/config.toml`; PATH for `~/.kimi-code/bin` **already wired** in this repo |
| **hermes** | Standalone autonomous agent framework (Python/uv) | `uv tool install hermes-agent` (PyPI `hermes-agent`, requires python ≥3.11,<3.14) or `curl …/install.sh` (TTY-interactive) | MIT | `~/.hermes/config.yaml` |
| **zeroclaw** | Standalone Rust agent runtime (assistant infra, not codex-style) | Prebuilt release tarball `zeroclaw-${triple}.tar.gz` from GitHub releases (checksum-verified); NOT in nixpkgs (#5987) | MIT OR Apache-2.0 | `~/.zeroclaw/config.toml`; repo ships `AGENTS.md`/`CLAUDE.md` ("the repos rules") |
| **oh-my-openagent** (opencode harness) | OpenCode plugin/harness; npm name still `oh-my-opencode` (dual-published rename; GitHub repo 301s to oh-my-openagent) | **npm-only — GitHub releases contain ZERO binaries** | SUL-1.0 (platform launchers MIT) | Registers in `opencode.json` plugin array; `~/.omo/omo.jsonc`; cache `~/.cache/opencode/packages/` |

Key corrections to prior assumptions:
- omx is **not** code-yeongyu's; the codex-side product of the oh-my-openagent family is **lazycodex**.
- oh-my-openagent's GitHub **releases page has no binaries** — the pinned npm tarball in
  `pkgs/opencode-omo.nix` IS the correct distribution channel.

## 3. Changes by file

### 3.1 Remove omx — `modules/linux/home-manager.nix`
- Delete the Dolphin service-menu `CopyPath` action (lines 436-439) that execs
  `omx-copy-path-to-clipboard`.
- Delete `home.file.".local/bin/omx-copy-path-to-clipboard"` (lines 758-776).
- Regression: `tests/readiness/task22/identity_static.py:19` already asserts no
  `oh-my-codex-sidecar` remains — keep as-is (it flips green after removal).
- `pkgs/codex-omx.nix` + lockfile already deleted (uncommitted); nothing else references them
  (verified by grep).
- Machine-side: after switch, remove any `omx` plugin entry from `~/.codex/config.toml` on each
  machine (documented in runbook).

### 3.2 oh-my-openagent harness — `pkgs/opencode-omo.nix` (+ activation line) → **5.0.0-beta.7**
- User-approved bump target; **reviewed 2026-08-13: beta.7 is now the latest beta** (release
  notes v5.0.0-beta.7 published; install lines `bun i -g oh-my-opencode@beta` /
  `oh-my-openagent@beta` / `lazycodex-ai@beta`). Pin **`5.0.0-beta.7`** (npm `beta` dist-tag
  on both `oh-my-opencode` and dual-published `oh-my-openagent`).
- `version = "5.0.0-beta.7"`; `src.url` = npm tarball
  `https://registry.npmjs.org/oh-my-opencode/-/oh-my-opencode-5.0.0-beta.7.tgz`;
  `hash` via fake-hash + build. Do NOT switch to GitHub releases (no binaries there).
- **Bin rename (5.0 breaking change):** the `omo` bin is REMOVED in 5.x — the launcher bin is
  now `omo-agent-toolkit` (postinstall rename notice per research). Therefore:
  - `postInstall` `makeWrapper $out/bin/omo …` must become `$out/bin/omo-agent-toolkit`.
  - The npm activation lines (darwin + standalone-linux): `install_if_missing omo …` must become
    `install_if_missing omo-agent-toolkit "${npm} install -g --ignore-scripts --force oh-my-opencode@5.0.0-beta.7"`
    (name check + version pin both change; 4.19.4's `omo` name check would never match on 5.0).
  - Verify at implementation time whether the beta.7 tarball still needs the postPatch
    lockfile/manifest injection (workspaces layout may differ) and whether the bin map changed
    further.
- beta.7 release-notes facts relevant here: `omo update` now detects Bun-vs-npm installs and
  prints the matching command; install paths with spaces/`$`/quotes get correctly shell-quoted
  update commands (our paths are plain `/Users/mei`, `$HOME` — unaffected); all Senpi
  workspace pins moved to `@code-yeongyu/senpi@2026.8.12-4`; single shared `$HOME/.omo/agent`
  state dir for nested processes (one agent home — good, matches our `~/.omo` expectations).
- Keep `--ignore-scripts` + postPatch pattern (postinstall cache-invalidation not needed in a
  store build). Derivation and npm activation must track the SAME version — no mixing.

### 3.3 kimi — activation + wrapper
- `modules/darwin/user-home.nix` + `modules/standalone-linux/home-manager.nix`, in
  `installCodingAgents`: add `install_if_missing kimi "${npm} install -g --force @moonshot-ai/kimi-code"`.
  - Verify `pkgs.nodejs` ≥ 22.19 (nixpkgs nodejs_22/24 current is fine; if the alias is older,
    use `${pkgs.nodejs_24}/bin/npm` explicitly).
- Add `kimi-wrapped` sops wrapper next to the existing wrappers in each file (darwin
  `user-home.nix` currently has pi/hermes/zeroclaw-wrapped; standalone-linux has
  codex/pi/hermes/zeroclaw-wrapped), and optionally in `modules/aspects/users/mei.nix` next
  to `codex-wrapped` for the shared aspect.
- PATH for `~/.kimi-code/bin` is already exported in bash/fish/zsh/nushell — no change needed.

### 3.4 hermes — automated install (was: manual)
- Wrapper `hermes-wrapped` already exists (darwin + standalone-linux) — no change.
- Replace the "install manually" note for hermes with activation line:
  `install_if_missing hermes "${uv}/bin/uv tool install hermes-agent"` (uv is already a package
  on both platforms; `uv tool install` is non-interactive and idempotent; binary lands in
  `~/.local/bin/hermes` which is on PATH).
- Update the activation comments (lines ~51-53 / ~80-82) that list pi/hermes/zeroclaw as
  manual-only — hermes becomes automated; pi stays manual (not in this request's scope; pi
  wrapper remains as-is).

### 3.5 zeroclaw — Nix derivation (most declarative; repo rules = prebuilt tarball)
- New `pkgs/zeroclaw.nix`: `fetchurl` the checksum-verified release tarball
  (`zeroclaw-aarch64-apple-darwin.tar.gz` on darwin, `zeroclaw-x86_64-unknown-linux-gnu.tar.gz`
  on linux — exact triple per latest release v0.8.x assets), `install` the `zeroclaw` binary;
  per-system src via `stdenv.hostPlatform` mapping; license `MIT OR Apache-2.0`.
- Add to package lists: `modules/darwin/packages.nix` (darwin) and the coding-agent derivations
  block of `modules/shared/packages.nix` (linux; alongside `opencode-omo`), or directly into
  `modules/standalone-linux/packages.nix`.
- Wrapper `zeroclaw-wrapped` already exists — no change.
- "Per the repos rules": the repo's `AGENTS.md`/`CLAUDE.md` working rules are about *working in
  their repo*, not our install; our install follows the official prebuilt-binary rule. Note this
  in the plan/README so it's not misread.

### 3.6 lazycodex — manual one-time install (TUI installer; cannot automate)
- The installer is TTY-interactive (`npx lazycodex-ai install`) — same class as pi/hermes/zeroclaw
  previously. Run once per machine as a documented runbook:
  1. `npx lazycodex-ai install` (or `--no-tui --codex-autonomous` for unattended autonomous mode)
  2. Ensure `~/.local/bin` on PATH (already is in this config) or set `$CODEX_LOCAL_BIN_DIR`
  3. Verify: `npx lazycodex-ai doctor`
- Precondition: `codex` installed + logged in (already handled by `installCodingAgents`).
- Document in README; note lazycodex = the codex-side omo harness (replaces omx in role).

### 3.7 Secrets — `secrets/coding-agents.yaml` (user action, sops)
- Existing keys already cover hermes (ANTHROPIC/GEMINI/OPENROUTER) and zeroclaw
  (OPENAI/ANTHROPIC/GEMINI/OPENROUTER); lazycodex rides codex auth.
- kimi: add `MOONSHOT_API_KEY` (or use `kimi`'s `/login` OAuth — no secret needed). Encrypt via
  `sops` with the existing recipients (2 age recipients already in the file).
- Wrappers inject these via `sops exec-env` — no code change needed beyond the new key.

### 3.8 Docs
- README: add a coding-agents section (README has no such section today — the only "install
  manually" hints live in activation comments referencing "see README") with the new matrix
  (kimi/hermes/zeroclaw automated; lazycodex manual runbook; omx removed).
- Note `OMO_DISABLE_POSTHOG=1` telemetry opt-out for the omo harness (optional hardening; could
  be added to `opencode-wrapped` env).

## 4. Verification

1. `nix eval .#apps.x86_64-linux --apply builtins.attrNames` and darwin eval unchanged (no flake
   app surface change).
2. `nix flake check` (tests: identity_static.py must pass with omx gone).
3. Home-manager configs evaluate: `nix eval .#darwinConfigurations.aarch64-darwin.system.drvPath`
   and the standalone home config drvPath.
4. `nix build .#nixosConfigurations.x86_64-linux.config.system.build.toplevel` NOT required
   (linux/home-manager.nix change affects home configs — verify via HM eval instead).
5. On-machine after switch: `kimi --version`, `hermes --version`, `zeroclaw --version`,
   `omo --version` (4.19.4), `npx lazycodex-ai doctor`; grep for `omx` in `~/.codex/config.toml`.
6. Commit only after user approval.

## 5. Risks / notes

- **kimi node version**: npm path needs node ≥ 22.19 — pin `nodejs_24` in the activation command
  if `pkgs.nodejs` is older.
- **hermes uv install** pulls its own Python (3.11-3.13) — needs network at activation; idempotent.
- **zeroclaw derivation**: exact release asset naming per platform must be confirmed against the
  latest release at implementation time; hash pin required.
- **lazycodex cannot be automated** (TUI) — the manual runbook is the only option; `--no-tui`
  exists for autonomous install if the user prefers.
- **5.0 is a beta**: expect churn (5.0 already renamed `omo` → `omo-agent-toolkit`). The
  derivation and the npm activation must move together and stay pinned to the same version;
  re-verify the bin map and postPatch needs against the actual 5.0.0-beta.6 tarball at
  implementation time.
- **telemetry**: omo harness (PostHog) is default-on; set opt-out env in wrappers if desired.
- omx removal touches KDE Dolphin service menus — the `CopyPath` action disappears on Linux;
  a generic clipboard action is not restored (out of scope; note in commit message).

## 6. Out of scope

- NixOS host agent wiring (evaluation-only).
- Adding `pi` beyond its existing wrapper (not requested).
- Migrating omo to 5.x / `omo-agent-toolkit`.
- Agent rules files (AGENTS.md/CLAUDE.md content) for this repo itself.

## 7. Ledger

- `event=task-start` | `plan=coding-agents-update` | `task=P2-T2-followup (unfree pin)` | `session_id=ses_00d883f2bffe7yTRuX5T3r0DY4` | `commands=[python3 -m json.tool, grep -c]` | `artifact=<config/package-exceptions.json rows 306-333: version 4.19.2→5.0.0-beta.7 + reviewedAt 2026-07-27→2026-08-14 for the 3 opencode-omo rows>` | `adversarial_classes={dirty_worktree: no-reset (file already carries a pre-existing uncommitted -55 diff — leave the rest untouched), stale_state: version-matches-derivation}` | `cleanup=none`
- `event=task-start` | `plan=coding-agents-update+machine-enrollment-darwin` | `task=DOCS` | `session_id=ses_005291ec5ffegNM2XuCveSGxf1` | `commands=[grep stale-phrases]` | `artifact=<README.md macOS/NixOS/coding-agents sections, docs/architecture/dendritic.md L130-149, docs/service-notes/homebrew-free-migration.md L53-57: removed evaluation-only/operationally-disabled/build-only/reserved-until-enrolled/build-switch-not-exposed language>` | `adversarial_classes={dirty_worktree: no-reset, misleading_success_output: verified-stale-phrases-gone}` | `cleanup=none`

## 8. Status: COMPLETED

- [x] Executed 2026-08-14 via /start-work (Atlas orchestration, 9 parallel workers + verify wave).
- [x] Verified: omo-agent-toolkit --version → 5.0.0-beta.7 (in-repo build, unfree pin updated);
      zeroclaw 0.8.4 built + `zeroclaw --version` verified; zeroclaw present in standalone-linux
      home packages; all plan-scoped `nix flake check` checks pass.
- [x] Committed: `8240ef0` (coding agents; docs shared in `8de1a88`).
- [x] Boulder: coding-agents-update work marked completed.
- [~] Deferred (user action on machines, documented in README): one-time `npx lazycodex-ai install`
      per machine; `MOONSHOT_API_KEY` in secrets/coding-agents.yaml (or kimi `/login`); Mac switch via
      `nix run .#build-switch` after pull.
