---
slug: nix-config-machine-readiness
status: approved-high-accuracy-reviewed
intent: clear
review_required: true
pending-action: execute the approved plan with $omo:start-work
approach: close P0 trust and session defects first; introduce bounded named-host contracts; preserve stable public interfaces; qualify each retained platform through evidence tiers; never convert VM, foreign evaluation, or missing physical evidence into support
approved: 2026-07-13
---

# Draft: nix-config-machine-readiness

## Components (topology ledger)
| id | outcome | status | evidence path |
| --- | --- | --- | --- |
| C1-security | Credentials, runtime secrets, login identities, installed SSH, and bootstrap-password retirement are fail-closed and recoverable. | active | `.omo/ulw-research/20260713-120115/verified-claims.md:21-34` |
| C2-install | Direct ISO, optional hardened remote installation, disk identity, boot capacity, rollback, and offline recovery have explicit trust and stop gates. | active | `.omo/ulw-research/20260713-120115/SYNTHESIS.md:378-465,896-963` |
| C3-hosts | Den composes shared policy, role, hardware, storage, identity, and evidence into named bounded hosts rather than architecture-only promises. | active | `modules/entities/hosts.nix:6-38`, `.omo/ulw-research/20260713-120115/SYNTHESIS.md:319-336` |
| C4-desktop | Niri, Noctalia, portals, themes, Kitty, OBS, input/output, and DDC have one authority and physical acceptance boundaries. | active | `modules/nixos/home-manager.nix:59-121`, `modules/linux/config/niri/config.kdl:5-194` |
| C5-platforms | Standalone HM and Apple Silicon Darwin are honest, typed, reproducible targets; Intel Darwin is retired; compatibility contracts remain stable. | active | `modules/entities/hosts.nix:17-38`, `modules/standalone-linux/home-manager.nix:4-69` |
| C6-evidence | Exported checks, native builds, VM/fault tests, offline kits, update canaries, and expiring physical records control every support transition. | active | `modules/flake/checks.nix:3-35`, `.omo/ulw-research/20260713-120115/intent-diff.md:6-27` |

## Open assumptions (announced defaults)
| assumption | adopted default | rationale | reversible? |
| --- | --- | --- | --- |
| Support vocabulary | Per-platform evidence vector (`evaluation`, `matchingNativeBuild`, `vmInstall`, `nativeActivation`, `physicalAcceptance`) with explicit applicability; derived public state; experimental/stable is an orthogonal release channel. | A universal VM ladder cannot model Darwin or standalone activation honestly. | Yes, but only with stronger evidence. |
| Linux cohort | First support lane is named mainstream x86_64, 64-bit UEFI, Secure Boot off, one AHCI/NVMe disk, GPT/ext4. | This is the only plausible bounded class in the exact research. | Yes, through separate profiles. |
| ARM Linux | Retain `nixosConfigurations.aarch64-linux` with an evaluation-only ceiling; its no-record current state is unsupported and it has no install/release target until authenticated E and a separately enrolled machine justify more. | Preserves the binding public alias without claiming hardware support. | Yes. |
| Darwin | Retain Apple Silicon with experimental release channel and evidence-derived state starting unsupported when no authenticated records exist; retire `x86_64-darwin`. | Nixpkgs 26.05 is the final Intel-Darwin lifecycle; release channel, ceiling, and current evidence state are different axes. | Retirement reversal requires a separate supported pin/EOL plan. |
| Storage | Fresh installs use 1 GiB FAT32 ESP, ext4 root, 10 boot generations, no hibernation. Existing 100 MiB layouts stop for an attended migration. LUKS2/swap/hibernation are future typed profiles, not implemented here. | Avoids silently destructive repartitioning or universal storage policy. | Yes, per host. |
| Installer | Repository-built signed direct ISO is supported. Direct disk authorization is digest+TTY+last recheck; remote adds OpenSSH signing, expiry, replay ledger, strict stage keys, and bounded transitions. | Closes current host-key/artifact defects without imposing fleet signing on an attended console install. | Yes. |
| Desktop authority | Noctalia owns session lock, notifications, and session wallpaper; LightDM retains a separately provenance-checked greeter image. OBS remains supported and is installed. | Matches the existing design while removing D-Bus and X11 ownership races. | Yes. |
| Developer tools | Keep Emacs and make it Nix/content-owned and offline-startable. | The repo already advertises Emacs clients and config; deleting it would narrow the requested environment. | Yes. |
| Darwin apps | nix-darwin owns GUI projection; HM owns user configuration and CLI packages; Darwin remains Homebrew-free. | Removes duplicate visible ownership without reintroducing Homebrew. | Yes. |
| Incident history | Rotate/revoke first, remove current tracked copies, scan current tree/history redacted, but do not rewrite public history in this implementation. | Rotation revokes capability; rewriting is disruptive and requires separate authorization. | A later coordinated rewrite remains possible. |
| Updates | Manual, trust-domain-scoped update PRs; no auto-merge. | Keeps provenance and rollback review explicit until the evidence system is mature. | Yes. |
| Testing | Characterization/TDD for repaired contracts, then exact eval, native build, VM, and fault injection. External/physical steps are evidence gates, never synthetic passes. | Matches the approved high-assurance strategy. | No weakening without reducing support claims. |

## Findings (cited - path:lines)
- The research converged on 10 P0, 25 P1, 20 intent rows, and a bounded-readiness decision rule at `.omo/ulw-research/20260713-120115/verified-claims.md:8-64` and `intent-diff.md:6-27`.
- Den and flake-parts are sound composition foundations, but the architecture-named hosts share one workstation/storage policy: `flake.nix:3-39`, `modules/entities/hosts.nix:6-38`, `modules/aspects/hosts/nixos-workstation.nix:3-13`.
- The current install path has an unauthenticated SSH ordering defect, mutable kexec artifact, `/dev/%DISK%`, a red unexported production-derived Disko test, and no cold-store offline proof: `.omo/ulw-research/20260713-120115/verified-claims.md:25-29,100-102`.
- The live NixOS MCP confirmed that firmware, per-vendor microcode, NetworkManager, fwupd, I2C, rtkit, systemd-boot limits, SSH password/KBI/root policy, per-host timezone/XKB, Facter DHCP, and hashed-password-file behavior are explicit options rather than universal defaults. Exact pinned evaluation remains controlling evidence.
- Niri is the sole login session, but the exact generation schedules obsolete X11 authorities and invokes an invalid Noctalia lock command; multiple notification candidates compete: `tests/dendritic-config-eval.nix:80-96`, `modules/nixos/home-manager.nix:59-121`, `modules/linux/config/niri/config.kdl:58`.
- Kitty palette/font/shell declarations reach every audited configuration, including macOS, while native rendering remains unverified: `modules/shared/home-manager.nix:402-438`, `.omo/ulw-research/20260713-120115/verified-claims.md:84-87`.
- Standalone HM has conflicting fixed and ambient identity owners; Darwin projects the same packages twice; Emacs and the documented Determinate bootstrap execute mutable network content: `modules/entities/hosts.nix:27-38`, `modules/standalone-linux/home-manager.nix:4-13`, `modules/darwin/base.nix:34-38`, `modules/darwin/user-home.nix:1-11`, `modules/shared/config/emacs/init.el:13-75`, `README.md:113-129`.
- Only three shallow checks are exported even though stronger suites exist; the isolated OVMF boot is positive but Disko rewrites the production selector and cannot prove physical identity: `modules/flake/checks.nix:3-35`, `.omo/ulw-research/20260713-120115/wave-2-esp-vm-capacity.md:46-85`.

## Decisions (with rationale)
1. Keep Den/flake-parts and repair boundaries instead of replacing the architecture framework.
2. Preserve `x86_64-linux`, `aarch64-linux`, both standalone names, Bash/Nushell parity, Niri-only login, one Noctalia unit per output, Kitty semantics, standalone incremental adoption, wallpaper transfer, and Homebrew-free Darwin.
3. Retire Intel Darwin; retain ARM Linux only as an evaluation compatibility output; Apple Silicon stays experimental until native activation.
4. Make direct verified ISO the supported install lane; require patched strict source, stage fingerprints, and content identity for any remote lane.
5. Use signed runtime disk manifests plus per-host storage leaves; a named leaf alone does not authorize a disk write.
6. Use a fresh-install 1 GiB/10/ext4 profile and stop rather than automatically migrate a 100 MiB ESP.
7. Prove recovery before disabling password/root SSH; expire the bootstrap password for forced local change but never lock the sole recovery path automatically.
8. Make Noctalia the session authority, retain the LightDM greeter as a separate asset owner, and remove obsolete state containing the exposed credential without reproducing it.
9. Retain Emacs, OBS, Kitty, and the standalone adoption interface; make each reproducible and test its real surface.
10. Treat external rotation, physical qualification, native macOS activation, and destructive installation as explicit stop gates that cannot be agent-declared green without evidence.

## Scope IN
- Every P0/P1 remediation and I1-I20 contract in the research bundle.
- Bounded support taxonomy, named host schema, hardware/network/storage/boot profiles, trusted install and recovery.
- Linux desktop/session/theming, standalone HM, Apple Silicon Darwin, developer bootstrap, CI/update/offline/physical evidence.
- Required regression tests, failure controls, evidence artifacts, and Lore-compliant atomic commits.

## Scope OUT (Must NOT have)
- No literal universal-machine claim; no unsupported class promoted from eval/closure/VM evidence.
- No automatic credential validation/rotation, history rewrite, disk write, repartition, Secure Boot enrollment, final reboot, or password lock.
- No Secure Boot, legacy BIOS, board-specific ARM, Apple Silicon NixOS, NVIDIA performance/hybrid, proprietary WLAN, RAID/LVM/ZFS, LUKS2, swap, or hibernation implementation in this plan.
- No `enableAllFirmware`, unconditional proprietary GPU, blanket latest-kernel promise, raw Facter import, global broken/unsupported escape, Homebrew, duplicate Noctalia spawn, or surprise standalone sudo.
- No state-version changes, removal of binding NixOS/standalone aliases, BSPWM restoration, Kitty semantic drift, unrelated flake updates, or broad formatting/refactor churn.

## Open questions
None. The user approved the recommended defaults on 2026-07-13. Defaults not in the approval brief but needed for closure are: no history rewrite in this implementation and LUKS2/swap/hibernation remain future profiles.

## Metis gap analysis
- Session: `/root/metis_plan_gap_analysis`
- Result: approved decisions sufficient; required 12 contradiction resolutions and a 26-todo topology covering P0-01..10, P1-01..25, and I1..I20.
- Folded corrections: split agent-executed versus physical/external verification; preserve ARM alias while quarantined; retire Intel Darwin without misreading P1-23; stop existing 100 MiB storage migration; preserve recovery ordering and wallpaper staging; independently inspect the unrewritten disk selector.

## Initial validation before dual review (superseded by round 1)
- Template/sequence/lexical-DAG/coverage/reference checks passed mechanically, but both reviewers correctly found that lexical acyclicity did not prove semantic dependencies, support authority, or executable QA. The old topological receipt is retained only as evidence of why round 1 was required; it is not a current PASS.
- Planner boundary remained valid: product worktree unchanged; only ignored `.omo` planning artifacts were written.

## Dual review round 1
- Native Momus `/root/momus_plan_review_round1`: **NOT OKAY**, seven blocker groups.
- Independent isolated `codex exec` session `019f5d7d-9a3b-71c2-b4dd-128b8a708859`, model `gpt-5.6-sol`, reasoning `xhigh`: **blocking issues**, fourteen groups.
- Consolidated corrections applied before round 2:
  1. replaced the universal VM ladder with gate applicability vectors and orthogonal release channels;
  2. made registry declarations + sanitized acceptance records the only inputs to a derived support projection;
  3. repaired all direct dependencies/shared-file ownership and recomputed waves/topology;
  4. defined receipt-backed immutable historical secret exceptions while retaining no-history-rewrite policy;
  5. split attended direct and signed remote manifest protocols, including canonical bytes, OpenSSH namespace/identity, signer custody, replay and recovery authorization;
  6. fixed the two-root/ten-entry/age/byte rollback invariant and durable reboot resume journal;
  7. left the real laptop pending until signed CPU intake and replaced cross-vendor identical-closure claims with same-policy/separate-closure qualification;
  8. gave every todo an exact stable happy/negative harness invocation and exact evidence markers;
  9. expanded owned coverage to all 73 P0/P1/I/D/POS IDs and narrowed POS-01/POS-06 to five retained outputs;
  10. fail-closed quarantined ARM deployment/no-flag routing while preserving evaluation aliases;
  11. selected an exact repository-built ISO, pinned Determinate installer source, Home Manager/Nix-owned Emacs, and explicit Qt5/Qt6 semantic oracle;
  12. required FAT32 `-F 32`, removed standalone plaintext secret evaluation, and defined consumer-scoped runtime delivery;
  13. replaced transient MCP/workflow references with locked source paths, official URLs, exact commands, and receipt schemas.

## Dual review round 2
- Native Momus `/root/momus_plan_review_round2`: **NOT OKAY**, nine blocker groups.
- Independent isolated `codex exec` session `019f5d95-b33d-7462-9f75-2b4af2615b1b`, model `gpt-5.6-sol`, reasoning `xhigh`: **blocking issues**, eleven groups.
- Consolidated corrections applied before round 3:
  1. moved harness creation into dependency-free todo 3, made every other todo downstream, and recomputed waves/DAG/commit order;
  2. defined a complete gate-to-state table, ceilings, output-to-host projection, class-minimum aggregation, matching-native rules, and Intel+AMD quorum;
  3. separated ignored raw logs from committed sanitized signed records, with closed schemas, canonical bytes, production/fixture signer isolation, expiry/invalidation, rotation, and revocation;
  4. split current-tree pure scans from full-depth Git history scans, authenticated a non-secret incident attestation, and isolated the provider exception from the known OpenPGP false positive;
  5. bound remote authorization to source/lock/release/kexec/disk and pre/installer/final SSH keys, fixed one-LF canonicalization, added stage aliases/options/deadlines, and ordered operator/target ledgers;
  6. removed the ISO hash cycle by separating embedded build identity from the detached completed-image release envelope;
  7. corrected the exact ESP attr query, reconciled Disko `1G` with measured binary GiB, enumerated byte classes, and made 70/80% behavior inclusive and deterministic;
  8. completed the locked rollback transaction state machine, health oracle, crash/fsync semantics, authorization reissue, and exact commands;
  9. declared two x86 host enrollment slots with separate vendor closures, rejected undeclared/same-vendor quorum, and explicitly kept fwupd unsupported;
  10. selected literal Qt5/Qt6 tuples with version-aware launch dispatch and real client tests;
  11. added exact matching-native Linux/macOS Emacs batch/daemon/client gates and bound Darwin promotion to them;
  12. removed the unowned online Determinate binary lane in favor of locally built, signed offline-kit bytes;
  13. made standalone depend on and consume todo 13's secret contract, and made executable CI release gating follow the cold-tested offline kit.

## Round-3 preflight validation (superseded by round-3 review)
- Template order: PASS; TL;DR is first and contains no scaffold placeholders.
- Structure: PASS; 26 sequential todos and 26 exact happy/negative harness contracts.
- Dependency graph: PASS with reciprocal edges; acyclic topological order `3 1 2 21 4 6 5 11 13 23 7 12 15 18 22 8 14 16 17 19 20 9 10 25 24 26`.
- Coverage: PASS; all 73 P0/P1/I/D/POS IDs present, with POS-01/POS-06 explicitly narrowed.
- Existing references: PASS; 121 existing path/line anchors present and within file length.
- Trust/authority review: PASS preflight; no self-referential image manifest, double-LF canonicalization, ignored evidence input, shallow-history green, fixture production signer, or unowned online bootstrap path remains.
- Planner boundary: PASS; `git status --short` and `git diff --check` remain empty for tracked product files.

## Dual review round 3
- Native Momus `/root/momus_plan_review_round3`: **NOT OKAY**, eleven blocker groups.
- Independent isolated `codex exec` session `019f5dad-172d-7713-b6f8-aa8d0a42a506`, model `gpt-5.6-sol`, reasoning `xhigh`, disposable workspace `/tmp/nix-plan-independent-review-r3.owRp3i`: **blocking issues**, thirteen groups.
- Consolidated corrections applied before round 4:
  1. replaced impossible pure signature/time evaluation with declaration-only `.#supportRegistry` plus exact runtime `.#verify-support` and authenticated JSON/digest consumers;
  2. anchored the root fingerprint outside the repository, added preceding-root update signatures, disjoint delegates/namespaces, reviewer fingerprint separation, and production fixture-root rejection;
  3. eliminated evidence self-reference with an exact subject-path digest and explicit lock/policy/source-archive/NAR/closure digest algorithms;
  4. split the common record fields from incident, support/native, release/install, and review-specific closed schemas;
  5. repaired every semantic DAG edge, reciprocal block list, wave, per-todo dependency, and topological commit order, including CI-before-kit and both vendor tests-before-release;
  6. separated executable current-tree credential containment from the external provider prerequisite, which now blocks only release/promotion through `external-not-verified`;
  7. defined the exhaustive six-target gate/ceiling/no-record/action mapping and made `pending` presentation-only;
  8. assigned the raw-evidence ignore to the repository `.gitignore` and required a global-excludes-disabled proof;
  9. completed recovery delegate/capability schemas, durable one-use ledgers, cross-reboot boot-resume reconciliation, exact rollback/profile side effects, and crash/terminal-state semantics;
  10. specified sector-derived ESP size, mounted FAT allocation math, one-time rounding/reserve, integer 70/80% thresholds, entry/specialisation accounting, and signed <=15-minute overrides;
  11. removed reusable ISO/repository host keys, bounded the attached-TTY password phase, added missing strict SSH options, preserved kexec identity, and pre-generated/delivered/verified a distinct final host key;
  12. corrected the pinned Determinate payload to Nix 2.34.8, bound `binaryTarball`, and separated the todo-14 fixture bundle from todo-25 production kits;
  13. required separate Intel/AMD named closures and V gates, corrected the locked Facter source path, and prohibited fixture evidence from production promotion;
  14. closed Qt routing through `config/theme/qt-launch-map.json` plus exhaustive closure/desktop/service ELF-major scans and real Qt5/Qt6 clients;
  15. froze validators/workflows in todo 24, made production signing an external handoff, and made todo 25 cold-test exact synthetic/per-enrolled-host signed bytes without agent/CI production keys;
  16. made default and explicit ARM/pending/undeclared deployment routes consult the authenticated installable predicate.

## Round-4 preflight validation
- Template/header order: PASS; the human TL;DR remains first.
- Structure: PASS; 26 sequential todos, each with one implementation boundary, references, exact happy+negative harness calls, evidence path, and Lore commit.
- Dependency graph: PASS; matrix and per-todo edges are reciprocal and acyclic with topological order `3 2 1 21 4 6 5 11 13 23 15 18 7 22 17 19 20 8 12 14 9 10 16 24 25 26`.
- Coverage: PASS; all 73 P0/P1/I/D/POS IDs are present with POS-01/POS-06 narrowing.
- Existing references: PASS; every repository-local path/line anchor exists and is within file length.
- Stale-contract scan: PASS; no Nix 2.34.7, old Facter path, obsolete recovery namespace, pure support-matrix verification, or old kit-before-CI ordering remains.
- Planner boundary: PASS; tracked `git status --short` is empty; only globally ignored `.omo` plan/draft artifacts changed.

