# curl-installed-coding-agents - Work Plan

## TL;DR (For humans)

**What you'll get.** On non-NixOS machines (standalone-linux + darwin), coding agents (codex, opencode, oh-my-codex, oh-my-openagent, Pi, Hermes, Zeroclaw) are installed via their native curl/npm installers through a home-manager activation script — self-updating, not Nix-managed. Nix still owns secrets (sops exec-env wrappers) and configs. NixOS keeps the existing Nix derivations untouched.

**Why this approach.** The Nix derivations (buildNpmPackage) pin versions and require manual hash updates. The curl-installed tools auto-update. Nix's role shrinks to: triggering initial install (activation), injecting secrets (wrapper scripts), and managing configs. NixOS keeps derivations because NixOS activation is the natural place for Nix-managed packages.

**What it will NOT do.** No changes to NixOS modules. No changes to flake.nix inputs. No changes to sops/secretspec infrastructure. No new overlays. No changes to README.md. No removal of pkgs/*.nix files (they remain for NixOS). No changes to config/package-exceptions.json.

**Effort.** ~6 todos across 3 waves.

**Risk.** Low. The activation script is additive and idempotent. Gating derivations is a parameter addition with a default that preserves current behavior.

**Decisions I made for you:**
- Activation skips install if binary already in PATH (idempotent, fast re-switches)
- npm/curl/bash referenced via nix store paths in activation (works regardless of PATH)
- pi/hermes/zeroclaw wrappers only on non-NixOS (not in mei.nix which applies to NixOS too)
- codex-wrapped/opencode-wrapped in mei.nix stay unchanged (they resolve `codex`/`opencode` from PATH — works for both nix derivation and curl-installed)
- Activation runs after writeBoundary (standard home-manager ordering)
- nodejs added to activation script references (npm needed for 3 of 7 agents)

## Scope

**In scope:**
- Add `includeCodingAgentDerivations ? true` parameter to `modules/shared/packages.nix`, gate codex-omx and opencode-omo behind it
- Pass `includeCodingAgentDerivations = false` from `modules/standalone-linux/packages.nix`
- Pass `includeCodingAgentDerivations = false` from `modules/darwin/packages.nix`
- Add `home.activation.installCodingAgents` to `modules/standalone-linux/home-manager.nix`
- Add `home.activation.installCodingAgents` to `modules/darwin/user-home.nix`
- Add pi-wrapped, hermes-wrapped, zeroclaw-wrapped wrapper scripts to `modules/standalone-linux/home-manager.nix`
- Add pi-wrapped, hermes-wrapped, zeroclaw-wrapped wrapper scripts to `modules/darwin/user-home.nix`

**Out of scope (Must NOT have):**
- No changes to NixOS modules (modules/nixos/, modules/linux/)
- No changes to flake.nix inputs
- No changes to sops.nix, secrets.nix, secretspec.toml, .sops.yaml, secrets/coding-agents.yaml
- No changes to pkgs/codex-omx.nix, pkgs/opencode-omo.nix, pkgs/omniwm.nix
- No changes to config/package-exceptions.json
- No changes to modules/aspects/users/mei.nix (codex-wrapped/opencode-wrapped stay as-is)
- No changes to modules/flake/packages.nix
- No new overlays
- No changes to README.md
- No changes to tests/

## Verification strategy

**Test strategy: tests-after with agent-executed QA**

- `nix eval` checks confirm derivations are absent on non-NixOS and present on NixOS
- `nix flake check` passes (or pre-existing failures documented)
- Activation script syntax validated via `nix eval` of the home-manager config
- Wrapper scripts verified via `nix eval` of home.packages

## Execution strategy

**Wave 1 — Gate derivations (3 todos, parallel):**
1. Gate codex-omx/opencode-omo in shared/packages.nix
2. Pass includeCodingAgentDerivations=false from standalone-linux
3. Pass includeCodingAgentDerivations=false from darwin

**Wave 2 — Activation + wrappers (2 todos, parallel):**
4. Add activation + wrappers to standalone-linux/home-manager.nix
5. Add activation + wrappers to darwin/user-home.nix

**Wave 3 — Verification (1 todo):**
6. Run nix eval checks + nix flake check

**Dependency matrix:**
- Wave 1 todos are independent (different files)
- Wave 2 depends on Wave 1 (activation replaces derivations)
- Wave 3 depends on all previous waves

**Commit strategy:**
- Commit 1: Wave 1+2 — "feat(agents): curl-installed coding agents on non-NixOS, Nix-managed secrets"
- Wave 3 is verification only (no commit)

## Todos

- [x] 1. **Gate codex-omx/opencode-omo behind `includeCodingAgentDerivations` in shared/packages.nix.** Edit `modules/shared/packages.nix`. Add `includeCodingAgentDerivations ? true` to the function parameters (line 1). Wrap the codex-omx callPackage (line 87) and the opencode-omo conditional block (lines 89-91) in `pkgs.lib.optionals includeCodingAgentDerivations [ ... ]`. The result: when `includeCodingAgentDerivations = true` (default, NixOS), both derivations appear. When `false` (non-NixOS), neither appears. **Exact change to line 1:** `{ pkgs, includeDocker ? true, includeOpencode ? true, includeCodingAgentDerivations ? true }:`. **Exact change to lines 87-91:** Replace the unconditional `(pkgs.callPackage ../../pkgs/codex-omx.nix { })` and the `++ pkgs.lib.optionals (includeOpencode && ...) [ ... ]` block with: `++ pkgs.lib.optionals includeCodingAgentDerivations ([ (pkgs.callPackage ../../pkgs/codex-omx.nix { }) ] ++ pkgs.lib.optionals (includeOpencode && pkgs.stdenv.hostPlatform.system != "x86_64-darwin") [ (pkgs.callPackage ../../pkgs/opencode-omo.nix { }) ])`. **Acceptance:** `nix eval .#nixosConfigurations.x86_64-linux.config.home-manager.users.mei.home.packages --apply 'ps: builtins.length (builtins.filter (p: (p.pname or "") == "codex-omx") ps)'` returns 1 (NixOS still has it). **QA:** Run the eval command. **Commit:** Included in commit 1.

- [x] 2. **Pass `includeCodingAgentDerivations = false` from standalone-linux/packages.nix.** Edit `modules/standalone-linux/packages.nix`. Change line 4-6 from `import ../shared/packages.nix { inherit pkgs; includeOpencode = false; };` to `import ../shared/packages.nix { inherit pkgs; includeOpencode = false; includeCodingAgentDerivations = false; };`. **Acceptance:** `nix eval .#homeConfigurations.standalone-linux.config.home.packages --apply 'ps: builtins.length (builtins.filter (p: (p.pname or "") == "codex-omx") ps)'` returns 0. **QA:** Run the eval command. **Commit:** Included in commit 1.

- [x] 3. **Pass `includeCodingAgentDerivations = false` from darwin/packages.nix.** Edit `modules/darwin/packages.nix`. Change line 4 from `import ../shared/packages.nix { inherit pkgs; includeDocker = false; };` to `import ../shared/packages.nix { inherit pkgs; includeDocker = false; includeCodingAgentDerivations = false; };`. **Acceptance:** `nix eval .#darwinConfigurations.aarch64-darwin.config.users.users.mei.home.packages --apply 'ps: builtins.length (builtins.filter (p: (p.pname or "") == "codex-omx") ps)'` returns 0 (or equivalent darwin home packages eval). **QA:** Run the eval command. **Commit:** Included in commit 1.

- [x] 4. **Add installCodingAgents activation + pi/hermes/zeroclaw wrappers to standalone-linux/home-manager.nix.** Edit `modules/standalone-linux/home-manager.nix`. Add after the `home = { ... };` block (after line 37, before `targets.genericLinux`): **(A) Activation script:**
```nix
home.activation.installCodingAgents = let
  npm = "${pkgs.nodejs}/bin/npm";
  curl = "${pkgs.curl}/bin/curl";
  bash = "${pkgs.bash}/bin/bash";
in lib.hm.dag.entryAfter ["writeBoundary"] ''
  install_if_missing() {
    local name="$1" cmd="$2"
    if ! command -v "$name" &>/dev/null; then
      echo "install-coding-agents: installing $name..."
      eval "$cmd"
    fi
  }
  install_if_missing codex "${npm} install -g @openai/codex"
  install_if_missing omx "${npm} install -g oh-my-codex"
  install_if_missing omo "${npm} install -g oh-my-opencode"
  install_if_missing opencode "${curl} -fsSL https://opencode.ai/install | ${bash}"
  install_if_missing pi "${curl} -fsSL https://pi.dev/install.sh | ${bash}"
  install_if_missing hermes "${curl} -fsSL https://hermes-agent.nousresearch.com/install.sh | ${bash}"
  install_if_missing zeroclaw "${curl} -fsSL https://zeroclawlabs.ai/install.sh | ${bash}"
'';
```
**(B) Wrapper scripts** — add to the existing `packages = ...` list (line 18), after the codex-wrapped entry:
```nix
((pkgs.writeShellScriptBin "pi-wrapped" ''
  set -euo pipefail
  export SOPS_AGE_KEY_FILE="${config.home.homeDirectory}/.config/sops/age/keys.txt"
  SECRETS_FILE="${config.home.homeDirectory}/nix-config/secrets/coding-agents.yaml"
  exec sops exec-env "$SECRETS_FILE" -- pi "$@"
'') // { pname = "pi-wrapped"; })
((pkgs.writeShellScriptBin "hermes-wrapped" ''
  set -euo pipefail
  export SOPS_AGE_KEY_FILE="${config.home.homeDirectory}/.config/sops/age/keys.txt"
  SECRETS_FILE="${config.home.homeDirectory}/nix-config/secrets/coding-agents.yaml"
  exec sops exec-env "$SECRETS_FILE" -- hermes "$@"
'') // { pname = "hermes-wrapped"; })
((pkgs.writeShellScriptBin "zeroclaw-wrapped" ''
  set -euo pipefail
  export SOPS_AGE_KEY_FILE="${config.home.homeDirectory}/.config/sops/age/keys.txt"
  SECRETS_FILE="${config.home.homeDirectory}/nix-config/secrets/coding-agents.yaml"
  exec sops exec-env "$SECRETS_FILE" -- zeroclaw "$@"
'') // { pname = "zeroclaw-wrapped"; })
```
**NOTE:** `pkgs.nodejs` must be available. It is not currently in standalone-linux packages. Add `pkgs.nodejs` to the standalone-linux packages list (line 12, after `pkgs.sops`). **Acceptance:** `nix eval .#homeConfigurations.standalone-linux.config.home.packages --apply 'ps: builtins.length (builtins.filter (p: (p.pname or "") == "pi-wrapped") ps)'` returns 1. `nix eval .#homeConfigurations.standalone-linux.home.activation.installCodingAgents` evaluates without error. **QA:** Run both eval commands. **Commit:** Included in commit 1.

- [x] 5. **Add installCodingAgents activation + pi/hermes/zeroclaw wrappers to darwin/user-home.nix.** Edit `modules/darwin/user-home.nix`. The file currently has `{ pkgs, user, ... }:` as params and a minimal `home = { ... };` block. **(A)** Add `lib` to the function params: `{ pkgs, lib, user, ... }:`. **(B)** Add activation script after the `home = { ... };` block:
```nix
home.activation.installCodingAgents = let
  npm = "${pkgs.nodejs}/bin/npm";
  curl = "${pkgs.curl}/bin/curl";
  bash = "${pkgs.bash}/bin/bash";
in lib.hm.dag.entryAfter ["writeBoundary"] ''
  install_if_missing() {
    local name="$1" cmd="$2"
    if ! command -v "$name" &>/dev/null; then
      echo "install-coding-agents: installing $name..."
      eval "$cmd"
    fi
  }
  install_if_missing codex "${npm} install -g @openai/codex"
  install_if_missing omx "${npm} install -g oh-my-codex"
  install_if_missing omo "${npm} install -g oh-my-opencode"
  install_if_missing opencode "${curl} -fsSL https://opencode.ai/install | ${bash}"
  install_if_missing pi "${curl} -fsSL https://pi.dev/install.sh | ${bash}"
  install_if_missing hermes "${curl} -fsSL https://hermes-agent.nousresearch.com/install.sh | ${bash}"
  install_if_missing zeroclaw "${curl} -fsSL https://zeroclawlabs.ai/install.sh | ${bash}"
'';
```
**(C)** Add wrapper scripts + nodejs to the `home.packages` list (line 7). Change from `packages = pkgs.callPackage ./packages.nix { };` to:
```nix
packages = (pkgs.callPackage ./packages.nix { }) ++ [
  pkgs.nodejs
  ((pkgs.writeShellScriptBin "pi-wrapped" ''
    set -euo pipefail
    export SOPS_AGE_KEY_FILE="${user.identity.home}/.config/sops/age/keys.txt"
    SECRETS_FILE="${user.identity.home}/nix-config/secrets/coding-agents.yaml"
    exec sops exec-env "$SECRETS_FILE" -- pi "$@"
  '') // { pname = "pi-wrapped"; })
  ((pkgs.writeShellScriptBin "hermes-wrapped" ''
    set -euo pipefail
    export SOPS_AGE_KEY_FILE="${user.identity.home}/.config/sops/age/keys.txt"
    SECRETS_FILE="${user.identity.home}/nix-config/secrets/coding-agents.yaml"
    exec sops exec-env "$SECRETS_FILE" -- hermes "$@"
  '') // { pname = "hermes-wrapped"; })
  ((pkgs.writeShellScriptBin "zeroclaw-wrapped" ''
    set -euo pipefail
    export SOPS_AGE_KEY_FILE="${user.identity.home}/.config/sops/age/keys.txt"
    SECRETS_FILE="${user.identity.home}/nix-config/secrets/coding-agents.yaml"
    exec sops exec-env "$SECRETS_FILE" -- zeroclaw "$@"
  '') // { pname = "zeroclaw-wrapped"; })
];
```
**NOTE:** Darwin uses `user.identity.home` (not `config.home.homeDirectory`) because this module receives `user` as a param, not the home-manager `config`. The codex-wrapped/opencode-wrapped wrappers in mei.nix use `config.home.homeDirectory` — that's fine because mei.nix is a homeManager module with `config` in scope. **Acceptance:** `nix eval .#darwinConfigurations.aarch64-darwin.config.home-manager.users.mei.home.packages --apply 'ps: builtins.length (builtins.filter (p: (p.pname or "") == "pi-wrapped") ps)'` returns 1 (or equivalent darwin eval path). **QA:** Run the eval command. **Commit:** Included in commit 1.

- [x] 6. **Verification: nix eval checks + nix flake check.** Run all verification commands: **(A)** NixOS still has derivations: `nix eval .#nixosConfigurations.x86_64-linux.config.home-manager.users.mei.home.packages --apply 'ps: builtins.length (builtins.filter (p: (p.pname or "") == "codex-omx") ps)'` → 1. **(B)** Standalone-linux does NOT have derivations: same eval on `.#homeConfigurations.standalone-linux` → 0. **(C)** Standalone-linux HAS wrappers: eval pi-wrapped → 1, hermes-wrapped → 1, zeroclaw-wrapped → 1, codex-wrapped → 1. **(D)** `bash tests/package-policy.sh` → exit 0. **(E)** `nix flake check 2>&1 | tail -20` → pass or pre-existing failure only. **Acceptance:** All checks pass. **QA:** Run all commands, capture output. **Commit:** No commit (verification only).

## Final verification wave

- [x] F1. **Plan compliance audit.** Re-read this plan and the working tree. Confirm: (a) every in-scope change is present; (b) every out-of-scope item is absent (no changes to NixOS modules, flake.nix, sops.nix, secrets.nix, secretspec.toml, .sops.yaml, secrets/, pkgs/*.nix, config/package-exceptions.json, modules/aspects/users/mei.nix, modules/flake/packages.nix, README.md, tests/); (c) NixOS still has codex-omx and opencode-omo derivations; (d) standalone-linux and darwin do NOT have codex-omx/opencode-omo derivations; (e) standalone-linux and darwin HAVE the activation script and pi/hermes/zeroclaw wrappers. Output "F1: PASS" or "F1: FAIL <reason>".

- [x] F2. **Scope fidelity.** Confirm: (a) `git diff HEAD -- modules/nixos/ modules/linux/` → empty; (b) `git diff HEAD -- flake.nix` → empty; (c) `git diff HEAD -- modules/aspects/features/sops.nix modules/aspects/features/secrets.nix secretspec/secretspec.toml .sops.yaml` → empty; (d) `git diff HEAD -- pkgs/` → empty; (e) `git diff HEAD -- config/package-exceptions.json` → empty; (f) `git diff HEAD -- modules/aspects/users/mei.nix` → empty; (g) `git diff HEAD -- modules/flake/packages.nix` → empty; (h) `git diff HEAD -- README.md tests/` → empty. Output "F2: PASS" or "F2: FAIL <reason>".

## Commit strategy

- Commit 1: Wave 1+2 — "feat(agents): curl-installed coding agents on non-NixOS, Nix-managed secrets"
- Wave 3 is verification only (no commit)

## Success criteria

1. NixOS still has codex-omx and opencode-omo as Nix derivations (unchanged)
2. Standalone-linux and darwin do NOT have codex-omx/opencode-omo derivations
3. Standalone-linux and darwin have home.activation.installCodingAgents that installs all 7 agents
4. Standalone-linux and darwin have pi-wrapped, hermes-wrapped, zeroclaw-wrapped wrapper scripts
5. Existing codex-wrapped/opencode-wrapped wrappers unchanged (mei.nix for NixOS+Darwin, standalone-linux for standalone)
6. tests/package-policy.sh passes
7. nix flake check passes (or pre-existing failures only)
8. No changes to any out-of-scope file
