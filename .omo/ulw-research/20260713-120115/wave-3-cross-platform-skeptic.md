# Wave 3 — adversarial cross-platform / standalone / Darwin review

Research date: 2026-07-13  
Repository revision: `e9f78180748f1feb428ffb20f9d932c5d9918a48`  
Mode: read-only counter-audit; no production files changed; no credentials inspected or reproduced.

## Executive verdict

The cross-platform design is **one repository with six separately provable configurations**, not one universally portable closure. All six outputs evaluate far enough to produce a top-level store path, but only the x86_64 NixOS closure has previously been realized on this research machine. Evaluation is not native build, activation, login, app/font registration, or physical hardware proof.

The strongest positive finding is narrower than “theming everywhere”: the exact Kitty program settings and the configured FiraCode Nerd Font package are present in **all six Home Manager configurations**, including both Darwin configurations. Exact Home Manager source also copies fonts from `home.packages` into `~/Library/Fonts/HomeManager` on Darwin rather than leaving macOS-unreadable symlinks. This makes the earlier “Kitty theme did not reach macOS” concern substantially unsupported. A physical Mac activation plus Kitty/CoreText lookup is still the final runtime proof.

The strongest disconfirming finding is that global package-policy bypasses are already masking two concrete cross-system incompatibilities:

- `aarch64-linux` NixOS includes x86-only `google-chrome-150.0.7871.46` even though `lib.meta.availableOn` is false.
- `x86_64-darwin` includes `iverilog-13.0`, whose exact pin marks that platform in `meta.badPlatforms`; it occurs in both the system and Home Manager package lists.

`allowUnsupportedSystem = true` makes those selections evaluable; it does not make the binaries usable or supported. `allowBroken = true` weakens the guard too, although the audited lists currently contain no package with `meta.broken = true`.

The standalone README is also objectively wrong today: the output does not default to an arbitrary current `USER`/`HOME`. Pure evaluation ignores the ambient variables and remains `mei`/`/home/mei`; the provided `home-switch` deliberately evaluates impurely, and an alternate user/home then conflicts with Den's fixed identity.

Finally, the current rolling Intel-Darwin output is not a supportable claim. It evaluates against Nixpkgs `26.11.20260705.d407951` with a deprecation warning, while Nixpkgs' official 26.05 release notes say 26.05 is the last supported `x86_64-darwin` release and 26.11 will neither build binaries nor support source builds. This output must be frozen on a dedicated 26.05-compatible input with a retirement date, or removed from the support matrix.

## Exact root inputs and output inventory

The root mappings in `flake.lock` (not similarly named transitive nodes) resolve to:

| Input | Exact root revision |
|---|---|
| Nixpkgs | `d407951447dcd00442e97087bf374aad70c04cea` |
| Home Manager | `a1645f40777620c4bd2b6d854b290c2fc354a266` |
| nix-darwin | `a1fa429e945becaf60468600daf649be4ba0350c` |
| Den | `1614f6f8ed435c5bb257408bf91fd662f9aac43e` |

The four declared systems produce six user-facing configurations:

| System | Configuration | Evaluated top-level path | Native status |
|---|---|---|---|
| `x86_64-linux` | `nixosConfigurations.x86_64-linux` | `/nix/store/2skzh1yk3bzz5g30zxf6ngcai78m3vci-nixos-system-nixos-26.11.20260705.d407951` | Previously realized on this x86 host; not a proof for arbitrary x86 hardware. |
| `aarch64-linux` | `nixosConfigurations.aarch64-linux` | `/nix/store/1vfrlw263xl9mfqcay2al1pj7c5cbmll-nixos-system-nixos-aarch64-26.11.20260705.d407951` | Evaluated only; contains unsupported Google Chrome and a PC-style boot/storage assumption; no board boot proof. |
| `aarch64-darwin` | `darwinConfigurations.aarch64-darwin` | `/nix/store/lf0n3hhss1w6k5vz4nilgpi9z0bgdnks-darwin-system-26.11.a1fa429` | Evaluated only; requires matching native build and activation on an existing `mei` Mac account. |
| `x86_64-darwin` | `darwinConfigurations.x86_64-darwin` | `/nix/store/v8pazliybqjihjhll595s0xi146blp0y-darwin-system-26.11.a1fa429` | Evaluated under an officially unsupported 26.11-era pin; contains a bad-platform package; not support-ready. |
| `x86_64-linux` | `homeConfigurations.standalone-linux` | `/nix/store/d9kfhvbx41x9n1r78j5sls3319b7lsmm-home-manager-generation` | Evaluated only; fixed `mei` identity; activation on a compatible existing Linux user/distro is required. |
| `aarch64-linux` | `homeConfigurations.standalone-linux-aarch64` | `/nix/store/23rmdki82sqm6g5i09kxxdjcjbffcdlg-home-manager-generation` | Evaluated only; fixed `mei` identity; native build/activation required. |