## Dual review round 4
- Native Momus `/root/momus_plan_review_round4`: **NOT OKAY**, nine blocker groups.
- Independent isolated `codex exec` session `019f5dca-e8d1-7860-8434-dc0185020d7c`, model `gpt-5.6-sol`, reasoning `xhigh`, disposable workspace `/tmp/nix-plan-independent-review-r4.ecwYug`: **blocking issues**, seventeen groups.
- Consolidated corrections applied before round 5:
  1. replaced repository-selected trust with a fixed externally provisioned root-version/digest/fingerprint/verifier anchor, persistent rollback-resistant time floor, independently built production verifier, explicit root-update chain, and production rejection of test anchor/time flags;
  2. made every protected consumer invoke the fixed verifier immediately before action through one process pipe, treating the result digest as audit-only and rejecting forged JSON plus a recomputed digest;
  3. made frozen-subject reconstruction recursive, NUL-safe, blob-OID based, and exact for 0644/0755/symlinks; pinned `subjectCommit`/epoch and all hex/SRI digest encodings;
  4. required all evaluation/build/ISO/kit/NAR/closure work to use the filtered subject archive, with each excluded record class proven artifact-neutral;
  5. replaced the universal record shape with closed discriminated root, incident, intake/declaration, E/B/V/N/P, release, install/recovery, review, CI-policy, cold-test, inventory, and signing-request schemas, exact TTLs/signatures/namespaces/invalidation, and separate `signingAllowed`/`releaseAllowed` predicates;
  6. kept hardware evidence outside pure composition: both production slots start vendor-null, intake authorizes only a deterministic reviewed source patch, and a later declaration record authenticates that committed subject;
  7. separated always-runnable synthetic Intel/AMD tests from declaration-derived production host/vendor tests and prohibited synthetic V/cold-test evidence from promotion;
  8. completed the target-by-action guard matrix and per-capability NixOS/Darwin P sets, assigning all guards to todo 2 and all task-26 fixture code/tests to todo 24 before freeze;
  9. made task 7 directly reverify authenticated installability and full manifest/disk identity immediately before its sole Disko call;
  10. completed the durable cross-reboot rollback state table, boot-resume lock reconstruction, exact profile/boot/reboot effects, crash boundaries, and terminal/reissue behavior;
  11. fixed the classic systemd-boot ESP inventory to unique final paths, allocation-unit attainable thresholds, one maximum temporary allocation, one reserve, and no UKI/specialisations;
  12. specified local-console-only bootstrap password change, public-key SSH continuity, later four-proof lock, and signed recovery ordering;
  13. pinned the full Determinate/Nix attrs, revision, source NAR, filename/store/NAR/flat-hash bindings and Nix 2.34.8 payload;
  14. closed Qt mapping and scan semantics, retained authoritative `config.org` with offline deterministic tangle/characterization, and embedded exact package-exception ownership/version/platform/expiry rows;
  15. fixed exact workflow files/triggers/jobs/runners/timeouts/resources/action SHAs/required checks, introduced a separately delegated signed repository-policy record, and retained external-not-verified when GitHub enforcement is absent;
  16. moved every kit/projection/schema/validator/signing workflow into todo 24, then made todo 25 frozen-subject artifact/evidence only and todo 26 preexisting-validator/evidence only;
  17. added todo 1 and todo 12 as direct release dependencies, required two pre-signing frozen-subject reviews plus provider/auth/platform/ruleset gates, external signatures, exact-byte cold tests, and final host-key/user/sudo/root-password-KBI/recovery assertions.

## Round-5 preflight validation
- Template/header order: PASS; TL;DR remains first and no scaffold placeholder exists.
- Structure: PASS; 26 sequential todos, each with exactly one implementation boundary, parallelization/dependencies, references, acceptance, exact happy+negative commands, evidence path, and commit disposition.
- Dependency graph: PASS; matrix and per-todo edges are reciprocal and acyclic with deterministic topological order `3 2 1 4 5 6 11 7 8 9 13 12 15 10 16 18 17 19 21 22 14 23 20 24 25 26`.
- Coverage: PASS; all 73 P0/P1/I/D/POS IDs are present, including narrowed POS-01/POS-06.
- Existing references: PASS; 129 repository-local path/line anchors exist and are within file length; future paths appear only as explicit deliverables.
- Stale-contract scan: PASS; no caller-selected production anchor/time, unauthenticated consumer handoff, abbreviated Nix revision, old payload version, synthetic task-26 production happy path, source-changing post-freeze todo, or circular pre-signing `releaseAllowed` remains.
- Planner boundary: PASS; `git diff --check` and tracked `git status --short` are empty; plan/draft are globally ignored `.omo` artifacts.

## Approval gate
status: approved
Approved action: write and high-accuracy-review `.omo/plans/nix-config-machine-readiness.md` only. Product implementation remains unauthorized.

## Dual review round 5
- Native Momus `/root/momus_plan_review_round5`: **NOT OKAY**, eight blocker groups.
- Independent isolated `codex exec` session `019f5df3-1c00-7891-b158-2fff89f0a1b4`, model `gpt-5.6-sol`, reasoning `xhigh`, disposable workspace `/tmp/nix-plan-independent-review-r5.5YAO4O`: **blocking issues**, twenty-five groups.
- Consolidated corrections applied before round 6:
  1. closed genesis/root-key distribution, root-update key rotation, SSHSIG principal/namespace/public-key construction, platform verifier build manifests, exact conformance vectors, and reproducible external-verifier ceremony;
  2. replaced verify-then-shell handoff with a locked snapshot/sealed-FD supervisor ABI, fixed action executable/argv/environment, rollback-resistant clock/record locks, deterministic exit codes, and explicit after-snapshot mutation semantics;
  3. restricted excluded evidence descendants by path/type/mode/link count and made filtered subject, candidate HEAD, epoch, and every digest preimage exact;
  4. completed recursively closed record schemas for synthetic/production V, implementation, auth proof, direct/remote install, kexec, recovery, reviews, CI, inventory, nested arrays, timestamps, and signature semantics;
  5. removed fresh-install circularity with target-specific `signingAllowed`, `releaseAllowed`, exhaustive action formulas, release-gated promotion, and isolated VM auth-suite evidence;
  6. added firmware/microcode and conditional remote-continuity physical capabilities plus omission tests;
  7. repaired ESP math to retain all current unknown allocations and repaired rollback with exact paths, journals, roots, locks, intermediate-state reconciliation, atomic nonce exchange, and guarded GC;
  8. specified the root security wrapper/sentinel crash protocol, typed console recovery, four signed later-retirement proofs, exact machine schema, sanitized collector, and closed RFC6902 proposal paths;
  9. isolated SSH from hostile user/system config with `-F /dev/null` and explicit proxy/control/canonicalization/local-command rejection;
  10. corrected Helium's Linux+Darwin unfree scope, removed Qt helper exceptions in favor of eleven exact mapped launch tuples, and froze Emacs behavior with locked Nixpkgs/local commands plus exact lsp-volar revision/NAR;
  11. distinguished installer 3.21.5, Determinate Nix 3.21.5, and upstream Nix 2.34.8 with exact attr/derivation/filename/version contracts;
  12. replaced impossible GitHub runner capacities with provisioned self-hosted labels, locally staged verified installer/payload bytes, non-circular merge/nightly/release rules, canonical GitHub API evidence, and fixed no-follow artifact ingress;
  13. kept the known historical credential out of merge gating while retaining it as a signing prerequisite, added the implementation-principal record, standardized exact external markers, and required actual production kits/records for tasks 25/26 HAPPY.

## Round-6 preflight validation
- Template/header order: PASS; human TL;DR remains first and all scaffold headers retain canonical order.
- Structure: PASS; 26 sequential todos each retain implementation boundary, references, acceptance, exact happy/negative QA, evidence, and commit disposition; external modes are separately exact.
- Dependency graph: PASS; 26 reciprocal matrix rows are acyclic with deterministic topological order `3 2 1 21 4 6 5 11 13 23 15 18 7 22 17 19 20 8 12 14 9 10 16 24 25 26`.
- Coverage/references: PASS; all 73 canonical IDs remain mapped and all repository-local path/line references exist within file bounds.
- Round-5 blocker scan: PASS; exact root/verifier/supervisor/clock/schema/predicate/P/ESP/rollback/helper/machine/SSH/package/Qt/Emacs/Determinate/CI/ingress/external-production contracts are present and stale runner/helper/circular-auth strings are absent.
- Planner boundary: PASS; `git diff --check` is clean, tracked `git status --short` is empty, and only globally ignored `.omo` plan/draft artifacts changed.

## Dual review round 6
- Native Momus `/root/momus_plan_review_round6`: **NOT OKAY**, twelve blocker groups.
- Independent isolated `codex exec` session `019f5e18-cebd-7ad2-9fbc-04aba6116dac`, model `gpt-5.6-sol`, reasoning `xhigh`, disposable workspace `/tmp/nix-plan-independent-review-r6.KDbIPb`: **blocking issues**, twenty-five groups. Two transport preflights failed before model dispatch (non-Git directory, then globally ignored `.omo`); the single actual review process began only after the same workspace was initialized and force-added.
- Consolidated corrections applied before round 7:
  1. separated todo-2 verifier engine/schema ownership, todo-24 final action-map ownership, and todo-25 external anchoring; action descriptors now bind exact program/hash/NAR/closure/argv/environment/FD/caller contracts and callers never supply programs;
  2. made genesis/rotation executable with fixed root paths, two-custodian requests/approvals, root/update/bootstrap namespaces, nonce/version ordering, platform verifier builds/vectors, atomic anchor replacement and recovery;
  3. separated trusted release-runner record creation from local target/installer consumption, with exact host-local root wrapper/launchd helper, OOB trust-bootstrap media, one-use root-signed provisioning, initialized clock floor, records/ledgers, and installed-target inheritance;
  4. added locked Git/Nix/OpenSSH runtime identities, exact JSON/timestamp grammar, one resolved candidate OID, worktree/ref recheck, and recursively closed critical receipt/suite/result/proposal/workflow/ledger/bootstrap schemas;
  5. separated root objects, evidence common fields, and complete canonical unsigned attended/signing requests; closed recovery actions and added update-canary U;
  6. replaced conflicting target/action tables with one normative action matrix, release-gated real install, non-circular cold-test install, exact ESP/kexec/transaction/password/update/release/support action IDs, and distinct local transaction commit vs support promotion;
  7. made release envelopes/request/inventory/ingress/cold-test exact-set bound and separated request-time C from fresh publish-time C;
  8. replaced source disk identity with privacy-safe `diskSlot`, bound private K to target/declaration/intake/stable disk, held the opened block-device FD and locks through Disko, and tested by-id rebinding;
  9. bound endpoint/user/login fingerprint and absolute known-host contents, included full filtered bare Git subject on live media, and made kexec load/execute one-use protected actions;
  10. repaired rollback for the permitted Nix GC-root symlinks, exact active/journal/health schemas, per-effect crash reconciliation, sequential root/pointer updates, and guarded GC; bound ESP recovery to full measured calculation/inventory and journaled writes;
  11. defined console-recovery credential FD/journal/crash/replay protocol, typed network fallback/keyfile scope/redacted diagnostics, and exact hardware commit+tree proposal identities;
  12. made P mode-discriminated and closed, added per-capability runbook/archive/oracle/signer/stop-gate production procedures, and made todo 26 execute rather than assume records;
  13. defined U domain/path/native/VM/rollback evidence and exact update action formulas;
  14. made CI executable with exact job entrypoints/order, full checkout isolation, provisioned self-hosted wipe/network contracts, verified direct local Determinate installer/payload, persistent release receipt verification, non-circular branch/nightly/release rules, bounded tar expansion and exact signed-set equality;
  15. added theme asset/provenance and recursive launch-resolution schemas, split Emacs baseline/final/generated digests into two ordered atomic commits, and separated fixture markers for todos 1-24 from production HAPPY only in todos 25-26;
  16. made immutable historical-secret scanning merge-green but non-authorizing while signed incident I remains exclusively a signing/release prerequisite.

## Round-7 preflight validation
- Template/structure: PASS; canonical header order and 26 sequential todos remain; todos 1-24 each expose exact FIXTURE+NEGATIVE commands, todos 25-26 alone expose production HAPPY, and external cases have exact markers.
- Dependency graph: PASS after adding direct todo-2 -> todo-24 action-map dependency; reciprocal 26-row matrix remains acyclic with order `3 2 1 21 4 6 5 11 13 23 15 18 7 22 17 19 20 8 12 14 9 10 16 24 25 26`.
- References: PASS; every repository-local path/line anchor exists and is within file bounds.
- Round-6 blocker scan: PASS; no release-runner-only local authorization, universal-root common schema, caller-selected action program, ambiguous promote, Darwin Emacs mismatch, 40-hex tree mismatch, GitHub-hosted capacity, helper-exception Qt, or unqualified source-todo HAPPY remains.
- Planner boundary: PASS; `git diff --check` clean, tracked worktree clean, ignored `.omo` artifacts only.

## Dual review round 7
- Native Momus `/root/momus_plan_review_round7`: **NOT OKAY**, twenty blocker groups covering subject-independent action descriptors, request authorization, recursive schema/digest/time closure, named quorum hosts, disk/ESP/recovery execution, exact SSH/kexec state, update/CI/runbook/theme/Emacs contracts, and frozen-subject ancestry.
- Independent isolated `codex exec` session `019f5e31-6377-7be2-b119-59073d3e681c`, model `gpt-5.6-sol`, reasoning `xhigh`, disposable workspace `/home/mei/.cache/nix-plan-reviews/round7-work.IELbrt`: **blocking issues**, forty-one groups. Review completed with `REVIEW_RC=0`; receipt workspace `/home/mei/.cache/nix-plan-reviews/round7-home.vh5aPR`.
- Round-7 correction intent for round 8: remove the committed subject-bound action-map fixed point; close the external anchor/root/bootstrap/request-authorization ceremonies; replace every abbreviated schema, digest, timestamp, action, FD, workflow, runbook, and state contract with literal normative rows; name both x86 enrollment slots; define realistic by-id resolution and exclusive Disko execution; make release payload/inventory/envelopes non-recursive; make publication durable for later installs; make CI executable from a preinstalled bootstrap plus verified offline input bundle; and add an exact F2 invocation/marker and operator-authorization stop gate.

## Round-8 preflight validation
- Ownership/fixed-point: PASS; todos 2-24 commit only subject-independent descriptor fragments and manifest, while todo 25 alone generates the external subject-bound action map and anchors its digest after freeze.
- Trust/schema closure: PASS preflight; anchor/root/update/custodian/bootstrap/privilege/request-authorization/publication/digest/time/FD/action/record schemas and production commands are literal and recursively closed by contract.
- Install/recovery/platform closure: PASS preflight; by-id resolution uses `readlinkat` plus an FD-aware destructive adapter; ESP/rollback/GC/password/SSH/kexec/hardware/network/P/U/theme/Emacs contracts are explicit and two x86 slots are named.
- CI/release closure: PASS preflight; four workflows, literal labels/events/checks/timeouts/environments, preinstalled bootstrap, signed offline input bundle, actor ownership, non-recursive payload/envelope/ingress sets, and durable publication are specified.
- Structure: PASS; 26 sequential todos and four final lanes; fixture/negative commands for todos 1-24 and production happy/negative/external commands for 25-26.
- Dependency graph: PASS and reciprocal/acyclic; topological order `3 2 1 21 4 6 5 11 13 23 7 15 18 22 8 12 14 17 19 20 9 10 16 24 25 26`.
- References: PASS; 129 repository-local reference anchors exist.
- Planner boundary: PASS; `git diff --check` and tracked `git status --short` are clean; only ignored `.omo` artifacts changed.

## Dual review round 8
- Native Momus `/root/momus_plan_review_round8`: **NOT OKAY**, thirty-one blocker groups.
- Independent isolated `codex exec` session `019f5e50-6cb5-7fd3-9ea5-c45d3f4f2f6c`, model `gpt-5.6-sol`, reasoning `xhigh`, disposable workspace `/home/mei/.cache/nix-plan-reviews/round8-work.651OZE`: **blocking issues**, fifty-one groups. Initial transport with nix-profile Codex 0.142.2 was rejected before model dispatch because gpt-5.6-sol required a newer CLI; the actual single independent review used user-local Codex 0.144.3 against the same isolated committed input and completed successfully.
- Round-8 correction intent for round 9: close the full descriptor/platform ownership matrix and executable/FD ABI; split ordinary/evidence-descendant/update subject semantics; make genesis/rotation/bootstrap/signer/operator ceremonies non-circular and literal; replace global array/time/digest shorthand with exhaustive registries; close direct/remote/K/SSH/kexec/ESP/rollback/password branches; unify machine/intake/capability schemas; split update authorization/result and define new-subject rotation; make P commands/class quorum/packages/theme/Emacs/Determinate/CI bundle workflows literal; and define state-selected production/final external-not-verified outcomes.

## Round-8 consolidated corrections before round 9
1. Completed the exhaustive action/platform ownership matrix and realized descriptor ABI with executable-relative/store/hash fields, discriminated receipt/FD branches, sealed Linux snapshots, unlinked read-only Darwin snapshots, exact setuid/launchd installation manifests, and no caller-selected executable.
2. Split ordinary/evidence-descendant/update subject branches; fixed the pre-plan implementation baseline OID; defined filtered tree/archive/pack equations, merge-free signed implementation history, and explicit update candidate ancestry.
3. Closed OOB genesis, root rotation, bootstrap media, host bootstrap, root-bundle, signer namespace/key-custody, and operator-authorization ceremonies; added a tenth independent install authorizer and exhaustive mutation authorization table.
4. Replaced global collection/time shorthand with a mandatory array-cardinality registry, per-record time ordering, and a digest registry that now covers K, update authorization/results, offline bundles, artifact/envelope sets, bootstrap bundle manifests, executables, closures, themes, Emacs, and all named result preimages.
5. Made request IDs, proposals, request authorization, pre-sign inventory, artifact digests, S, ingress, isolated VM disk authorization, publication, fixed signer inbox/output paths, and later-install publication semantics exact and non-recursive.
6. Closed direct/remote install branches, direct K and remote subaction ledgers, FD-native destructive disk access, strict SSH port/auth vectors, kexec stage deadlines, ESP calculation/pruning, rollback failure states, recovery transitions, and 192-bit yescrypt console recovery.
7. Unified canonical machine/source/declaration projection, derived capability declarations, sanitized hardware intake patching, two literal x86 host slots, and exact class quorum evaluation with no aggregate P.
8. Split pre-action update authorization UA, two scoped update-review records, and terminal update result U; old-map action predicates consume UA, while root rotation and new-subject release/promotion require U.
9. Added the exact package-exception schema and closure inventory, exact 25-row physical capability command/assertion matrix, per-platform 22-key Qt map with typed N/A branches, theme digest/provenance equations, and a non-self-referential two-commit Emacs baseline/manifest protocol.
10. Made Determinate bootstrap executable only on x86_64-linux and aarch64-darwin with exact argv/environment/effect manifests, offline payload/receipt verification, and explicit aarch64-linux denial.
11. Repaired CI with the missing history-security job, exact five required checks, per-job command manifests, signed offline input/store/tool bundles, isolated provisioning signer, bounded checkout/API network windows, permanent build egress denial, full-history known-exposed equality, and signed policy-proxy C records.
12. Made fixture/happy/external modes authenticated-state selected; production F2 cannot PASS without two frozen-subject reviews and has a separate non-promoting NOT VERIFIED lane. Clarified pre-freeze internal review versus post-freeze signed R ordering.

