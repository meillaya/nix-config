# Editor packaging and local-AI/GPU portability research

Date: 2026-07-13  
Repository pin examined: `NixOS/nixpkgs@59e69648d345d6e8fef86158c555730fa12af9de`  
Home Manager pin examined: `nix-community/home-manager@abfad3d2958c9e6300a883bd443512c55dfeb1be`

## Executive result

The portable design is **shared intent, host-selected realization**:

- Share editor settings, universal extension names, language-server packages, local API endpoint conventions, and non-secret AI configuration.
- Select editor package availability, native VSIX variants, Ollama/llama.cpp accelerator, device visibility, ROCm GFX target/override, CUDA architectures, drivers, service scope, models, and cache/build policy per host.
- Do not globally turn on `nixpkgs.config.cudaSupport` or `rocmSupport` merely to accelerate Ollama. The exact pin has explicit `ollama-{cpu,cuda,rocm,vulkan}` variants, while `llama-cpp` is directly overridable (`cudaSupport`, `rocmSupport`, `vulkanSupport`, `metalSupport`).
- On Apple Silicon, use the ordinary Darwin packages: pinned `llama-cpp` enables Metal by default and Ollama supports Metal. CUDA/ROCm variants are Linux concerns.
- For heterogeneous Linux machines, Vulkan is the broadest single GPU fallback and is comparatively small/cache-friendly; CUDA and ROCm are host-bound and much larger. Native backends may still win on supported hardware.
- Home Manager’s current editor modules solve configuration ownership more correctly than raw `home.file` links: VS Code has profiles/mutable extension semantics; Zed has explicit mutable settings/keymap/task/debug merging. The repo currently manages Zed’s settings as a store symlink only on standalone Linux.

No production files were changed. This report is the requested research artifact.

## Search/retrieval coverage and limitation

I ran 15 distinct GitHub code searches after opening the supplied search and guide, including:

1. `filename:vscode.nix`
2. `programs.vscode.profiles language:Nix`
3. `programs.vscode.extensions language:Nix`
4. `vscode-with-extensions language:Nix`
5. `buildVscodeMarketplaceExtension language:Nix`
6. `vscode-utils.extensionsFromVscodeMarketplace language:Nix`
7. `mutableExtensionsDir language:Nix`
8. `ollama-cuda language:Nix`
9. `ollama-rocm language:Nix`
10. `ollama-vulkan language:Nix`
11. `llama-cpp-vulkan language:Nix`
12. `llama-cpp-rocm language:Nix`
13. `cudaSupport ollama language:Nix`
14. `rocmOverrideGfx language:Nix`
15. `GGML_CPU_ALL_VARIANTS language:Nix`

The code-search API reported substantial pattern populations (for example, 624 hits for `programs.vscode.profiles`, 1,106 for `buildVscodeMarketplaceExtension`, 820 for `ollama-cuda`, 778 for `ollama-rocm`, 302 for `ollama-vulkan`). GitHub’s dedicated authenticated code-search rate limit was then exhausted when paging the supplied result set. Consequently, this is not a claim that all ~2,000 dynamically reported `filename:vscode.nix` matches were downloaded. I countered that limitation by reviewing the top-ranked results, cloning six representative repositories at exact commits, and reading the exact pinned Nixpkgs and Home Manager implementations in full. That primary-source evidence is more authoritative than dotfile frequency.

## Source ledger

### Supplied sources

- GitHub code search, `path:vscode.nix`: <https://github.com/search?q=path%3Avscode.nix&type=code>. Dynamic result set; sampled before the code-search API rate limit was exhausted.
- SteelPh0enix, “llama.cpp guide” (published 2024-10-28, updated 2024-12-25): <https://steelph0enix.github.io/posts/llama-cpp-guide/>. Full 13,831-word page was retrieved and read, especially build/backend sections.

### Exact repository pins (primary)