Both standalone evaluations also emit the existing upstream/pin warning that an `options.json` derivation references the Nixpkgs store path without proper string context and “may stop working in the future.” This is not a target-specific failure, but it is unresolved evaluation debt and should not be silently accepted in a zero-warning readiness claim.

## Adversarial claim adjudication

### A. Standalone identity conflict — **UPHELD (high confidence)**

Current ownership is split:

- `modules/entities/hosts.nix` declares both homes with `userName = "mei"`.
- `den.aspects.standalone-linux` includes `den.aspects.mei`, which includes Den's `define-user` battery.
- `modules/standalone-linux/home-manager.nix` separately derives `user` and `homeDirectory` from `NIXOS_CONFIG_*`, then ambient `USER`/`HOME`, then `mei`.
- `README.md` says the default is the current `USER` and `HOME` and advertises an override.
- `modules/flake/apps.nix` runs Home Manager with `--impure`, so ambient variables are visible in the normal wrapper.

Executed counterexample:

```text
pure default                                     => mei / /home/mei
pure with NIXOS_CONFIG_USER=alice, HOME=/home/alice => mei / /home/mei
impure with those alternate values               => evaluation error
```

The impure error is exact and names the two owners:

```text
homeManager@den/batteries/define-user/home: "/home/mei"
homeManager@standalone-linux: "/home/alice"
```

Home Manager activation then performs runtime sanity checks that `$USER` and `$HOME` equal configured `home.username` and `home.homeDirectory`. Therefore even a hand-built activation cannot truthfully be called generic unless identity is made one explicit input and tested with at least two non-`mei` identities.

Counterexample that narrows the claim: the configuration is coherent for the existing identity `mei`/`/home/mei`; editing the Den home entity can adapt it. The defect is not “Home Manager can never support another user,” but “the current advertised environment override and current-user default do not work.”

### B. Pure-vs-impure file targets — **PARTLY REFUTED / NARROWED (high confidence)**

`modules/nixos/files.nix` uses `builtins.getEnv "HOME"`. In pure evaluation this is empty, so keys and evaluated targets such as `/.config/niri/config.kdl` appear. That is noncanonical and makes evaluation output misleading.

However, exact Home Manager semantics prevent the feared root write in the current activation implementation:

- `file-type.nix` allows absolute or relative targets and strips the configured home prefix when present.
- `files.nix` builds the home-files tree and links each `relativePath` using `targetPath="$HOME/$relativePath"`.
- Thus a target beginning `/.config/...` becomes `$HOME//.config/...`, which resolves under the user's home.
- Absolute keys beginning `/home/mei/...` are normalized by the option's `apply` function to `.config/...`, `.cache/...`, and so on.

So the claim “pure evaluation sends NixOS dotfiles to filesystem root” is refuted for this exact Home Manager pin. The retained finding is architectural: configuration must not depend on ambient evaluation state; the unusual `/.config` targets are fragile, confusing, and unnecessary. Use `config.xdg.configHome`, relative `home.file` targets, or one explicit `homeDirectory` value.

### C. Duplicate Darwin GUI-app ownership — **UPHELD, impact narrowed (high confidence)**

Exact evaluation of `aarch64-darwin` shows:

- 121 `environment.systemPackages` names.
- 123 Home Manager package names.
- 111 name-level overlaps.
- The same `modules/darwin/packages.nix` list is explicitly installed at both levels.
- `targets.darwin.linkApps.enable = true` because `home.stateVersion = "23.11"` and the exact Home Manager default enables linkApps before 25.11.

The owners create distinct destinations:

- nix-darwin builds `system-applications` and rsyncs app bundles to `/Applications/Nix Apps`.
- Home Manager builds `home-manager-applications` and links it at `~/Applications/Home Manager Apps`.

Common GUI bundles include Kitty, Ghostty, iTerm2, Helium, Obsidian, OmniWM, Postman, Raycast, Stremio, Sublime Text, and Vesktop. This is genuine double presentation/ownership and can create duplicate Finder/Spotlight/LaunchServices candidates.

Narrowing: Nix does deduplicate common store dependencies, and duplicate package membership is not necessarily two independent downloads. The operational defect is two visible application projections and two lifecycle owners, not necessarily twice the whole closure size. Choose one app-bundle owner explicitly; retain HM for dotfiles/user CLI if nix-darwin owns `/Applications/Nix Apps`.

### D. FiraCode / Kitty on macOS — **EARLIER CONCERN DOWNGRADED (high confidence for declaration; runtime unverified)**

Executed evaluation across all six configurations returned the same Kitty contract:

```text
programs.kitty.enable = true
font_family = "FiraCode Nerd Font Mono"
background = "#161925"
foreground = "#c3c7d1"
home.packages contains nerd-fonts-fira-code-3.4.0+6.2
```

This directly proves the shared Kitty palette reaches both NixOS hosts, both standalone homes, Apple Silicon Darwin, and Intel Darwin at evaluation time.

The exact Home Manager Darwin font module builds a font environment from all `home.packages`, then uses `rsync -acL --delete` into `~/Library/Fonts/HomeManager`; its source comment explicitly notes that macOS does not recognize symlinked fonts. Consequently, absence from nix-darwin's `fonts.packages` is **not** evidence that the Kitty font is unprovisioned. It is provisioned at user scope by Home Manager after successful activation.

What remains unverified is native behavior, not declaration: activate on a physical Mac, confirm the files exist in `~/Library/Fonts/HomeManager`, inspect Kitty's resolved family (`kitty +list-fonts` / Kitty debug output), and verify glyph fallback and opacity in a real Aqua session. There is no supported way for Linux evaluation alone to prove CoreText registration or visual rendering.

Scope boundary: GTK/Kvantum/Niri theming is Linux-specific and should not be projected onto macOS. Cross-platform theme readiness should mean shared app-level semantic colors/fonts for Kitty (and separately selected apps), not macOS desktop equivalence.

### E. Intel-Darwin lifecycle — **UPHELD AND STRENGTHENED (very high confidence)**

The root pin reports itself as `26.11.20260705.d407951`. Its Intel-Darwin output evaluates with a warning, but official Nixpkgs release notes state:

- 26.05 is the final Nixpkgs release supporting `x86_64-darwin`.
- Binaries/support continue only until 26.05 reaches end of support at end-2026.
- For 26.11, Nixpkgs will no longer build packages for the platform or support building them from source.

The current output is therefore already on the wrong rolling branch for an honest supported Intel-Mac claim. `allowUnsupportedSystem` cannot restore Hydra binaries, upstream maintenance, removed definitions, or compatible dependencies. Its evaluation path is at best a temporary accidental capability.

Required truth: either use a separate root input pinned to 26.05 for Intel Darwin, run native Intel builds/activations, and publish a retirement/migration date no later than end-2026; or remove `x86_64-darwin` from supported outputs now.

### F. Global `allowBroken` / `allowUnsupportedSystem` — **UPHELD WITH EXECUTED COUNTEREXAMPLES (very high confidence)**

`lib/nixpkgs.nix` enables both flags globally for every OS configuration and for standalone `mkPkgs` imports. An exact scan of the combined system and HM package lists found:

| Configuration | `meta.broken=true` selections | `lib.meta.availableOn=false` selections |
|---|---:|---|
| NixOS x86_64 Linux | none | none |
| NixOS aarch64 Linux | none | `google-chrome-150.0.7871.46` |
| Darwin aarch64 | none | none |
| Darwin x86_64 | none | `iverilog-13.0` twice (system + HM) |
| Standalone x86_64 Linux | none | none |
| Standalone aarch64 Linux | none | none |

At the exact pin, Google Chrome declares Darwin plus `x86_64-linux`, not `aarch64-linux`. It is a prebuilt native binary, so bypassing the platform guard cannot create an ARM browser. Icarus Verilog lists `x86_64-darwin` in `badPlatforms` because several install tests fail there. These are concrete false-green package selections, not theoretical policy objections.

`allowBroken=true` has not been shown to mask a currently selected broken package, so that narrower claim is downgraded: it is a dangerous latent bypass rather than a demonstrated current failure. Production and CI should set both defaults false; any exception must name the package, output/host, rationale, upstream issue, owner, and expiry.

### G. GPU/backend labeling — **CORE CONCLUSION UPHELD; DARWIN LABELS NARROWED (high confidence)**

The root-pin AI execution report correctly replaces the earlier transitive-pin numbers. Exact local source establishes:

- Both Linux configurations install bare `pkgs.ollama`.
- Neither global CUDA nor ROCm support is enabled, so bare Ollama selects its CPU/default path on Linux.
- `ollama-{cpu,cuda,rocm,vulkan}` exist, but CUDA/ROCm/Vulkan enablement is explicitly gated by `hostPlatform.isLinux`.
- Therefore on Darwin, the `ollama-cuda`, `ollama-rocm`, and `ollama-vulkan` attributes can evaluate to the **same output** as ordinary Ollama. Their attribute names must not be reported as an active Darwin backend.
- Exact evaluated output equality confirms this for both Darwin architectures.
- Ordinary `llama-cpp` defaults Metal on `aarch64-darwin` only; `x86_64-darwin` defaults to CPU/BLAS because `metalSupport` requires both Darwin and AArch64.
- Linux Vulkan remains the broadest packaged cross-vendor option, but it still requires a working host driver/ICD and render-device permission. It is not a universal GPU guarantee.

The truthful design remains “shared AI intent, host-selected realization.” Backend selection belongs in inventoried host facts and must be proven at runtime with device visibility and a model smoke test. Never infer an active backend from an attribute suffix alone, particularly on Darwin.

### H. Editor/config portability — **PACKAGE PRESENCE UPHELD; CONFIG PARITY REFUTED (high confidence)**

`zed-editor` is in the shared package list and currently passes the package-availability scan on the four evaluated platforms. But the only managed Zed settings file is declared by `modules/standalone-linux/files.nix`. Exact home-file evaluation shows:

- standalone x86_64/aarch64 homes: `.config/zed/settings.json` is managed;
- integrated NixOS homes: no Zed settings target;
- Darwin homes: no Zed settings target.

There is no current VS Code/Home Manager editor module configuration. Thus a shared editor package must not be described as shared editor settings, theming, extensions, or native plugin readiness. The Wave 1C recommendation to use Home Manager's editor modules is a design recommendation, not current implementation evidence. Native VSIX architecture/licensing and mutable state still require host/application-specific policy.

## Truthful readiness definitions

### System-level definitions

| System | Honest readiness threshold | Current verdict |
|---|---|---|
| `x86_64-linux` | Native closure build; per-host Facter/hardware leaf; Disko VM plus sacrificial install; physical boot, firmware, wired/Wi-Fi, GPU, audio, suspend, Niri/session/portal; rollback drill. | **Evaluation/build baseline only; machine readiness not generalized.** |
| `aarch64-linux` | Native ARM build; board-specific boot chain/DT/firmware/storage module; supported ARM browser/package set; physical board boot/network/session; recovery path. | **Not ready.** Generic PC UEFI assumptions and unsupported Google Chrome disprove universality. |
| `aarch64-darwin` | Matching native build; existing `mei` account/home validation; graphical/TCC activation; app projection, Dock, shell, fonts, Kitty/theme and rollback checks. | **Conditionally evaluation-ready; native activation required.** |
| `x86_64-darwin` | Separate 26.05-compatible pin; native Intel build/activation; no bad-platform packages; migration deadline; same Aqua/font/app/rollback checks. | **Unsupported as currently pinned; do not advertise.** |

