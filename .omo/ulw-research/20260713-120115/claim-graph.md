# Claim Graph

Converged 2026-07-13 at repository baseline `e9f7818`. Atomic decision claims,
confidence, applicability and evidence anchors are in `verified-claims.md`.

## Intent-to-claim graph

| Intent | Governing claims | Current truth |
|---|---|---|
| I1 generic baseline + host isolation | P1-01, P1-02, POS-02, D-02 | Bounded x86 baseline exists; host assurance/storage leaves and physical class proof do not. |
| I2 boot/filesystem/initrd/hardware config | P0-04, P0-05, P1-06–P1-09, POS-03 | VM boot path is plausible; physical selector, production fixture, capacity, Secure Boot and alternate boot classes remain open. |
| I3 firmware/drivers/power | P1-02, P1-03, P2-01, D-02–D-04 | Redistributable baseline exists; microcode and host exceptions are missing; physical behavior unproved. |
| I4 Wi-Fi immediate use | P1-04, P1-05, POS-02, D-01 | Coherent installed NM/wpa stack; controller diagnosis/profile handoff/physical association absent. |
| I5 theming all hosts | P1-10–P1-13, POS-06, D-05–D-06 | Kitty is declared on all six; Linux theme authority/assets and native rendering are not closed. |
| I6 identity/secrets/bootstrap/wallpapers | P0-01, P0-10, P1-13–P1-15, P1-17, POS-07–POS-08 | Credential incident and identity/ownership defects remain; useful primitives pass. |
| I7 install paths/recovery | P0-02–P0-05, P1-18, POS-09, D-07–D-08 | Direct ISO can avoid kexec risk; unattended remote/offline/recovery contracts are not complete. |
| I8 rollback/GC/diagnostics | P1-06–P1-08, P1-16 | Current GC/ESP/rollback policies conflict; proportional gate design is decision-complete but unimplemented. |
| I9 role/platform separation | P1-01–P1-02, P1-14–P1-15, readiness/support matrices | WSL/server/macOS/native NixOS require separate roles; current graph overprojects shared assumptions. |
| I10 checks/CI | P0-05, P0-08–P0-09, P1-16 | Existing green surface is shallow and contains an executed false green. |
| I11 SSH/install trust | P0-01–P0-04, P0-10, POS-09 | Critical conditional transport/artifact findings upheld; validated design exists but is not integrated. |
| I12 Niri interoperability | P0-06–P0-07, P1-10–P1-12, POS-04–POS-05, D-05 | Portal split and unit ownership are positive; lock/session/notification/assets are not ready. |
| I13 truthful support boundary | P1-02, six-config matrix, support-class matrix | Literal universality rejected; compatibility-class support vocabulary is now decision-complete. |
| I14 reproducible shared editor startup | P1-19 | Emacs currently performs mutable/network-dependent bootstrapping; offline native startup is unproved. |
| I15 authenticated standalone bootstrap | P1-20 | README still prescribes a moving installer response piped to a shell. |
| I16 incremental standalone adoption | P1-14, P1-21 | Fixed identity is broken and the backup-safe/host-owned migration contract must be preserved during repair. |
| I17 Homebrew-free Darwin | P1-15, P1-22 | Nix owns Darwin packages/apps; native proof and one app projection owner remain open. |
| I18 compatibility interfaces | P1-23 | Public architecture aliases, Bash/Nushell parity, and Niri-only login are binding refactor constraints. |
| I19 external display brightness | P1-24, D-05 | I2C/DDC ownership is defined; physical displays and standalone helper remain unverified. |
| I20 location/input policy | P1-25 | Shared module hard-codes one timezone and keyboard layout; typed host/user overrides are absent. |

## Dependency edges