- Local nixpkgs lock: `59e69648d345d6e8fef86158c555730fa12af9de`.
  - llama.cpp package: <https://github.com/NixOS/nixpkgs/blob/59e69648d345d6e8fef86158c555730fa12af9de/pkgs/by-name/ll/llama-cpp/package.nix>
  - Ollama package: <https://github.com/NixOS/nixpkgs/blob/59e69648d345d6e8fef86158c555730fa12af9de/pkgs/by-name/ol/ollama/package.nix>
  - NixOS Ollama module: <https://github.com/NixOS/nixpkgs/blob/59e69648d345d6e8fef86158c555730fa12af9de/nixos/modules/services/misc/ollama.nix>
  - VS Code extension wrapper: <https://github.com/NixOS/nixpkgs/blob/59e69648d345d6e8fef86158c555730fa12af9de/pkgs/applications/editors/vscode/with-extensions.nix>
  - VS Code extension builders: <https://github.com/NixOS/nixpkgs/blob/59e69648d345d6e8fef86158c555730fa12af9de/pkgs/applications/editors/vscode/extensions/vscode-utils.nix>
  - NixOS VS Code module: <https://github.com/NixOS/nixpkgs/blob/59e69648d345d6e8fef86158c555730fa12af9de/nixos/modules/programs/vscode.nix>
- Home Manager lock: `abfad3d2958c9e6300a883bd443512c55dfeb1be`.
  - VS Code module implementation: <https://github.com/nix-community/home-manager/blob/abfad3d2958c9e6300a883bd443512c55dfeb1be/modules/programs/vscode/mkVscodeModule.nix>
  - Zed module: <https://github.com/nix-community/home-manager/blob/abfad3d2958c9e6300a883bd443512c55dfeb1be/modules/programs/zed-editor.nix>
  - Home Manager Ollama user service: <https://github.com/nix-community/home-manager/blob/abfad3d2958c9e6300a883bd443512c55dfeb1be/modules/services/ollama.nix>
- Current llama.cpp clone: `ggml-org/llama.cpp@6eddde06a4f25d55d538b5d15628dcc2b6882147`.
  - Build guide: <https://github.com/ggml-org/llama.cpp/blob/6eddde06a4f25d55d538b5d15628dcc2b6882147/docs/build.md>
  - Backend options: <https://github.com/ggml-org/llama.cpp/blob/6eddde06a4f25d55d538b5d15628dcc2b6882147/ggml/CMakeLists.txt>
- Current Ollama clone: `ollama/ollama@82f905cd9c06c6f0254d74c5326aa2a7f2f07e1f`.
  - Hardware support: <https://github.com/ollama/ollama/blob/82f905cd9c06c6f0254d74c5326aa2a7f2f07e1f/docs/gpu.mdx>

### Representative clones from the GitHub pattern search

- `max-baz/dotfiles@4780dd3028442110fc8e4bd0eee96c0c16b61e12`: Home Manager `programs.vscode.profiles.default`, nixpkgs extensions, declarative settings.
- `the-nix-way/nome@c4a40f1a11d839ff9347cdbf2f682ddb3f102853`: nixpkgs extensions plus pinned/hash-checked marketplace extensions, immutable extension directory.
- `henrysipp/omarchy-nix@308e0f85a0deb820c01cfbe1b4faee1daab4da12`: `extensionsFromVscodeMarketplace`; comments document the practical annoyance of immutable settings when GUI edits are desired.
- `nix-community/nix-vscode-extensions@e69ba8306153ba2617a109994c66870505201c5b`: daily generated marketplace/Open VSX extension sets; explicit platform-specific vs universal sets.
- `wimpysworld/nix-config@b87fd688c07257b0fd2d200201420034c857c468`: host metadata chooses CUDA/ROCm/Vulkan/CPU and explicit llama.cpp overrides.
- `noamsto/nix-amd-ai@d230d3492dd0ceb86467ee2fce0590a2fa344240`: pinned accelerator backends, platform branches, NixOS module checks, and backend-specific service wiring.

### Empirical cache checks against the exact lock

I evaluated output paths at the exact nixpkgs pin and queried `cache.nixos.org` narinfo. A `200` means that exact output existed at query time; `404` means it did not. This is a point-in-time observation, not a permanent Hydra guarantee.

## VS Code/editor packaging observations

### Dominant patterns

