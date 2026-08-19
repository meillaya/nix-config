# Independent convergence evidence audit

> **Superseded checkpoint.** This retained red audit describes the pre-closure
> state and its then-current O1-O134/I1-I13 inventory. The controlling current
> result is `convergence-reaudit.md`, including the closing context additions
> O135-O141 and I14-I20. Historical failures below are preserved as causal
> evidence rather than rewritten as if they never occurred.

Auditor: `convergence_evidence_auditor`  
Date: 2026-07-13  
Production revision: `e9f78180748f1feb428ffb20f9d932c5d9918a48`  
Scope: research artifacts and current repository only; no production edits.

## Verdict

**BLOCKED FOR EPISTEMIC CLOSURE; THE RESEARCH COVERAGE ITSELF PASSES.**

The source collection, base-lane floor, two expansion waves, redaction control,
and adversarial corrections are all present. The research cannot yet receive an
unconditional convergence PASS because its canonical ledgers were never
finished: `claim-graph.md` still says `Pending`, every row in `intent-diff.md`
still says `Unknown`/`Pending audit`, and `cause-disappearance.md` plus
`verification-economics.md` contain no data rows. Consequently there is no
single machine-readable place that distinguishes final claims from superseded
Wave 1/2 wording.

This is not a request for another broad search wave. It is a synthesis/ledger
closure blocker with exact fixes below.

## Structural audit

| Gate | Result | Evidence |
|---|---:|---|
| All supplied links classified | **PASS** | `source-ledger.md` has exactly S01-S60, 60 unique IDs, 58 unique URLs, no pending row. The two repeated URL pairs are correctly represented by three duplicate rows (S23, S47, S50). |
| Coverage limitations disclosed | **PASS** | S32 is explicitly `reviewed-partial-rate-limited`; the dynamic GitHub search was sampled and counterbalanced with exact upstream source. Blocked Photon pages are marked `blocked-recovered`, not silently called direct reads. |
| Dedicated base-lane floor | **PASS** | 15 non-root Wave 1/1B/1C reports: 6 + 6 + 3. Root direct inspection is additional, not counted to inflate the floor. |
| At least two expansion waves | **PASS** | Wave 2 has seven reports, including root exact-pin closure; Wave 3 has six adversarial skeptic reports. `expansion-log.md` journals every return. |
| Observation inventory | **PASS** | O1-O134 are unique and sequential. Evidence boundaries are recorded per row. |
| Root pin contradiction | **PASS, with canonicalization required** | Direct `flake.lock` evaluation resolves the root input through `root.inputs.nixpkgs = nixpkgs_3` to `d407951447dcd00442e97087bf374aad70c04cea`. `59e69648...` remains a legitimate helper `mkpasswd` pin/transitive node, but is not the system root pin. O50/O73 and `wave-2-root-exact-ai-pin.md` are controlling evidence. |
| Production tree untouched | **PASS** | HEAD remains `e9f7818...`; baseline patch is zero bytes; no tracked production diff is present. |
| Secret-value redaction | **PASS** | A value-aware scan found zero copies of the tracked credential bytes anywhere under the research session. Reports contain only field/type/length/digest metadata. The value was not reproduced in this audit. |
| Citation/content spot audit | **PASS WITH TEMPORAL QUALIFIERS** | Exact nixos-anywhere 4dfb813 source lines were independently reopened and support phase ordering, VM-test exclusions, insecure SSH option order, installer bypass, Disko/install ordering, and install-only assumptions. Root-pin links match the lock. Dynamic release/GitHub state must retain its observation date. No inspected citation was found to assert content absent from its target. |
| Canonical claim closure | **FAIL** | `claim-graph.md` is empty; old and corrected claim statements coexist without final disposition IDs. |
| Intent/status closure | **FAIL** | I1-I13 are all still `Unknown`; disappearance and verification-economics ledgers are empty. |

During this audit, only factual research metadata was corrected: S32/S33/S37
now point to their actual Wave 1C artifacts, and O79 now states the skeptic's
narrow boundary that the red test is a real fixture failure but not proof that
the live nixos-anywhere extra-files path fails.

## Blocking fixes

### B1 — Build the canonical claim graph

Populate `claim-graph.md` with one row per final synthesis claim. Every row must
contain: stable claim ID, final wording, status (`verified`, `modeled`,
`inferred`, `physical-deferred`, `refuted`, or `superseded`), severity,
observation IDs, counterevidence, pin/date validity, and final report section.

At minimum, explicitly supersede these older formulations rather than leaving
readers to discover the correction in later prose:

| Older formulation | Controlling final disposition |
|---|---|
| `59e696...` is the repository root Nixpkgs pin | **Refuted.** Root is `d407951...`; 59e696 remains only a helper/transitive pin. Use O50/O73. |
| One unchanged closure cannot span diverse hardware | **Refuted as absolute.** Generic compatibility-class closures are real; current x86 is only a conditional mainstream UEFI baseline and AArch64 only a plausible SystemReady template. Use O111-O113. |
| Every machine needs Facter/nixos-hardware to boot | **Refuted as prerequisite.** They are optional assurance/configuration inputs; concrete host leaves remain necessary to bind destructive choices and support claims. |
| Facter+NetworkManager conflict is a current defect | **Narrowed to prospective.** It occurs in executed synthetic enrollment at exact pin; current outputs do not import Facter. Use O74/O116. |
| 2 GiB safely retains 42 full current payloads under an 80% gate | **Refuted.** Exact arithmetic is 82.98%; use dynamic byte preflight or a larger XBOOTLDR policy. Use O124. |
| `%DISK%` itself fails open | **Refuted.** The literal placeholder fails closed in the observed tool path; the unsafe part is unbound human replacement with a valid wrong device. Use O123. |
| Red installTest proves the real install path fails | **Refuted.** It proves a non-self-contained fixture; causal isolation boots. The real extra-files choreography remains separately unverified. Use O79/O80. |
| X11 units are proven continuously active under Niri | **Narrowed.** They are unconditionally scheduled and may be active or fail/retry. Use O120. |
| Integrated NixOS has duplicate Noctalia units | **Refuted.** Exact generation has one integrated unit. |
| Portal routing is wholly coherent, including RemoteDesktop | **Narrowed.** ScreenCast/Screenshot/chooser/Secret routing is supported; exact Niri lacks Mutter RemoteDesktop input injection. Use O118. |
| GTK and Qt both have demonstrated conflicting values | **Narrowed.** GTK has competing writers; integrated Qt is redundant but materially aligned. |
| Runtime Noctalia state override is intrinsically a defect | **Refuted.** It is an intentional upstream policy; stale warnings/ignored declarative intent remain defects. |
| Kitty/Fira theming is absent on macOS | **Refuted statically.** It reaches all six evaluations and HM has a native font-copy path; physical CoreText/rendering remains deferred. Use O121/O130. |
| Darwin duplicate app ownership doubles store bytes | **Narrowed.** Two projection owners and 111 name overlaps are proven; Nix-store payload can deduplicate. Use O128. |
| `allowBroken` currently masks a selected broken package | **Not demonstrated/latent.** `allowUnsupportedSystem` has executed current counterexamples. Use O129/O132. |
| Missing formatter is a high-severity portability defect | **Refuted.** It is a low-severity developer-interface gap. |
| Shared root/user key independently creates a large privilege escalation | **Narrowed.** Direct root login is undesirable, but the normal user is already root-equivalent through Docker/Nix/admin boundaries. Use O117. |
| Tracked provider credential is critical/account takeover | **Refuted.** Impact is a medium confidentiality/read-only API exposure with unknown current validity; external regeneration remains an immediate incident action. Use O117. |
| Unchecked kexec affects every documented install | **Narrowed/conditional.** It affects the default kexec path; a recognized direct installer or install-only phase bypasses it. Use O114/O115. |

No final claim may cite O61's transitive-pin package numbers. Exact root-pin AI
facts must come from O73 / `wave-2-root-exact-ai-pin.md`.

### B2 — Close I1-I13 against the final graph

Replace every `Unknown` row in `intent-diff.md` with one of `met`, `partly met`,
`not met`, or `physical-deferred`, and link the canonical claim/observation IDs.
The present repository cannot truthfully mark the overall “any machine” intent
met. The correct top-level result is a bounded compatibility/support matrix plus
per-host enrollment and physical acceptance.

Particularly, Wi-Fi hardware appearance on the unidentified laptop, native
Darwin activation/CoreText, physical AArch64 boot, Secure Boot enrollment,
GPU/audio/suspend/hotplug, disk identity, post-reboot reachability, and live
portal/lock behavior must remain `physical-deferred`; static evaluation or VM
success must not convert them to PASS.

### B3 — Populate disappearance and verification-economics ledgers

`cause-disappearance.md` must record the major rejected causes and their
replacement explanation: missing Wi-Fi profile cannot explain a missing netdev;
Noctalia duplicate unit was absent; root-write fear was refuted by HM target
prefixing; 100 MiB is bootable but lacks rollback margin; placeholder literal is
fail-closed; current agenix plaintext exposure is absent because no secrets are
active.

