# Dendritic Den refactor with Nushell primary

## Objective and invariants

Replace the hand-built `outputs` graph with flake-parts plus pinned Den, make NixOS,
nix-darwin, and standalone Home Manager entities Den-owned, and reorganize machine
configuration around explicit capabilities. Preserve every existing public output and
all behavior characterized under `.omx/evidence/dendritic/`, except the intentional
Nushell and newly exposed architecture/check outputs. Preserve the ten already staged
bootstrap-password files throughout; never reset or rewrite the index as a shortcut.

Accepted deltas are limited to:

- `mei`'s NixOS and Darwin account shell becomes the pinned `pkgs.nushell`.
- Nushell is added to valid OS shells and enabled by Home Manager.
- Ghostty launches the Nix-store Nushell executable with `--login`.
- Den/flake-parts/import-tree inputs, Den-owned outputs, top-level overlays, and
  dendritic checks are added.

Everything else in the baseline JSON is a regression unless explicitly explained by
an upstream module's equivalent representation.

## Target layout

```text
flake.nix                              # inputs + one mkFlake/import-tree call only
modules/
  flake/
    dendritic.nix                     # imports pinned Den flake module
    systems.nix                       # four supported systems
    nixpkgs.nix                       # one package policy + overlay constructor
    overlays.nix                     # conventional flake.overlays output
    packages.nix                     # perSystem local package outputs
    apps.nix                         # perSystem operational apps
    dev-shells.nix                   # perSystem development shell
    checks.nix                       # structural/config regression checks
  entities/
    hosts.nix                        # thin host/user/home registry only
    defaults.nix                     # schema classes and state-version defaults only
  aspects/
    users/mei.nix                    # user account, HM baseline, all four shells
    hosts/nixos-workstation.nix      # aggregate includes for NixOS machines
    hosts/darwin-workstation.nix     # aggregate includes for Darwin machines
    features/nix-core.nix            # Nix policy, caches, GC, fonts/shared OS policy
    features/nixos-base.nix          # boot/network/services/users host baseline
    features/linux-desktop.nix       # legacy X11 desktop and Linux HM payload
    features/niri.nix                # Niri/portal/runtime and Niri HM payload
    features/darwin-base.nix         # macOS defaults/system package policy
    features/darwin-dock.nix         # Dock module and entries
    features/secrets.nix             # agenix import and platform identity paths
    features/storage.nix             # disko module + disk declaration
    features/bootstrap-password.nix  # external bootstrap verifier module
    features/standalone-linux.nix    # standalone-only package/files/mutable Codex
```

Large config/assets and low-level class modules may remain under their existing
`modules/{shared,linux,nixos,darwin,standalone-linux}` paths initially, but each must be
owned by exactly one capability aspect. `hosts/*` cease to compose modules and are
deleted only after parity. Do not use recursive legacy imports, string selectors,
`specialArgs` plumbing, `den.ctx`, mutual-provider shims, or one aspect per package.

## Execution waves

### 1. Freeze the current contract (rollback: no production files touched)

1. Record HEAD, index tree, staged path list, output inventory, input locks, and current
   behavior under `.omx/evidence/dendritic/`.
2. Commit no evidence; evidence is operational state. Preserve the existing index and
   compare it after each wave.
3. Add `tests/dendritic-architecture.sh`, `tests/dendritic-config-eval.nix`,
   `tests/dendritic-shells.sh`, and `tests/dendritic-boundaries.sh` before production
   edits. Capture RED results proving missing Den/flake-parts and current Zsh/Fish
   primary paths.
4. PIN gate: all five `tests/bootstrap-password-*` tests pass, and baseline eval covers
   output names, NixOS/Darwin/HM state versions, host/user facts, desktop/Niri/Dock,
   package/app/devShell keys, HM file/activation keys, and current shell projections.

### 2. Introduce the outer architecture (rollback: restore flake.nix/lock and remove flake modules)

1. Add `flake-parts`, `import-tree`, and Den pinned to
   `1614f6f8ed435c5bb257408bf91fd662f9aac43e`; follow existing nixpkgs where supported.
2. Reduce `flake.nix` to inputs and
   `inputs.flake-parts.lib.mkFlake { inherit inputs; } (inputs.import-tree ./modules/flake)`.
3. Move existing output factories without semantic edits into `modules/flake/*`.
   Configure `systems` once. Export the local overlay list conventionally while using
   the same list for all package sets.
4. Import `inputs.den.flakeModules.dendritic` from `modules/flake/dendritic.nix`.
5. GREEN gate: output key inventory is identical (plus allowed overlays/checks), app
   programs resolve, all four package/devShell/app systems evaluate, and bootstrap tests
   remain green.

### 3. Establish Den entities with coexistence adapters (rollback: keep flake-parts outputs, restore manual entity factories)

1. Declare two Linux hosts named `x86_64-linux` and `aarch64-linux`, two Darwin hosts
   named `x86_64-darwin` and `aarch64-darwin`, each with `users.mei.classes =
   [ "homeManager" ]`.
2. Declare standalone homes named `standalone-linux` and
   `standalone-linux-aarch64`; explicitly include the `mei` user aspect while retaining
   `home.username = "mei"` and current home directories/state versions.
