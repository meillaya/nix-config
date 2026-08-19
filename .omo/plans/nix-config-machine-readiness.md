# Machine-readiness final reconciliation

**Reconciled:** 2026-07-17

**Scope:** current working tree; repository readiness only

**Purpose:** final audit of the former Tasks 1-26 and F1-F4, not a new implementation plan

## Verdict

The repository has a substantially improved, evaluable multi-platform configuration, but it is **not production-qualified as a machine fleet**. Repository structure and selected configuration contracts are complete; focused readiness integrations are partial; obsolete requirements are superseded; physical, provider, media, credential-rotation, native Darwin, and runtime gates remain **NOT VERIFIED**.

No fixture, synthetic model, evaluation, dry run, or `--no-build` check in this record is physical qualification. No live Home Manager/NixOS switch, service restart, physical install, media boot, or native Darwin activation was performed.

## Status language

| Status | Meaning in this reconciliation |
| --- | --- |
| **COMPLETE** | A bounded repository-side feature exists in the current tree and has concrete current-tree evidence. It does not imply physical/runtime qualification. |
| **PARTIAL** | Useful implementation or tests exist, but the original contract is not fully realized or its runtime/external side is open. |
| **SUPERSEDED** | A former requirement is intentionally removed from the architecture and must not be reintroduced to satisfy the old plan. |
| **NOT VERIFIED** | The required external, physical, native-platform, media, credential, or runtime evidence is absent. This is not failure and is never converted to success by a fixture. |

## Normative architecture now

### Den/Dendritic boundaries

- Den is the entity/aspect layer and flake-parts is the outer output composer. Strict mode is loaded from `inputs.den.flakeModules.strict`.
- Entities are data only. Machine facts and validation live in the typed authority under `modules/entities/_machine-authority/`; entities carry explicit machine and user/home identity.
- Active NixOS and Darwin system modules consume `host.machine.identity`; their
  Home Manager modules consume `user.identity`. They do not redeclare account
  names or platform home paths.
- Behavior composes inward through:

  ```text
  shared policy -> platform -> role -> hardware/storage -> named host
  ```

