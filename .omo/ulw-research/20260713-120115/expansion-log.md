# Expansion Log

## Wave 0 — decomposition
Core question: Which concrete architecture, options, installation procedures, validation gates, and documented exceptions make this nix-config maximally reliable across its declared machines for firmware, drivers, networking, desktop theming, and day-one usability?

Axes:
1. Current repository architecture and portability boundaries.
2. Current hardware, firmware, networking, boot, and install behavior.
3. Current desktop/Niri/theming/macOS integration.
4. Official NixOS/Nix/nixpkgs installation, module, firmware, and operational guidance.
5. Reference multi-host repositories and installation frameworks.
6. Niri/Hyprland desktop patterns and themed shells.
7. Images, kexec, WSL, server, and alternate deployment models.
8. CI, evaluation, update automation, debugging, storage, and maintainability.
9. Community reports, issue-specific edge cases, and counterexamples.
10. Skeptical feasibility boundary: what cannot safely be universal.

Codebase relevant: yes · External: yes · Browsing: yes · Verification likely: yes · Final material format: HTML/PDF plus Markdown source.

## Wave 1a — root direct inspection
Workers spawned: root direct Nix/source evaluation plus six parallel research lanes.
Markers gained: wireless manager interaction; microcode defaults; boot/storage platform boundary; fwupd/rtkit/maintenance policy.
Leads opened: W1-L1 through W1-L4 above.

## Wave 1a return — official documentation
Markers gained: Facter lifecycle; Secure Boot; architecture boot matrix; offline closure; GPU matrix; nixos-hardware counterexamples.
Leads opened: W1-L5 through W1-L10.

## Wave 1a return — repository hardware/install
Markers gained: target probes; ARM identity; ESP capacity proof; exact host-key behavior; Wi-Fi reboot; entropyos target decision; deployed ESP state.
Dead ends closed: real hardware config history; historical microcode/encryption/board/Secure Boot policy; Disko evolution.

## Wave 1a return — deployment/images/roles
Markers gained: exact-lock image provider matrix; signed Secure Boot install/recovery path.

## Wave 1a return — operations/CI
Markers gained: open performance PR tracking; local benchmark; provenance tool comparison; target workflow audit.

## Wave 1a return — reference configs/Niri
No new leads; lane converged after all named repositories and additional Niri references repeated existing patterns.

## Wave 1a return — repository desktop/hosts
Markers gained: live Niri lock/DBus/portal audit; Noctalia runtime drift; live cross-host font/theme diagnostics.
Dead ends closed: Home Manager target escape; Noctalia hidden portal/keyring enablement.

## Wave 1B return — boot/hardware skeptic
Markers gained: concrete target intake (defer until hardware); exact ESP capacity proof.
Dead end closed: literal universal unchanged NixOS closure/image.
Contradiction opened: root nixpkgs pin d407951 vs erroneous 59e696 identification; exact-lock execution must settle.

## Wave 1B return — Niri/Noctalia upstream
No new leads; exact-pin lock/schema/lifecycle and portal contracts converged. High-confidence actionable defects added to claim graph queue.

## Wave 1B return — videos/community/tutorials
Markers gained: authenticated video comment errata (low value/defer); disposable VM of tsawyer recipes (only if adopted).
Dead ends closed: survey comment, rice image thread, dynamic subreddit feed as technical evidence.

## Wave 1B return — Darwin/HM/theme
Markers gained: native Mac drills (physical defer); app projection measurement; identity mutations; lock/closure dedup delta.

## Wave 1B return — exact-lock hardware/network
No new leads; exact semantics converged. Contradiction d407951 vs 59e696 closed in favor of root mapping d407951.

## Wave 1B return — security/trust
Markers gained: external credential rotation (non-code blocker); strict host lifecycle; verified kexec artifact; live installed-host audit; agenix/sync repair design.