## Round-9 preflight validation
- Structure: PASS; 26 sequential todos and four final lanes remain, with state-selected fixture/negative/happy/external outcomes.
- Dependency graph: PASS; 26 reciprocal matrix rows are acyclic with deterministic topological order `3 2 1 4 5 6 11 7 8 9 13 12 15 10 16 18 17 19 21 22 14 23 20 24 25 26`; each todo's inline blockers equal the matrix.
- References: PASS; 121 concrete repository-local path/line anchors exist and all are within file bounds; future deliverables remain explicit rather than falsely pre-existing.
- Stale-contract scan: PASS; no `known-unrevoked`, generic four-job command manifest, committed Emacs subject self-reference, or U-as-pre-action authorization remains.
- Planner boundary: PASS; tracked `git status --short` and `git diff --check` are clean, plan has no trailing whitespace, and only ignored `.omo` plan/draft artifacts changed.

## Dual review round 9
- Native Momus `/root/momus_plan_review_round9`: **NOT OKAY**, 52 blocker groups. Central diagnosis: the custom production PKI/action-map/privileged ABI was chronologically circular and far more complex than the requested configuration-hardening program.
- Independent isolated Codex CLI session `019f5e76-cee3-7e61-a673-32b8f41b3a8f`, model `gpt-5.6-sol`, reasoning `xhigh`, workspace `/home/mei/.cache/nix-plan-reviews/round9-work.uLmhhu`: **NOT OKAY**, 90 blocker groups. The first isolated HOME transport failed authentication before model dispatch; the single actual review used `CODEX_HOME=/home/mei/.codex`, completed with `REVIEW_RC=0`, and confirmed the same architectural overreach.
- Round-9 decision: do not patch the invented PKI/privilege framework. Replace it with a smaller standard-tool plan: Git/Lore commits, JSON Schema for non-authorizing evidence, explicit TTY-gated destructive scripts, pinned OpenSSH signatures only for offline bundle bytes, ordinary Nix store/NAR verification, no CI-held signing key, and support derived from evidence rather than mutable privileged state. This deletes the circular trust/action-map/descriptor/FD/root-key surface while preserving every researched product requirement and external/physical gate.

## Round-10 simplified-plan preflight
- The user approved the recommended defaults; approval remains planning-only and product implementation is still unauthorized.
- Replaced the rejected custom PKI/action-map/privileged ABI with standard Git/Lore review, non-authorizing JSON Schema evidence, attached-TTY destructive confirmation, ordinary Nix closure verification, and OpenSSH signatures only at the remote-install/offline-release boundaries.
- Corrected the x86 qualification rule to require the two-host vendor set `{GenuineIntel,AuthenticAMD}` without preassigning a vendor to a hostname.
- Added one normative fixture/negative/status harness contract, per-task evidence paths, explicit repository references for all 26 tasks, and a missing Task-26 verification contract.
- Fixed the release verifier executable paths, remote install-authorizer boundary, four required PR checks plus an evidence-gated optional native Darwin job, exact Kitty colors, and the non-recursive offline-kit `SHA256SUMS` generation/member equation.
- Structural preflight: PASS; 26 sequential todos, all with references/verification/commit disposition; reciprocal acyclic DAG order `1 3 2 4 5 6 11 7 8 9 13 12 15 10 16 18 17 19 21 22 14 23 20 24 25 26`; all 73 claim IDs mapped; no trailing whitespace.
- Complete-plan SHA-256 submitted for round 10: `95064d5bb6391ca0462c905d2ccce02c5f79e67ba702d601e9d100914fdc1169`.
- Planner boundary: tracked `git status --short` and `git diff --check` are clean; only globally ignored `.omo` plan/draft artifacts changed.

## Dual review round 10
- Native Momus `/root/momus_plan_review_round10`: **NOT OKAY**, eleven blocker groups.
- Independent isolated Codex CLI session `019f5e96-d449-7f21-b30e-4db293cf5e7a`, model `gpt-5.6-sol`, reasoning `xhigh`, workspace `/home/mei/.cache/nix-plan-reviews/round10.nWHlkX`: **NOT OKAY**, twenty-two blocker groups; completed with `REVIEW_RC=0`.
- Required round-11 corrections: separate five public outputs from the internal x86 qualifier; repair Task-1 harness chronology; use discriminated evidence records and `sourceGitCommit`; pin JSON Schema draft/validator and digest encodings; close release-key disabled/enrolled branches; enumerate package exceptions, host enums, assets, Noctalia and Action pins; permit/redact only the committed disk selector; require a local VT; define fresh-host key provisioning; replace the impossible kexec tmpfs handoff and vague remote deadlines; conservatively bound ESP writes; split rollback transitions; split direct/remote install capabilities; define subject-scoped status outcomes; bind exact Niri portal mapping; externalize mutable CI/provider claims; move all Task-25/26 tooling before freeze; include transitive flake/test closures in x86-only kits; remove undefined signature/shell-parity cases; and make Task 11 depend on Tasks 7/8 rather than the reverse.

## Round-10 consolidated corrections before round 11
1. Distinguished the five exact public flake outputs from `nixosConfigurations.nixos-x86-qualifier`; the qualifier is internal but participates in every closure/policy/theme/launcher/Disko check.
2. Made Task 1 create/self-test its minimal runner and evidence ignore before its first commit; Task 6 now extends rather than retroactively supplies the harness.
3. Replaced the universal evidence object with a Draft-2020-12 discriminated union using locked check-jsonschema 0.37.3; defined `sourceGitCommit`, restricted evidence-only descendants, exact record keys, raw lock hashing, NAR base16 conversion, and closure-digest bytes.
4. Closed the release state: because no production key was supplied, the committed default is publication-disabled; fixture keys cannot populate production paths, and later enrollment requires a reviewed pre-freeze product change.
5. Replaced prose package counts with a deterministic pre-policy inventory extractor across five public outputs plus the qualifier, fixed exception metadata, removed the stale pnpm insecure allowance, and made any genuine insecure dependency require a new approved amendment.
6. Closed host/profile/capability enums and cross-field rules, permitted only the enrolled disk-by-id source field as a raw identifier, required an actual local VT/root/no-SSH/no-sudo direct-install context, and separated `install.direct` from `install.remote`.
7. Added the attended offline final-host/agenix identity ceremony; removed the impossible kexec key handoff by hard-denying kexec and supporting only signed-manifest no-kexec remote installs with a controller-local nonce ledger and bounded probes.
8. Replaced impossible exact FAT updater modeling with a conservative cluster/metadata/reserve bound; split `boot` and `switch` rollback transitions, bounded health probes, rejected degraded by default, and moved login proof to physical evidence.
9. Pinned Noctalia revision/NAR/lock argv; made the portal interface-to-backend map single-valued; pinned theme sources/hashes/licenses; replaced unattributed/restrictive active artwork with a repository-authored CC0 managed wallpaper while retaining an attended signed extra-files path for personal wallpapers.
10. Defined exact GitHub jobs, required checks, hosted Linux/ARM runners, checkout/Determinate action SHAs, actionlint version, external GitHub-state evidence, exact current-CI predicate, and the security-review/CODEOWNERS split.
11. Moved every Task-25/26 builder/verifier/runbook/recorder/status test into Task 24 before freeze. Scoped kits to x86 NixOS; archived every transitive flake input and cold-test closure; used a pre-provisioned harness with a fresh alternate store; retained Tasks 25-26 as execution/evidence-only.
12. Defined all status owners/subjects and valid/absent/invalid markers, deterministic F4 aggregation, Task-25 publication success, exact Bash/Fish parity, and conditional final success semantics.

## Round-11 preflight validation
- Structure: PASS; 26 sequential todos, all with references, agent fixture+negative verification, and commit disposition.
- Dependency graph: PASS; reciprocal and acyclic with order `1 3 2 4 5 6 7 8 9 13 11 12 15 10 16 18 17 19 21 22 14 23 20 24 25 26`; Task 11 now follows Tasks 7/8/13 and Task 24 owns all pre-freeze release/qualification tooling.
- Coverage: PASS; all 73 claim IDs remain mapped.
- Planner boundary: PASS; tracked `git status --short` and `git diff --check` are clean; only ignored `.omo` artifacts changed.
- Complete-plan SHA-256 submitted for round 11: `0cd12326a57b888deeba755a248861a560fbd376ce11579866f7ce15d1589d10`.

## Dual review round 11
- Native Momus `/root/momus_plan_review_round11`: **NOT OKAY**, seven blocker groups.
- Independent isolated Codex CLI session `019f5eaf-dcde-7e02-8e2d-fad3d44df34d`, model `gpt-5.6-sol`, reasoning `xhigh`, workspace `/home/mei/.cache/nix-plan-reviews/round11.JmGlNG`: **NOT OKAY**, sixteen blocker groups; completed with `REVIEW_RC=0`.
- Round-12 correction scope: align waves with the actual DAG; permit only the immutable known-exposed history occurrence; eliminate the accidental supportRegistry public output; close and singly own incident/GitHub/publication/qualification schemas and selectors; split check-jsonschema commands; add literal ARM evaluation authority; correct Task-1 marker; bound/narrow the Disko race guarantee; make password retirement use live checks rather than evidence; preflight identities before erasure; disable Determinate diagnostics; unify wallpaper schema; replace command manifests/registries with literal scripts; keep CI on source/fixture gates rather than production bytes; canonicalize checksum paths; define release-key status; make intake optional/pending; and specify F4 precedence/composition.

## Round-11 consolidated corrections before round 12
1. Replaced prose waves with a dependency-valid topological sequence and moved Task 13 before Task 7 so identity media is verified before any erase confirmation.
2. Narrowed the plaintext prohibition to allow exactly the immutable `known-exposed` baseline history match while forbidding current/new/archive/kit/store/log/argv/env occurrences.
3. Removed `supportRegistry` as a public flake output; internal declaration checks now use `tests/readiness/support-registry.nix`.
4. Made Task 2 the sole owner of ten concrete closed Draft-2020-12 schemas with exact common/type fields, enums, selectors, TTLs, GitHub checks/labels, embedded publication signature, and qualification subjects. Split metaschema and instance validation into valid check-jsonschema commands.
5. Corrected Task-1's exact provider marker and added a literal ARM evaluation host record.
6. Added a 120-second direct confirmation, zero-Disko-call guarantees only before the one synchronous invocation, explicit post-start hotplug residual risk, and Task-13 identity preflight before confirmation plus post-mount revalidation/provisioning for direct and remote modes.
7. Made password retirement consume only fixed live checks/local confirmation, never non-authorizing records; disabled Determinate diagnostics and fail any network socket.
8. Unified personal wallpaper import under one exact companion schema and attended license input.
9. Replaced command manifests/action registries with literal per-job/per-capability scripts; the recorder is passive. CI now verifies source/gates/fixture signatures only, while attended Task 25 exclusively verifies production bytes.
10. Made physical intake optional: accepted patches land pre-freeze; absence keeps hosts pending/NOT VERIFIED without blocking F1-F3.
11. Canonicalized bare checksum paths with `%P`, prohibited `.`/`..`, and required bidirectional regular-file equality.
12. Added Task-11 release-key status and fully specified F4 call order, composite prerequisites, one final marker per subject, and precedence `INVALID > NOT VERIFIED > QUALIFIED`.

## Dual review round 12
- Native Momus `/root/momus_plan_review_round12`: **NOT OKAY**, four blocker groups: concrete evidence-schema closure, support-schema ownership, remote destructive authorization, and two-channel password retirement.
- Independent isolated Codex CLI session `019f5ec0-7701-71b2-b3b6-39edc0095f5b`, model `gpt-5.6-sol`, reasoning `xhigh`, workspace `/home/mei/.cache/nix-plan-reviews/round12.tUGvt3`: **NOT OKAY**, fourteen blocker groups; completed with `REVIEW_RC=0`.
- Round-13 correction scope: distinguish five release configuration paths from ordinary flake outputs and the sixth non-release qualifier; make `common.json` shared definitions and every concrete evidence record/selector/TTL executable; close Task-1 tools/trailer, target-side remote replay, two-level ISO signing and removable-media writing, initial password provisioning and SSH-to-local-VT retirement, precise offline-network semantics, PR/push CI history and installer pins, Darwin runner isolation/hash tooling, and independently observed publication/handoff proof.

## Round-12 preflight validation
- Structure: PASS; 26 sequential todos with references, fixture+negative verification, and commit disposition.
- Dependency graph: PASS; reciprocal and acyclic, with Task 13 now a direct prerequisite of Task 7.
- Coverage: PASS; all 73 claims remain mapped.
- Stale-contract scan: PASS; no supportRegistry public output, combined metaschema/instance command, command registry/manifest dispatch, undefined external-signature record, or recursive `./` checksum path remains.
- Planner boundary: PASS; tracked status/diff-check clean; only ignored plan artifacts changed.
- Complete-plan SHA-256 submitted for round 12: `c008289f9f1d71baa05c2f21ef1d55c1afc14cc216075527ac94237ebd0ab069`.

## Round-13 preflight validation
- Structure: PASS; 26 sequential todos, 26 reference blocks, 26 explicit verification blocks, and complete commit dispositions.
- Dependency graph: PASS; reciprocal and acyclic with deterministic topological order `1 3 2 4 6 5 13 15 18 21 7 17 19 22 23 8 9 11 12 14 20 10 16 24 25 26`.
- Contract closure: PASS preflight; exact five release configuration paths plus sixth non-release qualifier, nine concrete evidence schemas, target-side remote subaction claims, two-level ISO signing/media writing, two-channel password retirement, bounded network semantics, PR/push CI, Darwin isolation/hash tooling, and independent publication proof are specified.
- Planner boundary: PASS; tracked `git status --short` and `git diff --check` are clean; only ignored `.omo` artifacts changed.
- Complete-plan SHA-256 submitted for round 13: `f4e0179af5134a18264fa8668e3da34a6d96fd68a2cadb7b4752cbc060bfe45c`.

## Dual review round 13
- Native Momus `/root/momus_plan_review_round13`: **NOT OKAY**, seven blocker groups.
- Independent isolated Codex CLI session (workspace `/home/mei/.cache/nix-plan-reviews/round13.arYWg6`, isolated home `/home/mei/.cache/nix-plan-reviews/round13-home.2EhZBH`), model `gpt-5.6-sol`, reasoning `xhigh`: **NOT OKAY**, nine blocker groups; completed with `REVIEW_RC=0` after transport reconnection.
- Round-14 correction scope: close host-to-target mappings; narrow remote restart guarantees; assign the inner/outer ISO signing sequence; give Task 14 ARM CI-staging ownership; enumerate every CI job/runner/timeout/concurrency rule; define observation envelopes; restore Darwin Spotlight; make the early harness generic; repair Task-10 dependencies; close network fallback types; authenticate external evidence with role-separated standard OpenSSH signatures; close record graph/time invariants; disable every unintended SSH method; and reject unsafe filesystem/archive kit members before action.

## Round-14 preflight validation
- Structure: PASS; 26 sequential todos, each with repository references, an explicit verification block, and commit disposition.
- Dependency graph: PASS; reciprocal and acyclic with deterministic topological order `1 3 2 4 6 5 13 15 18 21 7 17 19 22 23 8 9 11 12 14 20 10 16 24 25 26`.
- Contract closure: PASS preflight; exact target mapping, bounded remote replay semantics, two-layer ISO signing, dual-architecture CI payload provenance, literal CI jobs, observation envelopes, full Darwin checklist, generic early harness, exact capability set, role-signed external records, graph/time invariants, closed SSH methods, and safe kit traversal are specified.
- Planner boundary: PASS; tracked `git status --short` and `git diff --check` are clean; only ignored `.omo` artifacts changed.
- Complete-plan SHA-256 submitted for round 14: `6d2fd295250bfe252d46b0c68c0e4a6d3f8d214f6a6eb2a4d83b5e9f3da46f9a`.

## Dual review round 14
- Native Momus `/root/momus_plan_review_round14`: **NOT OKAY**, five blocker groups.
- Independent isolated Codex CLI session `019f5f04-ebdf-77f3-a541-b9a27e7a9b31`, model `gpt-5.6-sol`, reasoning `xhigh`, workspace `/home/mei/.cache/nix-plan-reviews/round14.ZT8i7i`: **NOT OKAY**, eight blocker groups; completed with `REVIEW_RC=0`.
- Round-15 correction scope: keep Determinate payload evaluation isolated from root flake inputs; exempt evaluation-only ARM from installable-network invariants; retain the changed local-console password while retiring only bootstrap state; make production CI staging disabled/NOT VERIFIED until reviewed external enrollment; sign rather than byte-derive all records; anchor freshness to underlying events; reject duplicate/noncanonical JSON; close/canonicalize the install manifest and clocks; enumerate SSH users/keys/host keys/password transition; descriptor-bind disks/media; snapshot handoff bytes before use; and directly execute exact staged installer binaries instead of trusting installer-action defaults.

## Round-15 preflight validation
- Structure: PASS; 26 sequential todos, each with references, explicit verification, and commit disposition.
- Dependency graph: PASS; reciprocal and acyclic with order `1 3 2 4 6 5 13 15 18 21 7 17 19 22 23 8 9 11 12 14 20 10 16 24 25 26`.
- Contract closure: PASS preflight; isolated upstream flake evaluation, ARM-role exemption, retained console recovery, disabled external staging, signed/recomputed records, event-anchored TTL, duplicate-rejecting canonical JSON, closed install manifest, exact SSH stages, FD-bound destructive I/O, safe handoff snapshot, and direct verified installer invocation are specified.
- Planner boundary: PASS; tracked `git status --short` and `git diff --check` are clean; only ignored `.omo` artifacts changed.
- Complete-plan SHA-256 submitted for round 15: `a63b7ddd80caa75dac18a5594798161161627046ac8f889d8c523e56ee2a4da6`.

## Dual review round 15
- Native Momus `/root/momus_plan_review_round15`: **NOT OKAY**, three blocker groups: server-side forced-command confinement, reboot-proven rollback commit, and a real-tool-compatible stable disk-node ABI.
- Independent isolated Codex CLI session `019f5f32-6b2c-7203-a1fd-f6ba002f59a5`, model `gpt-5.6-sol`, reasoning `xhigh`, workspace `/home/mei/.cache/nix-plan-reviews/round15.hiJzLE`, isolated home `/home/mei/.cache/nix-plan-reviews/round15-home.Cp8l0N`: **NOT OKAY**, eleven blocker groups; completed with `REVIEW_RC=0`.
- Round-16 correction scope: make pre-Task-2 incident output non-authorizing; close task/final result schemas; enumerate every install/auth/physical/Darwin observation and promotion predicate; define canonical declaration/intake digests; close remote signature/endpoint/lifetime/kit boundaries; restrict both password-transition and temporary-key servers; require a distinct boot and exact candidate/previous generation for commit/rollback; adapt real Disko tools to private descriptor-bound block nodes; commit public immutable CI-staging URLs only when enrolled; add a distinct remote qualification claim/terminal; and make cross-platform F4 aggregate signed native validation rather than claiming foreign closure recomputation.

