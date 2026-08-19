---
slug: agent-packages-and-secrets
status: approved
intent: clear
review_required: true
plan_path: /home/mei/nix-config/.omo/plans/agent-packages-and-secrets.md
plan_sha256: pending-recompute-round-008
review_round_id: agent-packages-and-secrets-review-2026-07-27-008
round_status: complete
pending-action: execute via /start-work
approach: |
  Wave 1: Package applications (hydralauncher, vesktop, codex-omx buildNpmPackage+lockfile, opencode-omo buildNpmPackage+lockfile, omniwm)
  Wave 2: Secret infrastructure (.sops.yaml, encrypted secrets, secretspec manifest, validator modification)
  Wave 3: Secret delivery (wrapper scripts, home-manager wiring, sops-nix activation, standalone-linux delivery)
  Wave 4: Verification (policy test, flake check, build verification, secret delivery verification)
review:
  momus:
    status: approved
    workspace_root: /home/mei/nix-config
    runtime_home: null
    target: /home/mei/nix-config/.omo/plans/agent-packages-and-secrets.md
    round_id: agent-packages-and-secrets-review-2026-07-27-008
    plan_sha256: pending-recompute-round-008
    launch_id: momus-2026-07-27-008
    session: ses_05b2c1116ffeLL4PuSo9CX1mXE
    result: APPROVED — 23/23 checklist items pass
  independent:
    status: approved
    workspace_root: /home/mei/nix-config
    runtime_home: null
    target: /home/mei/nix-config/.omo/plans/agent-packages-and-secrets.md
    round_id: agent-packages-and-secrets-review-2026-07-27-008
    plan_sha256: pending-recompute-round-008
    launch_id: oracle-2026-07-27-008
    session: ses_05b2bce7fffe8YftQ4LtttGYow
    result: APPROVED — all 7 round-7 findings verified against locked nixpkgs source
---

# Draft: agent-packages-and-secrets

## Components (topology ledger)

| id | outcome | status | evidence |
|---|---|---|---|
| C1-hydralauncher | hydralauncher added to Linux x86_64 packages | pending | modules/linux/packages.nix |
| C2-vesktop | vesktop added to Linux packages | pending | modules/linux/packages.nix |
| C3-codex-omx | pkgs/codex-omx.nix created (fetchurl+makeWrapper, v0.20.3), replaces bare codex | pending | pkgs/codex-omx.nix |
| C4-opencode-omo | pkgs/opencode-omo.nix created (fetchurl+makeWrapper, v4.19.2, unfree), replaces bare opencode | pending | pkgs/opencode-omo.nix, config/package-exceptions.json |
| C5-omniwm | pkgs/omniwm.nix created for macOS arm64 | pending | pkgs/omniwm.nix |
| C6-wiring | Harness packages wired into package lists | pending | modules/shared/packages.nix, modules/darwin/packages.nix |
| C7-age-identity | Age identity generation documented | pending | docs/secrets/age-identity.md |
| C8-sops-config | .sops.yaml created with age recipient rules | pending | .sops.yaml |
| C9-encrypted-secrets | secrets/coding-agents.yaml created (sops-encrypted) | pending | secrets/coding-agents.yaml |
| C10-secretspec-manifest | secretspec.toml updated with coding agent secrets | pending | secretspec/secretspec.toml |
| C11-validator-mod | validators.nix modified to allow secretTrust on darwin/aarch64 | pending | modules/entities/_machine-authority/validators.nix |
| C12-wrapper-scripts | codex-wrapped, opencode-wrapped scripts created | pending | modules/aspects/users/mei.nix |
| C13-hm-wiring | Wrappers wired into home-manager config | pending | modules/aspects/users/mei.nix |
| C14-sops-activation | sops-nix activation-time delivery for NixOS/Darwin | pending | modules/aspects/features/sops.nix |
| C15-out-of-store | Out-of-store delivery for standalone-linux | pending | modules/standalone-linux/ |

## Open assumptions (announced defaults)