1. **Home Manager module (recommended for a personal workstation)**
   - `programs.vscode.enable = true`.
   - `programs.vscode.profiles.default.{userSettings,keybindings,userTasks,userMcp,extensions}`.
   - Current pin supports named profiles, `argvSettings`, snippets, update toggles, and central MCP integration.
   - Current Home Manager now has separate `programs.vscodium`, `programs.cursor`, `programs.windsurf`, `programs.kiro`, and `programs.antigravity`; using a fork as `programs.vscode.package` is now warned against because each fork has different config/data paths.

2. **NixOS system module (appropriate for system-wide editor/package/policy)**
   - `programs.vscode.extensions` produces `vscode-with-extensions` and can set `/etc/vscode/policy.json` and `EDITOR`.
   - It is less suited than Home Manager to per-user settings and profile ownership.

3. **Direct `vscode-with-extensions.override` (appropriate for a project app/dev shell)**
   - Wraps the editor with a generated immutable extension store and `--extensions-dir`.
   - Useful for project reproducibility, but less ergonomic for a daily GUI editor if users expect extension self-updates.

4. **Extension sources**
   - Prefer `pkgs.vscode-extensions.<publisher>.<name>` where present: reviewed and cached with nixpkgs.
   - For absent/outdated extensions, use `vscode-utils.buildVscodeMarketplaceExtension` or `extensionsFromVscodeMarketplace` with exact publisher/name/version/hash.
   - A pinned `nix-community/nix-vscode-extensions` input is reasonable for a large/current extension catalog. Its `vscode-marketplace` set deliberately selects the current platform-specific build before universal builds; `vscode-marketplace-universal` is useful for a truly shared extension list.

### Configuration ownership

- With only the default profile, Home Manager defaults `mutableExtensionsDir = true`: declarative extensions are linked alongside manually managed ones, and an immutable marker forces Code to regenerate its extension registry when the declarative set changes.
- With named profiles, Home Manager defaults the extension directory immutable and generates profile-specific `extensions.json`.
- VS Code `settings.json`, tasks, MCP config, keybindings, and snippets are Home Manager links. Choose declarative ownership intentionally; do not simultaneously expect Code to persist GUI edits to those paths.
- Runtime/global storage is correctly left writable. Home Manager modifies only profile registration inside `globalStorage/storage.json`; making all VS Code state declarative would be brittle and overwrite recents/session data.
- For Zed, the pinned Home Manager module is even more explicit: `mutableUserSettings`, `mutableUserKeymaps`, `mutableUserTasks`, and `mutableUserDebug` default true and merge declarative values into writable JSON/JSON5 during activation. Setting these false creates immutable config links.

### Extension portability details

- Some VSIX files are universal JavaScript; others contain native binaries and have separate `linux-x64`, `linux-arm64`, `darwin-x64`, and `darwin-arm64` artifacts. Treat native extension selection as system-specific.
- `nix-vscode-extensions` maps these four systems explicitly and also exposes universal-only sets.
- An extension’s marketplace availability does not imply VSCodium/Open VSX availability or compatible licensing.
- Language servers already installed by this repo (`nixd`, `nil`, `gopls`, `rust-analyzer`, `basedpyright`, etc.) should remain ordinary shared packages. Editor extension settings can point to `lib.getExe` store paths where a plugin otherwise downloads its own server.
- Nixpkgs’ VS Code FHS wrapper exists because many mutable third-party extensions download prebuilt FHS binaries. It improves compatibility but weakens pure/declarative extension closure control; prefer packaged extensions first.

## Local AI packaging observations

### Exact pinned nixpkgs behavior

#### llama.cpp

The pin packages llama.cpp build `b9842` and exposes backend parameters:

- CPU baseline: `cudaSupport = false`, `rocmSupport = false`, `vulkanSupport = false`; BLAS becomes the default when no accelerator backend is selected.
- Apple Silicon: `metalSupport` defaults true on `aarch64-darwin`; Accelerate/Metal are native choices.
- NVIDIA: `cudaSupport = true`, with explicit `CMAKE_CUDA_ARCHITECTURES` derived from the selected CUDA package set.
- AMD ROCm: `rocmSupport = true`, with explicit HIP compiler and `CMAKE_HIP_ARCHITECTURES` from `rocmGpuTargets`.
- Generic GPU: `vulkanSupport = true`.
- CPU portability: nixpkgs deliberately sets `GGML_NATIVE=false` and enables `GGML_CPU_ALL_VARIANTS` plus dynamic backend loading. This avoids illegal instructions on older CPUs while retaining fast variants at runtime. This is superior to a shared `-march=native` build.
- `LLAMA_BUILD_EXAMPLES=false` and `LLAMA_BUILD_SERVER=true` coexist in the package, proving the 2024 guide’s coupling claim is no longer current.

#### Ollama

The exact pin packages Ollama `0.31.1` with explicit attributes:

- `ollama` — uses global nixpkgs CUDA/ROCm policy only when exactly one is enabled; otherwise CPU.
- `ollama-cpu` — forces CPU.
- `ollama-cuda` — Linux CUDA runner.
- `ollama-rocm` — Linux ROCm runner.
- `ollama-vulkan` — Linux Vulkan runner and `OLLAMA_VULKAN=1`.

The NixOS module has removed its old `services.ollama.acceleration` option. Current NixOS configuration should set `services.ollama.package = pkgs.ollama-{cpu,cuda,rocm,vulkan}`. The module owns a hardened system service, writable model directory, model loading/synchronization, device policy, `render` supplementary group, and optional `HSA_OVERRIDE_GFX_VERSION`.

The exact Home Manager pin is behind that API evolution: its user-service module still has `acceleration = null|false|cuda|rocm` and lacks Vulkan in the enum. Setting `services.ollama.package = pkgs.ollama-vulkan` with `acceleration = null` is the viable Vulkan route there; for NixOS prefer the NixOS service.

### Cache and closure implications (exact pin, x86_64-linux)

| Package | cache.nixos.org | Closure size |
|---|---:|---:|
| `ollama` / `ollama-cpu` | present | 148.8 MiB |
| `ollama-cuda` | absent at query time | not measurable from public cache |
| `ollama-rocm` | present | 4.1 GiB |
| `ollama-vulkan` | present | 196.7 MiB |
| `llama-cpp` | present | 207.1 MiB |
| `llama-cpp-rocm` | present | 3.7 GiB |
| `llama-cpp-vulkan` | present | 142.5 MiB |

On `aarch64-linux`, CPU and Vulkan outputs were cached; CUDA and ROCm Ollama outputs and ROCm llama.cpp were not cached at query time. On `aarch64-darwin`, ordinary Ollama (83.1 MiB) and ordinary llama.cpp (30.2 MiB) were cached.

Consequences:

- ROCm closures are multi-GiB even when cached; CUDA/ROCm misses are expensive local builds and poor laptop defaults.
- CUDA/ROCm derivations are tied to toolchain/backend architecture lists; changing `cudaArches`, ROCm targets, CUDA/ROCm versions, or overlays changes store paths and loses cache reuse.
- Vulkan is the best cross-vendor Linux compromise for closure size and cache probability, not necessarily the fastest backend for every card.
- Do not place model weights in derivations. Models are tens/hundreds of GiB, operationally mutable, and already have a dedicated `modelsDir`/state boundary. Pin model identity/digest declaratively if desired, but keep the bulk model store outside the system closure.

## Portability matrix