## Round-15 consolidated corrections before round 16
1. Made Task 1's first incident commit always `NOT VERIFIED` and defined closed task/final result files with exact cases, markers, exits, digests, and six protected-action counters.
2. Added a closed observation-envelope `oneOf` table for direct/remote install, auth, all eighteen physical capabilities, and all nine Darwin checks, including exact fields, PASS predicates, script bindings, promotion rules, and connector semantics.
3. Defined one canonical host declaration projection/digest and a source-controlled, digest-linked, pointer-allowlisted RFC 6902 intake artifact.
4. Closed the remote install manifest around canonical literal IP/port endpoints, exact `<manifest>.sig`, a declaration-owned allowed-signers principal, a framed password-transition transport, pre-action verification, a 15-minute start authorization, and a fsynced 60-minute monotonic transaction.
5. Confined password transition with server ForceCommand and confined the temporary key with `restrict`, a manifest-bound dispatcher, a three-token zero-argument command language, and explicit shell/SFTP/SCP/forwarding/direct-device/kexec denial.
6. Replaced ambiguous by-id FD prose with safe symlink resolution plus held-descriptor identity and private root-only block nodes consumed by the real rendered Disko/sfdisk/mkfs stack under syscall tracing.
7. Required rollback transactions to record the originating boot ID, exact candidate/previous system/NAR/closure, and to commit/roll back only after a distinct boot into the exact recorded generation.
8. Split immutable `host-install-metadata.json` in Git/ISO/kit from the post-live-preflight ephemeral signed remote authorization manifest.
9. Required enrolled CI staging to commit public immutable content-addressed HTTPS URLs while keeping only upload credentials outside Git/CI.
10. Added `claim={host,install.remote}`, exact remote component sets, separate `status-remote` terminals, and clarified that F4 host/class/Darwin qualification does not silently promote the experimental remote lane.
11. Made platform-native validators recompute closure/check facts and sign native records; cross-platform F4 verifies their canonical signatures/evidence/component graph without pretending to realize foreign closures.

## Round-16 preflight validation
- Structure: PASS; 26 sequential todos, 26 reference blocks, 26 explicit verification blocks, and complete commit dispositions.
- Dependency graph: unchanged, reciprocal, and acyclic with deterministic order `1 3 2 4 6 5 13 15 18 21 7 17 19 22 23 8 9 11 12 14 20 10 16 24 25 26`.
- Contract closure: PASS preflight; exact observation, declaration, remote authorization/server, private device-node, reboot/rollback, immutable-kit, staging, remote-qualification, and cross-platform aggregation contracts are now specified.
- Planner boundary: PASS; tracked `git status --short` and `git diff --check` are clean; plan has no trailing whitespace and only ignored `.omo` artifacts changed.
- Complete-plan SHA-256 submitted for round 16: `8e8308adac7950f9bd7f09931646ae27c1f853abf309df18c9e5ea5c96ab0f51`.

## Dual review round 16
- Native Momus `/root/momus_plan_review_round16`: **NOT OKAY**, five blocker groups: normal udev by-id traversal, no-PTY remote confirmation, record/envelope closure, missing enrolled disk/public-trust inputs, and transaction-bound non-Wi-Fi transport proof.
- Independent Codex CLI workspace `/home/mei/.cache/nix-plan-reviews/round16.LYSB2d`, isolated home `/home/mei/.cache/nix-plan-reviews/round16-home.Kd3Vfr`, model `gpt-5.6-sol`, reasoning `xhigh`: **INVALID REVIEW TRANSPORT**, `REVIEW_RC=0`. The process inherited `/home/mei/nix-config` instead of entering the frozen workspace and correctly refused to review an absent committed `PLAN.md`; no approval was claimed and no replacement reviewer was spawned in round 16.
- Round-17 correction scope: allow normal relative udev symlinks while constraining final resolution beneath `/dev`; move remote human approval to a pinned local-VT broker compatible with `PermitTTY no`; bind records one-to-one to exact hashed observation envelopes; enroll sanitized disk expectations and public authorizer/login/final-host trust; bind the signed manifest and live SSH route to one non-Wi-Fi transport; and make a remote qualification depend solely on that transaction-complete remote install envelope rather than unrelated availability evidence.

## Round-16 consolidated corrections before round 17
1. Replaced the impossible by-id target rejection with `/dev`-FD `openat2(RESOLVE_BENEATH|RESOLVE_NO_MAGICLINKS)`, explicit whole-disk/sysfs checks, and pre/post major/minor/path equality; normal `../../<device>` links are positive fixtures.
2. Added a root-only single-request broker that pins the initiating active local VT and installer boot, reads each exact confirmation locally, and emits one in-memory sequence/transaction/deadline-bound approval for atomic dispatcher consumption; SSH remains no-PTY.
3. Added required `{path,sha256,checkId}` envelope references to install/auth/physical records and exactly nine to Darwin; validators parse referenced envelopes, enforce one-to-one selector binding, and never trust duplicated observations.
4. Extended the declaration digest with closed storage expectations and `publicTrust`; Task 13 owns public/private correspondence plus read-only disk-fact extraction, and Task 15 owns the reviewed intake patch.
5. Added signed `transportCapability`, live socket-route controller/path-digest proof, reroute rejection, and transaction binding to the remote manifest/envelope. Remote qualification now contains exactly that complete remote install record, preventing cross-run physical-record substitution.
6. Kept runtime installer-host and temporary install-key identities ephemeral while requiring manifest authorizer/permanent-login/final-host facts to match the reviewed declaration.

## Round-17 preflight validation
- Structure: PASS; all 26 tasks retain references, verification, and commit disposition, plus four final lanes.
- Dependency graph: unchanged, reciprocal, and acyclic; Task 13 now explicitly implements the shared read-only device resolver before Task 7 adds destructive private nodes.
- Contract closure: PASS preflight for by-id traversal, VT authorization, record-envelope mapping, disk/public-trust enrollment, transport proof, and remote qualification.
- Planner boundary: PASS; tracked status/diff-check clean, no trailing whitespace, ignored `.omo` artifacts only.
- Complete-plan SHA-256 submitted for round 17: `6d035345887747c1f37570d12267c703370b1919b723abd36e4bc95008a8ebac`.

## Dual review round 17
- Native Momus `/root/momus_plan_review_round17`: **NOT OKAY**, four blocker groups: canonical intake paths, observable firmware failure count, diagnostic/observation schema parity, and boot-bound pre-persistence replay denial.
- Independent isolated Codex CLI session `019f5f55-65d3-7653-a3b2-240d22bdab39`, model `gpt-5.6-sol`, reasoning `xhigh`, workspace `/home/mei/.cache/nix-plan-reviews/round17.PYADI7`, isolated home `/home/mei/.cache/nix-plan-reviews/round17-home.J2JTSZ`: **NOT OKAY**, seven blocker groups; completed with `REVIEW_RC=0`.
- Round-18 correction scope: add runtime install/host public keys and per-boot binding to the signed manifest; unify declaration/intake object paths and patch operations; serialize Task 13 before Task 15; make rollback end restored on the qualified candidate with exact journal/digests; close direct/remote, firmware, Wi-Fi/local-console, and DDC predicates; add explicit GitHub workflow/merge/push events; and require uniquely bound Darwin runner pre-attestation plus post-run destruction receipt.

## Round-17 consolidated corrections before round 18
1. Added signed canonical temporary-install and installer-host public keys/fingerprints plus installer boot ID; controller/target prove matching private keys, construct exact HostKeyAlias known-hosts bytes, and reject an old manifest after any reboot.
2. Defined one exact machine object for evaluation, digest, and intake; limited patches to sorted `add|remove|replace`, forbade `from`/move/copy/test/parent replacement, and aligned every mutable top-level path.
3. Added Task 13 as an explicit Task-15 dependency and repaired waves/block reciprocity.
4. Made NixOS rollback qualification a three-boot candidate→previous→candidate drill tied to the Task-9 journal and exact path/NAR/closure, ending live on candidate; applied the same non-no-op rollback/restoration binding to Darwin.
5. Split direct/remote null/boolean constants, added sanitized missing-firmware count, split Wi-Fi fields, aligned local-console diagnostics, and closed DDC char-device/sysfs/VCP operations and restoration.
6. Added PR workflow-event, actual-merge, and main-push timestamps plus exact checked-SHA/order/24-hour relationships.
7. Replaced reusable Darwin labels/pre-only proof with a unique attestation label/instance/image and an independently observed post-job clean-workspace/destruction/deregistration receipt bound to run/job/commit.

## Round-18 preflight validation
- Structure: PASS; 26 tasks, 26 reference blocks, 26 verification blocks, complete commit dispositions, and four final lanes.
- Dependency graph: PASS; reciprocal and acyclic with Task 13 before Task 15 and deterministic waves.
- Contract closure: PASS preflight for runtime SSH keys/boot, intake, rollback, observations, GitHub event timing, and Darwin runner lifecycle.
- Planner boundary: PASS; tracked tree and diff-check clean, no trailing whitespace, ignored `.omo` artifacts only.
- Complete-plan SHA-256 submitted for round 18: `cfed46dc22f8f83992e478a8ae385289a3d21cc9bb019e4296d89bf82c2df9dd`.

## Dual review round 18
- Native Momus `/root/momus_plan_review_round18`: **OKAY** with no blockers.
- Independent isolated Codex CLI session `019f5fa0-134f-7cd3-a1dc-7dd50bd701dd`, model `gpt-5.6-sol`, reasoning `xhigh`, workspace `/home/mei/.cache/nix-plan-reviews/round18.pdCJE2`, isolated home `/home/mei/.cache/nix-plan-reviews/round18-home.fEJeXq`: **NOT OKAY**, eleven blocker groups; completed with `REVIEW_RC=0`.
- Round-19 correction scope: make hardware predicates declaration-driven; reject every degraded systemd state; close recipient/ciphertext and crash-safe secret staging; specify the direct-install transaction; join publication, media, signer, final-host identity, and direct-install evidence exactly; require externally observed release/bootstrap enrollment; structure the fresh-medium handoff proof; make ISO/kit bytes reproducible; bound rollback retention/abandonment; define the F3 isolated-store universe; and keep raw hardware locators out of committed evidence.

## Round-18 consolidated corrections before round 19
1. Extended the canonical machine projection and intake allowlist with closed firmware/network/GPU/DDC declarations, public trust, secret recipients, and ciphertext digests; physical predicates now compare sanitized observations to those declarations.
2. Made any systemd state other than literal `running` fail instead of permitting a configurable degraded-unit allowlist.
3. Defined exact age recipient/decrypt equality plus length-framed, root-owned, fsynced, atomically renamed secret staging with an idempotent early-activation journal and crash/retry tests.
4. Added a fsynced direct-install journal with a random transaction ID, exact ordered states, target copy, mutation/replay rejection, and terminal boot verification.
5. Bound direct installation and F4 to the exact ISO, embedded payload manifest, enrolled non-fixture release signer, declaration, closure, and declared/installed final SSH host key.
6. Added closed dual-signed `release-enrollment` and `bootstrap-staging` records; local consistency alone remains NOT VERIFIED and malformed or mismatched observations are INVALID.
7. Added a closed `publication.handoff` envelope from an independently retrieved fresh-medium copy and exact publication/direct-install joins.
8. Fixed deterministic ISO and kit construction: pinned tools and literal argv, normalized epoch/locale/ownership/modes/compression, sorted canonical members, and two clean-store byte-equality runs.
9. Defined canonical current/recovery GC roots, two-generation retention, a 30-day abandoned-transaction threshold, and a typed local-VT abandonment ceremony.
10. Defined F3 as an exact bidirectionally manifested fresh isolated store; a separate read-only global-residue scan is non-normative and never deletes anything.
11. Restricted committed evidence to sanitized enums/counts/digests; raw I2C paths, interfaces, PCI/MAC/SSID/IP, serial/DMI values, and free-form tool output remain native-validator inputs only.

## Round-19 preflight validation
- Structure: PASS; 26 sequential tasks retain references, explicit fixture/negative verification, commit disposition, and four final verification lanes.
- Dependency graph: PASS; reciprocal and acyclic; destructive, release, publication, and qualification steps consume their declared prerequisites.
- Contract closure: PASS preflight for declaration-driven physical checks, health, secret staging, direct transactions, external enrollment, reproducible artifacts, publication handoff, rollback retention, F3 store scope, and sanitized evidence.
- Planner boundary: PASS; tracked `git status --short` and `git diff --check` are clean; only ignored `.omo` planning artifacts changed.
- Complete-plan SHA-256 submitted for round 19: `5bebdead7c327f0670e2dcc63f15917226ff6668c15b5709474e12dbef36d642`.

## Dual review round 19
- Native Momus `/root/momus_plan_review_round19`: **NOT OKAY**, nine blocker groups: foreign-platform F3 scope, firmware union/cardinality, rollback-drill reachability, direct private-identity staging, signature predicate, bootstrap observation shape, GitHub schema closure, and runbook closure.
- Independent isolated Codex CLI session `019f5ffc-b71e-7bf0-b745-b77698ee9eb0`, model `gpt-5.6-sol`, reasoning `xhigh`, workspace `/home/mei/.cache/nix-plan-reviews/round19.ON2wNF`, isolated home `/home/mei/.cache/nix-plan-reviews/round19-home.1I1TfN`: **NOT OKAY**, twelve blocker groups; completed with `REVIEW_RC=0`.
- Round-20 correction scope: close every platform-tagged host union and Darwin declaration; reconcile all hardware predicates; define byte-exact enrollment/GitHub/publication/runbook evidence; prove disk/boot postconditions; authenticate the remote installer and locally preloaded provisioning payload; add a reachable attended rollback drill; break bootstrap's source cycle and supply an authenticated pre-Nix verifier; narrow F3 to realizable x86 bytes plus native Darwin evidence; close final-lane joins; and eliminate ambient deterministic-build inputs.

## Round-19 consolidated corrections before round 20
1. Defined disabled/enrolled variants for boot, storage, public/secret trust, devices, capabilities, remote install, and platform evidence across installable x86, evaluation-only ARM, and Darwin records.
2. Reconciled firmware as a reason-bearing tagged union, required a nonempty installable-host firmware inventory, added exact power-daemon and I2C/sysfs declaration fields, and aligned network observation types.
3. Added source-derived Darwin network/TCC/app/theme/wallpaper/Emacs declarations and a fsynced attended activation/rollback/restoration journal with a native zero-match closure scan.
4. Closed bootstrap system rows, all GitHub nested objects/conditionals, publication tree/member/tool/cold-store digests, safe manifest/ISO parsing, and exact runbook rows/argv/digest mappings.
5. Added post-boot root/ESP parent-disk proof plus GPT, exact 1 GiB FAT32 ESP, ext4, no swap/encryption, UEFI, Secure Boot-off, and ten-entry predicates; fixed disk-model/serial normalization and identity framing.
6. Required remote mode to boot the same signed ISO, locally verify/import its immutable provisioning payload before SSH, bind installer path/NAR/closure and payload digests into the signed manifest, and atomically serialize the one-use password session.
7. Added a distinct local-VT-authorized `committed -> drill -> previous -> candidate -> restored` state path, crash/deadline behavior, GC-root suspension, and a fresh 30-day restoration anchor.
8. Added a carry-forward exception only for unchanged public enrollment state/contracts, a two-row authenticated pre-Nix verifier manifest, static per-platform verifier artifacts, and equivalence mutation tests against canonical locked-Python validation.
9. Narrowed F3 to exact realizable x86 closures, evaluation artifacts for ARM-only paths, and signed native Darwin closure scanning consumed only by F4.
10. Added exact per-lane task-result selector manifests, subject-specific status paths, ordered digest aggregation, NOT VERIFIED/INVALID rules, and the seven-call qualification join.
11. Defined exact commit/volume formulas and placed Git, gzip, Nix, coreutils, findutils, OpenSSH, util-linux/dosfstools, tar, zstd, squashfs, and xorriso behind one signed locked release-tool closure.
12. Unified direct/remote private identity staging through the same length-framed, fsynced, atomic helper and made independent signature recomputation with `signatureVerified=true` part of the normative install PASS predicate.

## Round-20 preflight validation
- Structure: PASS; 26 sequential tasks, 26 reference blocks, 26 verification blocks, 27 intended commits because Task 21 has two serialized commits, and four final lanes.
- Contract closure: PASS preflight for all twenty-one unique round-19 blocker themes, including cross-platform host unions, physical/Darwin predicates, evidence bytes, install trust/postconditions, rollback, bootstrap, F3, deterministic publication, and final joins.
- Stale-contract scan: PASS; no five-foreign-closure F3 claim, ambiguous bootstrap observer scalar, firmware-state mismatch, undefined runbook mapping, nullable install signature fields, or ambient release-tool path remains.
- Planner boundary: PASS; tracked status/diff-check clean, no trailing whitespace, and only ignored `.omo` plan/draft artifacts changed.
- Complete-plan SHA-256 submitted for round 20: `306cec5e753e0c4d965f3435a0228d938520aaf11bbee83d2bed98d4191c5c32`.

## Dual review round 20
- Native Momus `/root/momus_plan_review_round20`: **NOT OKAY**, four blockers: install-time signature availability, missing retained-publication locator/lifecycle, no boot-tested second fresh-install generation, and incomplete F4 collection/aggregate semantics.
- Independent isolated Codex CLI session `019f6035-274c-7f12-b8b3-c004318351bc`, model `gpt-5.6-sol`, reasoning `xhigh`, workspace `/home/mei/.cache/nix-plan-reviews/round20.Ve7Y4H`, isolated home `/home/mei/.cache/nix-plan-reviews/round20-home.lSn6z9`: **NOT OKAY**, thirteen blockers; completed with `REVIEW_RC=0`.
- Round-21 correction scope: bind GitHub review/merge identity and exact diffs; separate bootstrap source/state/TSV/closure digests; split stable disk identity from per-boot device binding; verify only embedded signatures during installation; close attended reboot/failure-rollback expiry paths; type all runbook runtime inputs; narrow firmware and secret claims; define an outer-signed safely extractable portable archive and retained snapshot lifecycle; consume Darwin CI proof; distinguish portable fixtures from native external status; order Task 6 before Task 4; and close final result, tree hash, case manifest, collect-all, subject, and aggregate semantics.

## Round-20 consolidated corrections before round 21
1. Bound GitHub evidence to a numbered squash PR, base/head/synthetic/result SHAs, one merge parent, merge event, canonical reviewed/merged diff digests, CODEOWNERS review, and post-merge push suite; direct/bypass pushes fail.
2. Replaced the cyclic `validatorContractSha256` with independent `bootstrapContractManifestSha256`, `bootstrapStateSha256`, `preNixManifestSha256`, and per-verifier closure digests.
3. Defined stable cross-boot disk identity solely from by-id/size/sectors/model-hash/serial-hash, with separate boot-local binding over boot ID/major/minor/sysfs path.
4. Split install proof into embedded `payloadSignatureVerified` and nullable remote authorization proof; outer archive and inner kit signatures are Task-25/F4 facts, not install-time prerequisites.
5. Added byte-distinct recovery/candidate closures, recovery-first and candidate-second fresh-install boots, local-VT one-use approvals, exact resume services, and complete failure-rollback/drill expiry/crash state machines.
6. Added typed runbook placeholders for transaction, activation, publication, and medium identity, exact argv substitution, a canonical retained publication snapshot, retention through record expiry plus seven days, and safe removable-medium handling.
7. Narrowed firmware evidence to declared driver binding plus zero observed load failures, and narrowed the absolute secret guarantee to project-produced artifacts and qualified current/recovery roots while keeping global residue non-normative.
8. Defined the three-file portable handoff, embedded/inner/outer signature layers, named `release-tools.json`, normalized deterministic archive, hostile-header rejection, descriptor-relative extraction, recovery/candidate kit members, and offline recovery/candidate/rollback/restoration cold test.
9. Added Task-24 Darwin status to F4 and required `darwin.state="completed"`; made Task-14/23 F1 fixtures explicitly portable schema/protocol simulations and reserved native ARM/Darwin claims for signed external status.
10. Made Task 4 depend on Task 6, repaired reciprocal dependencies/waves, and required Task-4's adapter/manifest exist before implementation starts.
11. Defined exact task/final schemas, `subject` nullability, canonical case manifests, current tracked-worktree hash including modes/symlinks/gitlinks, eight qualification selectors, collect-all behavior, four subject rows, deterministic markers, aggregate outcomes/exits, and canonical final evidence path.

