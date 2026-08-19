# agent-packages-and-secrets - Work Plan

## TL;DR (For humans)

**What you'll get.** Five new packages (hydralauncher, vesktop, codex-omx harness, opencode-omo harness, omniwm) plus a complete secret storage and delivery infrastructure using sops + secretspec. The harness wrappers replace the bare `codex`/`opencode` CLIs on PATH. Secrets are encrypted with sops, declared in secretspec, and delivered via wrapper scripts using `sops exec-env`.

**Why this approach.** Hydra and vesktop are already in nixpkgs — just add to package lists. Codex and Opencode need harness wrappers (buildNpmPackage derivations with generated lockfiles that wrap the base CLI). OmniWM needs a custom binary derivation (not in nixpkgs, macOS arm64 only). Secrets use sops for encryption at rest + secretspec for management, with both validator modification (for NixOS/Darwin activation-time delivery) AND out-of-store delivery (for standalone-linux).

**What it will NOT do.** No changes to flake.nix inputs (sops-nix already exists). No changes to tests/package-policy.sh or lib/nixpkgs.nix. No new overlays. No mkDerivation in lib/ or modules/ (policy constraint). No x86_64-darwin rows in package-exceptions.json. No changes to existing packages except replacing bare codex/opencode with harness wrappers.

**Effort.** ~20 todos across 4 waves. Wave 1 (packaging): 7 todos. Wave 2 (secret infrastructure): 5 todos. Wave 3 (secret delivery): 4 todos. Wave 4 (verification): 4 todos.

**Risk.** Low-to-medium. Harness wrappers use buildNpmPackage with generated lockfiles (npm tarball src + committed package-lock.json; postinstall scripts skipped via --ignore-scripts). OmniWM is macOS 26+ arm64 only. Validator modification is a significant change to machine authority model. secretspec 0.13.0 can't decrypt age files (use sops CLI directly).