- P0-02 + P0-03 + P0-04 + P0-05 → **safe destructive install gate**.
- P1-01 + P1-02 + P1-03 + P1-04 + physical D-01/D-02 → **named x86 host readiness**.
- P0-06 + P0-07 + P1-10 + P1-11 + P1-12 + physical D-05 → **Niri immediate-usability claim**.
- P0-08 + P0-09 + P1-16 → **truthful multi-system CI claim**.
- P0-01 + P0-10 + P1-17 + external D-09 → **secret/auth incident closure**.
- P1-06 + P1-07 + P1-08 → **rollback/capacity safety**.
- POS-06 + P1-12 + physical D-06 → **cross-host theme claim**.
- P1-19 + P1-20 + P1-21 → **reproducible standalone/developer bootstrap**.
- P1-22 + P1-15 + D-06 → **Homebrew-free native Darwin claim**.
- P1-23 + P1-24 + P1-25 + D-05 → **preserved interfaces and enrolled desktop ergonomics**.

## Canonical node registry

The wording and full evidence URLs live in `verified-claims.md`; this registry
is the stable machine-readable disposition layer requested by the convergence
audit.

| Claim IDs | Status | Severity / priority | Observation IDs | Controlling counterevidence or qualification | Validity | Final section |
|---|---|---|---|---|---|---|
| P0-01 | verified | medium impact / P0 incident | O55,O98–O104,O117 | No validity/account-takeover test; read-only API scope | public refs/store at e9f7818; external state current 2026-07-13 | P0 |
| P0-02 | verified | critical conditional / P0 | O54,O63,O92,O114 | Direct console/authenticated overlay removes precondition | nixos-anywhere 4dfb813/current as of date | P0 |
| P0-03 | verified | high conditional / P0 | O56,O63,O66,O93,O114 | Direct installer/install-only avoids default kexec | exact pin/release state 2026-07-13 | P0 |
| P0-04 | verified | critical destructive / P0 | O11,O63–O65,O81,O123 | Narrowed: literal placeholder fails closed; wrong valid replacement is risk | e9f7818/ff8702b | P0 |
| P0-05 | verified | release-gate P0 | O79–O81,O105,O131–O133 | Narrowed: fixture failure, not proven live install failure; isolated boot passes | exact pins/e9f7818 | P0 |
| P0-06 | verified | high session security / P0 | O38–O39,O85–O86,O120 | KDL syntax cannot validate spawned CLI; exact CLI/source does | Noctalia d8d8ed5/e9f7818 | P0 |
| P0-07 | verified | high usability / P0 blocker | O85,O87,O119 | Narrowed: multiple candidates, not guaranteed simultaneous processes | exact realized profile | P0 |
| P0-08 | verified | high false-green / P0 | O108,O129,O132 | Narrowed: allowBroken latent; unsupported has executed counterexamples | exact package graph | P0 |
| P0-09 | verified | high lifecycle / P0 support truth | O48,O126–O130 | Evaluation succeeds accidentally; support policy controls | 26.11-era root, policy observed 2026-07-13 | P0 |
| P0-10 | verified | high auth / P0 | O57,O101,O103,O117 | Narrowed: shared-key marginal escalation lower due existing root-equivalent roles | exact eval; live sshd deferred | P0 |
| P1-01 | verified | high architecture / P1 | O2,O10–O14,O74–O78 | Concrete leaves bind assurance/destructive choices, not generic boot prerequisites | e9f7818/d407951; physical deferred | P1 |
| P1-02 | inferred | high support boundary / P1 | O34–O37,O50–O53,O111–O113 | Generic compatibility classes refute absolute impossibility; physical class not executed | e9f7818/d407951; physical deferred | P1 |
| P1-03 | verified | high security freshness / P1 | O1,O50–O53,O111–O117 | Narrowed: missing microcode not generic boot failure; redistributable firmware exists | exact closure | P1 |
| P1-04 | verified | high connectivity / P1 | O8–O9,O51–O52,O74–O77,O115 | Narrowed: NM+wpa backend is coherent; remote Wi-Fi unsupported | exact pin/upstream current date | P1 |
| P1-05 | verified | high future collision / P1 | O74–O76,O116 | Prospective: current no-Facter outputs do not collide | exact/current synthetic enrollment | P1 |
| P1-06 | verified | high boot capacity / P1 | O79–O84,O122–O124 | Exact payload result plus modeled policy; future sizes vary; 2 GiB/42 correction controls | exact current payload | P1 |
| P1-07 | verified | high rollback / P1 | O84,O122 | Synthetic exact-builder evidence, not real VFAT/power-cut VM | exact builder | P1 |
| P1-08 | inferred | high rollback / P1 | O109,O122–O124 | Source/control-flow basis; physical rollback untested | e9f7818 | P1 |
| P1-09 | verified | high support boundary / P1 | O34–O36,O112,O125 | Physical firmware absent | exact output/current platform docs | P1 |
| P1-10 | verified | high session hygiene / P1 | O29,O85,O120 | Narrowed: scheduling proven; continuous activity/wallpaper conflict not | exact generation | P1 |
| P1-11 | verified | normal usability / P1 | O30,O88 | Clean profile lookup controls private unrelated closures | exact generation | P1 |
| P1-12 | verified | normal presentation / P1 | O70–O72,O89–O90 | Narrowed: GTK conflict/assets absent; Qt only redundant/aligned | exact store/config; rendering deferred | P1 |
| P1-13 | verified | normal provenance / P1 | O67–O72 | Policy/legal disposition distinct from runtime | e9f7818/upstream pin | P1 |
| P1-14 | verified | high genericity / P1 | O49,O126–O127 | Narrowed: root-write fear refuted; identity conflict remains | exact HM pin/e9f7818 | P1 |
| P1-15 | verified | normal ownership / P1 | O46–O47,O128 | Narrowed: store-byte doubling not established | exact Darwin/HM pins | P1 |
| P1-16 | verified | high evidence gap / P1 | O20–O23,O105–O110,O131–O134 | Narrowed: no workflow does not itself prove semantic invalidity | repo/remote state 2026-07-13 | P1 |
| P1-17 | verified | high functional / P1 | O98–O102,O117 | Narrowed: current agenix inactive; sync destination bug remains | e9f7818 | P1 |
| P1-18 | inferred | high offline readiness / P1 | O15–O19,O74–O78 | No cold-store physical test | Nix semantics/current repo | P1 |
| P1-19 | verified | high reproducibility / P1 | O135 | Clean-home offline native startup not executed | e9f7818 shared Emacs source | P1 |
| P1-20 | verified | high bootstrap trust / P1 | O136 | Vendor response content/authenticity not independently bound | e9f7818 README | P1 |
| P1-21 | verified intent | high migration safety / P1 | O137 | Current fixed identity violates part of the intent; second-host rehearsal deferred | reachable Lore history/current docs | P1 |
| P1-22 | verified intent | normal/high Darwin ownership / P1 | O138 | Native Darwin activation deferred | reachable Lore history/current docs | P1 |
| P1-23 | verified intent | high compatibility / P1 | O139 | Destructive install/parser/generation checks required after refactor | reachable Lore history/current interfaces | P1 |
| P1-24 | verified ownership, physical-deferred outcome | normal usability / P1 | O140 | Physical DDC and privileged helper execution deferred | reachable Lore history/current docs | P1 |
| P1-25 | verified | low/normal portability / P1 | O141 | User/location suitability is host-specific | e9f7818 shared NixOS source | P1 |
| P2-01 | verified | normal policy / P2 | O1–O4 | Option-state claim only; universal enablement rejected | e9f7818 | P2 |
| P2-02 | verified | normal capability / P2 | O61–O62,O73,O129–O130 | Narrowed: O61 package numbers superseded by root O73; physical GPU absent | root d407951 | P2 |
| P2-03 | verified | low/normal ownership / P2 | O59–O62,O130 | Dynamic code search sampled/rate-limited | e9f7818; search date | P2 |
| P2-04 | verified | normal provenance / P2 | O67–O69 | Discourse contextual, official branding normative | 2026-07-13 | P2 |
| P2-05 | inferred | low readiness relevance / P2 | O20–O23 | Performance claims workload/hardware/pin-specific; deferred | point in time | P2 |
| POS-01 | verified | positive | O1,O50–O53,O105–O106,O126–O130 | Six evaluate; only x86 closure has realization evidence | exact pins | Positive |
| POS-02 | verified | positive | O1,O50–O53,O111–O117 | Closure presence not physical behavior | exact pins | Positive |
| POS-03 | verified | positive | O80 | VM evidence; test-only secret isolation; selector/transport excluded | exact pins | Positive |
| POS-04 | verified | positive | O40,O91,O118 | Narrowed: RemoteDesktop input injection absent | exact pins/current portal docs | Positive |
| POS-05 | verified | positive | O85,O119–O121 | Refutes duplicate-unit suspicion; standalone is a different output | exact generation | Positive |
| POS-06 | verified | positive | O46–O49,O121,O130 | Static declaration only; CoreText/rendering physical-deferred | exact pins | Positive |
| POS-07 | verified | positive | O13,O65,O103,O110 | Test evidence; remote/install auth separate | e9f7818 | Positive |
| POS-08 | verified | positive | O102 | Primitive only; production integration absent | disposable exact test | Positive |
| POS-09 | verified | positive | O93–O96 | Design/harness; independent builder, operations, physical transitions deferred | exact sources/local harness | Positive |
| D-01 | physical-deferred | high connectivity | O115–O117 | Actual WLAN controller unavailable | expire on hardware/kernel/firmware change | Deferred |
| D-02 | physical-deferred | high class support | O111–O113 | Needs two diverse x86 physical hosts | expire on hardware/kernel/firmware change | Deferred |
| D-03 | physical-deferred | high ARM support | O112,O129 | Needs named ARM target/native build/boot | target/pin-specific | Deferred |
| D-04 | physical-deferred | high boot support | O125 | Needs signed/alternate firmware profiles and hardware | firmware/profile-specific | Deferred |
| D-05 | physical-deferred | high session security/usability | O118–O121 | Needs cold-login/lock/portal/render physical session | generation/hardware-specific | Deferred |
| D-06 | physical-deferred | high Darwin support | O121,O126–O130 | Needs native activation/CoreText/LaunchServices | pin/macOS/hardware-specific | Deferred |
| D-07 | physical-deferred | high offline availability | O15–O19,O74–O78 | Needs disconnected physical install/recovery | kit revision-specific | Deferred |
| D-08 | physical-deferred | critical conditional trust | O92–O97,O114 | Needs physical stage-transition and mismatch tests | installer/host-specific | Deferred |
| D-09 | physical-deferred | medium impact / P0 external action | O98–O104,O117 | Provider rotation/account review is external; never test old value | provider state | Deferred |

