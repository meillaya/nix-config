---
slug: secrets-stack-and-packages
status: review-round-initialized
intent: clear
review_required: true
plan_path: /home/mei/nix-config/.omo/plans/secrets-stack-and-packages.md
plan_sha256: 62dbc60c7ae2e0cb370a52018e0016c83f0aa75706131380d35a707468b85674
review_round_id: secrets-stack-and-packages-review-2026-07-24-004
round_status: active
pending-action: review .omo/plans/secrets-stack-and-packages.md
approach: Wire sops-nix and secretspec alongside the already-adopted agenix with a clear three-tier role split (NixOS activation files / structured shared secrets / app-facing typed secrets); add Sublime4 to Linux packages via nixpkgs with explicit unfree exceptions for x86_64-linux and aarch64-linux; add elecwhat-bin via a fresh derivation in pkgs/ that wraps the upstream piec/elecwhat pacman with electron + wrapGAppsHook3; do not enroll a real first secret in this pass.
review:
  momus:
    status: pending
    workspace_root: /home/mei/nix-config
    runtime_home: null
    target: /home/mei/nix-config/.omo/plans/secrets-stack-and-packages.md
    round_id: secrets-stack-and-packages-review-2026-07-24-004
    plan_sha256: 62dbc60c7ae2e0cb370a52018e0016c83f0aa75706131380d35a707468b85674
    launch_id: momus-2026-07-24-004
    session: null
    result: null
  independent:
    status: pending
    workspace_root: /home/mei/nix-config
    runtime_home: null
    target: /home/mei/nix-config/.omo/plans/secrets-stack-and-packages.md
    round_id: secrets-stack-and-packages-review-2026-07-24-004
    plan_sha256: 62dbc60c7ae2e0cb370a52018e0016c83f0aa75706131380d35a707468b85674
    launch_id: oracle-2026-07-24-004
    session: null
    result: null
---

# Draft: secrets-stack-and-packages

## Components (topology ledger)
| id | outcome (one line) | status | evidence path |
| --- | --- | --- | --- |
| C1-sops-input | Flake declares `sops-nix` input with `inputs.nixpkgs.follows = "nixpkgs"` and the lock file pins it. | active | `flake.nix:3-44`, `flake.lock:3-23` |
| C2-sops-aspect | A new `modules/aspects/features/sops.nix` Den aspect imports `sops-nix.nixosModules.default` / `darwinModules.default`, mirrors `age.identityPaths` into `sops.age.sshKeyPaths`, exposes `sops.secrets.*` config, and adds `pkgs.sops` to the host. It is included from `darwin-platform` and `linux-platform` exactly like the existing `secrets` aspect. | active | `modules/aspects/features/secrets.nix:1-19`, `modules/aspects/platforms/darwin.nix:1-9`, `modules/aspects/platforms/linux.nix:1-9` |
| C3-secretspec-binary | `pkgs.secretspec` is added to `modules/shared/packages.nix` so every enrolled host gets the `secretspec` CLI. A template `secrets/secretspec.toml` is added that declares empty profiles and aliases for `age://`, `keyring://`, `env://`, and `dotenv://` so the on-host surface is usable without committing plaintext material. | active | `modules/shared/packages.nix:1-139`, `pkgs/_template.nix:1-41` |
| C4-agenix-expansion | The existing `secrets` Den aspect stays the canonical host file-delivery story. The aarch64-darwin `id_ed25519_agenix` SSH identity is added as a secondary `age.identityPaths` entry on Darwin hosts only, so the dormant keypair provisioned by `apps/aarch64-darwin/create-keys` is wired into the actual agenix decryption path. NixOS hosts continue to use `id_ed25519` alone. No real first secret is enrolled in this pass. | active | `modules/aspects/features/secrets.nix:1-19`, `modules/darwin/secrets.nix:1-4`, `modules/nixos/secrets.nix:1-4`, `apps/aarch64-darwin/create-keys:48`, `apps/aarch64-darwin/copy-keys:47-48`, `apps/aarch64-darwin/check-keys:17,27-31` |
| C5-sublime4-linux | `sublime4` is added to `modules/linux/packages.nix` (NixOS + standalone-linux). Two new entries are added to `config/package-exceptions.json` for the latest stable `sublime4` build version on `x86_64-linux` and `aarch64-linux` with 90-day TTL rows. No darwin row is added because `sublime4` is not a darwin nixpkgs attribute. | active | `modules/linux/packages.nix:1-72`, `config/package-exceptions.json:1-313`, `lib/nixpkgs.nix:1-45` |
| C6-elecwhat-bin-derivation | A new `pkgs/elecwhat-bin.nix` is added. It `fetchurl`s the upstream `piec/elecwhat` `.pacman`, extracts `opt/elecwhat/resources/app.asar` plus `app.asar.unpacked/`, wraps the asar with `${electron}/bin/electron` via `makeWrapper`, hooks `wrapGAppsHook3` + `patchelf`, and installs a `makeDesktopItem` entry. It is added to `modules/linux/packages.nix` (Linux only, electron-as-AppImage is not a darwin story). | active | `pkgs/_template.nix:1-41`, `pkgs/README.md:1-64`, `tests/package-policy.sh:1-191` |
| C7-readme-role-split | The README "Secrets" section is rewritten as a three-tier decision tree: (a) agenix for NixOS activation-time files; (b) sops-nix for shared/structured secrets with path-based recipient policy; (c) secretspec for new apps that want typed secrets via SDK. The README also gets a short note that the agenix aspect is fully wired but no machine has `secretTrust.state = "enrolled"` yet, and that this plan does NOT enroll a first secret. | active | `README.md:163-183`, `secrets/README.md:1-14` |