## Wave 1C return — editor/AI/GPU patterns
Markers gained: explicit per-host accelerator selection; mutable editor ownership; exact closure/cache economics; stale AI sidecar documentation.
Limit recorded: GitHub dynamic code search was sampled before dedicated quota exhaustion; upstream modules and pinned repository clones supplied primary evidence.
Contradiction opened: worker labeled transitive nixpkgs `59e696...` as the repo pin; root graph is `d407951...`. Revalidate accelerator attributes and cache/closure figures at d407951 before locking exact-pin claims.
Leads opened: W1C-L1 exact root-pin Ollama/llama.cpp revalidation; W1C-L2 typed host accelerator metadata and negative platform assertions; W1C-L3 mutable Zed ownership migration proof.

## Wave 1C return — exact Disko/nixos-anywhere contract
Markers gained: destructive disk identity manifest; strict host-key fork/patch; content-addressed local kexec; exported installTest; executable recovery mount preflight; explicit Wi-Fi unsupported boundary.
Dead ends closed: appended `--ssh-option` cannot restore strict verification at this pin; VM-test cannot validate physical disk path or extra-files; pinning nixos-anywhere source alone does not pin default kexec content.
Leads opened: W1C-L4 strict known-host lifecycle; W1C-L5 signed/content-addressed install manifest and kexec; W1C-L6 exact ESP/installTest execution; W1C-L7 wrong/missing/correct recovery-mount negative tests; W1C-L8 attended Wi-Fi installer matrix.

## Wave 1C return — branding/theme assets
Markers gained: current official palette/asset authority; exact local raster provenance; GPL/CC attribution gaps; cursor/font availability; cold-session theme ownership test matrix.
No source-search expansion requested: remaining uncertainties require physical rendering/session state or unavailable creator metadata.
Leads opened for execution/design: W1C-L9 theme authority invariant; W1C-L10 asset attribution/replace policy; W1C-L11 physical macOS/Linux font/cursor/render drills.

## Wave 2 root return — exact AI pin contradiction
W1C-L1 closed: root `nixpkgs_3` d407951 was imported directly across Linux/Darwin systems. Variant identities largely match the transitive-node lane, but only the root-pin table in `wave-2-root-exact-ai-pin.md` is claim-lockable. Darwin accelerator-labelled Ollama variants collapse to the ordinary output, reinforcing explicit platform assertions. Runtime benchmark remains physical-host deferred.

## Wave 2 return — host/Facter/Wi-Fi intake
New high-risk lead discovered: exact d407951 Facter plus NetworkManager starts dhcpcd for detected physical interfaces unless `hardware.facter.detected.dhcp.enable=false`; dual ownership is an executed synthetic-config result. Raw Facter privacy/store boundary also requires an allowlist sanitizer before tracking. Architecture decision converged to shared policy + role + concrete hardware leaf + storage/boot leaf. Wi-Fi readiness remains physical-host deferred, with authenticated root-only NM keyfile handoff or local `nmtui` as safe patterns.
Wave 3 markers: adversarial Facter-DHCP future-change check; sanitizer equivalence; cold-store offline kit; actual unidentified laptop enrollment.

## Wave 2 return — Disko VM/ESP capacity
Critical executed red: production installTest formats successfully but activation fails because the fixture lacks the mandatory bootstrap hash; current flake checks hide it. Causal isolation proves the disk/systemd-boot/OVMF path itself boots. Exact FAT allocation proves 100 MiB holds only two unique current payloads, not 42; placeholder masking is structural. Decision candidate: 1 GiB/limit10 standard, or 512 MiB ESP + 2 GiB XBOOTLDR/limit42. Wave 3 markers: faithful dummy-secret fixture, ENOSPC last-known-good preservation, migration safety, physical firmware exceptions.

