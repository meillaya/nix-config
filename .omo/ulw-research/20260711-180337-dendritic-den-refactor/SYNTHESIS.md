# ULW-Research Synthesis: Den-dritic refactor of nix-config

Workers: 18 · Waves: 2 · Observation groups: 15+ · Executed verifications: 4

## Executive summary

The target should use **flake-parts as the sole outer output composer and pinned Den as the entity/aspect layer for NixOS, nix-darwin, and standalone Home Manager configurations**. Packages, apps, updater scripts, dev shells, and checks should remain ordinary `perSystem` outputs; overlays remain top-level. This matches Den's default template and current public multi-platform adopters while preserving this repository's unusually rich operational output surface. [Den outputs](https://github.com/denful/den/blob/1614f6f8ed435c5bb257408bf91fd662f9aac43e/modules/outputs.nix#L8-L30) [Den default template](https://github.com/denful/den/blob/1614f6f8ed435c5bb257408bf91fd662f9aac43e/templates/default/flake.nix#L3-L6)

Migration must be incremental and behavior-pinned. Den's authoritative guide explicitly supports retaining legacy modules while extracting aspects; independent reports agree that small slices and frequent checks are safer. [Den migration guide](https://github.com/denful/den/blob/1614f6f8ed435c5bb257408bf91fd662f9aac43e/docs/src/content/docs/guides/migrate.mdx#L35-L108) The current repository already has coherent aspect seams: shared package policy, shared CLI/user baseline, Linux desktop, Niri, legacy X11, Darwin workstation/Dock, secrets, storage, bootstrap installation, and standalone mutable Codex integration. See `wave-2-explore-migration-matrix.md`.

Nushell should be configured explicitly, not through `den.batteries.user-shell`. Against this repository's locked nixpkgs/Home Manager/nix-darwin, a temporary Den fixture proved that `environment.shells = [ pkgs.nushell ... ]`, `users.users.mei.shell = pkgs.nushell`, and `programs.nushell.enable = true` evaluate on NixOS and Darwin. Existing Bash, Zsh, and Fish modules and shebangs remain. Ghostty must stop hardcoding Fish if terminals are to open Nu. See `wave-2-verify-den-nushell-pilot.md`.

## Architecture decision

1. Add pinned `den`, `flake-parts`, and import-tree inputs.
2. Let flake-parts call one recursively imported top-level module tree.
3. Let Den own hosts, users, homes, and feature aspects.
4. Keep operational package/app/devShell/check logic in flake-parts `perSystem`.
5. Keep overlays as conventional top-level flake outputs.
6. Use current APIs only: `den.aspects`, `den.schema`, `den.hosts`, `den.homes`; no `den.ctx`, mutual-provider, or deprecated wrappers. [Den current migration API](https://github.com/denful/den/blob/1614f6f8ed435c5bb257408bf91fd662f9aac43e/docs/src/content/docs/guides/migrate-ctx.mdx#L14-L26)
7. Keep Home Manager content on the `mei` user aspect. Do not request `user` directly inside host-scoped class modules; pinned fixtures confirm issue #629 remains silently inert. Use explicit `provides.to-users` only for genuine host-to-user delivery. [Provide implementation](https://github.com/denful/den/blob/1614f6f8ed435c5bb257408bf91fd662f9aac43e/nix/lib/aspects/fx/aspect/provide.nix#L21-L28)

## Organization principles

Adopt from hlissner only bounded ideas: thin machine declarations, domain taxonomy, separate role/hardware/network/user facts, host-local versus shared secrets, and isolated packages/overlays. Do not copy universal recursive imports, string-profile selectors, or lateral global-config feature detection; that repository explicitly uses a custom host-centric architecture rather than Den. [hlissner loader](https://github.com/hlissner/dotfiles/blob/8fd49e4bb971f6035e4fd9c3e059f5dc2e8d87b9/lib/modules.nix#L43-L58)

Prefer a small number of stable aggregate aspects (`base`, `workstation`, `linux-desktop`, `darwin-workstation`, `mei`) plus coherent leaf capabilities. Do not create one aspect per package. Public evidence closest to this topology is vic/vix for multi-platform entities and nixicle for separating entity configurations from ordinary flake outputs. [vix entities](https://github.com/vic/vix/blob/5802915fa6b9444e444ae5e89b379b73b6763ac0/modules/hosts.nix#L2-L29) [nixicle outputs](https://github.com/hmajid2301/nixicle/blob/a10f7322101d264e9936bb8f5a21dba887338a39/modules/flake-outputs.nix#L68-L107)

## Nushell decision

- Enable `programs.nushell` in the shared Home Manager user aspect.
- Register Nushell plus Bash, Zsh, and Fish as valid OS shells.
- Set `mei`'s NixOS and Darwin account shell to `pkgs.nushell`.
- Make Ghostty launch Nu rather than `/bin/fish --login`.
- Let tmux inherit the account shell unless real QA proves an explicit default is needed.
- Preserve POSIX `/bin/sh`, all existing shell modules, and interpreter-specific shebangs.
- Keep OMX's internal compatibility wrapper on its supported Zsh/Bash path unless separately proven Nu-compatible; “primary terminal shell” does not require rewriting implementation scripts.

Primary sources: [NixOS shell registry](https://github.com/NixOS/nixpkgs/blob/fc9da8f8dfcd970268ecb090b4677b1263c84339/nixos/modules/config/shells-environment.nix#L209-L244), [Home Manager Nushell](https://github.com/nix-community/home-manager/blob/0992a2948749a61d54065e96df26d75d1b1da50f/modules/programs/nushell.nix#L45-L65), [nix-darwin shell registry](https://github.com/nix-darwin/nix-darwin/blob/d5bd9cd77aea4c0a8f49e7fd85545671a208ed15/modules/system/shells.nix#L11-L48), [Nushell login guidance](https://www.nushell.sh/book/default_shell.html).

## Verification contract

Before migration, capture all public output keys and critical option projections for NixOS, Darwin, standalone HM, bootstrap activation, desktop files, Dock, packages/apps, overlays, and shell state. After each aspect slice, compare against that snapshot, allowlisting only intentional Nushell deltas. Run all bootstrap lifecycle/helper/secret/mutation scripts, all-systems flake check, x86_64 NixOS toplevel dry-run/build, Darwin evals, standalone HM activation evaluation, and Nu/Bash/Zsh/Fish runtime smoke.

## Contradictions resolved

- **Den versus plain flake-parts:** plain flake-parts is simpler, but this repository has demonstrated cross-class user/system duplication across NixOS, Darwin, and standalone HM. Use Den narrowly for those configuration entities while retaining flake-parts for ordinary outputs.
- **Host-scope HM:** Den intentionally suppresses host-scope HM delivery after #609. Keep HM on user aspects.
- **Den user-shell battery:** generic name suggests it supports Nu; target-lock execution refutes that because NixOS/Darwin have no OS `programs.nushell` module.
- **Big-bang migrations in public history:** they demonstrate possibility, not safety. The authoritative guide and this task's regression risk require incremental extraction.

## Gaps and residual risk

- Live Darwin account activation/login cannot be tested from this Linux host; Darwin evaluation is the available proof.
- The live machine currently lacks Nu, so real Nu login/terminal/tmux smoke must occur after the package becomes available through the new configuration.
- Den is v0.x with current routing churn; pin the reviewed SHA and document upgrade review.
- x86_64-darwin support is ending in future nixpkgs; preserve the current compatible lock and treat architecture retirement as separate work.
- No reliable general migration duration exists; self-reports vary too widely and remain unresolved claim C7.

## Expansion trace

Wave 1 used 12 unique workers for repo architecture, module graph, shell behavior, tests/history, authoritative Den, dendritic comparisons, migration reports, Nushell, hlissner, public configs, Den shell internals, and skeptical counter-research. Wave 2 used 6 workers for routing execution, target-lock Den/Nu pilot, exact migration matrix, output composition fixture, locked shell behavior, and current adopter topology. All actionable research leads are either closed or converted into post-change verification scenarios. Convergence: zero unchecked architecture leads remain after two waves.