## Open assumptions (announced defaults)
| assumption | adopted default | rationale | reversible? |
| --- | --- | --- | --- |
| sops-nix flake input | Declare `sops-nix.url = "github:Mic92/sops-nix"` with `inputs.nixpkgs.follows = "nixpkgs"`. No `inputs.home-manager.follows` (sops-nix is only consumed by NixOS + Darwin here). | Standard sops-nix adoption per upstream README. Avoids a divergent nixpkgs pin. | Yes. |
| sops-nix key path | Mirror `${identity.home}/.ssh/id_ed25519` into `sops.age.sshKeyPaths` for both NixOS and Darwin; for aarch64-darwin hosts, also include `${identity.home}/.ssh/id_ed25519_agenix`. | Reuse the existing primary login SSH key (and the dormant `id_ed25519_agenix` on Darwin) without introducing a new identity file. Matches the existing agenix wiring. | Yes. |
| sops-nix package | Add `pkgs.sops` to `modules/shared/packages.nix` so the `sops` CLI is on every enrolled host. | The `sops` CLI is the on-host tool operators use to edit/rekey `.yaml`/`.json`/`.env` files. The sops-nix NixOS module's default already provides `sops-install-secrets`; this adds the user-facing binary. | Yes. |
| secretspec binary placement | Add `pkgs.secretspec` to `modules/shared/packages.nix` (every host). No NixOS module exists; no aspect needed. | secretspec is a per-app CLI/SDK; it is consumed by user processes, not the activation system. | Yes. |
| secretspec example toml | Add an empty `secrets/secretspec.toml` that declares `[project]`, `[providers]` aliases (no plaintext values), and one placeholder profile. The `.gitignore` already excludes `secrets/*` so the file MUST live at the repo root (e.g. `secretspec/secretspec.toml`) to stay in git. | Demonstrates the on-disk shape operators will use. The actual age provider lands in 0.17+ (unreleased as of 2026-07-24) so we do not commit a real `secrets.age` blob now. | Yes. |
| agenix key path on Darwin | Extend `modules/darwin/secrets.nix` so `age.identityPaths = [ "${identity.home}/.ssh/id_ed25519" "${identity.home}/.ssh/id_ed25519_agenix" ]`. NixOS hosts remain on `id_ed25519` only. | The `apps/aarch64-darwin/create-keys` and `copy-keys` scripts already provision `id_ed25519_agenix`; wiring it into agenix closes the gap. We do NOT do this on NixOS because no equivalent provisioning flow exists for x86 NixOS hosts. | Yes. |
| First secret | Do NOT enroll a first encrypted secret. The plan makes the three tools available; a follow-up plan (after the operator generates or imports the SSH identity and the age recipient) declares the first `age.secrets.<name>` / `sops.secrets.<name>` block and flips `secretTrust.state` to `enrolled`. | The repo's `validCrossFields` rule (`validators.nix:498-501`) requires `boot.state = "uefi"` + `storage.profile = "single-gpt-btrfs"` + `publicTrust.state = "enrolled"` to even allow `secretTrust.state = "enrolled"`. No machine currently satisfies that; forcing a first secret here would also force enrolling those orthogonal capabilities. | Yes. |
| Sublime Text package | Add `sublime4` to `modules/linux/packages.nix`. Do NOT add it to `modules/shared/packages.nix` (sublime4 is not a darwin nixpkgs attribute; sharing it would break darwin evaluation). | The repo's package-exceptions gate is keyed on `${system}:${pname}:${version}`. Sublime4's nixpkgs source only declares `aarch64-linux` and `x86_64-linux` in `meta.platforms`. Linux is the only legal target. | Yes. |
| Sublime Text license exception | Add two new rows to `config/package-exceptions.json`: one for `homeConfigurations.standalone-linux` and one for `nixosConfigurations.{aarch64-linux,x86_64-linux}` outputs, all with the current `sublime4` build version, `expiresAt` 90 days out, `reason: requested-desktop-application`, `owner: mei`. | Matches the existing pattern for `obsidian`, `spotify`, `claude-code` in `package-exceptions.json:92-103,256-267`. | Yes. |
| elecwhat-bin version pin | Pin to the latest upstream `piec/elecwhat` tag that has a published `.pacman` artifact (the librarian report shows AUR `elecwhat-bin` v1.14.0-2, which uses a piec release). Use a fake hash first and let nix report the real `sha256`. | Same pattern as `pkgs/README.md:18-29`. No existing nixpkgs PR for `elecwhat`; we own the recipe. | Yes (bump + re-hash later). |
| elecwhat-bin recipe shape | `stdenv.mkDerivation` with `fetchurl` on the upstream `.pacman` URL, `autoPatchelfHook` + `wrapGAppsHook3` in `nativeBuildInputs`, `runtimeInputs = [ electron xdg-utils ]`, `installPhase` that extracts `app.asar` to `$out/lib/elecwhat/resources/`, `app.asar.unpacked/` to `$out/lib/elecwhat/resources/`, and writes a `makeWrapper`d `$out/bin/elecwhat` plus a `makeDesktopItem` for `~/.local/share/applications/elecwhat.desktop`. | Mirrors the AUR `elecwhat-bin` PKGBUILD and the existing `_template.nix` patterns. The repo policy forbids `mkDerivation` inside `lib/` and `modules/` (`tests/package-policy.sh:32-37`) but does not scan `pkgs/`, so this is the legal home. | Yes. |
| elecwhat-bin scope | Add to `modules/linux/packages.nix` (NixOS + standalone-linux), not shared. The upstream `.pacman` is Linux-only. | The recipe builds on Linux via `stdenv.hostPlatform.system`; building on darwin would require a separate macOS recipe. | Yes. |
| README secrets rewrite | Replace the current "Secrets" section with a three-tier decision tree, and add a one-paragraph note that agenix is already wired but the operator has not enrolled a secret yet. Add a one-line note that this plan does NOT enroll a first secret. | The current README only mentions agenix by name; readers will be confused by the new SOPS + secretspec modules unless we tell them which tool solves which problem. | Yes. |
| Tests | Run `tests/package-policy.sh` after every change to verify: no `mkDerivation` leaked into `lib/`/`modules/`, no overlay exported, the unfree predicate is still wired, and the new Sublime row admits sublime4. | The repo has a policy gate that will fail the build if a `mkDerivation` leaks out of `pkgs/`. | n/a. |
| Flake inputs NOT touched | `nixpkgs`, `home-manager`, `darwin`, `disko`, `zen-browser`, `spicetify-nix`, `helium`, `noctalia`, `den`, `flake-parts`, `import-tree`, `emacs-overlay` are unchanged. Only `sops-nix` is added. | Minimal flake-input churn keeps lock diff reviewable. | n/a. |