| assumption | default | rationale | reversible? |
|---|---|---|---|
| Harness replaces bare CLI | codex-omx provides `codex` command, opencode-omo provides `opencode` command | User chose "Replace bare CLI" | Yes |
| One combined plan | Single plan covering packaging + secrets | User chose "One combined plan" | Yes |
| All major provider keys | OPENAI_API_KEY, ANTHROPIC_API_KEY, GEMINI_API_KEY, OPENROUTER_API_KEY, GITHUB_TOKEN | User chose "All major provider keys" | Yes |
| sops exec-env wrapper | Wrapper scripts use `sops exec-env` to inject secrets | User chose "sops exec-env wrapper" | Yes |
| Both validator mod + out-of-store | Modify validators.nix AND set up out-of-store delivery | User chose "Both" | Yes |
| Hydra from nixpkgs | Use `pkgs.hydralauncher` (v4.0.3, MIT, Linux-only) | Already in nixpkgs | Yes |
| OmniWM binary derivation | Pre-built .app ZIP, arm64-only, macOS 26+ | Not in nixpkgs, binary distribution | Yes |
| Vesktop on Linux | Add to modules/linux/packages.nix | Already on darwin, user wants it on Linux too | Yes |
| secretspec 0.13.0 limitation | Use sops CLI directly, not secretspec age provider | secretspec 0.13.0 lacks age provider (0.17+) | Yes |

## Findings (cited)

- Hydra Gaming Launcher is in nixpkgs as `hydralauncher` v4.0.3 (MIT, AppImage wrap, Linux-only, 24 platforms) — no custom derivation needed
- OmniWM is NOT in nixpkgs — needs custom binary derivation (v0.5.9, GPL-2.0-only, arm64-only, macOS 26+)
- Vesktop is already in darwin packages (modules/darwin/packages.nix:14) — just add to Linux
- Codex CLI is in nixpkgs (modules/shared/packages.nix:87) — need harness wrapper
- Opencode is in nixpkgs (modules/shared/packages.nix:92) — need harness wrapper
- oh-my-codex is npm package (Yeachan-Heo/oh-my-codex, v0.20.3, MIT) — wraps Codex CLI, entry point dist/cli/omx.js
- oh-my-openagent is npm package (code-yeongyu/oh-my-openagent, v4.19.2, SUL-1.0/unfree) — wraps Opencode, published as oh-my-opencode on npm, Bun workspace monorepo (no package-lock.json, buildNpmPackage infeasible)
- NixOS package eval path: config.home-manager.users.mei.home.packages (NOT config.environment.systemPackages)
- lib.licenses.sul1 does NOT exist in locked nixpkgs — must use lib.licenses.unfree + config/package-exceptions.json rows
- No decryption identity exists on this host (no ~/.ssh/id_ed25519, no age key)
- No .sops.yaml exists
- secretspec 0.13.0 can't decrypt age files (age provider is 0.17+)
- Machine authority validators block secretTrust enrollment on darwin/aarch64 (validators.nix:434-443)
- tests/package-policy.sh forbids mkDerivation in lib/ or modules/ — custom derivations must live in pkgs/

## Scope IN

- Add hydralauncher to modules/linux/packages.nix (x86_64 block)
- Add vesktop to modules/linux/packages.nix
- Create pkgs/codex-omx.nix (fetchurl + makeWrapper derivation, v0.20.3)
- Create pkgs/opencode-omo.nix (fetchurl + makeWrapper derivation, v4.19.2, unfree)
- Add opencode-omo rows to config/package-exceptions.json (3 systems)
- Create pkgs/omniwm.nix (binary derivation for macOS arm64)
- Wire codex-omx and opencode-omo into modules/shared/packages.nix (replacing bare codex/opencode)
- Wire omniwm into modules/darwin/packages.nix
- Add flake packages output (modules/flake/packages.nix)
- Document age identity generation steps (docs/secrets/age-identity.md)
- Create .sops.yaml with age recipient rules
- Create secrets/coding-agents.yaml (sops-encrypted) with 5 API keys
- Add !secrets/coding-agents.yaml to .gitignore
- Update secretspec/secretspec.toml with coding agent secret declarations
- Modify validators.nix to allow secretTrust enrollment on darwin/aarch64
- Create wrapper scripts (codex-wrapped, opencode-wrapped) using sops exec-env
- Wire wrappers into home-manager config (modules/aspects/users/mei.nix)
- Set up sops-nix activation-time delivery for NixOS/Darwin (modules/aspects/features/sops.nix)
- Set up standalone-linux delivery using committed in-store ciphertext

## Scope OUT (Must NOT have)

- No changes to flake.nix inputs (sops-nix already exists)
- No changes to flake.lock
- No changes to tests/package-policy.sh
- No changes to lib/nixpkgs.nix
- No new overlays
- No mkDerivation in lib/ or modules/
- No x86_64-darwin rows in package-exceptions.json
- No changes to existing packages (except replacing bare codex/opencode with harness wrappers)
- No changes to README.md
- No changes to secrets/README.md

## Approval gate

status: awaiting-approval
approach: Wave 1 (packaging) → Wave 2 (secret infrastructure) → Wave 3 (secret delivery) → Wave 4 (verification)
next: write .omo/plans/agent-packages-and-secrets.md after approval