## Round-21 preflight validation
- Structure: PASS; 26 sequential todos, 26 reference blocks, 26 verification blocks, complete commit dispositions, and four final lanes.
- Dependency graph: PASS; reciprocal and acyclic with deterministic order `1 3 2 6 4 5 13 7 8 9 11 12 15 16 18 17 19 21 22 14 23 20 10 24 25 26`; Task 6 precedes and blocks Task 4.
- Contract closure: PASS preflight for all seventeen unique round-20 findings, including GitHub binding, bootstrap digests, stable storage identity, signature availability, reboot/rollback, runbook runtime objects, firmware/secrets, publication, Darwin CI, native-platform scope, harness order, and final aggregation.
- Stale-contract scan: PASS; no old validator digest, combined signature flag, unstable disk identity, stale reboot subaction, `subject-or-null`, seven-selector aggregate, positive firmware-load claim, or ambiguous outer-kit wording remains.
- Planner boundary: PASS; tracked `git status --short` and `git diff --check` are clean; no trailing whitespace; only ignored `.omo` planning artifacts changed.
- Frozen complete-plan SHA-256 submitted for round 21: `77ae9dc347d81809ed24b4434bc78faf418b112bc211c47d8606daa143f4316d`.

## Dual review round 21
- Native Momus `/root/momus_plan_review_round21`: **NOT OKAY**, four blockers: conflicting direct-erase confirmation strings, undefined harness exit/result mapping, contradictory remote private-identity transfer claim, and no target-local remote bootstrap-password channel.
- Independent isolated Codex CLI session `019f607f-d6ff-78d3-8320-dd2147a65e70`, model `gpt-5.6-sol`, reasoning `xhigh`, workspace `/home/mei/.cache/nix-plan-reviews/round21.enQOEu`, isolated home `/home/mei/.cache/nix-plan-reviews/round21-home.kfJ8wL`: **NOT OKAY**, one blocker: Task-7 fresh-install boots did not create the committed Task-9 transaction required for rollback/publication/qualification; completed with `REVIEW_RC=0`.
- Round-22 correction scope: unify exact descriptor-bound erase approval; close exit/signal/timeout/result semantics; make the framed final-host/agenix stream the sole SSH key-transfer exception; generate/display/install the bootstrap password entirely through the held target VT and a one-use local hash FD; and consolidate recovery-to-candidate boot ownership through a crash-safe Task-7-to-Task-9 `install-handoff` whose stable binding/committed-entry digests join install, rollback, publication, and qualification evidence.

## Round-21 consolidated corrections before round 22
1. Added `deviceBindingSha256` to the sole direct erase phrase and required immediate held-descriptor recomputation before the first writer.
2. Defined exact case exit classes, tagged actual-exit objects, normal/signal/timeout matching, reserved harness-error exits, the `matched|mismatched` result enum, and PASS/INVALID aggregation.
3. Replaced the absolute no-key-transfer statement with one explicit exception for the length-framed final-host/agenix private identity stream; authentication/authorizer/login keys and all other payload material remain forbidden.
4. Added target-local bootstrap-password preparation: exact active-VT/broker authority, pinned yescrypt stdin, display-intent/completion crash poisoning, exactly-once plaintext display, one-use `SCM_RIGHTS` hash FD, separate identity stdin, fsynced target hash, and replay/cross-transaction denial.
5. Made Task 7 own only installer-to-recovery reboot, then create a fixed-path fsynced handoff consumed by Task 9's exclusive `import-install`; Task 9 alone owns candidate reboot, commit, rollback, and restoration.
6. Split stable Task-9 evidence into immutable `task9BindingDigest` and `task9CommittedEntryDigest`, plus the later terminal journal digest, avoiding a mutable-digest contradiction while binding install and rollback to one transaction.
7. Required Task 25 cold testing and Task 26 physical qualification to consume the same Task-7 terminal journal and Task-9 install-handoff/commit/drill, forbidding a separately created switch transaction.

## Round-22 preflight validation
- Structure: PASS; all 26 tasks retain references, explicit verification, commit disposition, and four final lanes.
- Dependency graph: PASS; reciprocal and acyclic with deterministic order `1 3 2 6 4 5 13 7 8 9 11 12 15 16 18 17 19 21 22 14 23 20 10 24 25 26`.
- Contract closure: PASS preflight for all five unique round-21 blockers: erase identity, harness exit classes, private-identity exception, bootstrap-password channel, and single-owner rollback handoff.
- Stale-contract scan: PASS; no three-field erase phrase, mutable `task9JournalDigest`, blanket SSH key-transfer denial, or Task-7-owned candidate reboot remains.
- Planner boundary: PASS; tracked status/diff-check clean, no trailing whitespace, ignored `.omo` artifacts only.
- Frozen complete-plan SHA-256 submitted for round 22: `000b1006ccaa8231a9b46de8c107c2e9ccdec1ba33debd353369bed138b9f800`.

## Dual review round 22
- Native Momus `/root/momus_plan_review_round22`: **NOT OKAY**, one blocker: publication uniqueness included artifact digests while status/F4 selected only by host, leaving nondeterministic record choice.
- Independent isolated Codex CLI session `019f608a-968d-7fc2-b627-15d727f5d184`, model `gpt-5.6-sol`, reasoning `xhigh`, workspace `/home/mei/.cache/nix-plan-reviews/round22.oPYthJ`, isolated home `/home/mei/.cache/nix-plan-reviews/round22-home.tDbhK9`: **NOT OKAY**, one blocker: pre-approval `nixos-rebuild boot|switch` could make the candidate persistent/default before reboot authorization; completed with `REVIEW_RC=0`.
- Round-23 correction scope: make publication unique by host/declaration/source and reject duplicates; make Task-9 staging build-only or nonpersistent, prove the previous boot default/entry set remains unchanged, and consume/fsync approval before any candidate bootloader mutation.

## Round-22 consolidated corrections before round 23
1. Changed publication uniqueness to `(hostId,declarationDigest,sourceGitCommit)`, declared every second matching record INVALID regardless of differing artifact/personal-wallpaper bytes, and made Task-25 status resolve exactly one record.
2. Replaced pre-approval `nixos-rebuild boot|switch` with `nixos-rebuild build`; `switch` uses only verified `switch-to-configuration test`, and both modes prove the prior default/entry set unchanged with no candidate entry.
3. Added durable consume-before-bootloader ordering: only after approval is fsynced consumed may the exact candidate `switch-to-configuration boot` install/select an entry; every consumed/install/default/journal crash boundary resumes idempotently without automatic reboot.
4. Applied the same consume-before-mutation rule to failure rollback, qualification rollback, and candidate restoration; unconsumed expiry leaves the prior default and candidate nonbootable.
5. Added power-loss/expiry tests proving pre-approval boots always select previous, candidate cannot be booted before approval consumption, and post-consumption recovery never rewinds authorization.

## Round-23 preflight validation
- Structure: PASS; 26 tasks, 26 reference blocks, 26 verification blocks, complete commit dispositions, and four final lanes.
- Dependency graph: PASS; reciprocal and acyclic with deterministic order `1 3 2 6 4 5 13 7 8 9 11 12 15 16 18 17 19 21 22 14 23 20 10 24 25 26`.
- Contract closure: PASS preflight for deterministic publication selection and approval-before-persistence boot safety.
- Stale-contract scan: PASS; no artifact-digest publication selector, pre-approval `nixos-rebuild boot`, or direct candidate-default mutation remains.
- Planner boundary: PASS; tracked status/diff-check clean, no trailing whitespace, ignored `.omo` artifacts only.
- Frozen complete-plan SHA-256 submitted for round 23: `d515bc7ff2b1dae4b5dcaff27f81ef8e8518a3f10b22635740b7306ec7a6a703`.

## Dual review round 23
- Native Momus `/root/momus_plan_review_round23`: **NOT OKAY**, one blocker: F3 authenticated only raw container bytes and could false-green secrets inside gzip, zstd, ISO, squashfs, or binary-cache/NAR content.
- Independent isolated Codex CLI session `019f6095-7e52-7fa2-bc23-1f2817612a74`, model `gpt-5.6-sol`, reasoning `xhigh`, workspace `/home/mei/.cache/nix-plan-reviews/round23.E63plk`, isolated home `/home/mei/.cache/nix-plan-reviews/round23-home.hz32e2`: **NOT OKAY**, four blockers: semantic Task-7/9 and Task-11/12 dependency cycles, underspecified Git diff extraction, evidence formats that omitted required declaration strings, and POSIX/PAX archive output conflicting with the verifier's PAX rejection; completed with `REVIEW_RC=0`.
- Round-24 correction scope: split generic rollback/password primitives from their later real integrations; define exact raw Git diff parsing and CODEOWNERS path semantics; close the declaration-projected evidence-string formats and hash native renderer text; use strict ustar with bounded ASCII names; and authenticate, recursively decode, manifest, and scan every generated container layer.

## Round-23 consolidated corrections before round 24
1. Reordered the dependency graph so Task 9 implements generic rollback/import primitives before Task 7's real no-stub handoff integration, and Task 12 implements the direct bootstrap-password/hash-FD primitive before Task 11's real no-stub remote broker integration.
2. Defined the exact locked-Git `--raw --no-renames -z --abbrev=40` command, record grammar, allowed statuses/modes, zero-SHA semantics, NFC path validation, byte ordering, submodule rejection, rename-as-delete-plus-add behavior, and CODEOWNERS treatment.
3. Closed committed declaration-projected identifiers for logical IDs, PCI/controller classes, drivers, D-Bus names, Darwin bundle IDs, and font families; replaced raw renderer evidence with an exact declaration-bound SHA-256 digest.
4. Replaced POSIX/PAX tar with `--format=ustar`, required ASCII safe complete member paths of at most 100 bytes with no prefix splitting, rejected PAX/GNU longname extensions, and added 100/101-byte personal-wallpaper and archive fixtures.
5. Made F3 verify signatures/checksums before decoding, scan raw and recursively decoded gzip/zstd/ustar/ISO/squashfs/NAR/store bytes, bind every parent/member edge bidirectionally, cap recursion, reject unsafe/unsupported decoder states, and inject the credential independently into every decoded container/cache form.

## Round-24 preflight validation
- Structure: PASS; 26 sequential tasks, 26 reference blocks, 26 verification blocks, 27 intended commits because Task 21 has two serialized commits, and four final lanes.
- Dependency graph: PASS; reciprocal and acyclic with deterministic order `1 3 2 6 4 5 8 13 18 21 9 15 19 22 23 7 17 12 11 16 14 20 10 24 25 26`; production integrations consume earlier production primitives without stubs.
- Contract closure: PASS preflight for exact Git diff semantics, declaration-bound evidence values, strict ustar member representation, and authenticated recursive F3 scanning.
- Stale-contract scan: PASS; no POSIX/PAX archive producer, raw expected-renderer evidence, raw-container-only F3 claim, or old Task-7/9 and Task-11/12 dependency edge remains.
- Planner boundary: PASS; tracked `git status --short` and `git diff --check` are clean; only ignored `.omo` planning artifacts changed.
- Frozen complete-plan SHA-256 submitted for round 24: `8d6754d8890b372b349e5b181c130525e43a500cafea3f09e6195f85aaa47d38`.

## Dual review round 24
- Native Momus `/root/momus_plan_review_round24`: **NOT OKAY**, three blockers: the exact Git source tar contains an unhandled global PAX header, Task-14 xz payload archives lacked a pinned decoder/scan path, and recursive decoder size/member limits were not numeric.
- Independent isolated Codex CLI session `019f60a9-aa81-7693-805b-936bf49044df`, model `gpt-5.6-sol`, reasoning `xhigh`, allocated workspace `/home/mei/.cache/nix-plan-reviews/round24.3bTpdv`, isolated home `/home/mei/.cache/nix-plan-reviews/round24-home.y1pxMQ`: **NOT OKAY without plan review** because the harness mistakenly left the CLI working directory at `/home/mei/nix-config`, so committed `PLAN.md` was absent there; completed with `REVIEW_RC=0`. This is recorded as a failed review round, not an approval or a plan defect; the next round must `cd` into the disposable committed workspace before invocation.
- Round-25 correction scope: allow only Git's exact source-global PAX record; pin and traverse xz payload archives; define immutable decoder/container/run byte and member limits with exact-boundary arithmetic and real decoder integration tests; and correct the independent review harness working directory.

## Round-24 consolidated corrections before round 25
1. Added xz to the exact signed `releaseTools` closure and required authenticated safe-tar traversal of both Task-14 `nix-3.21.5-*.tar.xz` payload archives, their graph edges, and injected-secret negatives.
2. Defined the sole PAX exception as Git's first `pax_global_header` with type `g`, octal size 64, and exact `52 comment=<sourceGitCommit>\n` payload; every other PAX header/key/order/value remains invalid.
3. Added production constants for raw-container, decoded-member, per-container bytes/members, aggregate bytes/members, and recursion depth; declared sizes are checked before allocation, streaming counters enforce actual bytes, equality is allowed, and limit+1/overflow/trailing/EOF mutants fail.
4. Required exact-limit/limit+1 arithmetic tests plus small real gzip/xz/zstd/tar/ISO/squashfs/NAR fixtures wired through the production counters.

## Round-25 preflight validation
- Structure: PASS; 26 sequential tasks, 26 reference blocks, 26 verification blocks, 27 intended commits because Task 21 has two serialized commits, and four final lanes.
- Dependency graph: PASS; reciprocal and acyclic with deterministic order `1 3 2 6 4 5 8 13 18 21 9 15 19 22 23 7 17 12 11 16 14 20 10 24 25 26`.
- Contract closure: PASS preflight for source-only PAX semantics, xz payload traversal, recursive decoder graph coverage, and numeric decompression-bomb limits.
- Stale-contract scan: PASS; no decoder whitelist omits xz, no raw-only scan remains, and the Git global PAX record is neither silently accepted nor rejected by the source parser.
- Planner boundary: PASS; tracked `git status --short` and `git diff --check` are clean; only ignored `.omo` planning artifacts changed.
- Frozen complete-plan SHA-256 submitted for round 25: `4669bd01581abb390d6f28940523c79b8e29d236129195cd0dd1be9f415dcd12`.

## Dual review round 25
- Native Momus `/root/momus_plan_review_round25`: **NOT OKAY**, two blockers: Task 7 lacked one canonical durable post-reboot journal locator, and CODEOWNERS proof could omit critical paths because the protected path set was open/self-referential.
- Independent isolated Codex CLI session `019f60ae-bd47-74d1-93a7-7ec621fe4dd2`, model `gpt-5.6-sol`, reasoning `xhigh`, workspace `/home/mei/.cache/nix-plan-reviews/round25.HCz9R8`, isolated home `/home/mei/.cache/nix-plan-reviews/round25-home.Hh73hj`: **NOT OKAY**, four blockers: F3 rejected legitimate links across all formats, remote manifest signing lacked a pre-SSH target-fact export, Darwin rollback did not bind/scan the previous generation, and installed observation used unspecified live-filesystem fsck probes; completed with `REVIEW_RC=0`.
- Round-26 correction scope: give install journals one crash-safe persistent locator; make whole-tree CODEOWNERS coverage exist on the freeze PR base; define format-specific safe link scanning; export a canonical target-derived manifest request over verified removable media; bind and scan Darwin's reviewed previous generation; and replace live fsck with exact read-only superblock/BPB probes.

## Round-25 consolidated corrections before round 26
1. Added volatile-to-persistent direct/remote journal promotion with exact `/var/lib/nix-config/install-transactions/<transactionId>/journal.json` locator, owner/mode/no-follow rules, atomic rename/fsync, identical reconciliation, divergent-collision failure, and fixed Task-24 lookup.
2. Required a dedicated pre-freeze bootstrap PR installing exact whole-tree `.github/CODEOWNERS` bytes `* @Meillaya\n`; the freeze PR binds that base digest, adds a closed `patterns:["*"]` manifest, and proves raw-diff/CODEOWNERS/reviewed-path bidirectional equality including deletions and renames.
3. Kept portable handoff archives link-free, but defined safe source/xz tar link targets, squashfs/NAR/store links, hardlink identity, typed graph edges, target-byte scanning, no dereference, closure-bounded absolute store targets, and link-specific mutants.
4. Added a 15-minute canonical manifest request containing every target/ISO-derived dynamic fact, retained its hash in target tmpfs, exported it atomically through a descriptor-verified removable medium before SSH, and required full signed-manifest projection equality and a one-use same-boot claim.
5. Extended Darwin rollback records/journals with previous source/lock/declaration/path/NAR/closure/review-record facts, required a reviewed reachable ancestor, and required signed zero-match native scans for both candidate and previous closures before rollback/F4 qualification.
6. Replaced live `fsck` with `O_RDONLY` descriptor-bound `blkid -p`, checked-in ext4-superblock and FAT32-BPB `pread` parsers, zero-write tests, and an explicit rule that consistency/repair is a separately authorized unmounted recovery action.

## Round-26 preflight validation
- Structure: PASS; 26 sequential tasks, 26 reference blocks, 26 verification blocks, 27 intended commits because Task 21 has two serialized commits, and four final lanes.
- Dependency graph: PASS; reciprocal and acyclic with deterministic order `1 3 2 6 4 5 8 13 18 21 9 15 19 22 23 7 17 12 11 16 14 20 10 24 25 26`; Task 7 owns the request-export primitive and Task 11 consumes it, so no semantic back-edge was introduced.
- Contract closure: PASS preflight for durable journal discovery, whole-tree review coverage, format-specific links, pre-SSH dynamic-fact transfer, two-generation Darwin rollback trust, and read-only installed filesystem observation.
- Stale-contract scan: PASS; no open trust/test/schema CODEOWNERS phrase, universal no-link rule, candidate-only Darwin scan, Task-11-owned pre-Task-7 request export, or native live fsck remains.
- Planner boundary: PASS; tracked `git status --short` and `git diff --check` are clean; only ignored `.omo` planning artifacts changed.
- Frozen complete-plan SHA-256 submitted for round 26: `9e583962f55cced73ca8201e0a4f71d3ba4a4bea03660dfce249dcbb20284e17`.

## Dual review round 26
- Native Momus `/root/momus_plan_review_round26`: **OKAY**.
- Independent isolated Codex CLI session `019f60c9-994f-7122-8307-d68f3a234357`, model `gpt-5.6-sol`, reasoning `xhigh`, workspace `/home/mei/.cache/nix-plan-reviews/round26.w7qFTm`, isolated home `/home/mei/.cache/nix-plan-reviews/round26-home.fPVl4N`: **NOT OKAY**, six blockers: a nonexistent nix-installer v3.21.5 pin; use of the actual historical credential rather than synthetic canaries in F3 fixtures; Task 2 validating Task-4 production objects before they exist; undefined manifest nonce/hash naming; dimensionally mixed ESP capacity arithmetic; and an underspecified temporary installer-root password/key transition that could lock on disconnect without an attended crash-safe state machine. Completed with `REVIEW_RC=0`.
- Round-27 correction scope: pin the real upstream v3.21.0 release and bytes; prohibit historical-secret fixture materialization; split abstract Task-2 and host-bound Task-4 validation; define target-generated nonce and distinct request/manifest hashes; make ESP accounting exact in bytes; and make temporary installer-root enable/key/lock/resume explicitly local-VT-authorized and crash-safe.

