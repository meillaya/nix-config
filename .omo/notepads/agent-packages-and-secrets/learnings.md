
## 2026-07-27T23:15 Session start (new plan execution)
- Pre-existing uncommitted changes in modules/shared/home-manager.nix and modules/standalone-linux/home-manager.nix (PATH cleanup + git signByDefault). NOT part of this plan.
- Previous plan "secrets-stack-and-packages" completed - sops-nix, secretspec, agenix already wired.
- On x86_64-linux. omniwm is aarch64-darwin only - cannot build locally.
- buildNpmPackage with generated lockfiles is proven (Oracle verified fetchurl+makeWrapper crashes).
- postPatch (NOT postUnpack) required for lockfile injection in buildNpmPackage.

## 2026-07-27: Added hydralauncher + vesktop to linux packages
- File: modules/linux/packages.nix — main list (lines 4-69 area)
- hydralauncher placed after halloy (alphabetical in Cross-Linux section)
- vesktop placed after virt-manager, before vlc
- Both verified via nix eval returning 1

## omniwm.nix (binary derivation)
- Created `pkgs/omniwm.nix` using `stdenvNoCC` (no ELF patching needed for macOS binary)
- Added `dontBuild = true` (prebuilt binary, no compilation)
- ZIP root contains `Contents/` directly (not wrapped in `OmniWM.app/`), so installPhase copies `Contents` into `$out/Applications/OmniWM.app/`
- `nix-instantiate --parse` passes; `nix eval` of meta/pname/version passes
- `drvPath` eval fails on x86_64-linux due to platform assert (`platforms = [ "aarch64-darwin" ]`) — this is expected and correct
- No `<nixpkgs>` channel on this machine; used `builtins.getFlake` + flake inputs for eval

## 2026-07-27 codex-omx package (buildNpmPackage)
- src hash: sha256-tsrP8puzUN9++Q1YnbAuX5b9fRT+J04Hk50O+w9Buu0=
- npmDepsHash: sha256-3IZ3EAEMo8oMrHSbItMxIhdBdw5pQ7qxsyocqVrTMzM=
- Lockfile generated via: npm install --package-lock-only --ignore-scripts (2396 lines, lockfileVersion 3)
- Build verified: result/bin/codex --version → "oh-my-codex v0.20.3"
- Both `omx` and `codex` (wrapper) binaries installed; codex wraps omx with codex on PATH
- Hash discovery used `nix build --impure --expr` with flake's nixpkgs (no <nixpkgs> in NIX_PATH)
- `.#codex-omx` flake output not yet wired (separate todo 7)

## 2026-07-27 opencode-omo package (buildNpmPackage)
- src hash: sha256-4y08SVBhz8NzOtFc+DLOx66oqUEIOwnB6uY6mZiZIS4=
- npmDepsHash: sha256-5UAlXz0lYSyF2ujpWe2cJN1ylwH93S6Kv6rhMW2W+No=
- CRITICAL: Must strip `scripts` in addition to `workspaces` and `devDependencies` from package.json
  - `scripts.prepare` = "bun run build" — npm pack runs prepare even with --ignore-scripts in some code paths
  - npmInstallHook's `npm pack --json --dry-run` triggers prepare → bun not found → jq parse error → cp failure
  - Stripping all scripts (jq 'del(.workspaces, .devDependencies, .scripts)') fixes the build
- Lockfile regenerated after stripping scripts (npm install --package-lock-only --ignore-scripts)
- Build verified: result/bin/opencode --version → "4.19.2"
- 6 binaries installed: lazycodex, lazycodex-ai, oh-my-openagent, oh-my-opencode, omo, opencode (wrapper)
- opencode wraps omo with opencode on PATH via makeWrapper
- 3 package-exceptions.json rows added: x86_64-linux, aarch64-linux, aarch64-darwin (NO x86_64-darwin, NO standalone-linux)
- `.#opencode-omo` flake output not yet wired (separate todo 7)
- Hash discovery used `nix build --impure --expr` with flake's locked nixpkgs rev (no <nixpkgs> in NIX_PATH)

## Wiring custom packages into platform package lists (2026-07-27)
- Nix flakes require git-tracked files. `pkgs/*.nix` must be `git add`-ed before `nix eval` can see them via `callPackage`.
- `pkgs.callPackage ../../pkgs/<name>.nix { }` works from both `modules/shared/` and `modules/darwin/` (same relative depth).
- `includeOpencode` guard correctly excludes opencode-omo from standalone-linux (which sets includeOpencode=false).
- bare `codex` replaced by `codex-omx` unconditionally; bare `opencode` replaced by `opencode-omo` conditionally.
- `omniwm` added to darwin packages only (macOS window manager).

## packages.nix flake output wiring (todo 7)
- Pattern: `mkConfiguredPkgs = (import ../../lib/nixpkgs.nix { inherit inputs; }).mkPkgs;` — mirrors apps.nix:4
- Must use `perSystem = { system, ... }` (NOT `{ pkgs, system, ... }`) — flake-parts default pkgs lacks allowUnfreePredicate
- omniwm guarded with `lib.optionalAttrs (system == "aarch64-darwin")` — aarch64-darwin only, NOT x86_64-darwin
- nix flake uses git tree: pkgs/ subdirectories (package-lock.json etc.) must be `git add`-ed before nix build can see them
- omniwm eval on x86_64-linux requires explicit system: `nix eval .#packages.aarch64-darwin.omniwm.drvPath`