### Configuration-level definitions

| Configuration | What “ready” may truthfully mean now | Mandatory native evidence still missing |
|---|---|---|
| `nixosConfigurations.x86_64-linux` | Exact evaluated closure exists and one x86 closure was realized. | A target-specific hardware leaf and full install/boot/device/session/rollback evidence for each supported host class. |
| `nixosConfigurations.aarch64-linux` | Expression evaluation only. | Remove unsupported Chrome; introduce real board profiles; native build, boot, firmware/network/GPU/session and recovery proof. |
| `darwinConfigurations.aarch64-darwin` | Coherent for an already-existing `mei` at `/Users/mei`; Kitty/Fira declarations are present. | Native system build; Aqua/TCC activation; dscl shell reconciliation; app/font registration; Dock and rollback proof. |
| `darwinConfigurations.x86_64-darwin` | Temporary expression evaluation under policy bypasses. | First move to supported 26.05 input or retire; then native build/activation and replace bad-platform Icarus Verilog. |
| `homeConfigurations.standalone-linux` | Coherent only for existing `mei` at `/home/mei`; package metadata scan is clean. | Fix identity contract; activate on representative non-NixOS x86 distribution; file-collision, desktop integration, GPU/service and rollback checks. |
| `homeConfigurations.standalone-linux-aarch64` | Coherent only for existing `mei` at `/home/mei`; package metadata scan is clean. | Same identity fix plus native ARM build/activation on a representative distribution; no emulation-only PASS. |

A configuration is not “ready” merely because `nix eval`, `nix flake show`, or `nix flake check --no-build` succeeds. For Darwin, success also requires the account already exists, the actual `HOME` matches, activation runs in a context allowed to manage `/Applications`, and Home Manager finishes its font/app file phases. For standalone Linux, Home Manager cannot supply kernel firmware, hardware drivers, NetworkManager, login manager, polkit, portal, or system service guarantees that belong to the host distribution.

## Priority corrections from this skeptic pass

### P0 — support truth and false-green removal

1. Set `allowUnsupportedSystem = false` and `allowBroken = false` by default; make exceptions scoped and expiring.
2. Remove/replace Google Chrome from the AArch64 NixOS output; a native ARM browser must be selected by host/system.
3. Remove/replace Icarus Verilog for Intel Darwin or scope it away from that platform.
4. Freeze Intel Darwin to a dedicated 26.05-compatible graph with a 2026 retirement plan, or delete the support claim/output.
5. Replace the standalone identity split with one entity-owned identity input; test two usernames/homes in pure evaluation and activation dry-runs. Correct the README.

### P1 — lifecycle and ownership

6. Select exactly one Darwin app-bundle projection owner; if nix-darwin owns GUI apps, explicitly disable HM `targets.darwin.linkApps`.
7. Add native build jobs for each system still claimed, then physical activation/rollback evidence for both Darwin architectures actually supported.
8. Keep the current shared Kitty declaration; add an assertion across all six configurations for the palette, font family, font package, and Darwin user-font target.
9. Replace ambient `builtins.getEnv HOME` path construction with configuration-derived XDG/home values even though exact HM currently normalizes it safely.

### P2 — editor and accelerator honesty

10. Decide whether Zed settings are intended to be shared. If yes, use the platform-aware HM module and test mutable/declarative ownership; otherwise label them standalone-only.
11. Do not claim VS Code portability until a module, extension source policy, native VSIX matrix, and mutable-state boundary exist.
12. Model Ollama/llama.cpp backend selection as a host capability, record the actual runtime backend, and retain a CPU fallback. Treat Darwin accelerator-suffixed aliases as labels with no force unless exact output/backend evidence says otherwise.