## Round-26 consolidated corrections before round 27
1. Replaced the nonexistent installer pin with official nix-installer v3.21.0 commit/source NAR, Determinate Nix input/source NAR, exact x86/aarch64 installer URLs, hashes, sizes, payload attrs/filenames, and version assertions; added the upstream release reference.
2. Prohibited copying, transforming, or materializing the actual historical credential in tests. F3 now uses only the two exact public non-authenticating synthetic canaries and binds the historical occurrence by pre-recorded object ID/blob digest/path/count.
3. Restricted Task 2 to abstract schemas/canonicalization/signatures/selectors and synthetic declaration fixtures. Task 4 now creates the four real machine objects and production registry, then wires the same validators to their host-bound projections; the dependency remains one-way.
4. Defined the manifest nonce as one 192-bit target-side `getrandom` result encoded as 48 lowercase hex, uniquely scoped to host/boot/request and never caller-supplied/reused. Distinguished `manifestRequestSha256` from `manifestSha256` and required the latter to be recomputed from the exact signed raw manifest frame and match journal, nonce claims, and observation.
5. Replaced mixed ESP block/byte prose with exact BPB-derived `clusterBytes`, `nonDataBytes`, `usableDataBytes`, allocated/candidate/directory/metadata/fixed-reserve terms, inclusive cluster-rounded 70/80-percent thresholds, checked unsigned-64 arithmetic, and malformed/inconsistent/cyclic/crosslinked FAT rejection.
6. Added exact attended installer-root transitions: local `ENABLE INSTALLER PASSWORD`, pinned stdin-only yescrypt/chpasswd handling and one-display journal; local `AUTHORIZE INSTALLER KEY`; key-active-before-lock ordering; no disconnect/timer lock; canonical crash states; digest-bound local `RESUME INSTALLER KEY`; and reboot removal/fresh-request requirements with boundary tests.

## Round-27 preflight validation
- Structure: PASS; 26 sequential tasks, 26 reference blocks, 26 verification blocks, 27 intended commits because Task 21 has two serialized commits, and four final lanes.
- Dependency graph: PASS; reciprocal and acyclic with deterministic order `1 3 2 6 4 5 8 9 13 7 12 11 15 16 18 17 19 21 22 14 23 20 10 24 25 26`; Task 2 remains abstract and Task 4 owns production projection validation.
- Contract closure: PASS preflight for real installer pins, synthetic-only secret fixtures, nonce/hash separation, exact ESP byte arithmetic, and attended crash-safe installer password/key transition.
- Stale-contract scan: PASS; no `3.21.5`, `manifestDigest`, mixed FAT block/byte formula, actual historical credential injection, automatic disconnect lock, or Task-2 read of a Task-4 production path remains.
- Planner boundary: PASS; tracked `git status --short` and `git diff --check` are clean; only ignored `.omo` planning artifacts changed.
- Frozen complete-plan SHA-256 submitted for round 27: `1e99f25d838f9dc3215a8b3452f778d5d7d66200e74fcd87d9ceada2c4e93ae3`.

## Dual review round 27
- Native Momus `/root/momus_plan_review_round27`: **NOT OKAY**, one blocker: the plan simultaneously prohibited reading/materializing the historical credential blob and required content-scanning every reachable Git object.
- Independent isolated Codex CLI session `019f60e1-f36c-7670-995b-bc7a47ae321f`, model `gpt-5.6-sol`, reasoning `xhigh`, workspace `/home/mei/.cache/nix-plan-reviews/round27.47UVrC`, isolated home `/home/mei/.cache/nix-plan-reviews/round27-home.lhWZQ6`: **NOT OKAY**, three blockers: no durable canonical post-reboot locator for the raw remote manifest/verification bytes; no descriptor-size or FAT-capacity binding for BPB ESP arithmetic; and the same historical-blob content-scan contradiction. Completed with `REVIEW_RC=0`.
- Round-28 correction scope: make the historical exception metadata-only before any content stream; retain and journal-bind the exact pre-erase verification bytes under the canonical transaction locator; explicitly join the persisted receipt to the independently reopened publication ISO; and bind FAT geometry to descriptor-authoritative size and entry capacity.

## Round-27 consolidated corrections before round 28
1. Replaced historical-secret content/hash validation with a metadata-first commit/tree walker that validates only the pre-recorded Git blob object ID, exact path, and occurrence count; excludes that ID before `cat-file`; trace-tests that exclusion; and content-scans every other reachable blob with generic rules and synthetic canaries.
2. Added a canonical root-only transaction sibling `verification/` snapshot containing the exact media verification receipt, embedded payload manifest/signature, release allowed-signers, and, for remote only, raw install manifest/signature/allowed-signers. It has a closed file set, atomic fsync promotion, file/digest/signature reopen checks, a journal state/digest, crash tests, 97-day minimum retention, and guarded attended cleanup.
3. Defined `isoArtifactSizeBytes` from a pinned builder-tested ISO9660/hybrid-GPT parser, exact descriptor-prefix hashing before erase, and a canonical receipt. Post-boot observation no longer pretends removed media is present: it revalidates retained bytes, while Task 25/F4 independently reopens the publication ISO and joins exact size/hash/payload facts.
4. Bound ESP BPB geometry to `BLKGETSIZE64`/`fstat` bytes, exact 1 GiB fresh-device size, descriptor-derived legacy stop decisions, checked data-cluster arithmetic, FAT32 cluster range, sufficient four-byte FAT entries, in-range indices, and mismatch/overflow/capacity negatives.

## Round-28 preflight validation
- Structure: PASS; 26 sequential tasks, 26 reference blocks, 26 verification blocks, 27 intended commits because Task 21 has two serialized commits, and four final lanes.
- Dependency graph: PASS; reciprocal and acyclic with deterministic order `1 3 2 6 4 5 8 9 13 7 12 11 15 16 18 17 19 21 22 14 23 20 10 24 25 26`.
- Contract closure: PASS preflight for metadata-only known-exposed handling, canonical durable verification snapshots, exact ISO size/hash publication joins, and descriptor/FAT-capacity-bound ESP arithmetic.
- Stale-contract scan: PASS; no all-reachable-object content claim, historical blob SHA recomputation, absent post-reboot manifest locator, raw-media post-boot rehash claim, BPB-only ESP length, `3.21.5`, or `manifestDigest` remains.
- Planner boundary: PASS; tracked `git status --short` and `git diff --check` are clean; only ignored `.omo` planning artifacts changed.
- Frozen complete-plan SHA-256 submitted for round 28: `de22f0cf940e1ef53c670bb82124c5c834a788da8f4ac2963a8ea4667d1a7b44`.

## Dual review round 28
- Native Momus `/root/momus_plan_review_round28`: **OKAY**.
- Independent isolated Codex CLI session `019f60f0-707b-73c1-b9d9-21aaaf50a738`, model `gpt-5.6-sol`, reasoning `xhigh`, workspace `/home/mei/.cache/nix-plan-reviews/round28.Pkyb15`, isolated home `/home/mei/.cache/nix-plan-reviews/round28-home.xGGO8c`: **NOT OKAY**, two blockers: the bare `HostKeyAlias` did not match the bracketed host/port known-hosts key; and excluding the known-exposed blob from direct `cat-file` requests overclaimed non-materialization because Git may internally reconstruct it as an OFS/REF delta base. Completed with `REVIEW_RC=0`.
- Round-29 correction scope: make the known-hosts key exactly the bare alias used verbatim by OpenSSH and prove it with a real nondefault-port connection; narrow the historical-secret assertion to direct request/emission/persistence boundaries, explicitly exclude trusted Git private delta-base memory, and test synthetic packed OFS/REF delta cases.

## Round-28 consolidated corrections before round 29
1. Changed the private known-hosts entry to exact bare `nix-config-installer-<hostId>-<installerBootId> <installerHostPublicKey>`, matching `HostKeyAlias` verbatim with no brackets/address/port, and required an actual strict-host-key fixture connection at a nondefault port plus negative variants.
2. Narrowed known-exposed handling honestly: the blob ID is never directly requested, emitted across a process boundary, hashed, persisted, or used as test data, but trusted Git may transiently reconstruct it in private memory as another blob's pack-delta base. Added public stand-in REF_DELTA/OFS_DELTA fixtures proving request-list exclusion, no stdout/stderr/temp/log leakage, and complete scanning of reconstructed allowed blobs.

## Round-29 preflight validation
- Structure: PASS; 26 sequential tasks, 26 reference blocks, 26 verification blocks, 27 intended commits because Task 21 has two serialized commits, and four final lanes.
- Dependency graph: PASS; reciprocal and acyclic with deterministic order `1 3 2 6 4 5 8 9 13 7 12 11 15 16 18 17 19 21 22 14 23 20 10 24 25 26`.
- Contract closure: PASS preflight for verbatim OpenSSH host-alias lookup and explicit packed-delta limitations/tests without weakening current-tree/artifact/closure/log secret absence.
- Stale-contract scan: PASS; no bracketed alias/port known-hosts entry, unqualified process-memory non-materialization claim, all-reachable-object direct request, `3.21.5`, or `manifestDigest` remains.
- Planner boundary: PASS; tracked `git status --short` and `git diff --check` are clean; only ignored `.omo` planning artifacts changed.
- Frozen complete-plan SHA-256 submitted for round 29: `0f205a52b2527c81c6fe83895504d1e4db51180a5d2c09652b456998ede97c8b`.

## Dual review round 29
- Native Momus `/root/momus_plan_review_round29`: **OKAY**.
- Independent isolated Codex CLI session `019f6103-5e76-7d42-bbaf-26bba2f9bb11`, model `gpt-5.6-sol`, reasoning `xhigh`, workspace `/home/mei/.cache/nix-plan-reviews/round29.h9gR2c`, isolated home `/home/mei/.cache/nix-plan-reviews/round29-home.GXxjmK`: **NOT OKAY**, three blockers: squash-merging could orphan branch-local release/bootstrap enrollment commits from candidate ancestry; Task 7 retained a whole-device exclusive open while real partition formatters needed their own opens; and the first contract-bearing Darwin freeze had no distinct reviewed previous generation. Completed with `REVIEW_RC=0`.
- Round-30 correction scope: stage optional enrollment as reviewed mainline squash merges between two reviewed source generations; define a real-tool-compatible whole-device/partition ownership handoff with exact syscall ordering; and make generation 1 foundation the explicit native Darwin predecessor of generation 2 candidate.

## Round-29 consolidated corrections before round 30
1. Replaced the single freeze with an exact foundation/enrollment/candidate mainline sequence. Foundation establishes the complete contract and generation-1 marker; release/bootstrap enrollment can only land afterward through separate reviewed mainline PRs whose actual squash commits and Task-24 records remain candidate ancestors; branch-local enrollment is invalid; candidate changes only the generation-2 marker and is the sole Task-25/26/F4 source.
2. Replaced the lifetime writable/exclusive whole-device open with a read-only identity anchor plus short exclusive preflight claims. The adapter closes the whole claim before real `sfdisk`, closes each partition claim before real `mkfs`, never overlaps whole and partition exclusive opens, keeps all tool paths inside the immutable private namespace, revalidates descriptor/sysfs/GPT facts between phases, and syscall-tests both the known failing retained-claim sequence and the successful release sequence.
3. Made Darwin qualification explicitly two-generation. The reviewed foundation can be natively activated and retained; the candidate marker names its exact foundation commit; Task 23 and F4 require that exact distinct foundation closure and its GitHub record. Missing foundation activation is honestly NOT VERIFIED, while self-reference, substitution, or malformed ancestry is INVALID.
4. Closed the evidence-signing bootstrap edge: production operator/observer public keys must already be present in the reviewed foundation source for that cycle to produce externally VERIFIED records; a disabled foundation still completes F1-F3, but later keys cannot retroactively authorize it.

## Round-30 preflight validation
- Structure: PASS; 26 sequential tasks, 26 reference blocks, 26 verification blocks, 28 intended commits because Tasks 21 and 24 each have two serialized commits, and four final lanes.
- Dependency graph: PASS; reciprocal and acyclic with deterministic order `1 3 2 6 4 5 8 9 13 7 12 11 15 16 18 17 19 21 22 14 23 20 10 24 25 26`; Task 24's two integration commits remain one dependency node, and optional enrollment is an external serialization point inside it.
- Contract closure: PASS preflight for mainline enrollment ancestry under squash merges, real-tool-compatible block-device ownership handoff, and an attainable two-reviewed-generation Darwin drill with explicit disabled/absent outcomes.
- Stale-contract scan: PASS; no lifetime whole-device writable claim, branch-local enrollment acceptance, single-generation Darwin self-qualification, retroactive support-key authorization, old source-freeze wording, `3.21.5`, or `manifestDigest` remains.
- Planner boundary: PASS; tracked `git status --short` and `git diff --check` are clean; only ignored `.omo` planning artifacts changed.
- Frozen complete-plan SHA-256 submitted for round 30: `10a1677587cad829ccb83bc5a30c7dc3b0e5ea3297b77679e894dce1186c61ec`.

## Dual review round 30
- Native Momus `/root/momus_plan_review_round30`: **NOT OKAY**, one blocker: closing both whole-device and partition exclusive claims before real tools reopened them left a preflight-to-open race rather than continuous kernel ownership.
- Independent isolated Codex CLI session `019f611c-71be-7560-b6df-f567308d2a85`, model `gpt-5.6-sol`, reasoning `xhigh`, workspace `/home/mei/.cache/nix-plan-reviews/round30.KIfRQ6`, isolated home `/home/mei/.cache/nix-plan-reviews/round30-home.EFfMwt`: **NOT OKAY**, four blockers: circular production bootstrap gating of foundation CI; F4 confusing evidence-descendant `HEAD` with candidate source; the same exclusive-open race; and impossible Darwin requirements that lock/declaration digests differ across a marker-only source change. Completed with `REVIEW_RC=0`.
- Round-31 correction scope: give the real storage tools duplicates of continuously retained exclusive open descriptions through a seccomp notification broker; separate hash-pinned non-authorizing CI bootstrap from production bootstrap evidence; bind F4's evidence-descendant tested commit separately from candidate source; and define exact Darwin equal/different generation facts with closure-materialized source metadata.

## Round-30 consolidated corrections before round 31
1. Replaced check-close-reopen with a seccomp user-notification FD broker. The supervisor retains the verified whole or partition `O_EXCL` open description throughout each real `sfdisk`/`mkfs` execution and injects duplicates with `SECCOMP_IOCTL_NOTIF_ADDFD`; all device opens are mediated, non-device reads use a closed descriptor-relative manifest without `CONTINUE`, and synchronized competing production tools must reach zero writes throughout the full writer interval.
2. Added exact two-row/nine-field `ci-bootstrap.tsv`, authenticated before Nix with fixed system tools and explicitly incapable of satisfying Task-14 production status. Disabled production staging now reports NOT VERIFIED without circularly failing generic PR/push suites; malformed CI bootstrap still fails before Nix, and release/publication gates still require production VERIFIED.
3. Added `sourceGitCommit` to final result records. F1-F3 bind source/tested commit to `HEAD`; F4 binds candidate as source while `testedGitCommit=HEAD` names either candidate or its strictly evidence-only descendant, with the complete diff and current tree hash revalidated.
4. Corrected Darwin relations: candidate/foundation source commits, system paths, top-level NAR hashes, closure digests, and scan digests differ; lock and declaration digests are equal. Exact generation bytes and clean `self.rev` are materialized as required closure members so the marker-only candidate is provably non-no-op.

## Round-31 preflight validation
- Structure: PASS; 26 sequential tasks, 26 reference blocks, 26 verification blocks, 28 intended commits because Tasks 21 and 24 each have two serialized commits, and four final lanes.
- Dependency graph: PASS; reciprocal and acyclic with deterministic order `1 3 2 6 4 5 8 9 13 7 12 11 15 16 18 17 19 21 22 14 23 20 10 24 25 26`; CI-bootstrap realization remains Task 14 work before the Task-24 foundation integration.
- Contract closure: PASS preflight for continuous real-writer kernel ownership, non-circular CI bootstrap, evidence-descendant F4 binding, and attainable byte-distinct Darwin generations with equal lock/declaration projections.
- Stale-contract scan: PASS; no close-before-tool exclusive handoff, production-status prerequisite for generic pre-Nix CI, `testedGitCommit=candidateCommit`, all-Darwin-digests-differ rule, `3.21.5`, or `manifestDigest` remains.
- Planner boundary: PASS; tracked `git status --short` and `git diff --check` are clean; only ignored `.omo` planning artifacts changed.
- Frozen complete-plan SHA-256 submitted for round 31: `c378c2c5bb1a756ad67f1d18cf43d0a0eb92e1504183b37a1a779be7e3151003`.

## Dual review round 31
- Native Momus `/root/momus_plan_review_round31`: **NOT OKAY**, two blockers: historical foundation/enrollment GitHub records were excluded by the generic evidence-only descendant rule once candidate changed a product file; and the seccomp broker overclaimed zero writes after injecting a writable FD if its supervisor then died.
- Independent isolated Codex CLI session `019f6128-a634-7ac1-bd3c-16bfcb97aac4`, model `gpt-5.6-sol`, reasoning `xhigh`, workspace `/home/mei/.cache/nix-plan-reviews/round31.Id6oJ8`, isolated home `/home/mei/.cache/nix-plan-reviews/round31-home.Cq9Ow3`: **NOT OKAY**, four blockers: insufficiently closed seccomp syscall/FD/read-manifest mechanics plus an unguarded whole-to-partition gap; enrollment PR CI still demanded evidence unavailable until after its push suite; F4 omitted Task-14 production status; and F4 could execute modified tracked validators despite checking only the committed candidate-to-HEAD diff. Completed with `REVIEW_RC=0`.
- Round-32 correction scope: define a closed historical GitHub-record exception; close the broker's tool sandbox and raw-GPT handoff contract while honestly journaling post-injection death; admit only exact pending enrollment evidence during generic enrollment CI; add Task 14 as an authenticated F4 selector; and require a committed clean tracked worktree before any F4 selector.

## Round-31 consolidated corrections before round 32
1. Added a narrowly historical GitHub-record rule for foundation/enrollment ancestors. Validators reconstruct the historical source/events, require byte-identical review/verifier policy through candidate, allow only the exact generation/enrollment/evidence paths to differ, require every intermediate product merge's own record, and retain current TTL/signature checks.
2. Made Task 7 own a closed per-tool sandbox manifest, exact FD 0/1/2/control/listener lifecycle, reserved-FD `execveat` handshake, syscall default-kill policy, descriptor-relative read rows/ENOENT probes, notification validation, allowed dirfd/flag/mode rules, and no-`CONTINUE` FD injection. The whole claim survives sfdisk; all partition claims are acquired and held together; the raw primary/backup GPT digest is revalidated after handoff and before any formatter write.
3. Narrowed supervisor-death claims: failures before writable injection guarantee zero writes; post-injection death is an explicit fsynced in-flight destructive-operation residual requiring attended restart/recovery, never a fabricated zero-write result.
4. Allowed exact fully byte-validated bootstrap enrollment PR/head and first post-merge push to report non-failing pending-evidence/NOT VERIFIED until their actual merge/push records can exist. Every release/publication gate remains VERIFIED-only; malformed or out-of-phase pending state is INVALID.
5. Added Task-14 bootstrap-staging status as the first of nine F4 selectors with its own `gateSelectorDigests` binding; CI-bootstrap and pending enrollment cannot satisfy it.
6. Required locked-Git clean index/worktree checks against committed HEAD before any F4 selector, so evidence-descendant validators cannot run from staged or unstaged tracked modifications.