## Wave 2 return — Niri/session/theme generated runtime
Exact generated-artifact and executable proof converged: broken lock IPC; three notification candidates (Noctalia/Mako/Dunst); active Picom/xautolock/xss-lock/i3lock/Polybar dependencies; OBS exit 127; dual wallpaper owners; eight stale Noctalia settings; split GTK/Qt authorities with missing requested cursor/UI fonts. Portal split and single NixOS Noctalia unit were positively verified, closing two earlier suspicions. Remaining leads are physical cold-login/lock/hotplug/suspend/portal/rendering drills and native macOS CoreText—carry as explicit deferred evidence, not more static search.

## Wave 2 return — SSH/kexec trust lifecycle
Exact kexec archive built and content identities recorded; manifest signature/digest harness passed 6/6. Trust design converged on strict-first patched installer, stage-specific host aliases, signed content-addressed manifest, disk/arch/boot gates, bounded transitions, install/reboot split, and `/mnt` final-key verification. Upstream issues #552/#598/#604 remain live counterevidence. Wave 3 markers: adversarial strict-first wrapper, independent kexec reproducibility, replay/signer operations, copy-host-key exact-revision VM variants.

## Wave 2 return — secrets/history/agenix remediation
Exposure and incident response converged without credential disclosure: public current/history/store copies; rotation must precede cleanup; scanner controls work with one explicit OpenPGP false positive; sync-secrets exact execution fails by targeting immutable store source; age runtime boundary primitive passes; root/user SSH authority and bootstrap persistence confirmed. External provider rotation/account review remains an unavoidable user-side blocker. Wave 3 markers: first-boot NM secret VM, recipient isolation/rekey, SSH/password lifecycle, scanner false-negative countersearch.

## Wave 2 return — CI/update/rollback lifecycle
Current green surface is demonstrably shallow: only three lightweight checks, six manual tests and two Disko tests unexported, no workflows/formatter, permissive broken/unsupported flags, options-context warning, Intel Darwin expiry, and cleanup/ESP/rollback mismatch. Tiered PR/native/nightly/release/physical matrix is decision-complete. Wave 3 markers: false-green adversary across hardware/boot/network/session/Darwin; warning-zero/update provenance; signed cache and physical evidence expiry.

## Wave 3 return — hardware universality skeptic
Absolute single-closure impossibility was refuted: bounded compatibility-class generic closures are real. Corrected boundary: current x86 is a plausible mainstream 64-bit UEFI/SATA-or-NVMe/ext4 baseline; current AArch64 is at most a SystemReady/UEFI template. Concrete hosts are assurance/destructive-choice evidence, not boot prerequisites; Facter and nixos-hardware are optional. Microcode is security/errata, not generic boot. Physical diverse-machine execution remains the stop boundary.

## Wave 3 return — network/trust skeptic
P0 transport and unchecked-kexec claims upheld but explicitly conditional: direct attended ISO, console, or authenticated overlay can remove the affected paths. Wi-Fi split clarified: remote/kexec unsupported, installed NM+wpa+redistributable firmware coherent. Facter/dhcpcd collision is prospective because current output has no Facter. Shared root/user key marginal severity downgraded given existing root-equivalent Docker/Nix authority. Provider credential impact recalibrated to medium confidentiality/read-only scope; rotation remains required.

## Wave 3 return — session skeptic
Broken lock and notification authority upheld P0; X11 components are unconditionally scheduled but healthy continuous activity wording downgraded. OBS/missing assets/warnings upheld P1. GTK conflict upheld; Qt conflict downgraded to redundancy. Runtime state override is intentional policy, not intrinsic defect. Duplicate integrated Noctalia and macOS Kitty omission refuted. New boundary: GNOME portal capture works, but RemoteDesktop input injection cannot be promised because exact Niri lacks Mutter RemoteDesktop.

## Wave 3 return — boot/disk/rollback skeptic
Placeholder itself is fail-closed (literal percent, guarded sgdisk rc4); human replacement/identity binding is unsafe. 100 MiB is bootable but has no reliable rollback budget. 2 GiB/42 was corrected: it uses 82.98%, violating an 80% gate; use dynamic byte preflight and >=3 GiB XBOOTLDR if 42 full payloads truly required. Exact builder is file-atomic, not set-transactional; clean app uses install mode with early loader.conf unlink. Secure Boot absent/unproved. Red installTest is test self-containment debt, not evidence real extra-files flow fails.