## Refuted or narrowed nodes

- R1: “one unchanged closure cannot span diverse hardware” — refuted as an
  absolute; bounded compatibility-class closures are valid.
- R2: `networking.wireless` competes with NetworkManager — refuted at exact pin.
- R3: unresolved `%DISK%` wipes another disk — refuted; literal is fail-closed,
  while wrong valid substitution remains unsafe.
- R4: integrated NixOS duplicates Noctalia unit — refuted.
- R5: pure HM `/.config` target writes under `/` — refuted at exact HM pin.
- R6: current agenix activation exposes runtime secrets — refuted; no secrets.
- R7: 2 GiB/42 meets 20% headroom — corrected; 82.98% occupancy.
- R8: missing microcode proves generic boot failure — refuted; it is
  security/errata debt.
- R9: current Wi-Fi absence is caused by missing SSID — refuted; no interface
  requires controller/driver/firmware/rfkill/kernel diagnosis.

## Evidence-state terminal

- **Verified by source/eval/execution:** P0/P1/P2/POS tables in
  `verified-claims.md`.
- **Implementation-deferred:** production remediations and CI gates.
- **Physical-host-deferred:** D-01 through D-08 where applicable.
- **External-action:** D-09 provider rotation/account review.
- **Unresolved source contradictions:** none.