| Host class | Preferred baseline | Preferred acceleration | What must be host-specific | Notes |
|---|---|---|---|---|
| `x86_64-linux`, no/unknown GPU | `ollama-cpu`, `llama-cpp` | CPU dynamic dispatch + BLAS | thread count, model size, NUMA | Safe/cached; no AVX assumption should leak to other arches. |
| `x86_64-linux`, NVIDIA | CPU fallback | `ollama-cuda`; `llama-cpp.override { cudaSupport = true; }` | NVIDIA driver, CUDA architecture set, visible devices, VRAM/model fit | Usually fastest native path; exact Ollama CUDA output was not in public cache at query time. |
| `x86_64-linux`, AMD supported by ROCm | CPU/Vulkan fallback | `ollama-rocm`; `llama-cpp.override { rocmSupport = true; }` | amdgpu/ROCm compatibility, GFX targets, `HSA_OVERRIDE_GFX_VERSION`, render/kfd access | Native path is current and supported, but multi-GiB closure. |
| Linux AMD/Intel/other Vulkan-capable GPU | CPU fallback | `ollama-vulkan`; `llama-cpp.override { vulkanSupport = true; }` | Mesa/vendor ICD, chosen device, `/dev/dri`/render access | Broadest portable GPU backend; device VRAM reporting may require privileges/capability. |
| `aarch64-linux` generic | `ollama-cpu`, `llama-cpp` | Vulkan when a suitable GPU/driver exists | SoC/GPU driver and VSIX arch; Jetson CUDA is a special host | CPU and Vulkan exact outputs were cached; do not assume x86 AVX or AMD ROCm. |
| `aarch64-darwin` Apple Silicon | ordinary `ollama`, ordinary `llama-cpp` | Metal (automatic/default) | model size vs unified memory; launchd/user service | Do not request CUDA/ROCm. Native Metal is preferable to a Vulkan-on-MoltenVK detour. |
| `x86_64-darwin` Intel Mac | ordinary CPU packages | CPU/Accelerate where supported | model size, aging platform | Ollama upstream says x86 Mac is CPU-only; nixpkgs warns 26.05 is the final x86_64-darwin release. |

## What belongs shared vs host-specific in this repo

### Shared

- Editor intent and non-native user settings (font size, autosave, panel layout, telemetry policy).
- A universal extension subset and language-server/tool packages already in `modules/shared/packages.nix`.
- Common editor abstraction/module enabling Zed (and optionally VS Code), but with platform availability guards.
- Local API convention (`127.0.0.1:11434`) and client settings, never credentials.
- Common Ollama service defaults: loopback bind, no firewall opening, models directory policy, environment variable schema.
- CPU fallback selection logic and common AI CLI packages (`codex`, `claude-code`, sidecar wrappers) where platform builds exist.

### Host-specific

- Whether local inference is enabled at all.
- `cpu|cuda|rocm|vulkan|metal`, GPU driver, compute/GFX architecture, device indices/UUIDs, user groups and device policy.
- Service implementation: NixOS system service vs standalone Home Manager user service vs Darwin launchd.
- Model inventory/context size based on RAM/VRAM/storage.
- Native VSIX variants and extensions that are Linux-only, Darwin-only, proprietary, or download platform binaries.
- Heavy builder/cache policy for CUDA/ROCm; ideally a cache populated by a matching builder rather than every workstation compiling independently.

A small host metadata option such as `localAi.acceleration = "cpu"|"cuda"|"rocm"|"vulkan"|"metal"` is justified. Derive the package and service from it. Avoid detecting the GPU at Nix evaluation/build time: builds must remain pure and cacheable, and the evaluation machine may differ from the deployed host.

## Local applicability

1. `modules/shared/packages.nix:270-298` already shares Codex, Claude Code, Zed, and language servers across all four declared systems. That is reasonable only while each package evaluates/builds on each platform; native editor extensions should not be added indiscriminately here.
2. `modules/nixos/packages.nix:57` and `modules/standalone-linux/packages.nix:71` install bare `ollama`. Because `lib/nixpkgs.nix` enables neither global CUDA nor ROCm, this is the CPU output at the exact pin. There is no local `services.ollama` declaration, so the repo installs a CLI/server binary but does not declaratively run or own the model store.
3. Ollama belongs in one reusable Linux AI module, not duplicated package lists. Host metadata should select `ollama-cpu/cuda/rocm/vulkan`; NixOS hosts should use `services.ollama.package` and standalone Linux may use the Home Manager service/package route.
4. `modules/standalone-linux/files.nix:19` owns `~/.config/zed/settings.json` as a Home Manager store link, but the same Zed package is installed on NixOS and Darwin without that config. Move the semantic settings to a shared `programs.zed-editor` Home Manager module. Use `mutableUserSettings = true` if GUI/agent edits should persist, or false only if strict immutability is intentional.
5. The repo’s writable-baseline pattern for Codex (`modules/standalone-linux/home-manager.nix:74-114`) is appropriate for files the tool regenerates. Zed’s upstream Home Manager module already provides a safer merge implementation, so do not replicate custom activation scripts for it.
6. Local docs are stale: `docs/service-notes/ai-sidecars.md` claims `oh-my-codex@0.15.0` and `oh-my-claude-sisyphus@4.13.3`, while `overlays/30-ai-sidecars.nix` pins `0.19.0` and `4.15.2` respectively.
7. `lib/nixpkgs.nix` globally sets `allowUnsupportedSystem=true` and `allowBroken=true`. That makes cross-system evaluation permissive but can hide a backend mistakenly selected for an unsupported host. Host selection should guard with explicit platform assertions rather than relying on these flags.
8. If VS Code is added, use Home Manager profiles rather than a hand-written `vscode.nix` copied from an old dotfile. The pinned Home Manager API has changed materially in 2026 (dedicated fork modules, profiles, MCP, argv settings).