## Wave 3 return — cross-platform skeptic
Standalone identity conflict upheld; feared root `/.config` write refuted by exact HM target prefixing. Darwin duplicate app projection upheld with 111 overlaps but narrowed to ownership/visibility rather than double store bytes. Kitty/Fira declared in all six configs; physical Mac only remains. Intel Darwin support strengthened as a hard 26.11-era false claim. `allowUnsupportedSystem` has concrete ARM Chrome and Intel Darwin iverilog counterexamples; allowBroken only latent. Darwin accelerator suffixes collapse and editor config is standalone-only.

## Wave 3 return — CI/supply-chain skeptic
No-workflow state is a visibility/evidence gap, not semantic invalidity. Strict eval proves unsupported escape hatch is an actual false green, while broken escape is currently unnecessary/latent. Formatter absence downgraded low; options warning is current upstream/scoped. Heavy checks belong scheduled/change-triggered rather than every PR. Signed Nix substitution is the cache boundary; cryptographic signing of physical evidence is optional single-operator defense-in-depth. Production red Disko test remains strongest missing-gate evidence.

## Final convergence — canonical lead closure

Every Wave 1/1B/1C/2/3 `EXPAND` item is closed below. Repeated phrasings are
deduplicated into canonical leads; the originating wave is named in the scope.