## Round-32 preflight validation
- Structure: PASS; 26 sequential tasks, 26 reference blocks, 26 verification blocks, 28 intended commits because Tasks 21 and 24 each have two serialized commits, and four final lanes.
- Dependency graph: PASS; reciprocal and acyclic with deterministic order `1 3 2 6 4 5 8 9 13 7 12 11 15 16 18 17 19 21 22 14 23 20 10 24 25 26`; the added Task-14 F4 selector is a final evidence gate, not a build dependency back-edge.
- Contract closure: PASS preflight for historical review evidence, broker syscall/FD semantics, whole-to-partition GPT handoff, enrollment pending evidence, authenticated production-bootstrap qualification, and clean-HEAD F4 execution.
- Stale-contract scan: PASS; no universal evidence-only rejection of historical GitHub records, post-injection zero-write supervisor-death guarantee, close-before-tool writer gap, enrollment-PR VERIFIED requirement, eight-selector F4, dirty tracked F4 execution, `3.21.5`, or `manifestDigest` remains.
- Planner boundary: PASS; tracked `git status --short` and `git diff --check` are clean; only ignored `.omo` planning artifacts changed.
- Frozen complete-plan SHA-256 submitted for round 32: `9d1af5ab6488871a684c559ef170c1da3292e3c3725ee39775dd8fd627a4f80a`.

## Dual review round 32
- Native Momus `/root/momus_plan_review_round32`: **OKAY**.
- Independent isolated Codex CLI session `019f6135-936d-7113-ab88-26d4deb8e5b0`, model `gpt-5.6-sol`, reasoning `xhigh`, workspace `/home/mei/.cache/nix-plan-reviews/round32.ujcGNk`, isolated home `/home/mei/.cache/nix-plan-reviews/round32-home.8WawiU`: **NOT OKAY**, four blockers: enrollment pending evidence omitted GitHub's event-bound synthetic merge SHA; only F4 rejected a dirty tracked worktree and no lane rejected unexpected untracked paths; Task 7 left executable FD 1023 reusable and device-open order/flags/cardinality/target FDs open; and Task 21's pre-squash `baselineCommit` would not remain reachable after the foundation squash merge. Completed with `REVIEW_RC=0`.
- Round-33 correction scope: admit only the exact event-bound enrollment synthetic merge with the same two-file diff; apply one closed dirty/untracked preflight to F1-F4; close every post-filter FD creator, injected FD assignment, read/device request sequence, executable-sentinel state, and FD-1023 reuse path; and replace branch ancestry with a committed content-addressed Emacs baseline fixture.

## Round-32 consolidated corrections before round 33
1. Replaced the Task-21 branch-commit baseline with immutable `tests/fixtures/emacs/pre-migration/` source/input bytes and a canonical behavior manifest. Tests compute `baselineFixtureSha256`, execute every network-denied baseline case before migration, and require the fixture tree retain the literal case-manifest digest afterward, so squash merging cannot orphan the evidence.
2. Allowed bootstrap pending evidence at exactly the enrollment PR head, GitHub event-bound `prSyntheticMergeSha`, or actual squash merge. The synthetic case requires the complete raw base-to-head diff contain only the two enrollment files and the event's base/head/synthetic SHA match the Task-24 PR contract; no release gate accepts pending state.
3. Added one F1-F4 locked-Git preflight and closed `preflight` tagged result. It rejects index/tracked changes, every unexpected nonignored or ignored untracked path, symlinks/special files/symlinked parents inside the narrow `.omo` allowlist, invokes no selector on failure, and writes one canonical INVALID final result; a passed F4 alone proceeds to all nine selectors without early exit.
4. Closed Task 7's broker manifest with ordered `readRows` and `deviceRows`, exact flags/cardinality/claim roles, fixed nonoverlapping injected FD ranges, SETFD injection, `RLIMIT_NOFILE=1024`, default-killed FD creators and RLIMIT mutation, a one-use executable-sentinel state machine, executable-only FD 1023, and explicit missing/extra/reordered/fixed-FD/sentinel/1023-reuse negatives.

## Round-33 preflight validation
- Structure: PASS; first H2 is `## TL;DR (For humans)`, 26 sequential tasks each have references/verification/commit disposition, and four final lanes are present.
- Dependency graph: PASS; reciprocal and acyclic with deterministic order `1 3 2 6 4 5 8 13 18 21 9 15 19 22 23 7 17 12 11 16 14 20 10 24 25 26`.
- Contract closure: PASS preflight for synthetic-merge enrollment status, common final-lane worktree isolation, content-addressed Emacs characterization, and fixed-FD seccomp request sequencing with no executable-FD recreation route.
- Stale-contract scan: PASS; no `baselineCommit`, v3.21.5, `manifestDigest`, F4-only clean-preflight wording, eight-selector qualification, old read-only tool-row schema, or unconditional dirty-worktree selector execution remains.
- Planner boundary: PASS; tracked `git status --short`, `git diff --check`, and planning-artifact trailing-whitespace checks are clean; only ignored `.omo` planning artifacts changed.
- Frozen complete-plan SHA-256 submitted for round 33: `b28e8a9576657386abca2e88103f83604c0e98c901270cff4f182fc9ca874634`.

## Dual review round 33
- Native Momus `/root/momus_plan_review_round33`: **NOT OKAY**, three blockers: executable FD 1023 lacked explicit addfd `newfd_flags=O_CLOEXEC`; the ESP budget had no transaction-bound call site before Task-9 bootloader writes; and mandatory generic CI bootstrap depended on unspecified external hosting.
- Independent isolated Codex CLI session `019f6141-f442-7d82-87ff-eb718c2561bb`, model `gpt-5.6-sol`, reasoning `xhigh`, workspace `/home/mei/.cache/nix-plan-reviews/round33.vDgUH2`, isolated home `/home/mei/.cache/nix-plan-reviews/round33-home.DsKHzL`: **NOT OKAY**, six blockers: Task-14 was omitted from F4's aggregate decision formula; Task 25 could publish a kit not bound to a final production secret scan; F3 had no closed descendant-process argv/environment/log capture contract; production `native`/`disko-vm` build records had no producer; evidence-descendant diff/ancestry validation was open; and personal wallpapers had no feasible kit-to-target transport. Completed with `REVIEW_RC=0`.
- Round-34 correction scope: close target FD flags and post-exec proof; serialize every bootloader publication behind a journal-bound ESP budget; give CI bootstrap an exact public hosting/pre-foundation staging gate; propagate Task-14 outcome through F4; bind final retained production bytes to a zero-match recursive scan; capture all task descendants fail-closed; add exact build observation/runbook promotion; make evidence descendants linear append-only raw-diff chains; and stage wallpapers locally from a separately authenticated signed kit medium.

## Round-33 consolidated corrections before round 34
1. Added explicit addfd `newfd_flags` to every read/device row, `O_CLOEXEC` for executable FD 1023, and positive post-exec `/proc/<pid>/fd/1023` absence plus wrong-target-flag/reuse negatives.
2. Made Task 9 the sole production Task-8 caller. Every candidate/install-handoff/failure-rollback/drill-rollback/drill-restore publication holds one no-follow bootloader lock and ESP/boot descriptors through canonical capacity digest, immediate revalidation, approval consumption, exact `switch-to-configuration boot`, post-write verification, and journal fsync; denial before consumption writes nothing and remains retryable.
3. Fixed generic CI hosting to the literal public GitHub release tag `ci-bootstrap-v1-nix-3.21.0`, content-addressed four-asset URLs, and a two-observer output-only verification receipt. Missing assets block the foundation PR at a named human-owned gate; CI has no upload authority or fallback URL and reauthenticates bytes on every run.
4. Scoped Task-14 production bootstrap to the three x86 F4 rows, propagated NOT VERIFIED/INVALID into those rows and aggregate, and required Task-14 VERIFIED plus all four qualified rows for aggregate PASS without making Darwin itself consume a Linux kit gate.
5. Added a non-self-referential `productionSecretScan` projection over final retained archive/cache/ISO/decoded bytes, required the Task-25 publication envelope/record/status to recompute it with zero matches, and joined it in x86 F4 so an earlier unpublished-kit absence row cannot publish.
6. Added mandatory Task-1-built ptrace/cgroup descendant capture for every task invocation: complete exec argv/environment and stdout/stderr stream manifests, no truncation/escape/reuse, zero generic/canary matches before output release, and a fresh all-52-selector F3 execution.
7. Added exact host-bound `build.native` and `build.disko-vm` runbook scripts, two independent fresh-store result projections, locked path/NAR/closure/check-output recomputation, passive dual-signed promotion, and mandatory Task-26 consumption.
8. Replaced prefix-only evidence descent with one locked-Git validator requiring strict ancestry, one-parent linear intermediate commits, per-edge plus aggregate raw no-renames parsing, and add-only mode-100644 files below the two evidence roots.
9. Added local-VT signed-kit wallpaper staging from a descriptor-distinct removable medium, strict outer/inner verification, sealed directory-FD handoff into Task-7 provisioning, exact `/mnt/home/.../Pictures/Wallpapers` copy/fsync/rehash, and the same local physical path for direct and remote installs without SSH payload transfer.

## Round-34 preflight validation
- Structure: PASS; first H2 is `## TL;DR (For humans)`, 26 sequential tasks each have references/verification/commit disposition, and four final lanes are present.
- Dependency graph: PASS; reciprocal and acyclic with deterministic order `1 3 2 6 4 5 8 13 18 21 9 15 19 22 23 7 17 12 11 16 14 20 10 24 25 26`.
- Contract closure: PASS preflight for seccomp target flags, ESP publication serialization, executable CI hosting, F4 gate propagation, final production scans, task-stream capture, production build evidence, evidence-only ancestry, and personal-wallpaper transport.
- Stale-contract scan: PASS; no self-referential scan result, implicit FD target flags, unguarded Task-9 boot publication, unspecified CI URL, four-row-only aggregate PASS, unpublished-kit-as-production scan, open process capture, missing build producer, prefix-only evidence descent, or kit-only wallpaper copy claim remains.
- Planner boundary: PASS; tracked `git status --short`, `git diff --check`, and planning-artifact trailing-whitespace checks are clean; only ignored `.omo` planning artifacts changed.
- Frozen complete-plan SHA-256 submitted for round 34: `a70ccb6fcb3dd9318812547fdddce21db41587a951b0bbb0ec620e3034fc892d`.

## Dual review round 34
- Native Momus `/root/momus_plan_review_round34`: **NOT OKAY**, three blockers: the observation-envelope discriminator excluded build despite build records requiring envelopes; the production scan was described as living in a retained publication snapshot before that snapshot could exist; and native ARM bootstrap execution lacked a closed evidence shape.
- Independent isolated Codex CLI session `019f6157-c01c-7492-aede-511ecde030f9`, model `gpt-5.6-sol`, reasoning `xhigh`, workspace `/home/mei/.cache/nix-plan-reviews/round34.OSlehY`, isolated home `/home/mei/.cache/nix-plan-reviews/round34-home.n59c8M`: **NOT OKAY**, two blockers: the same impossible build-envelope schema and a `publication.handoff` envelope that omitted the production scan and location-descriptor projection used by its PASS predicate. Completed with `REVIEW_RC=0`.
- Round-35 correction scope: make build a closed signed envelope variant; close native x86/ARM bootstrap execution and signatures; separate prepared-kit pre-scan state from post-retrieval publication promotion; bind the complete production scan and redacted medium locator in the publication envelope; and define every snapshot digest and recorder reference shape without lifecycle ambiguity.

## Round-34 consolidated corrections before round 35
1. Made `observationEnvelope` an explicit tagged union that includes `recordKind="build"`, with required build run ID/role, forbidden run fields on non-build variants, closed per-check observations, and exact two-role detached-signature promotion into each build record.
2. Added exact `build.native` and `build.disko-vm` observation fields/PASS predicates, role-specific paths/signatures, independent fresh-store executions, byte-equal result projections, and signature/run/reference negative cases.
3. Added four closed native bootstrap envelopes for `(x86_64-linux|aarch64-linux) × (operator|observer)`, exact resolved installer/verifier argv, native isolated execution, offline network policy, receipts, result equality, paths/hashes, and detached signatures.
4. Replaced the impossible prepublication retained-snapshot scan with a root-owned prepared-kit lifecycle: exactly five fsynced payload/scan files, an exact five-row digest, a sibling immutable receipt as the sole media-writer input, and fresh post-retrieval scan recomputation in a private publication staging tree.
5. Defined atomic publication promotion with descriptor-relative copy, verification/extraction/cold test/post-scan, complete tree fsync, `renameat2(RENAME_NOREPLACE)`, parent fsync, and no canonical final path after an interrupted or failed staging run.
6. Added the full production-scan and `locationDescriptorSha256` fields to `publication.handoff`, defined the location digest over redacted descriptor/sysfs facts, and required exact record/envelope/status/F4 equality.
7. Clarified that `retainedSnapshotDigest` is the exact three-file handoff subset rather than the entire promoted directory, while scan-file and derived-tree digests are separate envelope fields; made the passive recorder emit record-kind-specific reference shapes instead of an impossible universal triple.
8. Restored the scaffold's exact final `## Success criteria` heading and added lifecycle/schema mutation cases for prepared receipts, scan equality, location descriptors, build signatures, atomic promotion, and bootstrap native evidence.

## Round-35 preflight validation
- Structure: PASS; exact eight scaffold H2 headings, first H2 `## TL;DR (For humans)`, 26 sequential tasks each with references/verification/commit disposition, and four final lanes.
- Dependency graph: PASS; all 26 rows are reciprocal and acyclic with deterministic order `1 3 2 6 4 5 8 9 13 7 12 11 15 16 18 17 19 21 22 14 23 20 10 24 25 26`.
- Contract closure: PASS preflight for build-envelope variants, native bootstrap evidence, prepared-kit versus publication-snapshot lifecycle, atomic promotion, production-scan/location joins, and record-kind-specific recorder output.
- Stale-contract scan: PASS; no build-excluding envelope enum, universal triple-only recorder, prepublication retained-snapshot scan, unresolved static-verifier store placeholder, old success heading, v3.21.5, `manifestDigest`, or `baselineCommit` remains.
- Planner boundary: PASS; tracked `git status --short`, `git diff --check`, planning-artifact trailing-whitespace, conflict-marker, and ignored-artifact checks are clean; exactly the two ignored plan/draft artifacts changed.
- Frozen complete-plan SHA-256 submitted for round 35: `ef8144ea115e1ac24bae4d364dc2d7b0ce92c4747201ddefde21e48aefdcbfed`.

## Dual review round 35
- Native Momus `/root/momus_plan_review_round35`: **NOT OKAY**, two blockers: the registry `target` already contained the full `nixosConfigurations.*` path but the build runbook prepended that namespace again; and destructive writer in-flight states were fsynced by the broker but absent from the canonical install-journal state machine.
- Independent isolated Codex CLI session `019f616a-ccea-7880-900b-5f4fd8c204f7`, model `gpt-5.6-sol`, reasoning `xhigh`, workspace `/home/mei/.cache/nix-plan-reviews/round35.fOAikB`, isolated home `/home/mei/.cache/nix-plan-reviews/round35-home.DA32Vs`: **NOT OKAY**, two blockers: the same double-prefixed build target and no explicit collision rejection between the encrypted identity medium holding final private keys and the disk selected for erasure. Completed with `REVIEW_RC=0`.
- Round-36 correction scope: consume the registry's full target path verbatim; make destructive in-flight states part of the single exact install-journal transition sequence with fail-closed interrupted recovery; and retain/compare identity-medium descriptors before erase and before key streaming.

## Round-35 consolidated corrections before round 36
1. Changed the native build runbook to resolve `<target>.config.system.build.toplevel` because `target` is already a complete flake attribute path; added an explicit no-namespace-prepend rule.
2. Expanded the exact install-journal sequence to include `partition-writer-in-flight`, the completed partition state, both ordered per-partition formatter in-flight/completed states, and no other partition/formatter states.
3. Required every in-flight state to be fsynced before writable FD injection and its completed state only after clean writer exit, descriptor fsync, and post-write validation; an interrupted in-flight state is interpreted only as attended destructive recovery and cannot auto-resume.
4. Made target-local identity preflight retain whole-device/data-partition descriptors and parent topology, reject equality/shared-parent/rebinding with the install disk or boot ISO before `ERASE`, hold/revalidate them through provisioning, and keep the remote controller medium outside target-path resolution.
5. Added negative cases for the exact destructive journal state sequence, automatic resume attempts from in-flight states, identity-medium whole/partition collisions, boot/install shared parents, rebind before key streaming, and remote controller/target source confusion.

## Round-36 preflight validation
- Structure: PASS; exact eight scaffold H2 headings, 26 sequential tasks with references/verification/commit disposition, four final lanes, and clean formatting.
- Dependency graph: PASS; all 26 rows are reciprocal and acyclic with deterministic order `1 3 2 6 4 5 8 9 13 7 12 11 15 16 18 17 19 21 22 14 23 20 10 24 25 26`.
- Contract closure: PASS preflight for full-path target resolution, single-journal destructive writer states, interrupted destructive recovery, and identity-medium/install-disk/boot-ISO separation.
- Stale-contract scan: PASS; no `nixosConfigurations.<target>` double prefix, unenumerated in-flight state, unresolved identity-medium collision, lowercase sentence splice, old static-verifier placeholder, v3.21.5, `manifestDigest`, or `baselineCommit` remains.
- Planner boundary: PASS; tracked status and diff check are clean; only the two ignored plan/draft artifacts changed.
- Frozen complete-plan SHA-256 submitted for round 36: `f4d71f3aa989ccde947fbc421a028f754615571b8a5cfa987053b014253109f0`.

## Dual review round 36
- Native Momus `/root/momus_plan_review_round36`: **OKAY**.
- Independent isolated Codex CLI session `019f6177-d24d-7f83-b96c-b13b5e9311fa`, model `gpt-5.6-sol`, reasoning `xhigh`, workspace `/home/mei/.cache/nix-plan-reviews/round36.ownmk0`, isolated home `/home/mei/.cache/nix-plan-reviews/round36-home.DBcwgf`: **NOT OKAY**, four blockers: the exact secret scanner lacked closed byte rules/input/absence schemas; journal header/entry/digest preimages were undefined; public and encrypted removable-media filesystem/unlock/layout contracts were not executable; and raw FAT inspection on a mounted ESP was not synchronized against dirty cache or ordinary writers. Completed with `REVIEW_RC=0`.
- Round-37 correction scope: define one byte-exact scanner and manifest/result contract; define one canonical hash-chained journal wrapper with closed per-kind projections; define exact public and encrypted media preparation/mount/key layouts; and inspect/write the ESP only across synchronized zero-mount and private-writer-namespace boundaries.

## Round-36 consolidated corrections before round 37
1. Added canonical `config/security/secret-rules.json` with exact Python-bytes regex engine, five credential rule families plus both synthetic canaries, raw-byte/no-normalization semantics, overlapping-match cardinality, redacted match tuples, and scanner-closure binding.
2. Added closed `secret-scan-input.json` inputs/edges/production-absence schema, exact input IDs, byte/count/result derivation, absence applicability, and zero-match completeness rules shared by capture, F3, Darwin, and publication scans.
3. Added the canonical journal wrapper, closed hash-chained entry shape, exact header/entry/wrapper digest preimages, prefix-preserving replacement rule, and definitions for binding, first-committed, terminal-entry, and terminal-journal digests.
4. Added closed install and switch headers plus state-data unions, and common exact auth/Darwin header/data mappings; added digest/order/prefix/gap mutation tests.
5. Selected one-partition GPT/ext4 `NIXCFGDATA` for public request/kit/handoff media with an attended formatter, exact mount options, empty-before-write verification, fsync/remount/reread, and wrong-layout negatives.
6. Selected one-partition GPT/LUKS2 Argon2id plus inner ext4 for identity media, with sealed-memfd passphrase input, exact labels/mapper, closed five-file layout and manifest, controller/target key separation, read-only private mounts, teardown poisoning, and fixture-only automated keys.
7. Replaced mounted raw-FAT inspection with `lock+inhibitor -> writable-FD/mount census -> syncfs -> non-lazy zero-mount -> raw parse/revalidation -> approval -> one supervised private read-write writer namespace -> syncfs/unmount -> raw postverify -> exact original mount restoration`; unreadable foreign namespaces fail and hostile root remains explicit.