## Findings (cited - path:lines)
- `flake.nix:9` already declares `agenix.url = "github:ryantm/agenix"`; `flake.lock:3-23` pins it at rev `b027ee29d959fda4b60b57566c64c98a202e0feb`. Agenix is fully wired into `modules/aspects/features/secrets.nix:1-19` and is included from both `darwin-platform` (`modules/aspects/platforms/darwin.nix:6`) and `linux-platform` (`modules/aspects/platforms/linux.nix:6`).
- `modules/darwin/secrets.nix:1-4` and `modules/nixos/secrets.nix:1-4` set `age.identityPaths = [ "${identity.home}/.ssh/id_ed25519" ]` (single key, no `id_ed25519_agenix`).
- The aarch64-darwin `id_ed25519_agenix` keypair is provisioned by `apps/aarch64-darwin/create-keys:48` (generated), `apps/aarch64-darwin/copy-keys:47-48` (USB-imported), and linted by `apps/aarch64-darwin/check-keys:17,27-31`. It is currently NOT consumed by the agenix aspect.
- `lib/nixpkgs.nix:1-45` defines the `allowUnfreePredicate` keyed on `${system}:${pname}:${version}`. `tests/package-policy.sh:60-63` enforces that this predicate is present. The schema for unfree rows is in `config/package-exceptions.json:1-313`.
- `tests/package-policy.sh:32-37` scans `flake.nix`, `lib/`, and `modules/` for `(runCommand(Local)?|mkDerivation|build[A-Z][[:alnum:]_]*)`. `pkgs/` is NOT scanned, so a derivation at `pkgs/elecwhat-bin.nix` is legal.
- `tests/package-policy.sh:9-20` forbids `flake.overlays` exports and any `overlays.default` declaration.
- `pkgs/_template.nix:1-41` and `pkgs/README.md:1-64` establish the pattern for new derivations: `stdenv.mkDerivation` + `fetchzip`/`fetchurl` + `autoPatchelfHook` + a 0600 install phase. `makeWrapper` / `makeDesktopItem` / `wrapGAppsHook3` are not in the template but are the standard nixpkgs helpers.
- `modules/shared/packages.nix:1-139` is the cross-platform package list. `modules/linux/packages.nix:1-72` is the NixOS + standalone-linux extra. `modules/darwin/packages.nix:1-25` is the macOS extra.
- `config/package-exceptions.json:92-103,256-267` shows the existing `obsidian` and `spotify` Linux unfree rows as the template for `sublime4`. `package-exceptions.json:33-46,75-89,148-161,189-201` shows the existing `claude-code` rows as the cross-system template.
- `secrets/README.md:1-14` documents that the `secrets/` directory is git-ignored except for the README. A new `secretspec/secretspec.toml` at the repo root (not under `secrets/`) is the only way to keep the example in git.
- The `secretTrust` schema in `validators.nix:242-258` requires `ciphertexts != [ ]` and a `hostAgeRecipient` (bech32 `age1…`). No machine currently has `secretTrust.state = "enrolled"`; all four machines in `model.nix:28-29,65-66,102-103,139-140` carry the disabled singleton.
- Upstream sops-nix exposes `nixosModules.default`, `darwinModules.default`, and `homeManagerModules.default` from a single input; the README documents a `sops.age.sshKeyPaths` default of `[ "/etc/ssh/ssh_host_ed25519_key" ]` (which we will override to the user-ssh path to match agenix).
- `pkgs.secretspec` is in `nixos-unstable` at `0.16.0` (released 2026-07-17). It has no NixOS module. The `age` provider lands in 0.17+ (unreleased as of 2026-07-24) so the `secretspec.toml` we add cannot reference `age://…` without a working release.
- Sublime Text: canonical nixpkgs attribute is `sublime4` (NOT `sublime-text`); bare `sublime` is a deliberate throw in nixpkgs. `sublime4` is unfree and only declares `aarch64-linux` + `x86_64-linux` in `meta.platforms`.
- elecwhat-bin: NOT in nixpkgs. Upstream is `piec/elecwhat` (https://github.com/piec/elecwhat) — Electron 40, GPL-3.0-only, ships `.pacman` / AppImage / `.deb` / `.rpm` / `.snap` / `.tar.xz` artifacts. AUR `elecwhat-bin` v1.14.0-2 is maintained by the upstream `pierrec` and uses the `.pacman`.

## Decisions (with rationale)
1. Adopt all three tools together with a clear role split, rather than picking one. The user explicitly named all three; agenix is already wired, SOPS and secretspec are additive capabilities, and the three target different layers of the secret lifecycle (NixOS activation files / shared structured secrets / app-facing typed secrets).
2. Mirror agenix's `id_ed25519` into `sops.age.sshKeyPaths` so the same SSH identity decrypts both `.age` and `.sops.yaml` files. This avoids introducing a parallel key. On aarch64-darwin, also include the dormant `id_ed25519_agenix` so the existing keypair is finally consumed.
3. Do NOT enroll a first encrypted secret in this plan. Enrolling a first secret requires `boot.state = "uefi"` + `storage.profile = "single-gpt-btrfs"` + `publicTrust.state = "enrolled"` (`validators.nix:498-501`), which is a separate orthogonal capability workstream. This plan only makes the tooling available.
4. Add `sublime4` to `modules/linux/packages.nix` (not shared) because the nixpkgs attribute is Linux-only. Add a `sublime4` row for each of the two Linux home / NixOS outputs in `config/package-exceptions.json` with a 90-day TTL.
5. Author a custom `pkgs/elecwhat-bin.nix` rather than a flake input. The repo policy forbids overlays (`tests/package-policy.sh:9-20`) and forbids `mkDerivation` in `lib/`/`modules/` (`tests/package-policy.sh:32-37`); the legal home is `pkgs/`. The recipe uses the upstream `.pacman`, electron, and `wrapGAppsHook3` + `makeWrapper` + `makeDesktopItem` because the app is an Electron build, not a prebuilt ELF.
6. Add `secretspec/secretspec.toml` at the repo root (NOT under `secrets/`) because `secrets/*` is git-ignored. The toml contains only `[project]`, `[providers]` aliases with no plaintext values, and one placeholder profile — operators fill in real values on their own host after key enrollment.
7. Rewrite the README "Secrets" section to a three-tier decision tree and add a note that this plan does NOT enroll a first secret. The current README only mentions agenix; readers would otherwise be confused by the new SOPS + secretspec modules.

## Scope IN
- `flake.nix`: add `sops-nix` input with `inputs.nixpkgs.follows = "nixpkgs"`.
- `flake.lock`: refresh via `nix flake lock --update-input sops-nix` (only).
- New `modules/aspects/features/sops.nix`: Den aspect importing sops-nix modules, mirroring `age.identityPaths` into `sops.age.sshKeyPaths`, exposing `sops.secrets.*`, adding `pkgs.sops` to `environment.systemPackages`.
- `modules/aspects/platforms/darwin.nix`: add `den.aspects.sops` to the `includes` list.
- `modules/aspects/platforms/linux.nix`: add `den.aspects.sops` to the `includes` list.
- `modules/shared/packages.nix`: add `pkgs.sops` and `pkgs.secretspec`.
- `modules/linux/packages.nix`: add `sublime4` and `pkgs.callPackage ../../pkgs/elecwhat-bin.nix { }`.
- `modules/darwin/secrets.nix`: extend `age.identityPaths` to include `id_ed25519_agenix` for aarch64-darwin only.
- `modules/nixos/secrets.nix`: leave as-is (no `id_ed25519_agenix` provisioning flow on Linux).
- `config/package-exceptions.json`: add `sublime4` rows for `homeConfigurations.standalone-linux` and for both Linux `nixosConfigurations.*` outputs at the current build version, with `expiresAt` 90 days from `reviewedAt`, `reason: requested-desktop-application`, `owner: mei`.
- `pkgs/elecwhat-bin.nix`: new derivation per C6.
- `secretspec/secretspec.toml`: new template per C3 (under `secretspec/` at repo root, NOT under `secrets/`).
- `README.md`: rewrite the "Secrets" section to a three-tier decision tree; add a one-line note that this plan does NOT enroll a first secret.
- Agent-executed verification: `tests/package-policy.sh` PASS, `nix flake check` PASS, `nix flake show` enumerates the new `packages.x86_64-linux.elecwhat-bin` and `packages.aarch64-linux.elecwhat-bin` outputs and the new `sops-nix` input, and a `nix eval` of the four Linux outputs (NixOS x86_64, NixOS aarch64, standalone-linux, standalone-linux-aarch64) succeeds with `sublime4` resolving.

## Scope OUT (Must NOT have)
- No new flake inputs other than `sops-nix`. No `agenix-rekey` flake, no `secretspec` flake, no `nix-prefetch` flake.
- No new overlays or `flake.overlays` exports. No `overlays.default` in any module. (`tests/package-policy.sh:9-20` enforces this.)
- No `mkDerivation` / `runCommand` / `runCommandLocal` / `buildXxxYyy` in `lib/`, `modules/`, or `flake.nix` other than the existing `apps.nix` / `checks.nix` exclusions. The elecwhat-bin derivation MUST live at `pkgs/elecwhat-bin.nix`. (`tests/package-policy.sh:22-37` enforces this.)
- No `allowUnfree = true` in `lib/nixpkgs.nix`. Unfree admission stays via `allowUnfreePredicate` only. (`tests/package-policy.sh:55-58` enforces this.)
- No `allowBroken = true` or `permittedInsecurePackages` in `lib/nixpkgs.nix`. (`tests/package-policy.sh:45-53` enforces this.)
- No `sublime4` row for `aarch64-darwin` in `config/package-exceptions.json` (sublime4 has no darwin nixpkgs attribute; the predicate will never match and the row would be confusing). (`tests/package-policy.sh:77-100` would not reject it, but it would be dead code.)
- No `x86_64-darwin` rows in `config/package-exceptions.json` of any kind. (`tests/package-policy.sh:77-100` enforces this.)
- No new `age.secrets.*` or `sops.secrets.*` declarations. This plan makes the tooling available; a follow-up plan (after key enrollment) declares the first secret.
- No `flake.lock` updates for inputs other than `sops-nix`. No `nixpkgs` / `home-manager` / `darwin` / `disko` / `den` / `flake-parts` churn.
- No `secrets/*` plaintext material in git. The new `secretspec/secretspec.toml` at the repo root is the only example file, and it contains NO plaintext values.
- No new `secretspec` NixOS module wrapper. The package is CLI-only; writing a wrapper would be a hypothetical layer with no real consumer.
- No change to the existing `modules/aspects/features/secrets.nix` agenix wiring (we extend, not rewrite).
- No unrelated package additions, formatting rewrites, or refactors of existing modules beyond the listed edits.

## Open questions
1. **Role split (the one real fork).** Recommended: all three tools adopted with the C1–C4 split (agenix for host files / sops-nix for shared structured secrets / secretspec for new app-SDK consumers). Do you want this role split, or do you want one of:
   - (a) **All three adopted with the recommended three-tier role split** (RECOMMENDED — matches your literal ask; uses each tool where it is strongest).
   - (b) Keep agenix, ADOPT sops-nix only (skip secretspec; the use case for typed app SDKs is not in this repo today).
   - (c) Keep agenix, ADOPT secretspec only (skip sops-nix; you are fine with one-tool-per-file at the Nix level).
   - (d) Keep agenix, drop the SOPS + secretspec adoption entirely (literal ask was over-broad; ignore it).

## Approval gate
status: awaiting-approval
Approve `.omo/plans/secrets-stack-and-packages.md` to implement the four edits: sops-nix aspect + shared package additions, the agenix key-path extension on Darwin, Sublime4 + elecwhat-bin on Linux with the unfree exception row, and the README secrets rewrite. Default fork answer (if you say nothing) is 1.(a) — the recommended three-tier role split. If you choose 1.(b)–(d) instead, the sops-nix aspect + the secretspec toml are dropped; everything else stays.