`verification-economics.md` must distinguish cheap deterministic gates from
expensive or destructive gates. Required rows include exact eval, native build,
Disko VM, strict installer wrapper tests, FAT/ENOSPC fault injection, sacrificial
disk install, and per-physical-host acceptance. This prevents “not run because
expensive” from being misreported as green.

### B4 — Reconcile final severity labels

The final report must separate **impact severity** from **remediation priority**:

- SSH host-authentication bypass is critical only for a destructive remote
  install where the network path is not independently trusted; it remains high
  consequence on an ordinary LAN.
- Unchecked mutable kexec is high only when kexec actually runs.
- Credential regeneration is P0 incident response, while the documented impact
  is medium confidentiality/read-only and validity is unknown.
- Broken manual lock is P0 session-security functionality; notification owner
  ambiguity is high/P0 only as an immediate-usability release blocker, not a
  critical security issue.
- Remove xautolock/xss-lock/i3lock from the Wayland role as a lock-authority
  correction; Picom/Polybar cleanup is P1 session hygiene.
- Missing microcode is P1 security/errata freshness, not evidence of generic
  boot failure.
- The production-derived Disko test is a release-gate P0, but its failure is
  fixture self-containment debt, not a demonstrated physical installation
  failure.
- Missing formatter is low severity; `allowBroken` is latent; Facter/DHCP is
  prospective until host enrollment.

### B5 — Preserve citation and evidence boundaries in synthesis

The source ledger is complete enough to synthesize, but the final graph/report
must retain these qualifications:

1. S32 is a rate-limited sample, not an exhaustive census of GitHub VS Code
   configurations.
2. GitHub release mutability, issue state, Actions/ruleset state, cache presence,
   and upstream HEAD are point-in-time observations dated 2026-07-13.
3. `same` in the observation manifest means the report named by the preceding
   explicit artifact row; canonical claim rows should name the actual report to
   avoid ambiguous citation traversal.
4. Executed synthetic Nix evaluations, generated-store inspection, QEMU/OVMF,
   isolated D-Bus tests, FAT images, and fault harnesses are not physical-target
   evidence.
5. “Perfect on any machine” must be rejected as a literal guarantee. The
   evidence supports one repository with shared policies, bounded
   compatibility-class profiles, named host/storage leaves, and expiring
   physical acceptance evidence.

## Evidence-layer boundary audit

| Layer | Supported conclusions | Conclusions still forbidden |
|---|---|---|
| Repository/source | Declared options, paths, pins, policy owners | Runtime success or hardware support |
| Exact evaluation/generated artifacts | Selected services/packages, module conflicts, platform availability, command existence | Native activation, login timing, device binding |
| Executed synthetic/model | Facter/DHCP interaction, OpenSSH option precedence, FAT capacity, age boundary primitives, ENOSPC control flow | Physical NIC/firmware, real power loss, target disk identity |
| QEMU/OVMF | Generic UEFI/Disko/boot path under the test fixture | Vendor firmware, Secure Boot, Wi-Fi/GPU/suspend, real extra-files transport |
| Supporting live session on another host | CLI/DBus behavior is reproducible in that environment | Installed target Niri cold-login or multi-output lock correctness |
| Physical deferred | None may be reported as PASS yet | Wi-Fi netdev/association, GPU/audio/power, macOS rendering, ARM boot, sacrificial disk/recovery |

## Final audit state

Research breadth is sufficient and no additional generic source swarm is
required. After B1-B5 are implemented, re-run this convergence audit against the
canonical graph and synthesized Markdown/HTML/PDF. An unconditional PASS is
possible only if the final deliverables preserve every physical defer and use
the Wave 3 dispositions rather than the superseded Wave 1/2 wording.

## EXPAND

- No new broad research lead. Required work is canonical graph/intent/ledger
  closure, followed by deliverable review.
- Re-audit only temporally unstable sources immediately before publication if
  the report date changes materially.

## CLAIMS

- **AUDIT-1 (executed, high confidence):** all 60 supplied source entries are
  classified; the dedicated 15-lane base floor and two expansion waves are met.
- **AUDIT-2 (executed, high confidence):** no tracked credential bytes occur in
  the research artifacts.
- **AUDIT-3 (executed, high confidence):** root Nixpkgs is d407951; 59e696 is not
  the root system pin, though it remains a real helper/transitive pin.
- **AUDIT-4 (high confidence):** the evidence supports bounded compatibility
  classes and per-host physical acceptance, not literal universal readiness.
- **AUDIT-5 (blocking):** convergence cannot pass while the claim graph and
  intent/disappearance/economics ledgers remain empty or pending.