## Round-37 preflight validation
- Structure: PASS; exact eight scaffold H2 headings, 26 sequential tasks with references/verification/commit disposition, four final lanes, and clean formatting.
- Dependency graph: PASS; all 26 rows are reciprocal and acyclic with deterministic order `1 3 2 6 4 5 8 9 13 7 12 11 15 16 18 17 19 21 22 14 23 20 10 24 25 26`.
- Contract closure: PASS preflight for scanner byte rules/manifests/absence rows, journal digest preimages, exact public/encrypted media, and zero-mount ESP observation with one private writer.
- Stale-contract scan: PASS; no generic-rule-only scanner, undefined journal digest name, `filesystemType:"data"`, generic mountable-data-partition contract, mounted raw-FAT observation, target double prefix, old static-verifier placeholder, v3.21.5, `manifestDigest`, or `baselineCommit` remains.
- Planner boundary: PASS; tracked status/diff and plan/draft whitespace/conflict checks are clean; only the two ignored planning artifacts changed.
- Frozen complete-plan SHA-256 submitted for round 37: `c20e0676d4bb5c6ae4ecaaf45515808ae784af1e952427cb77fdcc99f981f45b`.


## Dual review round 37
- Native Momus `/root/momus_plan_review_round37`: **NOT OKAY**, five blockers: path-distinct byte-identical containers collapsed under parent-content hashes; the broad no-plaintext claim exceeded the deliberately generic historical scan; the exhaustive install journal omitted remote manifest/route/deadline/key facts and left the terminal digest undefined; auth/Darwin journal mappings were not closed; and publication had no preparation-to-observer join.
- Independent isolated Codex CLI session `019f618a-dd6d-7811-9727-12d4ed622695`, model `gpt-5.6-sol`, reasoning `xhigh`, workspace `/home/mei/.cache/nix-plan-reviews/round37.jT1uBf`, isolated home `/home/mei/.cache/nix-plan-reviews/round37-home.OUJjkG`: **NOT OKAY**, six blockers: checked-in canary literals self-matched the scanner closure; private-key rules omitted age/PGP/PKCS#8 forms; the install journal omitted remote facts; Task-11/12 journals were untyped; identity-media key generation/recovery-key location/destructive guards were undefined; and the controller install private key had no producer or cleanup lifecycle. Completed with `REVIEW_RC=0`.
- Round-38 correction scope: make scan graph identity path-sensitive; narrow historical assertions to the exact closed rule set and provider rotation; assemble canaries from fragments and cover all retained private-key forms; close every transaction kind/header/state/digest; give identity media an exact guarded five-key generation flow; link remote authentication into the install journal; and bind preparation, media retrieval, publication, status, and F4 through one immutable receipt triple.

## Round-37 consolidated corrections before round 38
1. Replaced content-hash parent edges with exact `{parentInputId,...,memberInputId}` edges whose IDs resolve to path-qualified input rows; byte-identical containers at different paths remain distinct and bidirectional cardinality is enforceable.
2. Narrowed the no-secret assertion to scanner-detectable matches under the closed rules, retained exact-object/path/count handling for the historical blob, and made provider rotation/activity review the only historical credential invalidation claim.
3. Changed public canaries to runtime assembly from checked-in noncontiguous fragments, forbade a complete canary in source/rules, and added native age, OpenPGP, PKCS#8, and encrypted-PKCS#8 private-key rules.
4. Expanded the canonical journal enum to install, switch, installer-auth, bootstrap-password, password-retirement, auth, and Darwin activation; defined all headers, state/data unions, resume branches, entry/header/wrapper/state digest preimages, remote direct/nullability rules, and the terminal-verification digest.
5. Added every remote request/manifest/nonce/boot/deadline/transport/route/SSH/key fact to the Task-7 install header and linked the sole Task-11 installer-auth journal into its durable verification snapshot instead of leaving a second ledger.
6. Made identity preparation accept exact host/device inputs, apply held-descriptor/removable/no-mount/no-swap/no-holder/private-namespace guards, and generate five fresh distinct target/controller keys directly inside the encrypted medium. The recovery private identity and manifest-bound install-authorizer now have exact protected locations and cleanup semantics.
7. Added `PREPARATION_ID` to the closed publication runbook inputs; bound preparation ID, receipt hash, and five-file snapshot digest in the publication record/envelope/status/F4; and used one logical `handoff/` scan root so pre-scan and post-retrieval manifests can be byte-equal despite different physical staging paths.
8. Added preparation fields to the exact `publication.handoff` envelope schema and required the final observer to reopen the immutable receipt/snapshot before promotion.

## Round-38 preflight validation
- Structure: PASS; exact eight scaffold H2 headings, 26 sequential tasks with references/verification/commit disposition, four final lanes, and clean formatting.
- Dependency graph: PASS; all 26 rows are reciprocal and acyclic with deterministic order `1 3 2 6 4 5 8 13 18 21 9 15 22 19 23 7 17 12 11 16 14 20 10 24 25 26`.
- Contract closure: PASS preflight for path-sensitive scan graphs, runtime canaries and retained key rules, complete install/auth/password/Darwin journals, guarded five-key identity media, remote journal linkage, and preparation-to-publication receipt binding.
- Stale-contract scan: PASS; no assembled canary literal, `parentSha256` edge, untyped remote ledger, unspecified controller install key, four-key identity manifest, publication-without-preparation runtime input, target double prefix, old static-verifier placeholder, v3.21.5, `manifestDigest`, or `baselineCommit` remains.
- Planner boundary: PASS; tracked status/diff and plan/draft whitespace/conflict checks are clean; only the two ignored planning artifacts changed.
- Frozen complete-plan SHA-256 submitted for round 38: `784ab562a501001a81de090eb9a24c67b4f6c77d369c4e474a1052ae8f0e8e7c`.


## Dual review round 38
- Native Momus `/root/momus_plan_review_round38`: **NOT OKAY**, two blockers: the broad generic assignment regex made zero-match scans of pinned Nixpkgs inputs unsatisfiable, and direct `noKexec` was null in observation but true in the journal.
- Independent isolated Codex CLI session `019f6198-a2f4-7031-becc-4670a340f001`, model `gpt-5.6-sol`, reasoning `xhigh`, workspace `/home/mei/.cache/nix-plan-reviews/round38.J6DgdJ`, isolated home `/home/mei/.cache/nix-plan-reviews/round38-home.Is3hNR`: **NOT OKAY**, five blockers: the same direct `noKexec` contradiction; no closed snapshot location for the installer-auth terminal digest; no closed snapshot location for personal-wallpaper provenance; missing `{PREPARATION_ID}` in the exhaustive placeholder enum; and a writable-FD race between ESP scan and unmount. Completed with `REVIEW_RC=0`.
- Round-39 correction scope: replace the high-false-positive assignment rule with a provider-specific high-confidence rule; make direct kexec facts inapplicable/null consistently; add one exact always-present install-state snapshot; add the missing publication placeholder; and close the ESP scan-to-unmount race with post-unmount and immediate pre-consumption FD/mount censuses.

## Round-38 consolidated corrections before round 39
1. Replaced `generic-assignment` with bounded `wallhaven-api-assignment`, retaining private-key, age, AWS, GitHub, and synthetic rules. Arbitrary public test assignments no longer poison whole locked-input scans, and no allowlist or input omission was introduced.
2. Made `noKexec=null` for direct media in both observation and journal; remote remains `noKexec=true`, and the plan still hard-denies remote kexec.
3. Added `installerAuthTerminalDigest` and `personalWallpaperStateDigest` to the canonical install header and terminal-verification preimage.
4. Added exact always-present `install-state.json` to the durable verification snapshot. It contains a direct-null/remote-terminal installer-auth digest and a closed managed-default/staged wallpaper provenance union; the journal header binds both.
5. Added `{PREPARATION_ID}` to the exhaustive runbook placeholder set so publication's three declared runtime inputs can form a valid argv template.
6. Required complete writable-FD and mount censuses after non-lazy ESP unmount and again immediately before approval consumption, inspecting `/proc/<pid>/fd`, `fdinfo` flags, descriptor device/filesystem identity, and detached live filesystem references. Ordinary processes have no pathname opening route after zero mounts; unreadable state remains INVALID.

## Round-39 preflight validation
- Structure: PASS; exact eight scaffold H2 headings, 26 sequential tasks with references/verification/commit disposition, four final lanes, and clean formatting.
- Dependency graph: PASS; all 26 rows are reciprocal and acyclic with deterministic order `1 3 2 6 4 5 8 13 18 21 9 15 22 19 23 7 17 12 11 16 14 20 10 24 25 26`.
- Contract closure: PASS preflight for attainable whole-input zero-match rules, direct/remote kexec consistency, installer-auth/wallpaper snapshot binding, publication placeholder completeness, and post-unmount ESP descriptor-race exclusion.
- Stale-contract scan: PASS; no `generic-assignment`, direct `noKexec=true`, unbound installer-auth digest, out-of-contract wallpaper provenance, missing preparation placeholder, pre-unmount-only writable-FD census, assembled canary literal, `parentSha256`, untyped remote ledger, target double prefix, old static-verifier placeholder, v3.21.5, `manifestDigest`, or `baselineCommit` remains.
- Planner boundary: PASS; tracked status/diff and plan/draft whitespace/conflict checks are clean; only the two ignored planning artifacts changed.
- Frozen complete-plan SHA-256 submitted for round 39: `b70e4e7f028ffbbf8e8b2510503c46029cf578a7fb1fb98b0a8b9c821dce9da7`.


## Dual review round 39
- Native Momus `/root/momus_plan_review_round39`: **NOT OKAY**, one blocker: pinned Nixpkgs intentionally contains public test private keys/AWS-shaped examples, so unconditional zero raw matches across complete locked inputs remained impossible.
- Independent isolated Codex CLI session `019f61a0-a48b-7fd2-a724-99ecd8cf2727`, model `gpt-5.6-sol`, reasoning `xhigh`, workspace `/home/mei/.cache/nix-plan-reviews/round39.CoBpvA`, isolated home `/home/mei/.cache/nix-plan-reviews/round39-home.eXcDGM`: **NOT OKAY**, three blockers: age/GitHub regex length bounds were off by one/minimum; NixOS GC protected a nonexistent `drill-authorized` state instead of the actual rollback-drill states; and the post-candidate update/renewal lifecycle was left materially undefined despite expiring singleton records. Completed with `REVIEW_RC=0`.
- Round-40 correction scope: classify only exact content-addressed locked public test fixtures separately from unexpected matches; correct every regex bound; enumerate the complete NixOS root-retention state set; and make the delivery's finite two-generation/30-day qualification boundary explicit instead of implying an undefined perpetual update system.

## Round-39 consolidated corrections before round 40
1. Empirically scanned every top-level locked input with the exact rules and defined canonical `config/security/upstream-public-fixtures.json`: three matched inputs, 41 exact tuples (38 private-key headers, one age key, two AWS-shaped examples), 8198 canonical bytes, SHA-256 `6b21e125b25a2b0f7d4c34981f90f73e8a81c30394cc8044d06c24155663a83e`.
2. Restricted public-fixture classification to the complete input name/revision/NAR/logical-path/file-size/file-hash/rule/offset/length tuple. Copies, generated outputs, project source, task streams, alternate paths, changed locks, omissions, additions, and duplicates remain unexpected failures; no matching bytes are emitted.
3. Extended common scan results, task capture, publication records/envelopes/status, Task-25 production results, Darwin scans, rollback observations, F3, and F4 with the fixed fixture-manifest digest and scope-exact approved count. Complete input scans require approved count 41 and unexpected count 0; task/realized-closure scans require approved count 0 and unexpected count 0.
4. Corrected exact regex ranges to private-key header 27..37, age secret key 36..116, GitHub token 33..266, AWS 20, and Wallhaven assignment 45..66.
5. Replaced the mistyped NixOS GC state list with every exact nonterminal/retained state; no transaction root is auto-pruned and `abandoned` is the sole attended removal terminal.
6. Closed lifecycle scope: this delivery permits only generation 1 foundation and generation 2 candidate, has an at-most-30-day aggregate qualification window, rejects post-candidate product commits/generations/duplicate singleton records, and requires a new approved plan before generation 3, updates, renewal, or continued qualification. Expiry becomes NOT VERIFIED rather than a rewrapped claim.

## Round-40 preflight validation
- Structure: PASS; exact eight scaffold H2 headings, 26 sequential tasks with references/verification/commit disposition, four final lanes, and clean formatting.
- Dependency graph: PASS; all 26 rows are reciprocal and acyclic with deterministic order `1 3 2 6 4 5 8 13 18 21 9 15 22 19 23 7 17 12 11 16 14 20 10 24 25 26`.
- Contract closure: PASS preflight for exact locked public-fixture classification, zero unexpected matches, regex ranges, NixOS GC state retention, and finite post-candidate lifecycle.
- Empirical fixture evidence: PASS; current locked input paths yielded exactly three matched inputs/41 tuples and canonical fixture-manifest SHA-256 `6b21e125b25a2b0f7d4c34981f90f73e8a81c30394cc8044d06c24155663a83e`.
- Stale-contract scan: PASS; no unconditional zero-raw-match whole-input claim, old regex ranges, NixOS `drill-authorized` GC typo, undefined post-candidate update promise, generic assignment rule, direct kexec contradiction, unbound install-state facts, missing preparation placeholder, pre-unmount-only FD census, assembled canary literal, `parentSha256`, or untyped remote ledger remains.
- Planner boundary: PASS; tracked status/diff and plan/draft whitespace/conflict checks are clean; only the two ignored planning artifacts changed.
- Frozen complete-plan SHA-256 submitted for round 40: `d44179658822bbe44af9c23887d964d8c2a9e70bee401274bc306a7610ddc842`.

## Dual review round 40
- Native Momus `/root/momus_plan_review_round40`: **NOT OKAY**, three blockers: the remote manifest/request schemas omitted their Task-7 transaction ID; the recovery reboot path lacked approval-consumed, boot-entry-in-flight, and boot-pending journal states; and Task 7 directly mutated boot state despite Task 9's sole-writer contract.
- Independent isolated Codex CLI session `019f61ac-0772-7841-8160-51e6ac55fd6c`, model `gpt-5.6-sol`, reasoning `xhigh`, workspace `/home/mei/.cache/nix-plan-reviews/round40.ee5qZB`, isolated home `/home/mei/.cache/nix-plan-reviews/round40-home.2Io2pO`: **NOT OKAY**, one blocker: canonical NAR and imported-store representations of the 41 approved upstream fixture rows were counted as unexpected duplicates even though the complete scan intentionally included all three representations. Completed with `REVIEW_RC=0`.
- Round-41 correction scope: bind the precreated Task-7 transaction ID into both signed remote schemas and every consumer; put the complete recovery-publication mutation behind Task 9 with explicit crash states; and separate the 41 logical fixture-base tuples from graph-derived authenticated byte representations without permitting copied or unlinked matches.

## Round-40 consolidated corrections before round 41
1. Split approved upstream-fixture accounting into `approvedPublicFixtureBaseMatchCount` and `approvedPublicFixtureRepresentationMatchCount` throughout the common scan result, task capture, publication record/envelope/status, Task-25 producer/consumer, Darwin native scans, rollback observations, F3, and F4.
2. Kept the canonical fixture manifest at exactly 41 logical source-file rows and derived every additional authenticated occurrence through unique `{fixtureRowId,inputId,representationKind,offset,length}` keys. The only representation kinds are `logical-file`, `nar-stream`, and `imported-store-file`; NAR offsets must map through the strict parser to the exact manifested member/relative offset, and imported files must join through that exact NAR edge. Copies and unlinked matches remain unexpected.
3. Added the already-created 48-hex Task-7 `transactionId` to both exact remote manifest and manifest-request schemas. The signed manifest, retained request, installer-auth transition, Task-7 wrapper, observation, and verification snapshot must join on that ID; it is distinct from nonce/request IDs.
4. Expanded the install-journal reboot sequence with `recovery-esp-budget-verified`, `recovery-reboot-consumed`, `recovery-boot-entry-in-flight`, and `recovery-boot-pending`, including exact state-data variants and fail-closed idempotent crash recovery.
5. Removed Task 7 as a bootloader writer. Its fixed call to Task 9's `publish-install-recovery <transactionId>` opens only canonical Task-7 state, acquires Task-8 resources, consumes approval before mutation, publishes/verifies the recovery entry/default, appends all recovery states, and is the sole recovery boot mutation path.
6. Added the missing previous-closure representation count to the Darwin rollback observation and made the native predicate explicitly require candidate/previous base counts, representation counts, and unexpected counts all equal zero.

## Round-41 preflight validation
- Structure: PASS; exact eight scaffold H2 headings, 26 sequential tasks with references/verification/commit disposition, four final lanes, and clean formatting.
- Dependency graph: PASS; all 26 rows are reciprocal and acyclic with deterministic order `1 3 2 6 4 5 8 9 13 7 12 11 15 16 18 17 19 21 22 14 23 20 10 24 25 26`.
- Contract closure: PASS preflight for transaction-bound remote schemas, Task-9-only recovery publication with consumed/in-flight/pending states, exact 41-row base fixture accounting, graph-derived representation accounting, and complete Darwin candidate/previous count fields.
- NixOS MCP evidence: PASS; live flake-input enumeration resolved 17 current input edges, including the top-level `agenix`, `home-manager`, and `nixpkgs` roots used by the empirically frozen public-fixture manifest.
- Stale-contract scan: PASS; no singular approved-fixture count field, base-only schema row, old request-ID wording, collapsed reboot transition, direct Task-7 boot writer, `all four counts`, or zero-unspecified-fixture-count wording remains.
- Planner boundary: PASS; tracked status/diff and plan/draft whitespace/conflict checks are clean; only ignored planning artifacts changed.
- Frozen complete-plan SHA-256 submitted for round 41: `51e12a9ef03f7931c99a46458a96d79b49ffb6d9bb28c3f70e88b7d780e88362`.

## Dual review round 41
- Native Momus `/root/momus_plan_review_round41`: **OKAY** for exact plan SHA-256 `51e12a9ef03f7931c99a46458a96d79b49ffb6d9bb28c3f70e88b7d780e88362`.
- Independent isolated Codex CLI session `019f61b3-ef26-75e1-81fe-5504409949e8`, model `gpt-5.6-sol`, reasoning `xhigh`, workspace `/home/mei/.cache/nix-plan-reviews/round41.iNs71n`, isolated home `/home/mei/.cache/nix-plan-reviews/round41-home.rXH9Uk`: **OKAY** for the same exact plan SHA-256. The disposable committed `PLAN.md` hash check passed and the command completed with `REVIEW_RC=0`.
- Same-SHA high-accuracy gate: **PASS**. No implementation began; the approved handoff is `$omo:start-work`.