## Anti-patterns to reject

- Enabling `nixpkgs.config.cudaSupport`/`rocmSupport` globally for one program; this changes unrelated packages and Ollama explicitly treats simultaneous CUDA+ROCm global flags as invalid, falling back to CPU.
- Putting `ollama-cuda` or ROCm in a shared all-host list.
- Assuming a package attribute’s evaluation means the backend works on the platform. On Darwin, Ollama’s enable flags are Linux-gated; accelerator-named expressions may collapse to the ordinary output rather than provide that accelerator.
- Building shared llama.cpp with `GGML_NATIVE`/`-march=native`; it reduces portability and binary-cache reuse. The exact pin intentionally uses runtime CPU variant dispatch.
- Assuming Vulkan is always faster than CUDA/ROCm/Metal; it is a portability fallback, not a universal performance winner.
- Making editor settings or runtime databases immutable without deciding who owns writes.
- Declaring mutable VS Code extensions while also expecting named-profile immutable extension registries.
- Fetching marketplace extensions without exact version/hash, or assuming a universal VSIX when it contains native binaries.
- Adding a moving extension flake without pinning it in `flake.lock`.
- Storing API keys, Ollama identity keys, histories, logs, or model blobs in the repo/Nix store.
- Binding Ollama to `0.0.0.0`, opening the firewall, or enabling CORS broadly by default.
- Installing driver SDKs only in a user profile and expecting NixOS system services/device policy to work.

## Supplied-guide claims: current vs outdated

| Claim in 2024 guide | 2026 verdict | Evidence/qualification |
|---|---|---|
| llama.cpp runs CPU-only and supports NVIDIA, AMD, Apple; Intel via SYCL/Vulkan | **Current, but incomplete** | Current upstream adds/expands OpenCL, OpenVINO, CANN, MUSA, ZenDNN, KleidiAI, WebGPU and other targets. |
| Vulkan is generic and easy for NVIDIA/AMD/Intel | **Broadly current** | Current upstream and pinned nixpkgs both support it; actual driver/operation coverage and performance vary. |
| AMD users should prefer Vulkan because ROCm was bugged | **Outdated as a general recommendation** | This was the author’s 2024 experience. Current Ollama documents ROCm v7 and explicit supported AMD lists; pinned nixpkgs builds/tests ROCm variants. Keep Vulkan as fallback, benchmark both. |
| A “reasonably modern CPU” means at least AVX | **Overstated/outdated portability claim** | AArch64, RISC-V, LoongArch, PowerPC and IBM Z paths exist. AVX is an x86 optimization, not a compatibility floor. |
| Metal for Apple Silicon and Accelerate default on Mac | **Current** | Current upstream and pinned nixpkgs default Metal on `aarch64-darwin`. |
| BLAS improves CPU performance | **Needs qualification** | Current upstream says BLAS mainly improves prompt processing at batch sizes >32 and does not improve token generation performance. |
| `GGML_VULKAN=ON`, `GGML_CUDA=ON`, `GGML_HIP=ON` | **Current** | Current flag names. Current Vulkan additionally requires SPIR-V headers that were absent from the guide’s MSYS dependency list. |
| Disabling `LLAMA_BUILD_EXAMPLES` unconditionally disables server | **Outdated** | Current server is under tools; exact nixpkgs builds `LLAMA_BUILD_EXAMPLES=false` and `LLAMA_BUILD_SERVER=true`. |
| CUDA/ROCm builds should target the local detected GPU | **Poor shared-Nix advice** | Useful for one-off local compilation, harmful for portable/cacheable Nix. Exact nixpkgs sets `GGML_NATIVE=false`, CPU runtime variants, CUDA architecture list, and ROCm targets explicitly. |
| `--gpu-layers 999` for full offload | **Still commonly effective, but not packaging policy** | Runtime/model/device decision; current tools also provide device listing/selection and multi-backend builds. |
| Python conversion does not need CUDA/ROCm PyTorch | **Generally current** | Conversion/quantization is not the inference backend; keep it out of host accelerator package selection unless a specific converter proves otherwise. |
| 7–8B and 8 GiB are a reasonable minimum | **Rule of thumb only** | Quantization, context/KV cache, model architecture, partial offload and current smaller/larger models make fixed thresholds unreliable. |