- Named-host aspects own final host projection. Ambient evaluator identity is not a supported input.
- Authoritative references: [Den](https://github.com/denful/den) and [DeepWiki: Den](https://deepwiki.com/denful/den).

### Evaluation inventory and release eligibility

`modules/flake/outputs.nix` declares exactly six configuration evaluation paths:

1. `darwinConfigurations.aarch64-darwin`
2. `homeConfigurations.standalone-linux`
3. `homeConfigurations.standalone-linux-aarch64`
4. `nixosConfigurations.aarch64-linux`
5. `nixosConfigurations.nixos-x86-qualifier`
6. `nixosConfigurations.x86_64-linux`

This list is evaluation coverage, not release eligibility. In particular,
`nixosConfigurations.aarch64-linux` is an evaluation role and
`nixosConfigurations.nixos-x86-qualifier` is a non-release qualifier. No path
is production-qualified by appearing in the inventory. `x86_64-darwin` is
unsupported and must remain absent from systems and configuration outputs.

### Package construction policy

- The reconciled architecture exports no repository-authored overlays and contains no custom standalone production package recipes for the retired package classes (including the former AI sidecars and production theme packages).
- This is deliberately not a "no derivations" claim: repository app/check wrappers and fixed-output fetches of upstream sources are still Nix derivations.
- Package/module consumption is through upstream flake, module, and package surfaces. The existing Emacs overlay is an upstream flake input, not a repository-authored overlay.
- Package cleanup removed the repository overlay export, all `x86_64-darwin` package exceptions, and the production theme `runCommand` derivations.
- Redundant installed helper derivations (`nixpkgs-search`,
  `setup-ddc-brightness`, and `nix-config-home-preflight`) were removed. The
  remaining repo-authored script derivations are bounded flake app/check
  wrappers and the required non-clobbering Home Manager backup command; they
  are not standalone package recipes.
- The former custom AI sidecars, release-pin/update machinery, and managed Claude/Codex/OMX baselines are out of scope and **SUPERSEDED**. User-owned tool state and provider lifecycle are not machine-readiness claims.

### Noctalia v5

- Noctalia comes from its upstream v5 flake modules and Cachix configuration; see [Noctalia v5 NixOS setup](https://docs.noctalia.dev/v5/getting-started/nixos/).
- `modules/aspects/features/noctalia.nix` imports the upstream NixOS and Home Manager modules and enables their systemd integration.
- Exactly one Noctalia user service is intended. The shared Niri config does not add a second Noctalia startup owner.
- Active Linux/standalone package and file surfaces contain no `swaybg`,
  `swaylock`, or `wlogout` owner; Noctalia is the sole configured Niri bar,
  notification, lock, and wallpaper path.
- `modules/standalone-linux/config/noctalia/config.toml` sets `launch_apps_as_systemd_services = true`.
- Home Manager sets `systemd.user.services.noctalia.Unit.X-SwitchMethod = "keep-old"`.
- The obsolete v4 `settings.json` credential-bearing file has been deleted. This makes no credential-rotation claim.
- `bin/setup-noctalia-cachix.sh` targets the systemd `nix-daemon.service` arrangement used by multi-user Nix and Determinate Nix on Linux. After writing the trusted configuration, a real run succeeds only if the unit is found, restarted, active, the effective URL/key are visible, and the daemon responds. Repository tests exercise those branches with explicit command stubs only; no live daemon action was performed.
- Cachix activation is not transactional: a failed restart or validation leaves the edited Nix configuration in place and exits nonzero with a recovery instruction. There is no automatic file rollback or live restoration proof, so daemon activation and rollback remain residual operational risks and **NOT VERIFIED** here.

### Manual out-of-store secret sync

- `sync-secrets` requires either `--repo-root` or
  `NIX_CONFIG_REPO_ROOT`; the argument takes precedence. Omitting both fails
  closed even inside a Git checkout. There is no detected-checkout fallback.
- The cloned secrets-repository URL is never logged. Source and destination
  symlinks are rejected recursively, and replacement of live files uses an
  atomic same-filesystem exchange.
- Home Manager does not ingest or manage the synced plaintext Calibre or Kavita
  files. Installing those files remains a manual runtime workflow outside Nix
  evaluation.
- These are repository-side contracts only. They do not establish live host
  containment, provider rotation, runtime installation, or machine
  qualification; the applicable physical, provider, native, runtime, and media
  gates remain **NOT VERIFIED**.

## Evidence recorded for this working tree

The leader verified the following repository-side evidence on the current
quiescent product tree after cleanup:

- All six configuration `drvPath` evaluations passed:

  ```text
  darwinConfigurations.aarch64-darwin.system.drvPath
  homeConfigurations.standalone-linux.activationPackage.drvPath
  homeConfigurations.standalone-linux-aarch64.activationPackage.drvPath
  nixosConfigurations.aarch64-linux.config.system.build.toplevel.drvPath
  nixosConfigurations.nixos-x86-qualifier.config.system.build.toplevel.drvPath
  nixosConfigurations.x86_64-linux.config.system.build.toplevel.drvPath
  ```

- `nix flake check --all-systems --no-build` passed.
- Current-tree secret policy, writable-checkout secret-sync regression,
  package policy, the Noctalia Cachix stub
  regression, dendritic architecture/boundaries/apps/config-eval/shells, and
  Tasks 7/15/17/22/23 fixture and negative lanes all passed. Protected action
  counts were zero.
- `nix run .#home-switch -- --dry-run` completed. It printed
  `Keeping old units: noctalia.service` and proposed removing the retired
  `.config/mako`, `.config/waybar`, and `.config/wlogout` links. It did not perform a live switch or
  service restart.
- The current source/evaluation audit found no competing Polybar, Dunst,
  screen-locker, swaylock, swaybg, wlogout, i3lock, awww, swww, Picom, Rofi,
  Waybar, Mako, BSPWM, or SXHKD ownership in the active NixOS, Linux, or
  standalone modules.
- `git diff --check` passed.

Evidence boundaries:

- `tests/readiness/README.md` explicitly defines Tasks 7/15/17/22/23 as fixture-only partial integrations with zero protected actions.
- Task 23 is portable fixture coverage; it is not native Darwin evidence.
- `nix flake check --all-systems --no-build` proves evaluation/check construction only. It does not realize foreign systems or prove activation.
- The Home Manager command was a dry run. It did not switch, restart, or otherwise activate Noctalia.
- The Cachix regression test writes only temporary configuration and uses explicit `systemctl`/`nix` stubs. Its confirmed and fail-closed branches are repository evidence, not proof that a real daemon accepted the configuration or that rollback works.

## Exact-tree evidence binding required for final verification

This plan edit changes the tree, so no exact-tree identifiers or hashes are recorded here. Final verification must wait for the edited tree to be quiescent and record these three values in the final evidence report, without substituting values captured before the last validation run:

```bash
git rev-parse --verify HEAD
git diff --cached --binary --full-index --no-ext-diff | sha256sum
git diff --binary --full-index --no-ext-diff | sha256sum
```

The recorded values are, respectively, the base commit, index diff hash, and unstaged worktree diff hash. Any subsequent index, worktree, or `HEAD` change invalidates the binding and requires verification plus capture again. Because Git diff streams omit untracked content, final exact-tree acceptance also requires every evidence-bearing untracked file to be staged, removed, or covered by a separately recorded content manifest. Hashes must not be invented or backfilled while other workers are still changing the tree.

## Original-task reconciliation

| ID | Status | Current disposition and evidence boundary |
| --- | --- | --- |
| 1. Credential exposure / incident gate | **PARTIAL** | The obsolete v4 file is deleted in the working tree and `tests/current-tree-secret-policy.sh` passes. Provider rotation, provider activity/history review, and any external incident receipt remain **NOT VERIFIED**. Never infer rotation from file removal. |
| 2. Support/evidence schema and claim map | **SUPERSEDED** | The former bespoke signed-record graph and 73-claim machinery are not the current architecture. This concise ledger replaces its planning role; external facts remain external gates. |
| 3. Platform/package policy and Intel Darwin retirement | **PARTIAL** | Current systems and evaluation paths exclude `x86_64-darwin`; package cleanup removed the repository overlay export, `x86_64-darwin` exceptions, production theme `runCommand` derivations, and three redundant installed helper derivations. Bounded app/check/backup script derivations remain legitimate infrastructure. Package policy rejects global escapes and permits only the upstream Emacs overlay. The task's custom AI package/release machinery is **SUPERSEDED** rather than incomplete. |
| 4. Typed host/identity/location authority | **COMPLETE** | `modules/entities/_machine-authority/{model,validators,crypto}.nix`, `machine-authority.nix`, and explicit identities in `modules/entities/hosts.nix` provide the current typed authority. NixOS/Darwin system modules consume `host.machine.identity`, Home Manager consumes `user.identity`, and source regressions reject hardcoded account/home literals in those active modules. Darwin exposes only build/search while its validated machine remains operationally disabled. This is repository completion only. |
| 5. Shared/platform/role/hardware/storage/named-host separation | **COMPLETE** | The aspect directories and dendritic boundary/configuration tests evidence the declared inward-only chain; entities remain data-only. |
| 6. Readiness harness/check surface | **PARTIAL** | `tests/readiness/run-task.sh` and manifests exist only for Tasks 7/15/17/22/23. The runner intentionally has no external-status or physical qualification mode. |
| 7. Per-host storage/install contracts | **PARTIAL** | Focused fixture and negative selectors cover disk identity, journals, staging, and rejection paths. Current machine storage profiles remain non-destructive/pending; there was no disk write or install. |
| 8. ESP budget / legacy-layout gate | **NOT VERIFIED** | A configured boot-entry limit is not evidence of ESP capacity, disk layout, bootability, or a physical legacy-layout transition. |
| 9. Boot-tested rollback generation | **NOT VERIFIED** | No live activation, reboot, recovery boot, or rollback drill was performed. |
| 10. Intel/AMD Disko/OVMF qualification | **SUPERSEDED** | Synthetic or fixture topology must not be described as production-shaped physical qualification. Any future VM tests remain VM tests; no class qualification follows. |
| 11. Direct media / experimental remote lane | **NOT VERIFIED** | Installer entry points and Task 7 guards do not prove signed media creation, media boot, remote installation, or a physical no-kexec flow. No media gate was run. |
| 12. Installed SSH / bootstrap credential retirement | **NOT VERIFIED** | Repository tests do not prove an installed host's SSH transition or retirement of bootstrap credentials. Credential lifecycle evidence is external/physical. |
| 13. Runtime secret roles and sync containment | **PARTIAL** | Both Linux sync apps require `--repo-root` or `NIX_CONFIG_REPO_ROOT`, with the argument taking precedence; omission fails closed even inside a checkout, with no detected-checkout fallback. The cloned repository URL is never logged. Source and destination symlinks are rejected recursively, and live replacement uses an atomic same-filesystem exchange. Home Manager does not ingest or manage the synced plaintext Kavita/Calibre files; installation remains a manual runtime workflow outside Nix evaluation. These are repository-side contracts only: no live host enrollment, decryption ceremony, installed-host containment, runtime installation, provider-side rotation, or physical/native/media qualification was verified. |
| 14. Standalone Nix bootstrap / offline verification | **PARTIAL** | Both standalone Home Manager outputs evaluate and `home-switch --dry-run` was exercised. Fresh bootstrap, offline installation, and live activation were not performed. |
| 15. Hardware enrollment and vendor closures | **PARTIAL** | Focused fixture and negative selectors cover collector/intake model contracts. No raw fixture was promoted to a production declaration and no physical machine was enrolled or qualified. |
| 16. First-boot Wi-Fi / recovery fallback | **NOT VERIFIED** | Typed capability fields or package availability do not prove first-boot networking, firmware, tethering, or recovery on hardware. |
| 17. GPU/audio/Bluetooth/power/suspend/DDC routing | **PARTIAL** | Typed routing and focused fixture/negative selectors exist. No device probe, suspend/resume cycle, renderer, Bluetooth/audio session, or physical DDC result was recorded. |
| 18. Noctalia as sole Niri session authority | **PARTIAL** | The current source/evaluation audit rejects competing Polybar, Dunst, screen-locker, swaylock, swaybg, wlogout, i3lock, awww, swww, Picom, Rofi, Waybar, Mako, BSPWM, and SXHKD ownership in active NixOS/Linux/standalone surfaces. Noctalia remains the only configured bar/notification/lock/wallpaper owner. All six configuration evaluations passed, and the current-tree Home Manager dry run retained `noctalia.service`. NixOS system-switch continuity and all live session/service runtime behavior remain **NOT VERIFIED** because no live switch or service restart occurred. |
| 19. OBS and portal ownership | **PARTIAL** | Repository configuration/evaluation covers application and portal surfaces, but no live capture, PipeWire, screencast, or portal-owner test was performed. |
| 20. Theme assets and Kitty semantics | **PARTIAL** | Shared configuration is present and evaluated, but visual/runtime parity on physical Linux and native Darwin is not verified. |
| 21. Deterministic/offline Emacs | **PARTIAL** | The tree uses the upstream pinned Emacs overlay and evaluation checks. No complete offline realization and launch was recorded for every release path. |
| 22. Standalone Home Manager incremental adoption | **PARTIAL** | Explicit identity and prerequisite fixture/negative selectors pass; the real app was exercised only with `--dry-run`, which retained `noctalia.service`. No live switch occurred. |
| 23. Apple Silicon Darwin ownership | **PARTIAL** | The evaluation path is aarch64-only, Homebrew-free intent is represented, portable fixture/negative selectors exist, and the disabled validated machine exposes build/search only—not switch/clean/update/key apps. Credential scripts cannot select ambient `$USER`. Native Darwin build, switch, relogin, rollback, TCC, app, media, and closure checks remain **NOT VERIFIED**. |
| 24. CI/update/release gate machinery | **SUPERSEDED** | The former monolithic signed-evidence/release-pin design, especially AI release maintenance, is not normative. Current flake checks are repository checks and do not authorize publication or qualification. |
| 25. Signed x86 offline kits | **NOT VERIFIED** | No production kit was built, signed, cold-imported, written to media, booted, or tied to a physical host. Upstream-only package policy remains in force. |
| 26. Physical capability qualification | **NOT VERIFIED** | No physical host qualification evidence exists for NixOS x86, ARM evaluation hardware, standalone installs, or Apple Silicon Darwin. |
| F1. Repository final | **PARTIAL** | The focused readiness, dendritic, package-policy, Cachix, and all-systems no-build checks above ran, but the former universal final runner/claim graph does not exist and is not required by this reconciliation. |
| F2. Runtime final | **NOT VERIFIED** | No live switch, restart, login session, reboot, install, rollback, portal/capture session, or offline cold start was performed. |
| F3. Security/release final | **SUPERSEDED** | The former exhaustive custom scanner/container/signing protocol is not the current release architecture. Current-tree credential cleanup remains Task 1 **PARTIAL**; provider rotation/history review remains **NOT VERIFIED**. |
| F4. Qualification final | **NOT VERIFIED** | There are no valid physical/provider/native-Darwin/media records from which to qualify any host or class. The aggregate must remain open. |

## Explicitly superseded requirements

The following must not be treated as backlog or reintroduced merely to make the old checklist green:

- repository overlay exports and custom standalone production package recipes for the retired package classes, including the former AI sidecars and production theme packages (this does not prohibit app/check wrapper derivations or fixed-output upstream source fetches);
- managed Claude/Codex/OMX baselines and AI release-pin, freshness, updater, or publication machinery;
- `x86_64-darwin` evaluation, release, or qualification;
- fixture-to-production promotion, synthetic-to-physical inference, or VM-to-host qualification;
- the former universal signed evidence graph, offline-kit graph, and scanner/container protocol as prerequisites for repository readiness.

## Open external gates

These gates intentionally remain open:

1. **Credential/provider:** the obsolete v4 file is absent and the current-tree secret-policy test passes; provider rotation and provider history/activity review remain external and **NOT VERIFIED**.
2. **NixOS physical — NOT VERIFIED:** per-host storage enrollment, install, boot, network, device behavior, reboot, recovery, and rollback require attended physical evidence.
3. **Media — NOT VERIFIED:** no installation image/kit was built, signed, cold-tested, written, or booted.
4. **Standalone runtime — NOT VERIFIED:** the evaluated Home Manager configurations still require an actual activation and application/session checks on each native architecture.
5. **Darwin native — NOT VERIFIED:** aarch64-darwin requires native build, activation, relogin, rollback/restoration, TCC, app ownership, and runtime checks.
6. **Noctalia runtime — NOT VERIFIED:** after an authorized live switch, verify the sole `noctalia.service`, session integration, launcher child services, lock/notification/wallpaper behavior, and logs. None of this was performed during reconciliation.
7. **Cachix daemon activation/rollback:** repository stubs prove fail-closed control flow only. A real `nix-daemon.service` restart, active-state/effective-config confirmation, daemon reachability check, and restoration from an activation failure remain **NOT VERIFIED**; failed activation can leave the trusted configuration edited and requires explicit operator recovery.

Repository checks may continue to improve independently, but the stop condition for claiming a production-ready machine is native, host-specific evidence for the applicable gates above. Until then, the truthful aggregate is **repository integration present; machine qualification NOT VERIFIED**.
