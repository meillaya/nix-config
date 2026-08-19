# secrets-stack-and-packages - Work Plan

## TL;DR (For humans)

**What you'll get.** A repository that *actually* supports three secret-management tools side-by-side: the already-adopted `agenix` (NixOS activation-time file delivery), a newly wired `sops-nix` Den aspect (shared/structured secrets with path-based recipient policy), and a new `secretspec` CLI plus template `secretspec.toml` (typed app-SDK consumers). Plus two new Linux packages — `sublime4` from nixpkgs (with four matching `package-exceptions.json` rows keyed on the package's real `pname = "sublimetext4"`) and a first-party `pkgs/elecwhat-bin.nix` derivation that wraps the upstream `piec/elecwhat` Electron `.pacman` with `electron` + `makeWrapper` + `wrapGAppsHook3` + `copyDesktopItems` + a verified SHA-256 hash. The README "Secrets" section is rewritten as a three-tier decision tree so a reader knows which tool to reach for.

> ⚠️ **Veto this plan at the gate if any of the following is wrong:**
> - The user expected `elecwhat-bin` to be an electronics reference tool. The actual upstream project at `github.com/piec/elecwhat` is a **WhatsApp client** (the name is a play on "electronic WhatsApp"). This plan installs the WhatsApp client. If you wanted an electronics tool, the AUR package name `elecwhat-bin` is misleading; rename or skip the package.
> - The user has aarch64 Linux machines. The elecwhat upstream ships **only x86_64 binaries** (Oracle downloaded and inspected the `.pacman`; it contains an x86-64 `sharp` native module). This plan restricts elecwhat-bin to `x86_64-linux` only; it is added to the existing x86_64-only block in `modules/linux/packages.nix` (alongside `hoppscotch` and `obsidian`) and is NOT installed on `aarch64-linux` hosts.