| Canonical lead (originating waves) | Closure class | Convergence disposition |
|---|---|---|
| Root lock identity and Ollama/llama variants (W1C editor) | resolved | Root pin is `d407951…`; transitive `59e696…` is contamination. Root variants re-evaluated in `wave-2-root-exact-ai-pin.md`. |
| Generic hardware versus concrete host leaves (W1 hardware/docs/boot; W2 host; W3 hardware) | resolved + physical-host-deferred | A bounded compatibility-class closure is valid. Concrete leaves bind destructive choices, exceptions and evidence. Physical multi-host proof remains D-02/D-03. |
| Intended laptop/EntropyOS hardware intake, WLAN controller, suspend/GPU/audio (W1 hardware; W2 host; W3 network/hardware) | physical-host-deferred | No static source can identify the missing radio. D-01/D-02 define exact acceptance. Whether the historical EntropyOS audit is a target is an implementation inventory choice, not a research contradiction. |
| Exact ESP capacity, generation retention, ENOSPC and deployed ESP state (W1 hardware/boot; W2 ESP; W3 boot) | resolved + implementation/physical-deferred | Exact payload/capacity and synthetic ENOSPC were executed. Policy is dynamic preflight + 1 GiB/10 ordinary or ≥3 GiB XBOOTLDR/42. Existing physical ESP/migration remains host-deferred. |
| Production Disko test and faithful bootstrap fixture (W1C Disko; W2 ESP/CI; W3 boot/CI) | implementation-deferred | Red cause isolated; build a dummy-secret fixture with negative controls and export it. |
| Physical disk identity and install-only `/mnt` recovery (W1C Disko; W3 boot) | implementation-deferred + physical-host-deferred | Placeholder semantics resolved; manifest-bound by-id/serial/size and wrong/missing/correct mount gates remain to implement and run sacrificially. |
| Strict known-host lifecycle and bounded retries (W1 hardware/security; W1C Disko; W2 SSH; W3 network) | implementation-deferred + physical-host-deferred | Source bug and patch shape are decision-complete. Pre→installer→final mismatch/continuity must be integrated and physically exercised. |
| Verified/signed kexec image, replay and signer operations (W1 security/deployment; W1C Disko; W2 SSH; W3 network) | resolved design + implementation/physical-deferred | Exact local artifact and 6/6 manifest harness pass. Independent rebuild, operations and physical transition remain. Direct ISO is the simpler supported alternative. |
| Direct ISO/kexec Wi-Fi and first-boot Wi-Fi handoff (W1 hardware/docs; W1C Disko; W2 host; W3 network) | resolved boundary + physical-host-deferred | Remote/kexec Wi-Fi unsupported; local ISO/NM or encrypted root-only keyfile is the supported design, with wired/USB/console fallback. Hardware association remains D-01. |
| Facter lifecycle/schema/privacy/DHCP interaction (W1 docs; W2 host; W3 hardware/network) | resolved + implementation-deferred | Optional, neither necessary nor sufficient. Exact DHCP collision/privacy boundary proved; sanitizer and `detected.dhcp=false` remain implementation work. |
| Firmware, microcode, GPU, power, fwupd and rtkit matrix (W1 docs/root; W2 host/AI; W3 hardware) | resolved policy + physical-host-deferred | Shared redistributable/Mesa baseline, enable CPU microcode, and host-route proprietary GPU/firmware/power exceptions. Runtime support is physical. |
| Secure Boot/TPM/BIOS/32-bit EFI/ARM board boot (W1 docs/deployment; W3 boot/hardware) | implementation-deferred | Current support is explicitly absent/unproved. Separate signed, GRUB, SystemReady or board profiles are required; no further source contradiction. |
| Hyper-V/VHDX/VM/cloud role (W1 deployment; W3 hardware) | implementation-deferred | Classified as a separate unverified role. Only adopt after exact image build plus provider-specific boot/console/agent test. |
| Offline closure/USB/cold-store install (W1 docs; W2 host; W3 network) | implementation/physical-deferred | Git checkout alone rejected. Named-host closure + installer + manifest + disconnected boot/install/recovery test required. |
| Niri lock, X11 services, notification owner, OBS, wallpaper and portal boundary (W1 desktop/Niri; W2 session; W3 session) | resolved + implementation/physical-deferred | Static/generated claims converged. Fix lock and single owners; portal scope is ScreenCast/Screenshot/chooser/Secret, not Mutter RemoteDesktop; cold-login and physical portal tests remain. |
| Noctalia runtime-state drift and stale keys (W1 desktop/branding; W2/W3 session) | resolved policy + implementation-deferred | State override is intentional, not intrinsically broken; eight stale warnings represent ignored intent. Choose declared-vs-mutable policy and make validation warning-free. |
| GTK/Qt/Kitty/fonts/cursors/wallpaper rendering (W1 desktop/Darwin/branding; W2/W3 session) | resolved statically + physical-host-deferred | Kitty reaches all six; GTK/assets broken, Qt redundancy narrowed. Linux cold render and Darwin CoreText remain D-05/D-06. |
| Branding palette/logo and artwork license/provenance (W1C branding) | resolved + implementation-deferred | Official palette/variants and local provenance are known. Add TASL/license metadata or replace uncertain/restrictive assets. Creator metadata unavailable beyond recorded upstream is a dead end. |
| Darwin app ownership, native activation, Intel lifecycle (W1B Darwin; W3 cross) | resolved policy + physical-host-deferred | One app owner; Apple Silicon native activation required; current Intel output unsupported and must retire or freeze. Closure-size-only comparison is duplicate/low-value. |
| Standalone generic identity and ambient HOME (W1 desktop/Darwin; W3 cross) | resolved + implementation-deferred | Root-write fear refuted; fixed-identity conflict upheld. One typed identity plus two-user mutation test required. |
| CI/workflow/pins/permissions/cache/update/rollback matrix (W1 operations; W2 CI; W3 CI) | resolved design + implementation-deferred | Repository has no workflow. Proportional eval/native/VM/release/physical gates are specified; Nix signed substitution is cache trust. Run timings after implementation. |
| Nixpkgs PR #535735, devenv speed, nix-why comparisons (W1 operations) | dead-end for readiness | Moving/performance/UX leads do not affect correctness. Revisit only after safety gates and with local benchmarks. |
| YouTube comments, dynamic subreddit, survey/rice posts, tsawyer disposable VM (W1B media) | dead-end / duplicate | Primary/current documentation supersedes them. The tsawyer recipe is not adopted, so executing it would not change this repository’s decision. |
| Dynamic GitHub `path:vscode.nix` pagination (W1C editor) | blocked by explicit source-access stop | Provider quota prevented exhaustive pagination. Exact upstream HM/Nixpkgs modules plus pinned representative repos closed ownership/portability conclusions; only ecosystem enumeration remains incomplete. |
| VS Code extension taxonomy and Zed mutable ownership (W1C editor; W3 cross) | implementation-deferred | No VS Code configuration currently exists; Zed config is standalone-only. Execute only after product ownership is chosen. |
| Local AI CPU/Vulkan/CUDA/ROCm benchmark and private cache economics (W1C editor; W2 root; W3 cross/CI) | physical-host-deferred / conditional implementation | Exact outputs/cache identities resolved. Benchmark identical models on known GPUs; add a trusted cache only if measured rebuild cost justifies its surface. |
| Provider credential rotation/history cleanup (W1 security; W2 secrets; W3 network/CI) | external-action + implementation-deferred | Rotation/account review cannot be performed by repository tooling. Current/history scanner and source removal follow rotation; old value must never be tested. |
| Agenix recipients, NM secret VM, SSH/password lifecycle, `sync-secrets` (W1 security; W2 secrets; W3 network) | resolved design + implementation-deferred | Current agenix inactive; primitive boundary passes; sync bug and auth lifecycle proven. Integrate per-host recipients/runtime plaintext and execute isolation/login matrices. |
| Native ARM strict package inventory (W2/W3 CI/cross) | implementation-deferred | First false green is Chrome; removing global unsupported bypass and native ARM evaluation/build will enumerate remaining packages. |
| Physical evidence signing (W2/W3 CI) | duplicate / optional | Evidence content, expiry and invalidation are mandatory; cryptographic signatures are optional defense-in-depth for a single trusted operator. |