**Decisions I made for you:**
- Harness wrappers replace bare CLI (you confirmed)
- One combined plan (you confirmed)
- All major provider keys: OPENAI_API_KEY, ANTHROPIC_API_KEY, GEMINI_API_KEY, OPENROUTER_API_KEY, GITHUB_TOKEN (you confirmed)
- sops exec-env wrapper delivery (you confirmed)
- Both validator modification AND out-of-store delivery (you confirmed)
- Hydra from nixpkgs (v4.0.3 in locked nixpkgs, MIT, platforms include aarch64-linux)
- OmniWM binary derivation (v0.5.9, GPL-2.0-only, arm64-only, macOS 26+, NAR hash: sha256-9yZSO/xk0g72XQtG0Y/2ca64QxqItryMGtFl3o8aqYo=)
- Vesktop on Linux (already on darwin, GPL-3.0-only)
- secretspec 0.13.0 limitation: use sops CLI directly, not secretspec age provider
- **Secrets file will be committed** (encrypted ciphertext is safe to commit; add `!secrets/coding-agents.yaml` to .gitignore)
- **Flake packages output will be added** (expose pkgs/ as flake package outputs)
- **Harness wrappers use buildNpmPackage with generated lockfiles** (lockfiles generated from the published npm package's package.json via `npm install --package-lock-only --ignore-scripts`, committed to pkgs/<name>/; oh-my-opencode's manifest requires jq sanitization to strip `workspaces` and `devDependencies` with `workspace:*` protocol before npm can resolve; postinstall scripts that download native binaries are skipped via `dontNpmBuild = true` + `npmFlags = [ "--ignore-scripts" ]` — Node.js-only mode. This reverses the earlier "no buildNpmPackage" directive because Oracle empirically proved fetchurl+makeWrapper crashes with ERR_MODULE_NOT_FOUND — the npm tarballs don't bundle dependencies)
- **oh-my-codex pinned at v0.20.3** (latest, MIT, npm tarball at registry.npmjs.org/oh-my-codex)
- **oh-my-openagent pinned at v4.19.2** (latest, SUL-1.0/unfree, npm tarball at registry.npmjs.org/oh-my-opencode, requires package-exceptions.json rows)
- **Standalone-linux uses the same committed in-store ciphertext** via sops exec-env wrappers (NOT out-of-store sync-secrets, to avoid model conflict)

## Scope

**In scope:**
- Add hydralauncher to modules/linux/packages.nix (main list, platforms include aarch64-linux)
- Add vesktop to modules/linux/packages.nix
- Create pkgs/codex-omx.nix (buildNpmPackage derivation with generated lockfile)
- Generate and commit pkgs/codex-omx/package-lock.json (from published npm package.json)
- Create pkgs/opencode-omo.nix (buildNpmPackage derivation with generated lockfile)
- Generate and commit pkgs/opencode-omo/package-lock.json (from published npm package.json, sanitized with jq)
- Generate and commit pkgs/opencode-omo/package.json (stripped manifest: workspaces and devDependencies removed)
- Add opencode-omo rows to config/package-exceptions.json (SUL-1.0 is unfree, 3 systems: x86_64-linux, aarch64-linux, aarch64-darwin)
- Create pkgs/omniwm.nix (binary derivation for macOS arm64)
- Wire codex-omx and opencode-omo into modules/shared/packages.nix (replacing bare codex/opencode)
- Wire omniwm into modules/darwin/packages.nix
- **Add flake packages output** (expose pkgs/ as flake package outputs in modules/flake/packages.nix)
- Document age identity generation steps (including ssh-to-age conversion)
- Create .sops.yaml with age recipient rules
- Create secrets/coding-agents.yaml (sops-encrypted) with 5 API keys
- **Add `!secrets/coding-agents.yaml` to .gitignore** (allow committing encrypted ciphertext)
- Update secretspec/secretspec.toml with coding agent secret declarations (preserve existing [project] section)
- Modify validators.nix to allow secretTrust enrollment on darwin/aarch64 (inline predicate preserving all identity fields)
- Create wrapper scripts (codex-wrapped, opencode-wrapped) using sops exec-env with absolute paths and SOPS_AGE_KEY_FILE
- Wire wrappers into home-manager config
- Set up sops-nix activation-time delivery for NixOS/Darwin (in sops.nix, not secrets.nix)
- Set up standalone-linux delivery using the same committed in-store ciphertext via sops exec-env wrappers

**Out of scope (Must NOT have):**
- No changes to flake.nix inputs (sops-nix already exists)
- No changes to tests/package-policy.sh
- No changes to lib/nixpkgs.nix
- No new overlays
- No mkDerivation in lib/ or modules/
- No x86_64-darwin rows in package-exceptions.json
- No changes to existing packages (except replacing bare codex/opencode with harness wrappers)
- No changes to README.md

## Verification strategy

**Test strategy: tests-after, with policy + build + secret delivery verification**

- Policy gate: `tests/package-policy.sh` must pass (exit 0, both PASS lines)
- Build gate: `nix flake check` must pass (or document pre-existing failures)
- Package verification: all new packages build successfully via `nix build .#<pkg>`
- Secret delivery verification: sops exec-env works, secretspec check passes
- Negative checks: no secret patterns in code, no secret files in repo (except committed ciphertext)

## Execution strategy

**Wave 1 — Package applications (7 todos):**
1. Add hydralauncher to Linux packages (main list)
2. Add vesktop to Linux packages
3. Create pkgs/codex-omx.nix (buildNpmPackage + generated lockfile)
4. Create pkgs/opencode-omo.nix (buildNpmPackage + generated lockfile) + package-exceptions.json rows
5. Create pkgs/omniwm.nix (binary derivation)
6. Wire harness packages into package lists
7. **Add flake packages output** (expose pkgs/ as flake package outputs)

**Wave 2 — Secret infrastructure (5 todos):**
8. Document age identity generation (including ssh-to-age conversion)
9. Create .sops.yaml with age recipient rules
10. Create secrets/coding-agents.yaml (encrypted) + add .gitignore exception
11. Update secretspec.toml with coding agent declarations (preserve [project])
12. Modify validators.nix to allow secretTrust on darwin/aarch64 (inline predicate)

**Wave 3 — Secret delivery (4 todos):**
13. Create wrapper scripts (with absolute paths and SOPS_AGE_KEY_FILE)
14. Wire wrappers into home-manager
15. Set up sops-nix activation-time delivery (in sops.nix)
16. Set up standalone-linux delivery using committed in-store ciphertext

**Wave 4 — Verification (4 todos):**
17. Run tests/package-policy.sh + nix flake check
18. Verify all packages build via `nix build .#<pkg>`
19. Verify secret delivery works
20. F1-F5 final verification wave

**Dependency matrix:**
- Wave 1 todos are independent (can be parallelized)
- Wave 2 depends on Wave 1 (secrets are for the packaged agents)
- Wave 3 depends on Wave 2 (delivery depends on infrastructure)
- Wave 4 depends on all previous waves

**Commit strategy:**
- Commit 1: Wave 1 (packaging) — "feat(packages): add hydralauncher, vesktop, codex-omx, opencode-omo, omniwm"
- Commit 2: Wave 2 (secret infrastructure) — "feat(secrets): add sops/secretspec infrastructure for coding agents"
- Commit 3: Wave 3 (secret delivery) — "feat(secrets): add secret delivery for coding agents"
- Wave 4 is verification only (no commit)

## Todos

- [x] 1. **Add hydralauncher to Linux packages.** Edit `modules/linux/packages.nix`. Add `hydralauncher` to the main list (lines 4-69). Hydra is in nixpkgs as `hydralauncher` v4.0.3 (MIT, AppImage wrap, Linux-only, 24 platforms include aarch64-linux). **Acceptance:** `nix eval .#nixosConfigurations.x86_64-linux.config.home-manager.users.mei.home.packages --apply 'ps: builtins.length (builtins.filter (p: (p.pname or "") == "hydralauncher") ps)'` returns 1. **QA:** Run the eval command, verify output is 1. **Failure:** If eval returns 0, check that hydralauncher is in the main list and nixpkgs has it. **Commit:** Included in commit 1.

- [x] 2. **Add vesktop to Linux packages.** Edit `modules/linux/packages.nix`. Add `vesktop` to the main list (lines 4-69). Vesktop is in nixpkgs (GPL-3.0-only, cross-platform). Already on darwin (modules/darwin/packages.nix:14). **Acceptance:** `nix eval .#nixosConfigurations.x86_64-linux.config.home-manager.users.mei.home.packages --apply 'ps: builtins.length (builtins.filter (p: (p.pname or "") == "vesktop") ps)'` returns 1. **QA:** Run the eval command, verify output is 1. **Failure:** If eval returns 0, check that vesktop is in the main list and nixpkgs has it. **Commit:** Included in commit 1.

- [x] 3. **Create pkgs/codex-omx.nix + generate lockfile.** Two sub-steps: (A) generate the lockfile, (B) write the derivation. **(A) Generate lockfile:** Run these commands to produce `pkgs/codex-omx/package-lock.json`:
  ```bash
  mkdir -p pkgs/codex-omx
  curl -sL -o /tmp/omx.tgz "https://registry.npmjs.org/oh-my-codex/-/oh-my-codex-0.20.3.tgz"
  cd /tmp && tar xzf omx.tgz package/package.json
  cd /tmp/package && npm install --package-lock-only --ignore-scripts
  cp /tmp/package/package-lock.json /home/mei/nix-config/pkgs/codex-omx/package-lock.json
  ```
  **(B) Create `pkgs/codex-omx.nix`** — buildNpmPackage derivation that replaces bare `codex`. Fetches the oh-my-codex npm tarball (v0.20.3, MIT), resolves dependencies via the committed lockfile, and wraps the `omx` CLI as `codex` with the real nixpkgs `codex` on PATH. **Structure:**
  ```nix
  { lib, buildNpmPackage, fetchurl, makeWrapper, codex }:

  buildNpmPackage rec {
    pname = "codex-omx";
    version = "0.20.3";

    src = fetchurl {
      url = "https://registry.npmjs.org/oh-my-codex/-/oh-my-codex-${version}.tgz";
      hash = "sha256-..."; # First build with lib.fakeHash, read the correct SRI hash from the error
    };

    # npm tarballs extract to package/
    sourceRoot = "package";

    # Inject the generated lockfile (committed alongside this file).
    # MUST be postPatch, NOT postUnpack: buildNpmPackage's npmDeps FOD
    # (fetchNpmDeps) only inherits prePatch/patches/postPatch — postUnpack
    # is silently dropped, causing "ERROR: No lock file!" in the FOD.
    # During postPatch, cwd is already inside sourceRoot, so use bare relative path.
    postPatch = ''
      cp ${./codex-omx/package-lock.json} package-lock.json
    '';

    npmDepsHash = "sha256-..."; # First build with lib.fakeHash, read the correct hash from the error

    # Tarball ships prebuilt dist/ — do NOT run npm run build (omx's build
    # script deletes dist/ and runs tsc, but no tsconfig.json is shipped).
    dontNpmBuild = true;

    # Skip lifecycle scripts in npm rebuild/pack (postinstall downloads native
    # Rust binaries we don't need; prepack depends on bun/build tooling).
    # Note: npm ci already hardcodes --ignore-scripts in npm-config-hook.sh.
    npmFlags = [ "--ignore-scripts" ];

    nativeBuildInputs = [ makeWrapper ];

    postInstall = ''
      makeWrapper $out/bin/omx $out/bin/codex \
        --prefix PATH : ${lib.makeBinPath [ codex ]}
    '';

    meta = {
      description = "Oh-my-codex harness for Codex CLI";
      homepage = "https://github.com/Yeachan-Heo/oh-my-codex";
      license = lib.licenses.mit;
      platforms = lib.platforms.all;
      mainProgram = "codex";
    };
  }
  ```
  **NOTE:** Uses `buildNpmPackage` with a generated lockfile (NOT fetchurl+makeWrapper — Oracle empirically proved that approach crashes with `ERR_MODULE_NOT_FOUND` because npm tarballs don't bundle dependencies; oh-my-codex has 3 runtime deps: `@iarna/toml`, `@modelcontextprotocol/sdk`, `zod`). The lockfile is generated from the published npm package's `package.json` (oh-my-codex is a flat package with no workspaces — `npm install --package-lock-only` works directly). `dontNpmBuild = true` is required because the tarball ships prebuilt `dist/cli/omx.js` and the build script (`fs.rmSync('dist',...) && tsc`) would destroy it (no tsconfig.json is shipped). `npmFlags = [ "--ignore-scripts" ]` skips lifecycle scripts in `npm rebuild`/`npm pack` (postinstall downloads native Rust binaries `omx-api`, `omx-explore-harness`, `omx-runtime`, `omx-sparkshell`; prepack depends on build tooling). The entry point is `dist/cli/omx.js` (verified from the npm tarball). To get both hashes: set `hash` and `npmDepsHash` to `lib.fakeHash`, run `nix build .#codex-omx`, read the correct SRI hashes from the error messages, then update. **Acceptance:** `nix build .#codex-omx` succeeds. `result/bin/codex --version` works. **QA:** Run `nix build .#codex-omx`, then `result/bin/codex --version`. **Failure:** If build fails on src hash, use the SRI hash from the error message. If build fails on npmDepsHash, use the hash from the error message. If build fails with "ERROR: No lock file!", verify `postPatch` (NOT `postUnpack`) injects the lockfile. If `--version` crashes with MODULE_NOT_FOUND, verify the lockfile was injected (check `postPatch`). **Commit:** Included in commit 1.

- [x] 4. **Create pkgs/opencode-omo.nix + generate lockfile + add package-exceptions.json rows.** Three sub-steps: (A) generate the lockfile and stripped manifest, (B) write the derivation, (C) add package-exceptions.json rows. **(A) Generate lockfile + stripped package.json:** The published oh-my-opencode tarball retains `"workspaces"` (27 entries) and 26 `"workspace:*"` devDependencies — npm does not support the `workspace:` protocol and will fail with `EUNSUPPORTEDPROTOCOL`. You must sanitize before generating. Run these commands to produce `pkgs/opencode-omo/package-lock.json` AND `pkgs/opencode-omo/package.json`:
  ```bash
  mkdir -p pkgs/opencode-omo
  curl -sL -o /tmp/omo.tgz "https://registry.npmjs.org/oh-my-opencode/-/oh-my-opencode-4.19.2.tgz"
  cd /tmp && tar xzf omo.tgz package/package.json
  # Strip workspaces and devDependencies (workspace:* protocol is unsupported by npm)
  cd /tmp/package && jq 'del(.workspaces, .devDependencies)' package.json > package.json.tmp && mv package.json.tmp package.json
  npm install --package-lock-only --ignore-scripts
  cp /tmp/package/package-lock.json /home/mei/nix-config/pkgs/opencode-omo/package-lock.json
  cp /tmp/package/package.json /home/mei/nix-config/pkgs/opencode-omo/package.json
  ```
  **(B) Create `pkgs/opencode-omo.nix`** — buildNpmPackage derivation that replaces bare `opencode`. Fetches the oh-my-opencode npm tarball (v4.19.2, SUL-1.0 license), resolves dependencies via the committed lockfile, and wraps the `omo` CLI as `opencode` with the real nixpkgs `opencode` on PATH. **SUL-1.0 is NOT in the nixpkgs license set** — use `lib.licenses.unfree` and add rows to `config/package-exceptions.json`. **Derivation structure:**
  ```nix
  { lib, buildNpmPackage, fetchurl, makeWrapper, opencode }:

  buildNpmPackage rec {
    pname = "opencode-omo";
    version = "4.19.2";

    src = fetchurl {
      url = "https://registry.npmjs.org/oh-my-opencode/-/oh-my-opencode-${version}.tgz";
      hash = "sha256-..."; # First build with lib.fakeHash, read the correct SRI hash from the error
    };

    # npm tarballs extract to package/
    sourceRoot = "package";

    # Inject the generated lockfile AND stripped manifest (committed alongside this file).
    # MUST be postPatch, NOT postUnpack: buildNpmPackage's npmDeps FOD
    # (fetchNpmDeps) only inherits prePatch/patches/postPatch — postUnpack
    # is silently dropped, causing "ERROR: No lock file!" in the FOD.
    # During postPatch, cwd is already inside sourceRoot, so use bare relative paths.
    # The stripped package.json removes "workspaces" (27 entries) and "devDependencies"
    # (26 workspace:* deps) — npm ci fails with EUNSUPPORTEDPROTOCOL on workspace:* protocol.
    postPatch = ''
      cp ${./opencode-omo/package-lock.json} package-lock.json
      cp ${./opencode-omo/package.json} package.json
    '';

    npmDepsHash = "sha256-..."; # First build with lib.fakeHash, read the correct hash from the error

    # Tarball ships prebuilt bin/oh-my-opencode.js — do NOT run npm run build
    # (omo's build script is "bun run script/build.ts" — no bun in sandbox,
    # and script/build.ts is not shipped in the tarball).
    dontNpmBuild = true;

    # Skip lifecycle scripts in npm rebuild/pack (postinstall downloads
    # platform-specific native binaries; prepack depends on bun/build tooling).
    # Note: npm ci already hardcodes --ignore-scripts in npm-config-hook.sh.
    npmFlags = [ "--ignore-scripts" ];

    nativeBuildInputs = [ makeWrapper ];

    postInstall = ''
      makeWrapper $out/bin/omo $out/bin/opencode \
        --prefix PATH : ${lib.makeBinPath [ opencode ]}
    '';

    meta = {
      description = "Oh-my-openagent harness for Opencode";
      homepage = "https://github.com/code-yeongyu/oh-my-openagent";
      license = lib.licenses.unfree; # SUL-1.0, not in nixpkgs license set
      platforms = lib.platforms.all;
      mainProgram = "opencode";
    };
  }
  ```
  **(C) Add package-exceptions.json rows.** Edit `config/package-exceptions.json`. Append 3 rows to the `"unfree"` array (one per system where opencode-omo is wired — NOT x86_64-darwin, NOT standalone-linux since includeOpencode=false):
  ```json
  {
    "expiresAt": "2026-10-25",
    "maxTtlDays": 90,
    "output": "nixosConfigurations.x86_64-linux",
    "owner": "mei",
    "pname": "opencode-omo",
    "reason": "requested-coding-agent-harness",
    "reviewedAt": "2026-07-27",
    "system": "x86_64-linux",
    "version": "4.19.2"
  },
  {
    "expiresAt": "2026-10-25",
    "maxTtlDays": 90,
    "output": "nixosConfigurations.aarch64-linux",
    "owner": "mei",
    "pname": "opencode-omo",
    "reason": "requested-coding-agent-harness",
    "reviewedAt": "2026-07-27",
    "system": "aarch64-linux",
    "version": "4.19.2"
  },
  {
    "expiresAt": "2026-10-25",
    "maxTtlDays": 90,
    "output": "darwinConfigurations.aarch64-darwin",
    "owner": "mei",
    "pname": "opencode-omo",
    "reason": "requested-coding-agent-harness",
    "reviewedAt": "2026-07-27",
    "system": "aarch64-darwin",
    "version": "4.19.2"
  }
  ```
  **NOTE:** Uses `buildNpmPackage` with a generated lockfile AND stripped manifest (NOT fetchurl+makeWrapper — Oracle empirically proved that approach crashes with `ERR_MODULE_NOT_FOUND` because npm tarballs don't bundle dependencies; oh-my-opencode has 17 runtime deps including `@opentui/*`, `@opencode-ai/sdk`, `posthog-node`, `commander`). **The published oh-my-opencode tarball is NOT a flat package** — it retains `"workspaces"` (27 entries) and 26 `"workspace:*"` devDependencies from the Bun monorepo. npm does not support the `workspace:` protocol (`EUNSUPPORTEDPROTOCOL`), so both the lockfile generation AND the build-time `npm ci` require the stripped `package.json` (jq `del(.workspaces, .devDependencies)`). The stripped manifest is committed alongside the lockfile and injected via `postPatch`. `dontNpmBuild = true` is required because the build script is `bun run script/build.ts` (no bun in sandbox, script not shipped). `npmFlags = [ "--ignore-scripts" ]` skips lifecycle scripts in `npm rebuild`/`npm pack` (postinstall is `node postinstall.mjs` which downloads platform-specific native binaries; prepack depends on bun/build tooling). The npm package is published as `oh-my-opencode` (dual-published as `oh-my-openagent`). The entry point is `bin/oh-my-opencode.js` (empirically verified from the npm tarball's `package.json` `"bin"` field — all 5 bin aliases point to this single file). `lib.licenses.sul1` does NOT exist in locked nixpkgs — use `lib.licenses.unfree`. The `allowUnfreePredicate` in `lib/nixpkgs.nix` checks `system:pname:version` against `config/package-exceptions.json`, so the rows above are required for evaluation to succeed. To get both hashes: set `hash` and `npmDepsHash` to `lib.fakeHash`, run `nix build .#opencode-omo`, read the correct SRI hashes from the error messages, then update. **Acceptance:** `nix build .#opencode-omo` succeeds. `result/bin/opencode --version` works. **QA:** Run `nix build .#opencode-omo`, then `result/bin/opencode --version`. **Failure:** If build fails with "package is unfree", check package-exceptions.json rows match `system:pname:version`. If build fails on src hash, use the SRI hash from the error message. If build fails on npmDepsHash, use the hash from the error message. If build fails with "ERROR: No lock file!", verify `postPatch` (NOT `postUnpack`) injects the lockfile. If build fails with `EUNSUPPORTEDPROTOCOL: workspace:*`, verify `postPatch` also overwrites `package.json` with the stripped manifest. If `--version` crashes with MODULE_NOT_FOUND, verify both files were injected (check `postPatch`). **Commit:** Included in commit 1.

- [x] 5. **Create pkgs/omniwm.nix.** Create `pkgs/omniwm.nix` — binary derivation for macOS arm64. Fetches pre-built .app ZIP (v0.5.9, GPL-2.0-only). The zip root contains `Contents/` + `._Contents` (NOT `OmniWM.app`). Installs to `$out/Applications/OmniWM.app/`, symlinks `omniwmctl` to `$out/bin/`. **Structure:**
  ```nix
  { stdenvNoCC, lib, fetchzip, ... }:
  stdenvNoCC.mkDerivation {
    pname = "omniwm";
    version = "0.5.9";
    src = fetchzip {
      url = "https://github.com/BarutSRB/OmniWM/releases/download/v0.5.9/OmniWM-v0.5.9.zip";
      hash = "sha256-9yZSO/xk0g72XQtG0Y/2ca64QxqItryMGtFl3o8aqYo=";
    };
    installPhase = ''
      mkdir -p $out/Applications/OmniWM.app
      cp -r Contents $out/Applications/OmniWM.app/
      mkdir -p $out/bin
      ln -s $out/Applications/OmniWM.app/Contents/MacOS/omniwmctl $out/bin/omniwmctl
    '';
    meta = {
      description = "Niri and Hyprland inspired tiling window manager for macOS";
      homepage = "https://github.com/BarutSRB/OmniWM";
      license = lib.licenses.gpl2Only;
      platforms = [ "aarch64-darwin" ];
      mainProgram = "omniwmctl";
    };
  }
  ```
  **NOTE:** Use `stdenvNoCC` per pkgs/README.md (binary derivation). The zip root is `Contents/` (verified via nix-prefetch-url --unpack). Upstream warns unzip-style extraction strips the Developer ID signature — consider bsdtar extraction per the DavSanchez reference the upstream README endorses. **Acceptance:** `nix build .#omniwm` succeeds on aarch64-darwin. `result/bin/omniwmctl --version` works. **QA:** Run `nix build .#omniwm` (on macOS arm64), then `result/bin/omniwmctl --version`. **Failure:** If build fails, check ZIP extraction, verify macOS 26+ requirement, check OmniWM repo for build instructions. **Commit:** Included in commit 1.

- [x] 6. **Wire harness packages into package lists.** Edit `modules/shared/packages.nix`: remove bare `codex` (line 87) and `opencode` (line 92, inside the `includeOpencode` conditional at lines 89-93), add `codex-omx` and `opencode-omo` via `pkgs.callPackage`. **NOTE:** The `includeOpencode` conditional must be preserved for opencode-omo. The replacement should be:
  ```nix
  # Remove: codex (line 87)
  # Replace the includeOpencode conditional (lines 89-93) with:
  ++ pkgs.lib.optionals (includeOpencode && pkgs.stdenv.hostPlatform.system != "x86_64-darwin") [
    (pkgs.callPackage ../../pkgs/opencode-omo.nix { })
  ]
  # Add codex-omx unconditionally (replacing bare codex) inside the main list:
  (pkgs.callPackage ../../pkgs/codex-omx.nix { })
  ```
  Edit `modules/darwin/packages.nix`: add `omniwm` via `pkgs.callPackage`. **Acceptance:** `nix eval .#homeConfigurations.standalone-linux.config.home.packages --apply 'ps: builtins.length (builtins.filter (p: (p.pname or "") == "codex-omx") ps)'` returns 1. `nix eval .#nixosConfigurations.x86_64-linux.config.home-manager.users.mei.home.packages --apply 'ps: builtins.length (builtins.filter (p: (p.pname or "") == "opencode-omo") ps)'` returns 1. `nix eval .#darwinConfigurations.aarch64-darwin.config.environment.systemPackages --apply 'ps: builtins.length (builtins.filter (p: (p.pname or "") == "omniwm") ps)'` returns 1. **NOTE:** standalone-linux has `includeOpencode = false` (modules/standalone-linux/packages.nix:6), so opencode-omo will NOT appear there. **QA:** Run the eval commands, verify outputs are 1. **Failure:** If eval returns 0, check that callPackage paths are correct and packages build. **Commit:** Included in commit 1.

- [x] 7. **Add flake packages output.** Edit `modules/flake/packages.nix`. Change `packages = { };` to expose pkgs/ as flake package outputs. **Use configured pkgs from lib/nixpkgs.nix** (NOT perSystem's default `pkgs` argument — flake-parts injects unconfigured `nixpkgs.legacyPackages` which lacks `allowUnfreePredicate`, causing unfree eval failure for opencode-omo). **Guard omniwm with platform conditional** since it's aarch64-darwin only. **Pattern mirrors `modules/flake/apps.nix:4`:**
  ```nix
  { inputs, lib, ... }:
  let
    mkConfiguredPkgs = (import ../../lib/nixpkgs.nix { inherit inputs; }).mkPkgs;
  in {
    perSystem = { system, ... }:
      let pkgs = mkConfiguredPkgs system; in {
        packages = {
          codex-omx = pkgs.callPackage ../../pkgs/codex-omx.nix { };
          opencode-omo = pkgs.callPackage ../../pkgs/opencode-omo.nix { };
        } // lib.optionalAttrs (system == "aarch64-darwin") {
          omniwm = pkgs.callPackage ../../pkgs/omniwm.nix { };
        };
      };
  }
  ```
  **NOTE:** Do NOT use `perSystem = { pkgs, system, ... }` — flake-parts' default perSystem pkgs is `nixpkgs.legacyPackages` without `allowUnfreePredicate` (verified: forcing `.drvPath` on an unfree package under it fails with "has an unfree license, refusing to evaluate"). The configured pkgs from `lib/nixpkgs.nix` wires `allowUnfreePredicate` against `config/package-exceptions.json`, which is required for opencode-omo (meta.license = lib.licenses.unfree). The 3 exception rows cover exactly the flake's 3 systems (modules/flake/systems.nix: x86_64-linux, aarch64-linux, aarch64-darwin). **Acceptance:** `nix build .#codex-omx` succeeds. `nix build .#opencode-omo` succeeds. `nix build .#omniwm` succeeds (on aarch64-darwin only). **QA:** Run the build commands, verify exit 0. `nix flake check` passes on all systems (omniwm is guarded). **Failure:** If opencode-omo fails with "unfree license", verify the package-exceptions.json rows match `system:pname:version` and that `mkConfiguredPkgs` is used (not perSystem's default pkgs). **Commit:** Included in commit 1.

- [x] 8. **Document age identity generation.** Create `docs/secrets/age-identity.md`. Document how to generate age identity: `age-keygen -o ~/.config/sops/age/keys.txt` or use existing SSH key `~/.ssh/id_ed25519`. Document how to get the age public key: `age-keygen -y ~/.config/sops/age/keys.txt` OR convert SSH key to age: `ssh-to-age < ~/.ssh/id_ed25519.pub` (requires `ssh-to-age` tool). **NOTE:** The repo's sops-nix uses `sops.age.sshKeyPaths` (sops.nix:8,15-18), which converts SSH keys to age at runtime. The .sops.yaml creation rules need an age1... recipient. Use `ssh-to-age` to convert. **Acceptance:** `docs/secrets/age-identity.md` exists and is clear. **QA:** Read the documentation, verify it's clear and complete. **Failure:** If documentation is unclear, revise. **Commit:** Included in commit 2.

- [x] 9. **Create .sops.yaml.** Create `.sops.yaml` at repo root with age recipient rules for `secrets/coding-agents.yaml`. **Structure:**
  ```yaml
  keys:
    - &admin <age1-public-key>  # Get via: ssh-to-age < ~/.ssh/id_ed25519.pub
  creation_rules:
    - path_regex: secrets/coding-agents\.yaml$
      key_groups:
        - age:
            - *admin
  ```
  **NOTE:** The `<age1-public-key>` placeholder must be replaced with the actual age1... recipient derived from the SSH key via `ssh-to-age`. **Acceptance:** `.sops.yaml` exists and is valid YAML. `sops --version` works. **QA:** Run `sops --version`, verify `.sops.yaml` is valid YAML. **Failure:** If YAML is invalid, fix syntax. **Commit:** Included in commit 2.

- [x] 10. **Create secrets/coding-agents.yaml (encrypted) + add .gitignore exception.** Create `secrets/coding-agents.yaml` with 5 API keys: OPENAI_API_KEY, ANTHROPIC_API_KEY, GEMINI_API_KEY, OPENROUTER_API_KEY, GITHUB_TOKEN. Encrypt with sops: `sops --encrypt --age <age1-public-key> secrets/coding-agents.yaml`. **Add `!secrets/coding-agents.yaml` to .gitignore** (allow committing encrypted ciphertext). **NOTE:** The encrypted ciphertext is safe to commit (that's the whole point of sops). The .gitignore exception allows the flake to include the file in its source tree (required for sops-nix activation-time delivery). **Acceptance:** `secrets/coding-agents.yaml` exists and is encrypted. `sops --decrypt secrets/coding-agents.yaml` works. `git status` shows the file as tracked. **QA:** Run `sops --decrypt secrets/coding-agents.yaml`, verify it decrypts. **Failure:** If decryption fails, check age key, re-encrypt. **Commit:** Included in commit 2.

- [x] 11. **Update secretspec.toml.** Edit `secretspec/secretspec.toml`. **Preserve the existing `[project]` section (lines 6-8) and EXAMPLE_TOKEN (line 18).** Append the 5 coding agent secret declarations: OPENAI_API_KEY, ANTHROPIC_API_KEY, GEMINI_API_KEY, OPENROUTER_API_KEY, GITHUB_TOKEN. **Structure (append to existing file):**
  ```toml
  # Append to [profiles.default] section:
  OPENAI_API_KEY = { description = "OpenAI API key (delivered via sops exec-env)", required = false }
  ANTHROPIC_API_KEY = { description = "Anthropic API key (delivered via sops exec-env)", required = false }
  GEMINI_API_KEY = { description = "Gemini API key (delivered via sops exec-env)", required = false }
  OPENROUTER_API_KEY = { description = "OpenRouter API key (delivered via sops exec-env)", required = false }
  GITHUB_TOKEN = { description = "GitHub token (delivered via sops exec-env)", required = false }
  ```
  **NOTE:** Do NOT point dotenv:// at the encrypted YAML. Keys are declared with required=false + description only. Delivery happens via sops exec-env. **Acceptance:** `secretspec check` passes. **QA:** Run `secretspec check`, verify exit 0. **Failure:** If check fails, check TOML syntax, verify provider configuration. **Commit:** Included in commit 2.

- [x] 12. **Modify validators.nix.** Edit `modules/entities/_machine-authority/validators.nix`. Modify the darwin branch (lines 482-489) to allow `secretTrust.state = "enrolled"` while preserving all identity fields. **Current darwin branch (lines 482-489):**
  ```nix
  else if isDarwin then
    machine.cpuVendor == "Apple"
    && machine.firmware == "apple"
    && machine.kernel == "disabled"
    && machine.gpu == "apple-metal"
    && machine.network == "native-darwin"
    && machine.platformExpectations.kind == "darwin"
    && operationallyDisabled machine
  ```
  **Replace with (preserve all identity fields, only relax secretTrust):**
  ```nix
  else if isDarwin then
    machine.cpuVendor == "Apple"
    && machine.firmware == "apple"
    && machine.kernel == "disabled"
    && machine.gpu == "apple-metal"
    && machine.network == "native-darwin"
    && machine.platformExpectations.kind == "darwin"
    && machine.publicTrust.state == "disabled"
    && (machine.secretTrust.state == "disabled" || machine.secretTrust.state == "enrolled")
    && machine.boot.state == "disabled"
    && machine.storage.profile == "none"
    && machine.devices.state == "disabled"
    && machine.capabilities.state == "disabled"
    && machine.ddcConnectors == [ ]
    && machine.remoteInstall == false
  ```
  **NOTE:** This inlines `operationallyDisabled` but relaxes `secretTrust.state` to allow "enrolled" while keeping `publicTrust.state == "disabled"`, `boot.state == "disabled"`, `storage.profile == "none"`, and all other constraints. This is a documented exception for darwin workstations that need secrets but don't have full trust enrollment. **Acceptance:** `nix flake check` passes. `nix eval .#darwinConfigurations.aarch64-darwin.config.system.build.toplevel` succeeds. **QA:** Run `nix flake check`, verify exit 0. **Failure:** If check fails, check validator logic, verify constraints are correct. **Commit:** Included in commit 2.

- [x] 13. **Create wrapper scripts.** Create wrapper scripts `codex-wrapped` and `opencode-wrapped` that use `sops exec-env` to inject secrets. **Use absolute paths** and specify `SOPS_AGE_KEY_FILE` for runtime decryption. **Materialization:** Use `writeShellScriptBin` in home-manager. **Structure:**
  ```bash
  #!/usr/bin/env bash
  set -euo pipefail
  export SOPS_AGE_KEY_FILE="${HOME}/.config/sops/age/keys.txt"
  SECRETS_FILE="${HOME}/nix-config/secrets/coding-agents.yaml"
  exec sops exec-env "$SECRETS_FILE" -- codex "$@"
  ```
  **NOTE:** The absolute path must be specified. `SOPS_AGE_KEY_FILE` must point to the age key file for runtime decryption. The wrapper must be materialized as a package on PATH (via writeShellScriptBin in home-manager). **Acceptance:** Wrapper scripts exist and are executable. `codex-wrapped --version` works. **QA:** Run `codex-wrapped --version`, verify it works. **Failure:** If wrapper fails, check sops exec-env syntax, verify secrets file exists at the absolute path, verify SOPS_AGE_KEY_FILE points to valid age key. **Commit:** Included in commit 3.

- [x] 14. **Wire wrappers into home-manager.** Edit `modules/aspects/users/mei.nix` (NOT `modules/shared/home-manager.nix` — that file is imported as the `programs` attribute at mei.nix:53, so adding `home.packages` there would nest it under `programs.home.packages` which is invalid). Add wrapper scripts to `home.packages` at the homeManager module level (lines 50-90). **Exact code (add inside the homeManager module, before `gtk.gtk4.theme`):**
  ```nix
  homeManager = { config, pkgs, lib, ... }: {
    home.packages = [
      (pkgs.writeShellScriptBin "codex-wrapped" ''
        set -euo pipefail
        export SOPS_AGE_KEY_FILE="${config.home.homeDirectory}/.config/sops/age/keys.txt"
        SECRETS_FILE="${config.home.homeDirectory}/nix-config/secrets/coding-agents.yaml"
        exec sops exec-env "$SECRETS_FILE" -- codex "$@"
      '')
      (pkgs.writeShellScriptBin "opencode-wrapped" ''
        set -euo pipefail
        export SOPS_AGE_KEY_FILE="${config.home.homeDirectory}/.config/sops/age/keys.txt"
        SECRETS_FILE="${config.home.homeDirectory}/nix-config/secrets/coding-agents.yaml"
        exec sops exec-env "$SECRETS_FILE" -- opencode "$@"
      '')
    ];
    gtk.gtk4.theme = config.gtk.theme;
    home.file = import ../../shared/files.nix { inherit config pkgs lib; };
    programs = (import ../../shared/home-manager.nix { inherit config pkgs lib; }) // {
      # ... existing nushell config ...
    };
  };
  ```
  **NOTE:** The wrappers apply to NixOS and Darwin (via the mei aspect). Standalone-linux has its own wrapper in todo 16 (codex-wrapped only, since includeOpencode = false). **Acceptance:** `codex-wrapped` and `opencode-wrapped` are on PATH on NixOS and Darwin. **QA:** Run `which codex-wrapped`, verify it exists. **Failure:** If not on PATH, check home-manager configuration. **Commit:** Included in commit 3.

- [x] 15. **Set up sops-nix activation-time delivery.** Edit `modules/aspects/features/sops.nix` (NOT secrets.nix — that's the agenix aspect). Add `sops.secrets.*` declarations for coding agent secrets inside BOTH the `nixos` and `darwin` submodules of the Den aspect. Configure sops-nix to decrypt `secrets/coding-agents.yaml` at activation time. **Exact code (add inside both nixos and darwin submodules):**
  ```nix
  { inputs, ... }:
  {
    den.aspects.sops = { host, ... }: {
      nixos = { pkgs, ... }: {
        imports = [ inputs.sops-nix.nixosModules.default ];
        sops.age.sshKeyPaths = [ "${host.machine.identity.home}/.ssh/id_ed25519" ];
        environment.systemPackages = [ pkgs.sops ];
        # Add these inside the nixos submodule:
        sops.secrets."OPENAI_API_KEY" = {
          sopsFile = ../../../secrets/coding-agents.yaml;
          format = "yaml";
        };
        sops.secrets."ANTHROPIC_API_KEY" = {
          sopsFile = ../../../secrets/coding-agents.yaml;
          format = "yaml";
        };
        sops.secrets."GEMINI_API_KEY" = {
          sopsFile = ../../../secrets/coding-agents.yaml;
          format = "yaml";
        };
        sops.secrets."OPENROUTER_API_KEY" = {
          sopsFile = ../../../secrets/coding-agents.yaml;
          format = "yaml";
        };
        sops.secrets."GITHUB_TOKEN" = {
          sopsFile = ../../../secrets/coding-agents.yaml;
          format = "yaml";
        };
      };
      darwin = { pkgs, ... }: {
        imports = [ inputs.sops-nix.darwinModules.default ];
        sops.age.sshKeyPaths = [
          "${host.machine.identity.home}/.ssh/id_ed25519"
          "${host.machine.identity.home}/.ssh/id_ed25519_agenix"
        ];
        environment.systemPackages = [ pkgs.sops ];
        # Add the same sops.secrets.* declarations inside the darwin submodule:
        sops.secrets."OPENAI_API_KEY" = {
          sopsFile = ../../../secrets/coding-agents.yaml;
          format = "yaml";
        };
        sops.secrets."ANTHROPIC_API_KEY" = {
          sopsFile = ../../../secrets/coding-agents.yaml;
          format = "yaml";
        };
        sops.secrets."GEMINI_API_KEY" = {
          sopsFile = ../../../secrets/coding-agents.yaml;
          format = "yaml";
        };
        sops.secrets."OPENROUTER_API_KEY" = {
          sopsFile = ../../../secrets/coding-agents.yaml;
          format = "yaml";
        };
        sops.secrets."GITHUB_TOKEN" = {
          sopsFile = ../../../secrets/coding-agents.yaml;
          format = "yaml";
        };
      };
    };
  }
  ```
  **NOTE:** The sopsFile path `../../../secrets/coding-agents.yaml` is relative to `modules/aspects/features/sops.nix` (features -> aspects -> modules -> repo root). The file must be committed (encrypted ciphertext) and tracked by git (required for flake source tree). **Acceptance:** `nix eval .#nixosConfigurations.x86_64-linux.config.sops.secrets` returns the declared secrets. **QA:** Run the eval command, verify secrets are declared. **Failure:** If eval fails, check sops-nix configuration, verify secrets file path and git tracking. **Commit:** Included in commit 3.

- [x] 16. **Set up standalone-linux delivery using committed in-store ciphertext.** Edit `modules/standalone-linux/home-manager.nix`. The file already sets `packages = import ./packages.nix { inherit pkgs inputs; };` at line 18 inside the `home = { }` block. **Append the wrapper scripts to the existing list** (do NOT create a separate `home.packages` block). **Only add `codex-wrapped`** (NOT `opencode-wrapped`, since standalone-linux has `includeOpencode = false` and `opencode` won't be on PATH). **Exact code (modify line 18):**
  ```nix
  # Change line 18 from:
  # packages = import ./packages.nix { inherit pkgs inputs; };
  # To:
  packages = (import ./packages.nix { inherit pkgs inputs; }) ++ [
    (pkgs.writeShellScriptBin "codex-wrapped" ''
      set -euo pipefail
      export SOPS_AGE_KEY_FILE="${config.home.homeDirectory}/.config/sops/age/keys.txt"
      SECRETS_FILE="${config.home.homeDirectory}/nix-config/secrets/coding-agents.yaml"
      exec sops exec-env "$SECRETS_FILE" -- codex "$@"
    '')
  ];
  ```
  **NOTE:** Standalone-linux uses the SAME committed in-store ciphertext as NixOS/Darwin (NOT out-of-store sync-secrets, to avoid model conflict). The `SOPS_AGE_KEY_FILE` must point to the age key file for runtime decryption. Only `codex-wrapped` is added (NOT `opencode-wrapped`) because `includeOpencode = false` means `opencode` is not on PATH on standalone-linux. **Acceptance:** `codex-wrapped` is on PATH on standalone-linux. **QA:** Run `which codex-wrapped`, verify it exists. **Failure:** If not on PATH, check home-manager configuration. **Commit:** Included in commit 3.

- [x] 17. **Run tests/package-policy.sh + nix flake check.** Run `bash tests/package-policy.sh` and `nix flake check`. Both must pass. **Acceptance:** Both commands exit 0. **QA:** Run both commands, verify exit 0. **Failure:** If either fails, check error messages, fix issues. **Commit:** No commit (verification only).

- [x] 18. **Verify all packages build.** Run `nix build .#codex-omx`, `nix build .#opencode-omo`, `nix build .#omniwm` (on macOS arm64). All must succeed. **Acceptance:** All builds succeed. **QA:** Run the build commands, verify exit 0. **Failure:** If build fails, check error messages, fix derivation. **Commit:** No commit (verification only).

- [x] 19. **Verify secret delivery works.** Run `sops exec-env secrets/coding-agents.yaml -- env | grep OPENAI_API_KEY`. Run `secretspec check`. Both must work. **Acceptance:** Secrets are delivered correctly. **QA:** Run the commands, verify secrets are present. **Failure:** If secrets not delivered, check sops configuration, verify secrets file exists. **Commit:** No commit (verification only).

- [x] 20. **F1-F5 final verification wave.** Run F1 (plan compliance audit), F2 (code quality review), F3 (real manual QA), F4 (scope fidelity), F5 (secret delivery verification). All must PASS. **Acceptance:** All 5 verifiers PASS. **QA:** Run all 5 verifiers, verify all PASS. **Failure:** If any verifier fails, check error messages, fix issues. **Commit:** No commit (verification only).

## Final verification wave

- [x] F1. **Plan compliance audit.** Re-read `/home/mei/nix-config/.omo/plans/agent-packages-and-secrets.md` and the working tree. Confirm: (a) every change in Scope IN is present in the diff; (b) every change in Scope OUT is absent; (c) all three commits match the commit strategy; (d) the 7 targeted nix eval commands pass (hydralauncher, vesktop, codex-omx, opencode-omo, omniwm, darwin toplevel, sops.secrets); (e) the file count is exactly 20 (19 source files + .gitignore). Output "F1: PASS" or "F1: FAIL <reason>".

- [x] F2. **Code quality review.** Review all diffs from the 3 commits. Check: (a) no secret patterns in code; (b) recipe structure correct (codex-omx, opencode-omo use buildNpmPackage with generated lockfiles + postPatch injection + dontNpmBuild + makeWrapper; opencode-omo also injects stripped package.json; omniwm uses fetchzip + stdenvNoCC); (c) no mkDerivation in lib/ or modules/; (d) no x86_64-darwin rows; (e) harness wrappers replace bare CLI correctly. Output "F2: PASS" or "F2: FAIL <reason>".

- [x] F3. **Real manual QA.** Re-run all 7 targeted nix eval commands, policy test, build verification, secret delivery verification. All must pass. Output "F3: PASS" or "F3: FAIL <reason>".

- [x] F4. **Scope fidelity.** Confirm: (a) no unrelated flake input updates; (b) no changes to tests/package-policy.sh or lib/nixpkgs.nix; (c) no new overlays; (d) no changes to existing packages except replacing bare codex/opencode; (e) no changes to README.md; (f) .gitignore has `!secrets/coding-agents.yaml` exception; (g) config/package-exceptions.json has exactly 3 new opencode-omo rows (x86_64-linux, aarch64-linux, aarch64-darwin). Output "F4: PASS" or "F4: FAIL <reason>".

- [x] F5. **Secret delivery verification.** Verify: (a) sops exec-env wrapper scripts work; (b) sops-nix activation-time delivery works; (c) standalone-linux delivery works using committed in-store ciphertext; (d) secretspec check passes. Output "F5: PASS" or "F5: FAIL <reason>".

## Commit strategy

- Commit 1: Wave 1 (packaging) — "feat(packages): add hydralauncher, vesktop, codex-omx, opencode-omo, omniwm"
- Commit 2: Wave 2 (secret infrastructure) — "feat(secrets): add sops/secretspec infrastructure for coding agents"
- Commit 3: Wave 3 (secret delivery) — "feat(secrets): add secret delivery for coding agents"
- Wave 4 is verification only (no commit)

## Success criteria

1. All 5 packages are added and build successfully: hydralauncher, vesktop, codex-omx, opencode-omo, omniwm
2. Harness wrappers replace bare codex/opencode on PATH
3. Flake packages output exposes pkgs/ as flake package outputs
4. Secret infrastructure is set up: .sops.yaml, secrets/coding-agents.yaml (committed), secretspec.toml
5. Validators are modified to allow secretTrust enrollment on darwin/aarch64 (inline predicate preserving all identity fields)
6. Secret delivery works: sops exec-env wrapper scripts with SOPS_AGE_KEY_FILE, sops-nix activation-time delivery, standalone-linux delivery using committed in-store ciphertext
7. tests/package-policy.sh passes
8. nix flake check passes (or pre-existing failures documented)
9. All 7 targeted nix eval commands pass
10. All 5 final verifiers (F1-F5) PASS