## Reproduction commands and evidence boundary

Representative executed probes:

```bash
# Exact root mappings
jq '.nodes.root.inputs' flake.lock

# Six output paths
nix eval --raw .#nixosConfigurations.x86_64-linux.config.system.build.toplevel
nix eval --raw .#nixosConfigurations.aarch64-linux.config.system.build.toplevel
nix eval --raw .#darwinConfigurations.aarch64-darwin.system
nix eval --raw .#darwinConfigurations.x86_64-darwin.system
nix eval --raw .#homeConfigurations.standalone-linux.activationPackage
nix eval --raw .#homeConfigurations.standalone-linux-aarch64.activationPackage

# Identity disconfirmation
NIXOS_CONFIG_USER=alice NIXOS_CONFIG_HOME=/home/alice \
  nix eval --impure --raw .#homeConfigurations.standalone-linux.config.home.username

# Package metadata, using each output's exact pkgs
# lib.meta.availableOn hostPlatform package and package.meta.broken were evaluated
# over combined system/HM package lists.

# Kitty/Fira contract
# programs.kitty settings and Fira-named home.packages were evaluated for all six HM configs.
```

This pass proves expression values and exact upstream source semantics. It does **not** claim any foreign system was built on this Linux host, any Darwin activation ran, any Mac font/app database changed, any ARM board booted, or any GPU backend executed.

## Primary evidence

Local exact sources:

- `modules/entities/hosts.nix`
- `modules/aspects/hosts/{nixos-workstation,darwin-workstation,standalone-linux}.nix`
- `modules/aspects/users/mei.nix`
- `modules/standalone-linux/home-manager.nix`
- `modules/flake/apps.nix`
- `modules/darwin/{base,packages,user-home,system}.nix`
- `modules/shared/{home-manager,packages}.nix`
- `modules/nixos/packages.nix`
- `lib/nixpkgs.nix`
- root-pinned Home Manager `modules/{home-environment,files}.nix`, `modules/lib/file-type.nix`, `modules/targets/darwin/{fonts,linkapps}.nix`
- root-pinned nix-darwin `modules/system/applications.nix`, `modules/users/{default,user}.nix`
- root-pinned Nixpkgs `pkgs/by-name/{go/google-chrome,iv/iverilog,ll/llama-cpp,ol/ollama}/package.nix`

Authoritative upstream URLs:

- Home Manager Darwin fonts at the exact root pin: https://github.com/nix-community/home-manager/blob/a1645f40777620c4bd2b6d854b290c2fc354a266/modules/targets/darwin/fonts.nix
- Home Manager Darwin app links at the exact root pin: https://github.com/nix-community/home-manager/blob/a1645f40777620c4bd2b6d854b290c2fc354a266/modules/targets/darwin/linkapps.nix
- Home Manager activation identity checks at the exact root pin: https://github.com/nix-community/home-manager/blob/a1645f40777620c4bd2b6d854b290c2fc354a266/modules/home-environment.nix
- nix-darwin system application projection at the exact root pin: https://github.com/nix-darwin/nix-darwin/blob/a1fa429e945becaf60468600daf649be4ba0350c/modules/system/applications.nix
- nix-darwin user ownership at the exact root pin: https://github.com/nix-darwin/nix-darwin/blob/a1fa429e945becaf60468600daf649be4ba0350c/modules/users/default.nix
- Nixpkgs 26.05 Intel-Darwin lifecycle: https://nixos.org/manual/nixpkgs/unstable/release-notes#x86_64-darwin-26.05
- NixOS 26.05 announcement: https://nixos.org/blog/announcements/2026/nixos-2605/
- Nixpkgs package configuration: https://nixos.org/manual/nixpkgs/unstable/#chap-packageconfig

## EXPAND