## codex-wrapped in standalone-linux (2026-07-27)
- `writeShellScriptBin` sets `name` attribute, NOT `pname`. Verification filters using `(p.pname or "")` will return 0 for writeShellScriptBin packages. Use `(p.name or "")` instead.
- `modules/aspects/users/mei.nix:52` already adds codex-wrapped AND opencode-wrapped to home.packages via the Den aspect system. This is wired into standalone-linux through the flake's home entity composition.
- Adding codex-wrapped again in `modules/standalone-linux/home-manager.nix` creates a DUPLICATE. The mei aspect already provides it.
- standalone-linux `packages.nix` has `includeOpencode=false` which only controls the `opencode-omo` package from shared/packages.nix — it does NOT affect the `opencode-wrapped` script from the mei aspect.

## codex-wrapped/opencode-wrapped in modules/aspects/users/mei.nix (2026-07-27)
- Added `home.packages` at the homeManager module level (before `gtk.gtk4.theme`), NOT inside the `programs` attr (which imports ../../shared/home-manager.nix — nesting there would create invalid programs.home.packages).
- GOTCHA: `pkgs.writeShellScriptBin` sets `name` but NOT `pname`. Verification filters on `(p.pname or "")`, so plain writeShellScriptBin returns 0. Fix: `(pkgs.writeShellScriptBin "x" ''...'' // { pname = "x"; })` — the `//` preserves `type = "derivation"` + `outPath`, so it remains a valid package for home.packages while exposing pname.
- Same codex-wrapped pattern already exists in modules/standalone-linux/home-manager.nix (without pname override).
- Nix `''...''` string: `${config.home.homeDirectory}` interpolates (intended); `$SECRETS_FILE` and `"$@"` pass through as literal shell vars (no `${}` = no interpolation).
- Verified built script content: SOPS_AGE_KEY_FILE=/home/mei/.config/sops/age/keys.txt, SECRETS_FILE=/home/mei/nix-config/secrets/coding-agents.yaml, exec sops exec-env "$SECRETS_FILE" -- <cmd> "$@".
- Verification: `nix eval .#nixosConfigurations.x86_64-linux.config.home-manager.users.mei.home.packages --apply 'ps: builtins.length (builtins.filter (p: (p.pname or "") == "codex-wrapped") ps)'` → 1 (same for opencode-wrapped).

## pname fix for writeShellScriptBin (2026-07-27)
- Pattern: `((pkgs.writeShellScriptBin "name" '' ... '') // { pname = "name"; })` — double parens required
- standalone-linux DOES include the mei aspect (opencode-wrapped from mei.nix evaluates to count 1), contradicting earlier assumption
- codex-wrapped count is 2 in standalone-linux: one from mei.nix aspect + one from standalone-linux/home-manager.nix

## Verification Run (2026-07-27)

### tests/package-policy.sh: PASS
- `package-policy-source=PASS`
- `package-policy-probe=PASS`
- Exit code 0. All packages in package lists have valid licenses or exceptions in config/package-exceptions.json.

### nix flake check: PRE-EXISTING FAILURE (sublimetext4)
- Error: `Refusing to evaluate package 'sublimetext4-4200'` — broken due to insecure OpenSSL dependency.
- This is a **pre-existing, unrelated failure** — not caused by any package-policy changes.
- Workaround exists via `problems.handlers.sublimetext4.broken = "warn"` in nixpkgs config.
- All other evaluations proceed normally; the failure is isolated to sublimetext4 evaluation.

## Package Build Verification (Wave 2)
- `nix build .#codex-omx` ✅ exit 0 — `codex --version` → "oh-my-codex v0.20.3, Node.js v24.16.0, Platform: linux x64"
- `nix build .#opencode-omo` ✅ exit 0 — `opencode --version` → "4.19.2"
- `nix eval .#omniwm.drvPath` ❌ on x86_64-linux — omniwm is NOT exposed in x86_64-linux packages (only codex-omx and opencode-omo are)
- omniwm eval works via: `nix eval --impure --expr '(builtins.getFlake ...).packages.aarch64-darwin.omniwm.drvPath'` → `/nix/store/x5md9ac8h5rr7n4a1qwd3h9q1n76bibp-omniwm-0.5.9.drv`
- Key insight: omniwm is aarch64-darwin ONLY — the flake correctly does not expose it for x86_64-linux, so `nix eval .#omniwm.drvPath` will always fail on this host. Must use explicit system attribute path for cross-system eval.

## F1 Audit (2026-07-27)
- All 17 in-scope items present and correct.
- All 7 explicit out-of-scope constraints satisfied.
- FAIL reason: scope creep in modules/shared/home-manager.nix (PATH cleanup + git signing) and modules/standalone-linux/home-manager.nix (sessionPath removals). These are unrelated housekeeping changes mixed into the plan's working tree.
- Fix: revert the unrelated hunks in those two files before committing.