3. Set `den.schema.user.classes = [ "homeManager" ]`. Use Den's current host/home
   schemas and outputs only. Attach the existing host/HM modules through temporary
   coherent capability aspects, not through `den.batteries.import-tree`.
4. Ensure Den's HM integration has `useGlobalPkgs`, user packages, backup semantics,
   and secret path arguments expressed as module values rather than hidden
   `extraSpecialArgs`.
5. Delete manual `nixosConfigurations`, `darwinConfigurations`, and
   `homeConfigurations` factories only when exact output and behavior comparison is
   green.

### 4. Extract capability ownership (rollback after every individual aspect)

Move one coherent capability at a time, keeping class content unchanged and running the
comparison gate after every move:

1. `nix-core` and unified nixpkgs/overlay policy.
2. `mei`: shared HM programs/files/packages and explicit user facts.
3. `nixos-base`, then `storage`, `bootstrap-password`, and `secrets`.
4. `niri`, then `linux-desktop`; keep their Home Manager content on `mei` or explicitly
   deliver a genuine host-selected payload with `provides.to-users`. Never request a
   `user` argument inside a host-class module.
5. `darwin-base`, `darwin-dock`, and Darwin secrets.
6. `standalone-linux`, including writable Codex activation semantics and ambient user
   override behavior only if the baseline proves it intentional. Prefer explicit
   entity facts over evaluator `HOME`/`USER` reads.
7. Make aggregate workstation aspects include leaf capabilities. Host declarations
   contain only system/name/users/includes and architecture-specific facts.
8. Once no imports reference `hosts/nixos`, `hosts/darwin`, or unreachable
   `modules/darwin/files.nix`, delete those superseded entrypoints and prove their
   absence with the boundary test.

### 5. Make Nushell primary (rollback: one aspect plus Ghostty source)

1. In `mei.homeManager`, enable `programs.nushell`, set safe Nu-native settings and
   aliases only, and retain existing `programs.bash`, `programs.zsh`, and
   `programs.fish` blocks unchanged.
2. In `mei.nixos` and `mei.darwin`, add Nushell, Zsh, Bash, and Fish to
   `environment.shells`; set `users.users.mei.shell = pkgs.nushell`. Do not use
   `den.batteries.user-shell "nushell"`.
3. Render Ghostty's `command` from the HM module as `${pkgs.nushell}/bin/nu --login`;
   eliminate `/bin/fish --login` from both generated and source configs. Let tmux
   inherit the account shell. Keep OMX's explicit Zsh/Bash compatibility selector and
   all interpreter shebangs.
4. GREEN gate checks NixOS and Darwin account shells, all HM instances' Nushell enable,
   all secondary shell enablement/registration, Ghostty's store path, and real
   `nu`, `bash`, `zsh`, and `fish` marker commands from the evaluated package set.

### 6. Documentation, final checks, and cleanup

1. Update `README.md` with the target map, aspect rules, output names, common commands,
   and Den pin/upgrade review policy. Add `docs/architecture/dendritic.md` explaining
   entity/aspect ownership and why flake outputs remain separate. Update installation
   docs only where command/output paths changed.
2. Run `nix fmt` or the repository's formatter, Nix parser evaluation for every tracked
   `.nix`, `nix flake show --all-systems`, `nix flake check --all-systems`, NixOS
   toplevel dry-run/build, both Darwin system evals, both standalone HM activation
   evals, every app/package key eval, all new structural/config tests, and all five
   bootstrap tests.
3. Compare fresh behavior JSON with the baseline using a machine-readable allowlist
   containing only the accepted deltas above. Record command, exit code, and diff in
   `.omx/evidence/dendritic/`.
4. Run architecture, code-quality, security, QA, and context reviews against one frozen
   tree. Fix every finding and rerun affected gates until unconditional approval.
5. Verify no temp fixtures/processes remain, no secrets were introduced, and the final
   staged set contains both the original ten files and this refactor. Do not commit.

## Required final evidence

- `baseline-state.txt`, `output-inventory-baseline.json`, `behavior-baseline.json`
- `architecture-red.txt`, `shells-red.txt`, `boundaries-red.txt`
- `output-inventory-green.json`, `behavior-green.json`, `behavior-diff.txt`
- `bootstrap-pin.txt`, `bootstrap-green.txt`, `shells-green.txt`
- `flake-check.txt`, `cross-platform-eval.txt`, `build-dry-run.txt`
- `boundaries-green.txt`, `secret-scan.txt`, `cleanup.txt`
- reviewer artifacts ending in code APPROVE, architecture CLEAR, security/QA/context
  PASS, and final UNCONDITIONAL APPROVAL

## Key risks and controls

- **Den routing churn:** immutable SHA, current public APIs only, structural rejection of
  compatibility APIs, and target-lock eval on all entity classes.
- **Silent user/HM omission:** assert exact HM output and embedded-user projections for
  every architecture; HM lives on the user aspect.
- **Cross-platform blindness:** Linux builds plus Darwin evaluation; explicitly report
  that live macOS activation remains untested.
- **Disk/install regression:** never execute disko; evaluate its declaration and rerun
  bootstrap/install mutation tests only.
- **Index collision with prior work:** record/stage by explicit path, compare the
  original staged blob IDs before final staging, and never use reset/checkout/clean.