- LEAD: physical Apple Silicon activation and Kitty/CoreText inspection — WHY: declaration and copy semantics are strong, but native font registration/rendering remains unobserved — ANGLE: build/switch in Aqua, inspect `~/Library/Fonts/HomeManager`, `kitty +list-fonts`, screenshots, rollback.
- LEAD: single-owner Darwin app migration — WHY: duplicate destinations are proven, but LaunchServices duplicate presentation needs native before/after measurement — ANGLE: `lsregister`, Spotlight/Finder inventory, set `targets.darwin.linkApps.enable = false`, rebuild, compare.
- LEAD: generic identity mutation test — WHY: current override fails — ANGLE: refactor one identity source, evaluate/activate dry-run for `alice:/home/alice` and `mei:/home/mei` on both Linux architectures.
- LEAD: native ARM package/build proof — WHY: exact metadata already disproves current Google Chrome selection — ANGLE: remove it, native ARM closure build, board-specific boot test.
- LEAD: Intel Darwin disposition — WHY: current 26.11 graph is officially unsupported — ANGLE: either dedicated 26.05 lock/native canary with end date or output deletion.

## CLAIMS

- CLAIM: All six configurations evaluate to a top-level store path, but only the x86_64 NixOS closure has prior local realization evidence; native activation remains unverified for both Darwin and both standalone outputs. — VERDICT: UPHELD — RISK: high — EVIDENCE: executed exact `nix eval --raw` output-path probes; Wave 2 CI lifecycle report — COUNTER: no matching native builders/physical targets were available.
- CLAIM: The standalone output's advertised current-user/current-home override is broken because Den fixes `mei` while impure module evaluation selects the ambient/override identity. — VERDICT: UPHELD — RISK: high — EVIDENCE: exact pure/impure mutation probes and conflict error — COUNTER: editing the Den entity can support another fixed user, so the limitation is current design/advertising rather than Home Manager itself.
- CLAIM: Pure `builtins.getEnv HOME` evaluation writes NixOS Home Manager files to `/`. — VERDICT: REFUTED for the exact pin — RISK: normal — EVIDENCE: exact Home Manager file-type and link-generation source plus evaluated targets — COUNTER: `targetPath="$HOME/$relativePath"` keeps `/.config` targets under HOME, though the configuration remains noncanonical and fragile.
- CLAIM: Darwin GUI applications have two active projection owners. — VERDICT: UPHELD — RISK: normal — EVIDENCE: 111 evaluated package-name overlaps, HM linkApps enabled, distinct system/HM application build paths and destinations — COUNTER: Nix store dependencies are deduplicated; the defect is duplicate visible ownership, not necessarily double closure download.
- CLAIM: Kitty theming and FiraCode declaration apply to every declared Home Manager configuration, macOS included. — VERDICT: UPHELD at evaluation/activation-design level — RISK: normal — EVIDENCE: six-config exact evaluation and root-pinned HM Darwin font-copy module — COUNTER: physical CoreText/Kitty rendering is still not verified.
- CLAIM: The current rolling `x86_64-darwin` output is a supported target. — VERDICT: REFUTED — RISK: high — EVIDENCE: root pin is 26.11-era; official Nixpkgs lifecycle says 26.05 is last supported and 26.11 drops builds/source support — COUNTER: expression evaluation still succeeds today, but that is accidental capability rather than support.
- CLAIM: Global unsupported/broken flags create only hypothetical risk. — VERDICT: REFUTED for unsupported; narrowed for broken — RISK: high — EVIDENCE: exact `availableOn=false` Google Chrome on ARM Linux and Icarus Verilog on Intel Darwin; no current `meta.broken=true` selection — COUNTER: allowBroken remains latent rather than presently exercised.
- CLAIM: Accelerator-suffixed Ollama attributes identify the active backend on every system. — VERDICT: REFUTED on Darwin — RISK: high — EVIDENCE: exact root source gates CUDA/ROCm/Vulkan to Linux and exact Darwin variant outputs are identical — COUNTER: host-selected Linux variants remain meaningful when drivers/devices are proven.
- CLAIM: Shared editor package presence implies shared editor configuration. — VERDICT: REFUTED — RISK: normal — EVIDENCE: Zed package is shared, but exact Zed settings target exists only in standalone Home Manager outputs; no VS Code module exists — COUNTER: package availability itself is currently clean on the audited systems.