## EXPAND

- When host GPU inventory is known, benchmark `llama-bench` on CPU vs Vulkan vs the native backend using the same model, quantization, context, and batch settings; record prompt-processing and token-generation separately.
- Evaluate a small typed host metadata module and assertions for the four declared systems; make accelerator choice explicit rather than inferred.
- If adding VS Code, enumerate desired extensions and classify each as nixpkgs, marketplace universal, or platform-specific before choosing whether `nix-vscode-extensions` is warranted.
- Test the Home Manager Zed mutable merge on a copy of the current settings before moving ownership; the current raw store link may have prevented local edits.
- Consider a matching private cache only if CUDA/ROCm outputs are routinely rebuilt; use exact system/toolchain/target parity.
- GitHub code search should be paged after its dedicated rate-limit window resets if exhaustive enumeration of every dynamic `vscode.nix` result remains a hard requirement. The primary-source conclusion is unlikely to change.

## CLAIMS

1. **High confidence:** At this repo’s exact nixpkgs pin, explicit Ollama variants are the supported NixOS interface; the old NixOS `services.ollama.acceleration` option is removed.
2. **High confidence:** Bare `ollama` in this repo resolves CPU because neither global CUDA nor ROCm support is enabled.
3. **High confidence:** `aarch64-darwin` ordinary llama.cpp uses Metal by default; CUDA and ROCm are not portable Darwin choices.
4. **High confidence:** Nixpkgs’ llama.cpp CPU strategy is portable runtime dispatch (`GGML_NATIVE=false`, all CPU variants), not host-native compilation.
5. **High confidence:** Home Manager’s current VS Code and Zed modules encode mutable/immutable ownership details that raw `home.file` recipes commonly miss.
6. **High confidence:** Accelerator selection, GPU architecture and service/device permissions must be host-specific; editor semantics and universal tooling can be shared.
7. **High confidence, point-in-time:** At query time the exact x86_64-linux CPU, Vulkan and ROCm outputs listed above were on cache.nixos.org, while exact `ollama-cuda` was not; ROCm closures were ~3.7–4.1 GiB and Vulkan ~142–197 MiB.
8. **Medium confidence:** Vulkan is the best default GPU portability fallback for unknown heterogeneous Linux GPUs, but native CUDA/ROCm should be benchmarked on known supported hosts.
9. **High confidence:** The supplied 2024 guide is valuable conceptually but its ROCm preference, AVX compatibility floor, server/examples coupling, and dependency lists must not be copied as current Nix packaging rules.
10. **High confidence:** `docs/service-notes/ai-sidecars.md` is already stale relative to the overlay versions.

---

## Parent exact-lock audit note

The worker report incorrectly calls `59e69648...` the repository's root Nixpkgs pin. The root `nixpkgs` input is `d407951447dcd00442e97087bf374aad70c04cea`; `59e69648...` is a transitive lock node. Architectural conclusions remain useful, but exact package attributes, version numbers, cache presence, and closure sizes above are **provisional** until repeated at `d407951...`. This discrepancy is tracked as W1C-L1 and will not be silently promoted into the final verified-claim graph.