### Final stop boundary

No source contradiction remains open. Irreducible leads are only:

1. production implementation and rerun of the specified gates;
2. physical x86, ARM, Niri, Wi-Fi, firmware, boot and macOS activation tests;
3. provider-side credential rotation/account review;
4. source-access-limited exhaustive GitHub code-search pagination, which cannot
   affect the exact-repository conclusions.

The decision-complete claim set is `verified-claims.md`; dependencies and
refutations are locked in `claim-graph.md`.

## Convergence audit B1–B5 closure addendum

The independent `convergence-audit.md` initially blocked epistemic closure
because canonical ledgers were empty. The following bounded fixes now close its
five blockers without another search wave:

- **B1 closed:** `claim-graph.md` contains stable atomic node dispositions,
  allowed evidence statuses, severity/remediation separation, observation IDs,
  counterevidence, validity and final-section pointers. Superseded claims are
  explicitly refuted/narrowed and O61 is prohibited as controlling root-pin
  evidence.
- **B2 closed:** `intent-diff.md` maps I1–I20 to `met`, `partly met`, `not met`,
  and/or `physical-deferred`, with canonical claims and observations.
- **B3 closed:** `cause-disappearance.md` records fourteen rejected/narrowed
  causes; `verification-economics.md` orders cheap deterministic through
  destructive physical gates and never treats an unrun gate as green.
- **B4 closed:** `verified-claims.md` separates impact from remediation priority
  for conditional SSH/kexec risk, medium-impact credential incident, session
  blockers, prospective Facter, latent allowBroken, microcode freshness,
  fixture-only Disko red, and low-severity formatter/performance work.
- **B5 closed:** exact pins/dates, rate-limit disclosure, synthetic/VM/physical
  boundaries, and literal-universality rejection are preserved in every
  canonical artifact.

No generic source lead was reopened. Publication must still retain all physical,
implementation and external stop-boundary items in `verified-claims.md`.