**Why this approach.** The repo's dendritic layout already isolates platform concerns into `modules/aspects/features/*.nix` and `modules/aspects/platforms/*.nix`. Mirroring the existing `secrets` aspect's shape for sops-nix keeps the diff small and reviewable. `pkgs/elecwhat-bin.nix` is the legal home for a custom derivation (the `tests/package-policy.sh:22-37` gate forbids `mkDerivation` in `lib/` and `modules/` but does not scan `pkgs/`). The `secretspec.toml` template lives at `secretspec/secretspec.toml` at the repo root — `secrets/*` is git-ignored. The `secretspec` binary is consumed straight from nixpkgs (no flake input, no wrapper) and the version-0.13.0 `check` subcommand is invoked directly via `nix run --inputs-from . nixpkgs#secretspec -- check --provider local_env ...` (lock-scoped to the flake's pinned nixpkgs, with an explicit provider because the template declares aliases without a default).

**What it will NOT do.** It will not enroll a first encrypted secret on any host; that requires `secretTrust.state = "enrolled"`, which the `validators.nix:498-501` cross-field rule ties to `boot.state = "uefi"` and `storage.profile = "single-gpt-btrfs"` (orthogonal capability work). It will not change the existing agenix aspect's `agenix` import or `age.identityPaths` shape beyond adding the Darwin `id_ed25519_agenix` secondary key. It will not add a secretspec NixOS module (none exists in nixpkgs; the CLI is the entire surface). It will not add a `secretspec` flake input (we consume `pkgs.secretspec` from nixpkgs). It will not touch the `age` flake input or any other existing input. It will not enroll Sublime on Darwin (`sublime4` is not a darwin nixpkgs attribute) and will not commit any x86_64-darwin exception row (the policy test rejects them). It will not install elecwhat-bin on aarch64-linux hosts. It will not export a `packages.*` attribute from the flake (the flake-parts/Den layout does not export packages; package presence is verified by `nix eval` on the per-configuration package lists, not by `nix flake show`).

**Effort.** ~14 implementation steps across 3 commit waves + 4 final-verifier steps + the policy test. All changes are local; no remote is touched. Net diff is **13 files** (12 source files + `flake.lock`): the prior round's "12" count was off by one because `flake.lock` was overlooked.

**Risk.** Low-to-medium. The biggest concrete risks are (1) a sops-nix module API drift between its `darwinModules.default` and the locked `nixpkgs` causing evaluation failure (mitigated by an evaluation assertion before commit), (2) a moving elecwhat upstream release tag producing a different artifact than planned (mitigated by pinning to `v1.14.0` and using the Oracle-verified `sha256-GcQdKClPQEgZWmhYFgpmypGhh/pibj1dR2PpvNG2yqw=`), (3) Sublime4 `pname`/`version` drift between the worker reading this plan and the locked nixpkgs (mitigated by requiring the worker to read the live `nix eval --raw --inputs-from . nixpkgs#sublime4.pname` and use the exact string), (4) the secretspec 0.13.0 CLI's exact command-line shape changing in a future release (mitigated by the verification running the `check` subcommand and asserting only the exit code, not a specific output phrase), and (5) the elecwhat upstream binary becoming available for aarch64 in a future release (mitigated by an explicit live `nix eval --inputs-from . nixpkgs#elecwhat-bin.*` check before authoring the derivation — see Todo 10).

**Decisions I made for you (veto at the gate):**
- The three secret tools get a three-tier role split (this is the option you confirmed).
- `pkgs.sops` is added by the sops aspect to the host's `environment.systemPackages` (matching the existing agenix aspect's pattern of owning its own CLI in the aspect), NOT duplicated into `modules/shared/packages.nix`. `pkgs.secretspec` is added to `modules/shared/packages.nix` (no aspect owns it). `pkgs.sops` is ALSO added to `modules/standalone-linux/packages.nix` because the standalone-Linux home config does not include `linux-platform` (it would otherwise lack the `sops` CLI entirely).
- Sublime4 + elecwhat-bin go in `modules/linux/packages.nix` (NixOS + standalone-linux). Sublime4 goes in the cross-platform list (both x86_64 and aarch64). elecwhat-bin goes in the existing `lib.optionals (stdenv.hostPlatform.system == "x86_64-linux")` block (only x86_64).
- Sublime4 gets four `package-exceptions.json` rows (one per Linux output) keyed on `pname: "sublimetext4"` (the actual nixpkgs `pname`, NOT the attribute name `sublime4`) and on the live `nix eval --raw --inputs-from . nixpkgs#sublime4.version` output for the `version` field.
- The `id_ed25519_agenix` secondary key is added to the Darwin `age.identityPaths` list unconditionally; the provisioning scripts in `apps/aarch64-darwin/` are already darwin-only, so this is functionally aarch64-darwin-only today without a system check.
- The `secretspec.toml` template excludes `age://` aliases because the `age` provider is in secretspec 0.17+ (unreleased as of 2026-07-24); the pinned nixpkgs carries 0.13.0. Allowed providers in the template: `keyring://`, `dotenv://`, `env://`. The `check` invocation passes `--provider local_env` to disambiguate (the manifest's `[providers]` aliases are not auto-selected).
- `secretspec` is invoked via `nix run --inputs-from . nixpkgs#secretspec -- check -f secretspec/secretspec.toml --provider local_env --no-prompt --reason "validate manifest"` (NOT `nix run .#secretspec`, because the flake does not export a `secretspec` app). The toml `revision` is `"1.0"` (the 0.13.0 validator requires this exact string). All `nixpkgs#` references use `--inputs-from .` so the locked nixpkgs is used, not the global registry.
- The elecwhat-bin build QA uses `nix-build <drvPath> --no-out-link` (where `<drvPath>` is the derivation's `drvPath` from `nix eval .#homeConfigurations.standalone-linux.config.home.packages --apply '...'`) — NOT `nix-build .#elecwhat-bin` (which would fail because the flake does not export `packages.x86_64-linux.elecwhat-bin`).
- Commits are grouped by logical wave (secret-manager wiring / secrets story docs / new packages) for reviewable diffs.

## Scope

**In scope.**
- `flake.nix`: add `sops-nix` input with `inputs.nixpkgs.follows = "nixpkgs"`. No other input changes.
- `flake.lock`: refresh only the `sops-nix` node (`nix flake lock --update-input sops-nix`).
- New `modules/aspects/features/sops.nix`: Den aspect importing `sops-nix.nixosModules.default` (NixOS host block) and `sops-nix.darwinModules.default` (Darwin host block). Each block: imports the sops-nix module, sets `sops.age.sshKeyPaths = [ "${identity.home}/.ssh/id_ed25519" ]` (NixOS) / `[ "${identity.home}/.ssh/id_ed25519" "${identity.home}/.ssh/id_ed25519_agenix" ]` (Darwin), adds `pkgs.sops` to `environment.systemPackages`, and **does NOT** declare any `sops.secrets.*` block.
- `modules/aspects/platforms/darwin.nix`: add `den.aspects.sops` to the `includes` list, after `den.aspects.secrets`.
- `modules/aspects/platforms/linux.nix`: add `den.aspects.sops` to the `includes` list, after `den.aspects.secrets`.
- `modules/shared/packages.nix`: add `pkgs.secretspec` to the cross-platform list. Do NOT add `pkgs.sops` here (the sops aspect owns it for NixOS/Darwin; the standalone-linux package list owns it for standalone Linux).
- `modules/standalone-linux/packages.nix`: add `sops` to the cross-platform block (because the standalone Linux home does not include `linux-platform`, it does NOT get `pkgs.sops` from the sops aspect; the standalone operator needs the `sops` CLI to edit `.sops.yaml` files locally).
- `modules/darwin/secrets.nix`: extend `age.identityPaths` to include `${identity.home}/.ssh/id_ed25519_agenix` (secondary key, optional file).
- `modules/nixos/secrets.nix`: unchanged.
- New `secretspec/secretspec.toml` at the repo root. Exact content is specified in Todo 7.
- `modules/linux/packages.nix`: add `sublime4` to the cross-platform list (x86_64 and aarch64). Add `(pkgs.callPackage ../../pkgs/elecwhat-bin.nix { })` to the existing `lib.optionals (stdenv.hostPlatform.system == "x86_64-linux")` block (alongside `hoppscotch` and `obsidian`).
- `config/package-exceptions.json`: add four new rows for `sublimetext4` per system (see Todo 9 for exact schema; the `pname` field is `sublimetext4`, the actual nixpkgs pname, NOT the attribute name `sublime4`).
- New `pkgs/elecwhat-bin.nix`: derivation per Todo 11. Wraps the upstream `piec/elecwhat` v1.14.0 `.pacman` (verified SHA-256 `sha256-GcQdKClPQEgZWmhYFgpmypGhh/pibj1dR2PpvNG2yqw=`) with `electron` + `makeWrapper` + `wrapGAppsHook3` + `copyDesktopItems`. Restricts `meta.platforms = [ "x86_64-linux" ]`.
- `README.md`: rewrite the "Secrets" section per Todo 8. Remove the false claim that sops ships on every host; correct it to "sops ships on NixOS and Darwin hosts; standalone Linux Home Manager installs sops directly from the shared package set".

**Out of scope (Must NOT have).**
- No new flake inputs other than `sops-nix`.
- No new overlays; no `flake.overlays.*` exports; no `overlays.default` in any module (`tests/package-policy.sh:9-20`).
- No `mkDerivation` / `runCommand` / `runCommandLocal` / `buildXxxYyy` in `lib/`, `modules/`, or `flake.nix` other than the existing `apps.nix` / `checks.nix` exclusions (`tests/package-policy.sh:22-37`). The elecwhat-bin derivation MUST live at `pkgs/elecwhat-bin.nix`.
- No `allowUnfree = true` in `lib/nixpkgs.nix` (`tests/package-policy.sh:55-58`).
- No `allowBroken = true` or `permittedInsecurePackages` in `lib/nixpkgs.nix` (`tests/package-policy.sh:45-53`).
- No `sublimetext4` row for any Darwin output (sublime4 is not a darwin nixpkgs attribute).
- No `x86_64-darwin` row in `config/package-exceptions.json` of any kind (`tests/package-policy.sh:77-100`).
- No new `age.secrets.*` blocks anywhere (no `age.secrets.<name> = { ... };`, no `age.secrets."<quoted-name>" = { ... };`, no `age.secrets = { <attr> = { ... }; };`).
- No new `sops.secrets.*` blocks anywhere (no `sops.secrets.<name> = { ... };`, no `sops.secrets."<quoted-name>" = { ... };`, no `sops.secrets = { <attr> = { ... }; };`).
- No `.age` / `.sops.yaml` / `.sops.json` / `.sops.env` / `secrets.age` / `secrets.age.recipients` / conventionally named `secrets/<basename>.yaml` files in the working tree.
- No plaintext values inside `secretspec/secretspec.toml` — only the `[project]`, `[providers]`, and empty `[profiles.default]` skeleton.
- No `flake.lock` updates for inputs other than `sops-nix`.
- No `secretspec` flake input (we consume the package from nixpkgs).
- No `nixos-render-docs` overlay (`tests/package-policy.sh:65-68`).
- No additional Rust declarations in `modules/shared/packages.nix` (`tests/package-policy.sh:102-140`).
- No `nix run .#secretspec` (the flake does not export a `secretspec` app; the verification uses `nix run --inputs-from . nixpkgs#secretspec -- ...` instead).
- No `nix flake show --json` positive package assertions (the flake does not export `packages.*`; the verification uses `nix eval` on the per-configuration package lists).
- No `nix-build .#elecwhat-bin` (the flake does not export `packages.*`; the build verification uses `nix-build <drvPath>` where `<drvPath>` comes from `nix eval`).
- No elecwhat-bin on aarch64-linux hosts (the upstream `.pacman` is x86_64-only).
- No unrelated package additions, formatting rewrites, or refactors of existing modules beyond the listed edits.
- No new secrets file in `secrets/` other than the existing `README.md` and `calibre/*.json` (which is manually-runtime-only and out of scope).
- No enroll of `secretTrust.state` to `"enrolled"` on any machine; no `age.secrets.<name>` and no `sops.secrets.<name>` block.

## Verification strategy

**Test strategy: tests-after, with policy + evaluation gates as the proof.**

- **Policy gate (must pass before commit):** `bash tests/package-policy.sh` must exit 0 and print both `package-policy-source=PASS` and `package-policy-probe=PASS`.
- **Evaluation gate (must pass before commit):** `nix flake check` must exit 0.
- **Targeted evaluations (must pass per system, 19 queries total):**
  - `nix eval --json .#nixosConfigurations.x86_64-linux.config.sops.age.sshKeyPaths` returns a JSON array of length ≥ 1.
  - `nix eval --json .#darwinConfigurations.aarch64-darwin.config.sops.age.sshKeyPaths` returns a JSON array of length ≥ 1.
  - `nix eval --json .#darwinConfigurations.aarch64-darwin.config.age.identityPaths` returns a JSON array of length ≥ 2 (the new `id_ed25519_agenix` entry must be present).
  - `nix eval .#homeConfigurations.standalone-linux.config.home.packages --apply 'ps: builtins.length (builtins.filter (p: (p.pname or "") == "sublimetext4") ps)'` returns 1.
  - `nix eval .#homeConfigurations.standalone-linux-aarch64.config.home.packages --apply 'ps: builtins.length (builtins.filter (p: (p.pname or "") == "sublimetext4") ps)'` returns 1.
  - `nix eval .#nixosConfigurations.x86_64-linux.config.home-manager.users.mei.home.packages --apply 'ps: builtins.length (builtins.filter (p: (p.pname or "") == "sublimetext4") ps)'` returns 1.
  - `nix eval .#nixosConfigurations.aarch64-linux.config.home-manager.users.mei.home.packages --apply 'ps: builtins.length (builtins.filter (p: (p.pname or "") == "sublimetext4") ps)'` returns 1.
  - `nix eval .#homeConfigurations.standalone-linux.config.home.packages --apply 'ps: builtins.length (builtins.filter (p: (p.pname or "") == "elecwhat-bin") ps)'` returns 1.
  - `nix eval .#nixosConfigurations.x86_64-linux.config.home-manager.users.mei.home.packages --apply 'ps: builtins.length (builtins.filter (p: (p.pname or "") == "elecwhat-bin") ps)'` returns 1.
  - `nix eval .#homeConfigurations.standalone-linux-aarch64.config.home.packages --apply 'ps: builtins.length (builtins.filter (p: (p.pname or "") == "elecwhat-bin") ps)'` returns 0 (elecwhat-bin is x86_64-only; must not appear on aarch64).
  - `nix eval .#nixosConfigurations.aarch64-linux.config.home-manager.users.mei.home.packages --apply 'ps: builtins.length (builtins.filter (p: (p.pname or "") == "elecwhat-bin") ps)'` returns 0.
  - `nix eval .#darwinConfigurations.aarch64-darwin.config.environment.systemPackages --apply 'ps: builtins.length (builtins.filter (p: (p.pname or "") == "elecwhat-bin") ps)'` returns 0.
  - `nix eval .#homeConfigurations.standalone-linux.config.home.packages --apply 'ps: builtins.length (builtins.filter (p: (p.pname or "") == "secretspec") ps)'` returns 1.
  - `nix eval .#homeConfigurations.standalone-linux.config.home.packages --apply 'ps: builtins.length (builtins.filter (p: (p.pname or "") == "sops") ps)'` returns 1 (sops is added for standalone-linux in Todo 6).
  - `nix eval .#homeConfigurations.standalone-linux-aarch64.config.home.packages --apply 'ps: builtins.length (builtins.filter (p: (p.pname or "") == "sops") ps)'` returns 1.
  - `nix eval .#nixosConfigurations.x86_64-linux.config.environment.systemPackages --apply 'ps: builtins.length (builtins.filter (p: (p.pname or "") == "sops") ps)'` returns 1 (sops is added to NixOS via the sops aspect).
  - `nix eval .#nixosConfigurations.aarch64-linux.config.environment.systemPackages --apply 'ps: builtins.length (builtins.filter (p: (p.pname or "") == "sops") ps)'` returns 1.
  - `nix eval .#darwinConfigurations.aarch64-darwin.config.environment.systemPackages --apply 'ps: builtins.length (builtins.filter (p: (p.pname or "") == "sops") ps)'` returns 1.
  - `nix run --inputs-from . nixpkgs#secretspec -- check -f secretspec/secretspec.toml --provider local_env --no-prompt --reason "validate manifest"` exits 0.
- **Elecwhat-bin build verification (must pass per system):**
  - `drv=$(nix eval --raw .#homeConfigurations.standalone-linux.config.home.packages --apply 'ps: (builtins.head (builtins.filter (p: (p.pname or "") == "elecwhat-bin") ps)).drvPath') && nix-build "$drv" --no-out-link` exits 0 (proves the derivation actually builds; the `--no-out-link` means no `result` symlink is created, and the build is verified by the exit code).
- **Negative checks (must return zero hits):**
  - `grep -rEn '(age|sops)[.]secrets[[:space:]]*=' lib/ modules/ flake.nix pkgs/` returns no matches.
  - `grep -rEn 'age[.]secrets[.][^[:space:]=]+' lib/ modules/ flake.nix pkgs/` returns no matches.
  - `grep -rEn 'sops[.]secrets[.][^[:space:]=]+' lib/ modules/ flake.nix pkgs/` returns no matches.
  - `grep -rEn 'age[.]secrets[.]["a-zA-Z]' lib/ modules/ flake.nix pkgs/` returns no matches (catches quoted `age.secrets."<name>"` declarations).
  - `grep -rEn 'sops[.]secrets[.]["a-zA-Z]' lib/ modules/ flake.nix pkgs/` returns no matches (catches quoted `sops.secrets."<name>"` declarations).
  - `find . \( -name '*.age' -o -name '*.sops.yaml' -o -name '*.sops.json' -o -name '*.sops.env' -o -name 'secrets.age' -o -name 'secrets.age.recipients' \) -not -path './.git/*' -not -path './.omo/*' -not -path './result*'` returns no results.
  - `find secrets -type f -not -name 'README.md' -not -path 'secrets/calibre/*' -not -path './.git/*' -not -path './.omo/*' -not -path './result*'` returns no results (no new plaintext files under secrets/).
- **Secret manager surface check:** `nix eval .#darwinConfigurations.aarch64-darwin.config.environment.systemPackages --apply 'ps: builtins.length (builtins.filter (p: (p.pname or "") == "agenix") ps)'` returns ≥ 1.

## Execution strategy

The implementation is grouped into three logical commit waves. **Order within a wave is fixed by the dependency matrix below; cross-wave order is also fixed (wave 1 before wave 2 before wave 3).**

- **Wave 1 — secret-manager adoption:** add sops-nix input, create the sops aspect, wire it into the platform aspect `includes`, add `pkgs.secretspec` to shared packages, add `pkgs.sops` to the standalone-linux package list, and extend the Darwin `age.identityPaths`.
- **Wave 2 — secrets story documentation:** author `secretspec/secretspec.toml` template; rewrite the README "Secrets" section.
- **Wave 3 — new packages:** verify nixpkgs lacks `elecwhat-bin`, author `pkgs/elecwhat-bin.nix`, add `sublime4` to `modules/linux/packages.nix`, add the four `sublimetext4` rows to `config/package-exceptions.json`, and add the elecwhat-bin callPackage to the x86_64-only block in `modules/linux/packages.nix`.

**Dependency matrix (each row depends on every row above it):**
- Wave 1.1 (sops input) → Wave 1.2 (sops aspect created) → Wave 1.3 (sops aspect wired into darwin + linux platform aspects) → Wave 1.4 (shared packages: secretspec) → Wave 1.5 (darwin agenix key path) → Wave 1.6 (standalone-linux packages: sops CLI)
- Wave 2.1 (secretspec toml) → Wave 2.2 (README rewrite)
- Wave 3.1 (verify nixpkgs lacks elecwhat-bin) → Wave 3.2 (sublime4 in packages + exception rows) → Wave 3.3 (elecwhat-bin derivation) → Wave 3.4 (elecwhat-bin callPackage)

**Mapping from waves to todo numbers (monotonic by design):**
- Wave 1.1 → Todo 1
- Wave 1.2 → Todo 2
- Wave 1.3 → Todo 3
- Wave 1.4 → Todo 4
- Wave 1.5 → Todo 5
- Wave 1.6 → Todo 6
- Wave 2.1 → Todo 7
- Wave 2.2 → Todo 8
- Wave 3.1 → Todo 9
- Wave 3.2 → Todo 10
- Wave 3.3 → Todo 11
- Wave 3.4 → Todo 12
- Verification gates → Todos 13, 14

**Commit strategy (matches the waves).** Three commits in total:
- `commit 1` (wave 1): all six steps in wave 1 (Todos 1, 2, 3, 4, 5, 6), one commit.
- `commit 2` (wave 2): the two steps in wave 2 (Todos 7, 8), one commit.
- `commit 3` (wave 3): the four steps in wave 3 (Todos 9, 10, 11, 12), one commit.

Wave 3's first step (Todo 9) is a verification rather than a file edit. If the check reveals that nixpkgs DOES have `elecwhat-bin`, the worker should stop and surface the discrepancy before authoring the derivation (Todo 11). If the check reveals nixpkgs still lacks `elecwhat-bin` (the expected outcome as of 2026-07-24), the worker proceeds to author the derivation. The worker's commit log MUST record the output of the live check.

**Worker must run `bash tests/package-policy.sh` AND `nix flake check` after each commit** and both must pass before continuing to the next wave. The final verification wave runs after all three commits.

## Todos

- [x] 1. **Add sops-nix flake input.** In `/home/mei/nix-config/flake.nix`, add the new input inside the `inputs = { ... };` block, immediately after the `agenix` input (line 9) for grouping:

  ```nix
  sops-nix = {
    url = "github:Mic92/sops-nix";
    inputs.nixpkgs.follows = "nixpkgs";
  };
  ```

  Then `cd /home/mei/nix-config && nix flake lock --update-input sops-nix` to refresh only the `sops-nix` node. Do NOT run a blanket `nix flake update`. Verify the lock changed only in the `sops-nix` and `sops-nix_2` (if any) node trees: `git diff flake.lock | grep -E '^[+-]    "' | sort -u` must show only `"sops-nix"` lines added/removed (and possibly a sibling `sops-nix_2` follow alias). Confirm `nix flake metadata --json | jq -r '.locks.nodes["sops-nix"].locked.owner'` returns `Mic92`.

  **Happy QA:** `nix flake metadata --json | jq -r '.locks.nodes["sops-nix"].locked.repo'` returns `sops-nix`. `nix eval --raw --inputs-from . nixpkgs#lib.version` still works (no other lock churn; `--inputs-from .` scopes the query to the flake's locked nixpkgs).

  **Failure QA:** if the input URL is mis-typed (e.g. `github:Mic92/sops-nix-typo`), `nix flake lock --update-input sops-nix` errors with HTTP 404. If the `inputs.nixpkgs.follows = "nixpkgs"` line is missing, `nix flake check` errors with a divergent nixpkgs message.

  **Commit line:** `chore(flake): add sops-nix input with nixpkgs follows`

- [x] 2. **Create `modules/aspects/features/sops.nix`.** New file. This aspect imports the sops-nix modules, mirrors the agenix `age.identityPaths` into `sops.age.sshKeyPaths`, and adds `pkgs.sops` to the host's `environment.systemPackages`. It does NOT declare any `sops.secrets.*` block. The exact file content:

  ```nix
  { inputs, ... }:
  {
    den.aspects.sops = { host, ... }: {
      nixos = { pkgs, ... }: {
        imports = [
          inputs.sops-nix.nixosModules.default
        ];
        sops.age.sshKeyPaths = [ "${host.machine.identity.home}/.ssh/id_ed25519" ];
        environment.systemPackages = [ pkgs.sops ];
      };
      darwin = { pkgs, ... }: {
        imports = [
          inputs.sops-nix.darwinModules.default
        ];
        sops.age.sshKeyPaths = [
          "${host.machine.identity.home}/.ssh/id_ed25519"
          "${host.machine.identity.home}/.ssh/id_ed25519_agenix"
        ];
        environment.systemPackages = [ pkgs.sops ];
      };
    };
  }
  ```

  Do NOT add any `sops.secrets.<name> = { ... };` block. Do NOT add any `sops.defaultSopsFile = ...;`. Do NOT add any `sopsFile` option override. The aspect's only job is module import + ssh key path + binary. After writing the file, `nix eval .#nixosConfigurations.nixos-x86-qualifier.config.sops.age.sshKeyPaths` must succeed and return a 1-element list; `nix eval .#darwinConfigurations.aarch64-darwin.config.sops.age.sshKeyPaths` must return a 2-element list. The sops-nix module treats `sshKeyPaths` entries as SSH public-key files (or paths it can derive the public key from) and converts them to age recipients; the value `${identity.home}/.ssh/id_ed25519` is valid because the existing agenix aspect already relies on the same private key file (see `modules/{darwin,nixos}/secrets.nix:3`).

  **Happy QA:** `nix eval .#nixosConfigurations.x86_64-linux.config.environment.systemPackages --apply 'ps: builtins.length (builtins.filter (p: (p.pname or "") == "sops") ps)'` returns `1`. `nix eval --json .#darwinConfigurations.aarch64-darwin.config.sops.age.sshKeyPaths` returns a JSON array of two strings.

  **Failure QA:** if the sops-nix nixos module is not imported, `nix eval .#nixosConfigurations.x86_64-linux.config.sops.age.sshKeyPaths` errors with "The option `sops.age.sshKeyPaths' does not exist". If `id_ed25519_agenix` is omitted from the darwin block, the same eval returns a 1-element list (negative assertion for the next step).

  **Commit line:** included in `commit 1`.

- [x] 3. **Wire `den.aspects.sops` into the two platform aspects.** Edit two files:

  - `/home/mei/nix-config/modules/aspects/platforms/darwin.nix` — add `den.aspects.sops` to the `includes` list, immediately after the existing `den.aspects.secrets` line. The new list becomes:
    ```nix
    den.aspects.darwin-platform.includes = [
      den.aspects.shared-policy
      den.aspects.darwin-base
      den.aspects.secrets
      den.aspects.sops
      den.aspects.darwin-home
    ];
    ```
  - `/home/mei/nix-config/modules/aspects/platforms/linux.nix` — add `den.aspects.sops` to the `includes` list, immediately after the existing `den.aspects.secrets` line. The new list becomes:
    ```nix
    den.aspects.linux-platform.includes = [
      den.aspects.shared-policy
      den.aspects.nixos-base
      den.aspects.secrets
      den.aspects.sops
      den.aspects.desktop-media
    ];
    ```

  Order matters: `den.aspects.sops` MUST appear after `den.aspects.secrets` so the agenix `age.identityPaths` is set before sops reads the same identity. Do NOT add a new `den.aspects.sops` declaration anywhere else. Do NOT include `sops` in any named-host aggregate (e.g. `aarch64-darwin.nix`, `nixos-laptop.nix`); the platform aspects own the inclusion. Do NOT add `den.aspects.sops` to a standalone-Linux platform aspect (there is no such aggregate; standalone Linux home configs do NOT include `linux-platform`). After editing, run `nix eval .#darwinConfigurations.aarch64-darwin.config.sops.age.sshKeyPaths` and `nix eval .#nixosConfigurations.x86_64-linux.config.sops.age.sshKeyPaths` — both must succeed.

  **Happy QA:** `nix eval .#nixosConfigurations.x86_64-linux.config.environment.systemPackages --apply 'ps: builtins.length (builtins.filter (p: (p.pname or "") == "sops") ps)'` returns `1`. `nix eval .#nixosConfigurations.x86_64-linux.config.environment.systemPackages --apply 'ps: builtins.length (builtins.filter (p: (p.pname or "") == "agenix") ps)'` returns `1` (the existing agenix binary is preserved).

  **Failure QA:** if `den.aspects.sops` is added to the includes list but the aspect file from Todo 2 is missing, `nix flake check` errors with `attribute 'sops' missing` or `unknown den aspect`. If `den.aspects.sops` is added before `den.aspects.secrets`, the same eval still works but sops-nix would import first; the order is preferred, not strictly required for evaluation, so this is a soft assertion.

  **Commit line:** included in `commit 1`.

- [x] 4. **Add `pkgs.secretspec` to `modules/shared/packages.nix`.** Edit `/home/mei/nix-config/modules/shared/packages.nix`. Add `secretspec` to the list, grouped near the other CLI tools in the "General packages for development and system management" section (after `aria2`, line 7). Do NOT add `sops` here — the sops aspect owns `pkgs.sops` for NixOS/Darwin (Todo 2) and the standalone-linux package list owns it for standalone Linux (Todo 6). Do NOT add `secretspec` to the per-platform `packages.nix` files (it goes to every host via shared).

  **Happy QA:** `nix eval .#homeConfigurations.standalone-linux.config.home.packages --apply 'ps: builtins.length (builtins.filter (p: (p.pname or "") == "secretspec") ps)'` returns `1`. `nix eval .#nixosConfigurations.x86_64-linux.config.home-manager.users.mei.home.packages --apply 'ps: builtins.length (builtins.filter (p: (p.pname or "") == "secretspec") ps)'` returns `1` (HM rollup puts it on both).

  **Failure QA:** if `secretspec` is added to the per-platform `darwin/packages.nix` only, the nixos eval above returns `0` (negative assertion). If `secretspec` is added under a wrong attribute name (e.g. `secretspec-cli`), the eval errors with "attribute 'secretspec-cli' missing".

  **Commit line:** included in `commit 1`.

- [x] 5. **Extend `modules/darwin/secrets.nix` for the secondary SSH key.** Edit `/home/mei/nix-config/modules/darwin/secrets.nix`. Change the `age.identityPaths` from a 1-element list to a 2-element list:

  ```nix
  { identity }:
  {
    age.identityPaths = [
      "${identity.home}/.ssh/id_ed25519"
      "${identity.home}/.ssh/id_ed25519_agenix"
    ];
  }
  ```

  Do NOT touch `modules/nixos/secrets.nix` — the `id_ed25519_agenix` provisioning flow (`apps/aarch64-darwin/{create-keys,copy-keys,check-keys}`) is darwin-only. The agenix module tolerates a missing optional identity file (it just falls back to the next entry). Do NOT add a `sopsFile` block; this is the agenix aspect's job.

  **Happy QA:** `nix eval --json .#darwinConfigurations.aarch64-darwin.config.age.identityPaths` returns a JSON array of two strings, the first being the home-relative `id_ed25519` and the second being `id_ed25519_agenix`. `nix eval --json .#nixosConfigurations.x86_64-linux.config.age.identityPaths` still returns a 1-element list (no regression on Linux).

  **Failure QA:** if the file is changed to a single-element list (regression), the first eval returns a 1-element list. If a typo in the home path (e.g. `${identity.hom}/.ssh/id_ed25519`) is introduced, evaluation errors with "attribute 'hom' missing".

  **Commit line:** included in `commit 1`.

- [x] 6. **Add `sops` to `modules/standalone-linux/packages.nix`.** Edit `/home/mei/nix-config/modules/standalone-linux/packages.nix`. Append `sops` to the existing cross-platform list (the `shared-packages ++ linux-packages ++ [...]` block, NOT the x86_64-only `zen-browser` block). This is needed because the standalone-Linux home config does NOT include `linux-platform` (verified in `modules/standalone-linux/home-manager.nix`), so it does NOT receive `pkgs.sops` from the sops aspect; the standalone operator needs the `sops` CLI to edit `.sops.yaml` files locally.

  **Happy QA:** `nix eval .#homeConfigurations.standalone-linux.config.home.packages --apply 'ps: builtins.length (builtins.filter (p: (p.pname or "") == "sops") ps)'` returns `1`. `nix eval .#homeConfigurations.standalone-linux-aarch64.config.home.packages --apply 'ps: builtins.length (builtins.filter (p: (p.pname or "") == "sops") ps)'` returns `1`. `nix eval .#nixosConfigurations.x86_64-linux.config.environment.systemPackages --apply 'ps: builtins.length (builtins.filter (p: (p.pname or "") == "sops") ps)'` still returns `1` (NixOS gets `sops` from the sops aspect, not from shared).

  **Failure QA:** if `sops` is omitted, the standalone-linux eval returns `0`. If `sops` is added under a wrong attribute name (e.g. `sops-nix`), the eval errors with "attribute 'sops-nix' missing".

  **Commit line:** included in `commit 1`.

- [x] 7. **Author `secretspec/secretspec.toml` template at the repo root.** New file at `/home/mei/nix-config/secretspec/secretspec.toml`. Exact content:

  ```toml
  # SecretSpec manifest template for this nix-config repo.
  # Operators fill in real values on their own host after key enrollment.
  # The `age` provider is intentionally NOT aliased here because the pinned
  # nixpkgs carries secretspec 0.13.0 (the `age` provider lands in 0.17+,
  # unreleased as of 2026-07-24).
  [project]
  name = "nix-config"
  revision = "1.0"

  [providers]
  host_keyring = "keyring://"
  local_env     = "env://"
  local_dotenv  = "dotenv://"

  [profiles.default]
  # Example placeholder. Replace with a real entry when an app adopts
  # the SecretSpec SDK or the `secretspec run` wrapper.
  EXAMPLE_TOKEN = { description = "Placeholder", required = false }
  ```

  After writing, run `nix run --inputs-from . nixpkgs#secretspec -- check -f secretspec/secretspec.toml --provider local_env --no-prompt --reason "validate manifest"` from the repo root. The expected result is exit code 0; the stdout/stderr contents may include a list of "missing" or "unresolved" secrets, which is OK because the template declares an optional placeholder. The `--provider local_env` flag is required because the template's `[providers]` block declares multiple aliases without setting a default. Do NOT commit the audit log that `secretspec check` may create at `~/.local/state/secretspec/audit.jsonl` (it is created in the worker's home directory, not in the repo). Do NOT add any `age://` alias. Do NOT add any real secret value.

  **Happy QA:** `nix run --inputs-from . nixpkgs#secretspec -- check -f secretspec/secretspec.toml --provider local_env --no-prompt --reason "validate manifest"; echo "exit=$?"` prints `exit=0`. `cat secretspec/secretspec.toml | wc -l` returns ≥ 15 (proves the file has real content). `grep -c '^password\|^secret\|^token\|^key' secretspec/secretspec.toml` returns 0 (no plaintext values, the only line matching this pattern is `EXAMPLE_TOKEN` which is an attribute name, not a value).

  **Failure QA:** if the file is committed at `secrets/secretspec.toml` instead, `git status` shows it as ignored (`secrets/*` is in `.gitignore:9`). If `revision = "1"` is used instead of `revision = "1.0"`, `secretspec check` (0.13.0) exits 2 with a parse error about the revision format. If `--provider local_env` is omitted, the command exits 1 with "No provider backend configured". If a real age recipient is added to `[providers]`, secretspec fails to resolve it (no keychain item) and exits non-zero.

  **Commit line:** included in `commit 2`.

- [x] 8. **Rewrite the README "Secrets" section as a three-tier decision tree.** Edit `/home/mei/nix-config/README.md`, replacing the current "Secrets" section (lines 163-183) with the following content:

  ```markdown
  ## Secrets

  This repo adopts three secret-management tools, each for a different layer.
  They are additive — pick the one that matches the use case.

  ### When to use which

  - **agenix** — NixOS activation-time file delivery. Use for system services
    that read a file path (e.g. `services.foo.environmentFile =
    config.age.secrets."foo-env".path`). The aspect at
    `modules/aspects/features/secrets.nix` is wired into both Darwin and Linux
    platforms and ships the `agen` / `agenix` CLI on every host.
  - **sops-nix** — shared/structured secrets (YAML, JSON, ENV, INI). Use when
    a single SOPS file lists multiple secrets for a host, or when the
    recipient policy should be path-based. The aspect at
    `modules/aspects/features/sops.nix` is wired into both Darwin and Linux
    platforms and ships the `sops` CLI on NixOS and Darwin hosts. The
    standalone Linux Home Manager configuration adds `sops` directly to its
    package list (`modules/standalone-linux/packages.nix`) because the
    standalone home does not include `linux-platform`.
  - **secretspec** — typed app-SDK consumers. Use when a new application
    imports the Rust / Python / Go / Node SDK and wants compile-time
    guarantees about which secrets it requires. The `secretspec` CLI is
    shipped via `modules/shared/packages.nix`. A template manifest lives at
    `secretspec/secretspec.toml`.

  ### Recipient / policy files

  - **agenix** recipient lists live in `secrets.nix` (per the
    `agenix` upstream convention; this repo has none committed yet).
  - **sops-nix** creation rules would live at the repo root in `.sops.yaml`
    (this repo has none committed yet; not yet created).
  - **secretspec** provider aliases and profiles live in
    `secretspec/secretspec.toml` (a template is committed; the actual
    production profiles are operator-local).

  ### Current state

  - agenix, sops-nix, and secretspec are all installed and wired.
  - **No first secret is enrolled.** Every declared machine in
    `modules/entities/_machine-authority/model.nix` carries
    `publicTrust.state = "disabled"; secretTrust.state = "disabled";`.
  - The `validators.nix:498-501` cross-field rule requires
    `boot.state = "uefi"` + `storage.profile = "single-gpt-btrfs"` +
    `publicTrust.state = "enrolled"` before any
    `secretTrust.state = "enrolled"` may be set. That capability work is
    outside the scope of this repo's current machine authority.
  - When you are ready to add the first real secret, follow the
    `agenix` / `sops-nix` / `secretspec` upstream docs and edit
    `modules/entities/_machine-authority/model.nix` accordingly.

  ### Local staging boundary

  The ignored local `secrets/` directory is an out-of-store staging boundary.
  Home Manager does not ingest or manage the synced plaintext Kavita or
  Calibre files and does not create `home.file.source` links for them. After
  syncing, install only the files an application needs as a manual runtime
  workflow outside Nix evaluation, for example:

  ```bash
  install -d -m 0700 "$HOME/Documents/Kavita/config" "$HOME/.config/calibre"
  install -m 0600 secrets/kavita/appsettings.json \
    "$HOME/Documents/Kavita/config/appsettings.json"
  install -m 0600 secrets/calibre/{global.py.json,gui.py.json,customize.py.json} \
    "$HOME/.config/calibre/"
  ```

  These commands are a manual runtime workflow, not a Home Manager
  activation or proof that provider credentials were rotated.

  Only encrypted material intended for `agenix` or `sops-nix` may be
  referenced by `modules/*/secrets.nix`; do not add ignored plaintext
  application state to a flake source or Nix path. SecretSpec-managed
  secrets are read at runtime by the application; they do not pass
  through the Nix store.
  ```

  After the rewrite, verify with `grep -c 'tier\|agenix\|sops-nix\|secretspec' README.md` returns ≥ 8 (the new section mentions each tool multiple times), and `grep -c 'first secret is enrolled' README.md` returns ≥ 1.

  **Happy QA:** `grep -q 'No first secret is enrolled' README.md` exits 0. `grep -q 'modules/aspects/features/sops.nix' README.md` exits 0. `grep -q 'modules/aspects/features/secrets.nix' README.md` exits 0. `grep -q 'secretspec/secretspec.toml' README.md` exits 0. The original install commands for Kavita/Calibre are preserved (the existing 8 install lines are kept verbatim inside the new section). The phrase "ships on every host" is NOT in the new section (the standalone-Linux caveat is added).

  **Failure QA:** if the rewrite drops the "These commands are a manual runtime workflow" disclaimer, a careful reader may interpret the install commands as activation-time steps. If the new section says "secretTrust is enrolled" (incorrect), `grep -q 'secretTrust.state = "enrolled"' README.md` exits 0 (this is the wrong claim). If the new section keeps the false claim "sops CLI ships on every host", `grep -q 'sops CLI ships on every host' README.md` exits 0 (this is wrong; sops is NixOS/Darwin only).

  **Commit line:** included in `commit 2`.

- [x] 9. **Verify nixpkgs lacks `elecwhat-bin` before authoring the derivation.** The user's literal ask is "If no nixpkgs exist, write a derivation." This step checks the live nixpkgs (the locked pin in `flake.lock`) for an `elecwhat-bin` attribute. If present, STOP and surface the discrepancy to the user (Todo 11 should be skipped; the package-exceptions.json row from Todo 10 and the `pkgs/elecwhat-bin.nix` should NOT be authored). If absent, proceed with the rest of Wave 3.

  Run, in order:
  ```bash
  nix eval --raw --inputs-from . nixpkgs#elecwhat-bin.pname 2>&1
  nix eval --raw --inputs-from . nixpkgs#elecwhat-bin.version 2>&1
  ```

  The expected outcome (as of 2026-07-24, per the Oracle's research): both commands exit non-zero with "error: attribute 'elecwhat-bin' missing". This means nixpkgs still lacks the package; proceed to Todo 10, 11, 12.

  If either command exits 0 (e.g. nixpkgs has gained `elecwhat-bin` since the Oracle's research), record the output in the worker's session log, STOP authoring `pkgs/elecwhat-bin.nix`, and report back: "nixpkgs now provides `elecwhat-bin`; the plan's derivation step is unnecessary. Awaiting user decision: drop elecwhat-bin, or keep the local derivation alongside nixpkgs?" The user may then choose (a) drop elecwhat-bin entirely, (b) keep the local derivation (perhaps with a different version pin), or (c) switch to nixpkgs and skip Todo 11 + 12.

  This step does NOT produce a file change. The worker's commit log MUST record the output of both `nix eval` invocations.

  **Commit line:** included in `commit 3` (the file changes in the same commit as Todo 10, 11, 12; the verification output is recorded in the commit body).

- [x] 10. **Add `sublime4` to `modules/linux/packages.nix` + four `package-exceptions.json` rows for `sublimetext4`.** Two edits.

  First, read the live pname and version from the locked nixpkgs (use `--inputs-from .` so the query uses the flake's pinned nixpkgs, not the global registry):
  ```bash
  nix eval --raw --inputs-from . nixpkgs#sublime4.pname
  nix eval --raw --inputs-from . nixpkgs#sublime4.version
  ```
  The `pname` MUST be `sublimetext4` (the nixpkgs pname, not the attribute name `sublime4`). The `version` is the build number (e.g. `4200`); capture it into a shell variable and use it in the JSON rows below. The package-exceptions predicate in `lib/nixpkgs.nix:17-38` keys on `${system}:${packageName}:${packageVersion}` where `packageName = pname` (line 24). Using `sublime4` as the `pname` in package-exceptions.json will NOT authorize the package — the predicate will never match.

  - Edit `/home/mei/nix-config/modules/linux/packages.nix`: add `sublime4` to the cross-platform list, after `zathura` (line 67). Do NOT add it to `modules/darwin/packages.nix` (sublime4 is not a darwin nixpkgs attribute). Do NOT add it to `modules/shared/packages.nix` (would break darwin evaluation). The nixpkgs attribute is `sublime4`; the package's `pname` is `sublimetext4`.

  - Edit `/home/mei/nix-config/config/package-exceptions.json`: append four new entries to the `unfree` array. Each row's `pname` is `"sublimetext4"` (the captured `pname`, NOT the attribute name). Each row's `version` is the captured `version`. The four rows, in order:
    ```json
    ,
    {
      "expiresAt": "2026-10-22",
      "maxTtlDays": 90,
      "output": "homeConfigurations.standalone-linux",
      "owner": "mei",
      "pname": "sublimetext4",
      "reason": "requested-desktop-application",
      "reviewedAt": "2026-07-24",
      "system": "x86_64-linux",
      "version": "<LIVE_VERSION_STRING>"
    },
    {
      "expiresAt": "2026-10-22",
      "maxTtlDays": 90,
      "output": "homeConfigurations.standalone-linux-aarch64",
      "owner": "mei",
      "pname": "sublimetext4",
      "reason": "requested-desktop-application",
      "reviewedAt": "2026-07-24",
      "system": "aarch64-linux",
      "version": "<LIVE_VERSION_STRING>"
    },
    {
      "expiresAt": "2026-10-22",
      "maxTtlDays": 90,
      "output": "nixosConfigurations.x86_64-linux",
      "owner": "mei",
      "pname": "sublimetext4",
      "reason": "requested-desktop-application",
      "reviewedAt": "2026-07-24",
      "system": "x86_64-linux",
      "version": "<LIVE_VERSION_STRING>"
    },
    {
      "expiresAt": "2026-10-22",
      "maxTtlDays": 90,
      "output": "nixosConfigurations.aarch64-linux",
      "owner": "mei",
      "pname": "sublimetext4",
      "reason": "requested-desktop-application",
      "reviewedAt": "2026-07-24",
      "system": "aarch64-linux",
      "version": "<LIVE_VERSION_STRING>"
    }
    ```

    Replace `<LIVE_VERSION_STRING>` with the literal output of `nix eval --raw --inputs-from . nixpkgs#sublime4.version`. Do NOT hardcode a version. Do NOT add a row for any `darwinConfigurations.*` output. Do NOT add a row for `x86_64-darwin` (the policy test at `tests/package-policy.sh:77-100` rejects it). Do NOT add a separate row for `nixosConfigurations.nixos-x86-qualifier` — the existing `lib/nixpkgs.nix:17-38` predicate keys only on `${system}:${pname}:${version}` and ignores the `output` field; the qualifier output reuses the x86_64-linux authorization. The `expiresAt` is exactly 90 days from `reviewedAt` (2026-07-24 + 90 = 2026-10-22); this matches the existing 90-day TTL convention. Run `python3 -m json.tool config/package-exceptions.json > /dev/null` to confirm the JSON is still well-formed.

  **Happy QA:** `nix eval .#nixosConfigurations.x86_64-linux.config.home-manager.users.mei.home.packages --apply 'ps: builtins.length (builtins.filter (p: (p.pname or "") == "sublimetext4") ps)'` returns `1`. `nix eval .#homeConfigurations.standalone-linux-aarch64.config.home.packages --apply 'ps: builtins.length (builtins.filter (p: (p.pname or "") == "sublimetext4") ps)'` returns `1`. `nix eval .#darwinConfigurations.aarch64-darwin.config.environment.systemPackages --apply 'ps: builtins.length (builtins.filter (p: (p.pname or "") == "sublimetext4") ps)'` returns `0` (sublime4 is Linux-only, must not appear on darwin). `nix eval --raw --inputs-from . nixpkgs#sublime4.pname` returns `sublimetext4` (proves the QA predicate is correct).

  **Failure QA:** if the `pname` in the JSON row is `sublime4` (typo / attribute-name confusion), the unfree predicate in `lib/nixpkgs.nix:30-38` rejects `sublimetext4:4200` and `nix flake check` errors with "package 'sublime4' is unfree" (because the predicate never matches the real pname). If the `version` string in the JSON row does not exactly match `nix eval --raw --inputs-from . nixpkgs#sublime4.version`, the same unfree-rejection error occurs. If a row is added for `darwinConfigurations.aarch64-darwin`, the eval still works (sublime4 doesn't exist on darwin) but the row is dead code and the row is also outside the policy test's positive assertions.

  **Commit line:** included in `commit 3`.

- [x] 11. **Author `pkgs/elecwhat-bin.nix`.** New file at `/home/mei/nix-config/pkgs/elecwhat-bin.nix`. This wraps the upstream `piec/elecwhat` v1.14.0 `.pacman` (a WhatsApp client despite the project name; verified by the Oracle's binary inspection). Exact content:

  ```nix
  { stdenv, fetchurl, electron, makeWrapper, copyDesktopItems, makeDesktopItem, wrapGAppsHook3, lib }:

  stdenv.mkDerivation rec {
    pname = "elecwhat-bin";
    version = "1.14.0";

    src = fetchurl {
      url = "https://github.com/piec/elecwhat/releases/download/v${version}/elecwhat-${version}.pacman";
      hash = "sha256-GcQdKClPQEgZWmhYFgpmypGhh/pibj1dR2PpvNG2yqw=";
    };

    nativeBuildInputs = [ makeWrapper wrapGAppsHook3 copyDesktopItems ];

    dontBuild = true;
    dontConfigure = true;

    unpackPhase = ''
      runHook preUnpack
      mkdir -p extracted
      tar -xJf $src -C extracted
      runHook postUnpack
    '';

    installPhase = ''
      runHook preInstall
      mkdir -p $out/lib/elecwhat/resources $out/bin $out/share/icons/hicolor/256x256/apps
      cp -r extracted/opt/elecwhat/resources/app.asar $out/lib/elecwhat/resources/
      if [ -d extracted/opt/elecwhat/resources/app.asar.unpacked ]; then
        cp -r extracted/opt/elecwhat/resources/app.asar.unpacked $out/lib/elecwhat/resources/
      fi
      # Install bundled icon (the upstream .pacman ships icons under
      # extracted/usr/share/icons/hicolor/<size>/apps/).
      if [ -d extracted/usr/share/icons ]; then
        cp -r extracted/usr/share/icons/* $out/share/icons/hicolor/ 2>/dev/null || true
      fi
      makeWrapper ${electron}/bin/electron $out/bin/elecwhat \
        --add-flags $out/lib/elecwhat/resources/app.asar \
        --prefix XDG_DATA_DIRS : "$out/share" \
        --set ELECTRON_OZONE_PLATFORM_HINT "auto"
      runHook postInstall
    '';

    desktopItems = [
      (makeDesktopItem {
        name = "elecwhat";
        exec = "elecwhat %U";
        icon = "elecwhat";
        comment = "WhatsApp client (piec/elecwhat)";
        categories = [ "Network" "InstantMessaging" "Chat" ];
        terminal = false;
        desktopName = "ElecWhat";
        startupWMClass = "elecwhat";
      })
    ];

    meta = {
      description = "WhatsApp client built with Electron (piec/elecwhat)";
      longDescription = ''
        Despite the project name "elecwhat" (a play on "electronic WhatsApp"),
        this package wraps a WhatsApp desktop client, not an electronics
        reference tool. Upstream: https://github.com/piec/elecwhat.
      '';
      homepage = "https://github.com/piec/elecwhat";
      license = lib.licenses.gpl3Only;
      platforms = [ "x86_64-linux" ];
      mainProgram = "elecwhat";
    };
  }
  ```

  Notes on the recipe:
  - `nativeBuildInputs` uses `copyDesktopItems` (the build hook that processes `desktopItems = [ ... ]`), NOT `makeDesktopItem` (the constructor function — passing a function in `nativeBuildInputs` makes the derivation unevaluable). The `makeDesktopItem` function is called inside `desktopItems = [ ... ]` to produce the desktop file record.
  - `wrapGAppsHook3` is the right hook for locked nixpkgs (which has dropped `wrapGAppsHook` v2; the Oracle verified the locked nixpkgs rejects `wrapGAppsHook` as renamed). It wraps the Electron binary so the app picks up GSettings/Qt themes at runtime.
  - The unpack phase uses `tar -xJf` (xz) explicitly because the upstream `.pacman` is gzipped-xz (not gzip-bzip2); the `-J` flag forces xz decompression. Using `tar -xf` with auto-detection may fail on some Nix store builds because the inner compression of a `.pacman` is not always sniffed reliably.
  - The icon install is defensive: the upstream `.pacman` ships icons under `extracted/usr/share/icons/hicolor/<size>/apps/elecwhat.png`; the `if [ -d extracted/usr/share/icons ]` guard and `2>/dev/null || true` tolerate releases that omit the icon.
  - `meta.platforms = [ "x86_64-linux" ]` only (no aarch64): the Oracle downloaded and inspected the upstream artifact and confirmed the bundled `sharp` native module is x86_64-only.
  - The hash `sha256-GcQdKClPQEgZWmhYFgpmypGhh/pibj1dR2PpvNG2yqw=` is the Oracle-verified SRI of the upstream v1.14.0 `.pacman` asset. If the upstream release is replaced or repacked, the hash will mismatch and the build will fail with "hash mismatch in fixed-output derivation"; the worker should re-fetch the hash via `nix-prefetch-url --type sha256 <url>` and update the recipe.

  **Build verification.** The flake does not export `packages.x86_64-linux.elecwhat-bin`, so `nix-build .#elecwhat-bin` will fail. Instead, get the derivation path from the package list, then build it directly:
  ```bash
  drv=$(nix eval --raw .#homeConfigurations.standalone-linux.config.home.packages --apply 'ps: (builtins.head (builtins.filter (p: (p.pname or "") == "elecwhat-bin") ps)).drvPath')
  nix-build "$drv" --no-out-link
  ```
  The first command resolves the derivation from the locked flake (using the locked nixpkgs); the second builds it. `--no-out-link` means no `./result` symlink is created; the build is verified by exit code 0 and the printed store path. The build substitutes from Cachix if possible; otherwise it compiles from source.

  **Happy QA:** the two-command sequence above exits 0 and prints a `/nix/store/…-elecwhat-bin` store path. The store path contains `bin/elecwhat` (a `makeWrapper` script), `lib/elecwhat/resources/app.asar`, `share/applications/elecwhat.desktop`, and `share/icons/hicolor/<size>/apps/elecwhat.png` (if the upstream shipped icons). Verify with: `ls -la <store-path>/bin/elecwhat <store-path>/share/applications/elecwhat.desktop <store-path>/lib/elecwhat/resources/app.asar` — all three paths must exist.

  **Failure QA:** if the upstream tag is wrong (e.g. `v1.15.0` does not exist), `fetchurl` errors with HTTP 404 (the `hash` would still match a wrong file at the right URL, so a wrong URL is the failure mode). If the hash is wrong (e.g. upstream repacked the `.pacman`), the build errors with "hash mismatch in fixed-output derivation". If `makeDesktopItem` is mistakenly added to `nativeBuildInputs` (the broken approach), evaluation errors with "a function is being called as a build input" or similar. If `app.asar.unpacked` extraction fails (different upstream layout), the `if [ -d … ]` guard prevents the build from failing but the resulting binary may error at runtime for native-module-loaded features. If `makeWrapper` references the wrong electron path (e.g. `${pkgs.electron_40}/bin/electron` instead of `${electron}/bin/electron`), the wrapper is created but `elecwhat` fails at runtime with "electron: command not found". If the unpack uses `tar -xf` instead of `tar -xJf` and the auto-detection fails, the build errors with "gzip: not in gzip format" or similar.

  **Commit line:** included in `commit 3`.

- [x] 12. **Add `elecwhat-bin` to the x86_64-only block in `modules/linux/packages.nix` via `callPackage`.** Edit `/home/mei/nix-config/modules/linux/packages.nix`. Append the following to the existing `lib.optionals (stdenv.hostPlatform.system == "x86_64-linux") [ hoppscotch obsidian ]` block (lines 69-72), NOT to the cross-platform list:

  ```nix
  (pkgs.callPackage ../../pkgs/elecwhat-bin.nix { })
  ```

  Do NOT add `elecwhat-bin` to `modules/darwin/packages.nix` or `modules/shared/packages.nix` (electron-as-pacman recipe is x86_64-linux-only). Do NOT add it to the cross-platform section of `modules/linux/packages.nix` (the `meta.platforms = [ "x86_64-linux" ]` constraint would cause `nix flake check` to fail on aarch64).

  **Happy QA:** `nix eval .#homeConfigurations.standalone-linux.config.home.packages --apply 'ps: builtins.length (builtins.filter (p: (p.pname or "") == "elecwhat-bin") ps)'` returns `1`. `nix eval .#nixosConfigurations.x86_64-linux.config.home-manager.users.mei.home.packages --apply 'ps: builtins.length (builtins.filter (p: (p.pname or "") == "elecwhat-bin") ps)'` returns `1`. `nix eval .#homeConfigurations.standalone-linux-aarch64.config.home.packages --apply 'ps: builtins.length (builtins.filter (p: (p.pname or "") == "elecwhat-bin") ps)'` returns `0` (must not appear on aarch64). `nix eval .#nixosConfigurations.aarch64-linux.config.home-manager.users.mei.home.packages --apply 'ps: builtins.length (builtins.filter (p: (p.pname or "") == "elecwhat-bin") ps)'` returns `0`. `nix eval .#darwinConfigurations.aarch64-darwin.config.environment.systemPackages --apply 'ps: builtins.length (builtins.filter (p: (p.pname or "") == "elecwhat-bin") ps)'` returns `0`.

  **Failure QA:** if the callPackage path is wrong (e.g. `../../pkgs/elecwhat.nix`), `nix flake check` errors with "path '/home/mei/nix-config/pkgs/elecwhat.nix' does not exist". If the package is added to the cross-platform section, `nix flake check` errors with "aarch64-linux is not supported by this derivation" because the `meta.platforms` is x86_64-only.

  **Commit line:** included in `commit 3`.

- [x] 13. **Run `tests/package-policy.sh`.** From the repo root, `bash tests/package-policy.sh`. The script must exit 0 and print both `package-policy-source=PASS` and `package-policy-probe=PASS` to stdout. If it exits 1, the failure message will name the violating line. Re-run after every commit. The policy test enforces (a) no `overlays/` directory contents; (b) no `flake.overlays` exports or `overlays.default` in `flake.nix` or `modules/`; (c) no `runCommand` / `runCommandLocal` / `mkDerivation` / `buildXxxYyy` in any `.nix` file under `lib/` or `modules/` (other than the two excluded files `apps.nix` and `checks.nix`); (d) no `allowBroken` / `permittedInsecurePackages` / `allowUnfree = true` in `lib/nixpkgs.nix`; (e) `allowUnfreePredicate` IS present in `lib/nixpkgs.nix`; (f) only the `emacs-overlay` is in `overlays`; (g) no `x86_64-darwin` rows in `package-exceptions.json`; (h) the existing Rust declarations in `modules/shared/packages.nix` are unchanged.

  **Happy QA:** `bash tests/package-policy.sh; echo "exit=$?"` prints `exit=0`. The output includes `package-policy-source=PASS` and `package-policy-probe=PASS` on separate lines.

  **Failure QA:** if `mkDerivation` is accidentally pasted into `modules/linux/packages.nix` (e.g. an inline derivation instead of `callPackage`), the script exits 1 with "retired standalone package recipes must not return to production modules". If a row is added to `package-exceptions.json` with `system: x86_64-darwin`, the script exits 1 with "package exceptions must not contain x86_64-darwin rows".

  **Commit line:** not a separate commit; this is a verification gate that runs after every commit.

- [x] 14. **Run `nix flake check` and the targeted evaluations.** From the repo root, run all of these in order:

  1. `nix flake check` — must exit 0. If it fails, the error names the failing configuration (e.g. `nixosConfigurations.x86_64-linux`, `darwinConfigurations.aarch64-darwin`).
  2. The 19 targeted `nix eval` commands listed in the "Verification strategy" section above. All must return the expected counts/lists.
  3. The seven negative `grep` / `find` checks listed in the "Verification strategy" section above. All must return zero results.
  4. The elecwhat-bin build verification (two-command sequence) from Todo 11 must exit 0.
  5. `nix run --inputs-from . nixpkgs#secretspec -- check -f secretspec/secretspec.toml --provider local_env --no-prompt --reason "validate manifest"; echo $?` must print `0`.

  Do NOT run `nix flake show --json` to verify package presence (the flake does not export `packages.*`; the per-configuration package lists are the source of truth). Do NOT run `nix run .#secretspec` (no secretspec app is exported by the flake). Do NOT run `nix-build .#elecwhat-bin` (the flake does not export `packages.x86_64-linux.elecwhat-bin`; use the two-command `nix eval` + `nix-build` sequence from Todo 11). Do NOT use `nixpkgs#<attr>` without `--inputs-from .` for any of the targeted queries (it would resolve against the global registry, not the locked nixpkgs).

  Record the output of each command in the worker's session log. If any check fails, fix and re-run before declaring the work complete.

  **Happy QA:** all 12 checks pass; `nix flake check` exits 0; the 19 `nix eval` system-pkg queries return the expected counts; the 7 negative grep/find queries return empty; the elecwhat-bin build exits 0; the secretspec CLI check exits 0.

  **Failure QA:** if `nix flake check` errors with "package 'sublime4' is unfree", the worker forgot to use `pname: "sublimetext4"` in the package-exceptions.json rows (or the version string does not match `nix eval --raw --inputs-from . nixpkgs#sublime4.version`). If `nix flake check` errors with "attribute 'elecwhat-bin' missing", the worker did not add the `callPackage` to `modules/linux/packages.nix` (Todo 12). If `nix eval .#homeConfigurations.standalone-linux.config.home.packages --apply 'ps: builtins.length (builtins.filter (p: (p.pname or "") == "elecwhat-bin") ps)'` returns 0, the derivation exists but is not in the package list (the callPackage is in the wrong block). If `nix flake check` errors with "aarch64-linux is not supported by this derivation", the elecwhat-bin callPackage was added to the cross-platform section instead of the x86_64-only block.

  **Commit line:** not a separate commit; this is the pre-handoff gate.

## Final verification wave

These four verifiers run in parallel after all fourteen implementation todos are complete. ALL must APPROVE before handoff. Record each result in the worker's session log.

- [x] F1. **Plan compliance audit.** Re-read `/home/mei/nix-config/.omo/plans/secrets-stack-and-packages.md` (this file) and the working tree, and confirm: (a) every change in `## Scope / In scope` is present in the diff; (b) every change in `## Scope / Out of scope` is absent; (c) all three commits match the commit strategy ("one commit per wave"); (d) the 19 targeted `nix eval` commands and 7 `grep`/`find` checks all pass; (e) the file count is exactly 13 (12 source files + `flake.lock`; not 10, not 12, not 14). Use `git log --oneline -3` to confirm commit count and `git diff main..HEAD --stat` to confirm file scope. Output a verdict line "F1: PASS" or "F1: FAIL <reason>".

- [x] F2. **Code quality review.** Re-read the diff for the four new/modified files (`modules/aspects/features/sops.nix`, `pkgs/elecwhat-bin.nix`, `secretspec/secretspec.toml`, `config/package-exceptions.json`) plus the nine edits (`modules/aspects/platforms/darwin.nix`, `modules/aspects/platforms/linux.nix`, `modules/darwin/secrets.nix`, `modules/standalone-linux/packages.nix`, `modules/shared/packages.nix`, `modules/linux/packages.nix`, `README.md`, `flake.nix`, `flake.lock`). Confirm: (a) no `mkDerivation` leaked into a non-`pkgs/` file; (b) no `sops.secrets.*` or `age.secrets.*` block (no aggregate assignments, no quoted names); (c) no plaintext secret value; (d) the elecwhat-bin derivation uses `makeWrapper` correctly with `${electron}/bin/electron` and `copyDesktopItems` in `nativeBuildInputs` (NOT `makeDesktopItem`); (e) the `meta.platforms` of elecwhat-bin is `[ "x86_64-linux" ]` only; (f) the `package-exceptions.json` rows use `pname: "sublimetext4"` (NOT `sublime4`) and the live `version` from `nix eval --raw --inputs-from . nixpkgs#sublime4.version`; (g) the README rewrite preserves the original Kavita/Calibre install commands verbatim AND does not claim "sops ships on every host"; (h) the elecwhat-bin recipe's `unpackPhase` uses `tar -xJf` (xz) explicitly, not `tar -xf`; (i) all `nixpkgs#` references in the verification commands use `--inputs-from .`. Output a verdict line "F2: PASS" or "F2: FAIL <reason>".

- [x] F3. **Real manual QA.** Re-run the 19 `nix eval` commands and 7 negative `grep`/`find` checks from Todo 14 one more time, plus `nix flake check`, the elecwhat-bin build verification, and the secretspec CLI check. Output a verdict line "F3: PASS" or "F3: FAIL <reason>".

- [x] F4. **Scope fidelity.** Confirm: (a) no unrelated flake input was updated (only `sops-nix`); (b) no other module was reformatted or refactored; (c) no other package was added or removed; (d) the README change is exactly the Secrets section; (e) the `tests/package-policy.sh` PASS output is recorded in the worker's session log; (f) the elecwhat-bin derivation's `meta.description` says "WhatsApp client" (not "electronics reference"); (g) no `nix run .#secretspec` or `nix flake show --json` positive package assertion appears in the worker's notes (the flake does not export those); (h) Todo 9's `nix eval --inputs-from . nixpkgs#elecwhat-bin.pname/version` output is recorded in the commit body (proving the worker confirmed nixpkgs still lacks the package before authoring the derivation); (i) no `nix-build .#elecwhat-bin` appears in the worker's notes (use the two-command sequence from Todo 11); (j) no bare `nixpkgs#` query (without `--inputs-from .`) appears in the worker's notes. Output a verdict line "F4: PASS" or "F4: FAIL <reason>".

## Commit strategy

Three commits, in this order, each immediately preceded by `bash tests/package-policy.sh` (must exit 0) and followed by `git status` (must show no uncommitted changes). **Total: 13 files** (commit 1: 8 files, commit 2: 2 files, commit 3: 3 files — 12 source files + 1 lockfile in commit 1).

1. **`chore(flake+secrets): adopt sops-nix, secretspec, and darwin agenix secondary key`**
   - `flake.nix` (one new input)
   - `flake.lock` (one new node + possible sibling `sops-nix_2` follow alias)
   - `modules/aspects/features/sops.nix` (new file)
   - `modules/aspects/platforms/darwin.nix` (one line in `includes`)
   - `modules/aspects/platforms/linux.nix` (one line in `includes`)
   - `modules/shared/packages.nix` (one new package, `secretspec`)
   - `modules/standalone-linux/packages.nix` (one new package, `sops`)
   - `modules/darwin/secrets.nix` (one new entry in `age.identityPaths`)

2. **`docs(secrets): add secretspec toml template and rewrite README secrets section`**
   - `secretspec/secretspec.toml` (new file)
   - `README.md` (rewrite of "Secrets" section only)

3. **`feat(packages): add sublime4 and elecwhat-bin to linux packages`**
   - `pkgs/elecwhat-bin.nix` (new file)
   - `modules/linux/packages.nix` (two additions: `sublime4` in the cross-platform list and the elecwhat-bin `callPackage` in the x86_64-only block)
   - `config/package-exceptions.json` (four new rows for `sublimetext4`)

`flake.lock` is NOT modified in commit 3 (the only flake input that changed was `sops-nix` in commit 1; no new inputs in commit 3). Commit 3 modifies 3 source files only; `flake.lock` is in commit 1. The "13 files" total is a UNION across commits.

After all three commits, run `nix flake check` once more as the pre-handoff gate.

## Success criteria

The plan is successful if and only if all of the following are true at handoff:

1. `git log --oneline -3` shows exactly the three commits above, in order.
2. `git diff main..HEAD --stat` shows changes to exactly the **13** files listed in the commit strategy (12 source files + 1 lockfile; not 10, not 12, not 14).
3. `bash tests/package-policy.sh` exits 0 with both `package-policy-source=PASS` and `package-policy-probe=PASS`.
4. `nix flake check` exits 0.
5. The 19 targeted `nix eval` commands return the expected counts/lists. Sublime (`sublimetext4`) appears on all four Linux outputs and not on darwin. Elecwhat-bin appears on the two x86_64 Linux outputs and not on aarch64-linux or darwin. `sops` appears on the four Linux outputs and on darwin. `secretspec` appears on every host.
6. The 7 negative `grep`/`find` commands return no results. Specifically: no `age.secrets.*` or `sops.secrets.*` blocks (including quoted and aggregate forms for both `age` and `sops`); no `.age` / `.sops.yaml` / `.sops.json` / `.sops.env` / `secrets.age` files; no new plaintext files under `secrets/`.
7. The elecwhat-bin build verification (two-command sequence from Todo 11) exits 0 and prints a valid store path containing `bin/elecwhat`, `share/applications/elecwhat.desktop`, and `lib/elecwhat/resources/app.asar`.
8. `nix run --inputs-from . nixpkgs#secretspec -- check -f secretspec/secretspec.toml --provider local_env --no-prompt --reason "validate manifest"; echo $?` prints `0`.
9. All four final-verifier rows (F1–F4) report PASS.
10. No file under `secrets/` other than the existing `README.md` and `calibre/*.json` is added (the `gitignore` would hide any new entry anyway).
11. `nix eval --raw --inputs-from . nixpkgs#sublime4.pname` returns `sublimetext4` (proves the package-exceptions.json rows use the correct pname).
12. `git diff main..HEAD -- '*.age' '*.sops.yaml' '*.sops.json' '*.sops.env' 'secrets.age*'` is empty.
13. The elecwhat-bin derivation's `meta.description` reads "WhatsApp client" (or contains the word "WhatsApp"), NOT "electronics reference" or "electronics component".
14. The commit body of commit 3 records the output of `nix eval --raw --inputs-from . nixpkgs#elecwhat-bin.pname` and `nix eval --raw --inputs-from . nixpkgs#elecwhat-bin.version` (Todo 9's verification step), proving the worker confirmed nixpkgs still lacks the package before authoring the derivation.
