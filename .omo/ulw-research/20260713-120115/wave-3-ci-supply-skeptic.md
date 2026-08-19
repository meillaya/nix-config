# Wave 3 adversarial review — CI, supply chain, and false-green claims

**Review date:** 2026-07-13  
**Repository revision:** `e9f78180748f1feb428ffb20f9d932c5d9918a48`  
**Scope:** challenge Wave 1 operations/security and Wave 2 CI/trust conclusions; no production files changed and no credential value reproduced.

## Executive verdict

The earlier research is directionally right that the repository lacks a durable
verification surface, but it sometimes treats “has CI” as if it were a product
property and proposes a larger matrix than is necessary to expose the current
failures. CI is not required by Nix and its absence does not make a personal
configuration wrong. For this repository, however, the absence is a material
**evidence gap** because:

1. the public remote has no workflow, no branch protection/ruleset, and no
   required status check;
2. the production Disko `installTest` is red but is not in the exported check
   surface;
3. `allowUnsupportedSystem = true` is currently hiding an x86-only package in
   the declared aarch64 Linux configuration; and
4. the user's target claim is automatic portability, not merely “I can repair
   my own laptop after a failed rebuild.”

The highest-signal solution is therefore a small mandatory PR/pre-push gate,
one real native build for every platform that remains *claimed*, a scheduled or
change-triggered Linux VM lane, and a separate physical-host qualification
record. Do not make every expensive test a default `checks` member and then run
an unqualified `nix flake check` in every job. Do not use a GitHub cache of the
Nix store keyed only by `flake.lock`; use normal signed Nix substitution. Do not
pretend CI can prove firmware, Wi-Fi, GPU, suspend, EFI/NVRAM, or disk identity.

The installer transport and exposed-credential findings remain more urgent
than workflow polish. A green workflow cannot compensate for a destructive
installer that does not authenticate the target host or for a credential that
must be revoked outside Git.

## Direct adversarial observations

### A. Workflow absence is real, long-standing, and not an accidental deletion

Executed against the local repository and authenticated public remote:

```text
git ls-files '.github/**'                         -> empty
git log --all -- .github                         -> empty
historical tree scan over all local revisions    -> no .github files
GET /repos/Meillaya/nix-config/actions/workflows  -> total_count: 0
GET /repos/Meillaya/nix-config/actions/permissions
                                                   enabled: true
                                                   allowed_actions: all
                                                   sha_pinning_required: false
GET /repos/Meillaya/nix-config/branches/main/protection
                                                   branch not protected
GET /repos/Meillaya/nix-config/rulesets           -> []
```

This makes “no CI” an upheld fact. It does **not** prove why the owner omitted
CI. The history supports “manual workflow from inception,” not “CI was removed”
or “Actions are disabled.” A workflow added without branch protection would be
informational only: direct pushes could still bypass it. For a single-owner
personal repo, an equivalent fail-closed local pre-push/release procedure can
be acceptable; for the stated immediate-portability goal, an unrecorded manual
procedure is too easy to skip and supplies no durable evidence to a second
machine.

### B. The current exported surface misses a real red installation test

`modules/flake/checks.nix:3-35` exports only three source-oriented checks. Wave
2's executed evidence shows those three x86 checks pass in 22 seconds, while
the actual production
`nixosConfigurations.x86_64-linux.config.system.build.installTest` fails during
activation because its Disko fixture does not stage the required bootstrap
password-hash contract. A controlled test-only isolation proves that the disk
layout can boot under OVMF, but does not turn the production test green.

That is the strongest concrete justification for automation: this is not a
hypothetical “CI might catch something someday.” A currently relevant install
output is already red, and `nix flake check` cannot report it because it is not
owned by the current check/gate surface. The same VM test also rewrites the
literal production `%DISK%` placeholder to `/dev/vdb`, so a separate pure
assertion on the *unrewritten production configuration* is mandatory.

The earlier statement “export all manual tests and both Disko tests as checks”
needs a cost caveat. `nix flake check` builds every selected-system `checks`
derivation unless `--no-build` is used. Putting all heavy VM tests in `checks`
while also prescribing `nix flake check -L` in every native PR job defeats the
proposed fast/nightly split. Either:

- export them as clearly named checks but have PR jobs build an explicit
  lightweight allowlist and nightly jobs build the integration allowlist; or
- expose heavy integration derivations under a separately documented output
  (`hydraJobs`, packages, or a project-specific integration output) and invoke
  them explicitly.

Discoverability matters; forcing every integration test into the default fast
path does not.

### C. `allowUnsupportedSystem` is an executed false green;
`allowBroken` is presently only an unnecessary escape hatch

Two clean `git archive HEAD` copies were evaluated with only research-local
changes:

| Variant | Command | Result |
|---|---|---|
| `allowBroken=false`, unsupported still allowed | `nix flake check path:$TMP --all-systems --no-build --show-trace` | **rc 0**, 6 s |
| both `allowBroken=false` and `allowUnsupportedSystem=false` | same | **rc 1**, 6 s |

The strict-platform run failed on
`google-chrome-150.0.7871.46` inside the declared `aarch64-linux` host. Nixpkgs
reports that package's platforms as x86_64 Linux plus Darwin, not aarch64
Linux. The repository selects `google-chrome` in
`modules/nixos/packages.nix:88`; the same package policy is shared by both
architecture-named hosts.

Therefore:

- **upheld/high:** `allowUnsupportedSystem=true` is masking a concrete
  architecture error today. It must be removed, and package selection must be
  made host/platform-aware. Merely adding an ARM runner would likely turn the
  hidden metadata error into a build or runtime failure rather than make Chrome
  portable.
- **downgraded/medium-low current impact:** `allowBroken=true` suppresses a
  valuable guard and should be removed, but the all-system no-build evaluation
  succeeded with it disabled. No currently evaluated package was proved to
  need it. Calling both flags equally responsible for observed false greens
  overstates the evidence.

The Nixpkgs manual confirms that broken/platform policy is checked at
evaluation time for evaluated packages and that these two flags override the
default rejection behavior:
<https://nixos.org/manual/nixpkgs/unstable/#chap-packageconfig>.

### D. The formatter conclusion is factual but low severity

`nix fmt -- --check` fails because the flake exports no formatter. That is a
developer-interface gap, not portability, firmware, installer, or runtime
evidence. A pinned formatter plus a normalized tree is useful, but it belongs
after the red install test, platform escape hatch, installer trust, and secret
incident. `git diff --check` is a dependency-free first gate. Do not label the
absence of `formatter` a high-severity system defect.

### E. The `options.json` warning is upstream, current, scoped, and not fixed by
simply updating the pin

The warning is real and comes from the root Nixpkgs
`nixos/lib/make-options-doc/default.nix`: option JSON has string context
discarded and is passed into a derivation. The important correction to Wave 2
is that there is **no known fixed current pin** at review time:

- Nixpkgs issue [#485682](https://github.com/NixOS/nixpkgs/issues/485682) is
  open.
- Commit `a4a56fe47b252409336946681efac7b0c4521bbd` changed `builtins.toFile` to
  `passAsFile`, but Nix 2.33 now emits the equivalent warning at
  `builtins.derivation`.
- Current Nixpkgs `master` at observed revision
  `e8a02fc3224f20e319a850a3f0b4ddead450df6b` still contains
  `unsafeDiscardStringContext` at the same option-JSON boundary.

The issue is documentation/provenance metadata, not evidence that the booted
system, Wi-Fi, or firmware is broken. “Update to a fixed pin” is therefore
refuted as an available immediate remedy. The cost-effective policy is:

1. recognize the exact fingerprint as one upstream exception with issue,
   owner, and review date;
2. fail on new/unclassified warnings;
3. carry a tested local patch only if the generated documentation is actually
   relied upon and the warning becomes a failure; or
4. explicitly disable the unwanted documentation output if the user decides
   it has no value.

Do not globally require literal zero stderr while the exact upstream exception
is unresolved. Do not disable useful docs solely to produce a cosmetically
quiet log. The Nix manual also distinguishes evaluation from building:
`--no-build` does not build checks, while `--all-systems` only selects all
system outputs for checking
(<https://nix.dev/manual/nix/2.19/command-ref/new-cli/nix3-flake-check>).

### F. Cache recommendations need Nix-native semantics, not a generic key

There is no project workflow or project cache today, so no current cache is
poisoned. For future CI:

- GitHub's dependency cache is branch/tag scoped, restored as untrusted input,
  readable from some untrusted PR contexts, and capable of poisoning later
  workflows. GitHub explicitly says not to store secrets in it:
  <https://docs.github.com/en/actions/concepts/workflows-and-actions/dependency-caching#cache-security>.
- A key of only `hash(flake.lock) + OS + architecture` is **not** a complete
  identity for this repository: tracked source changes outside `flake.lock`
  change derivations, local overlays/fixed-output source declarations matter,
  action/Nix versions affect the evaluator, and a generic restored archive is
  not automatically a trusted Nix substitute.
- Normal Nix substitution already addresses outputs by store path and verifies
  non-content-addressed imports with a trusted signature when `require-sigs`
  remains at its default `true`. Official documentation:
  <https://nix.dev/manual/nix/2.21/command-ref/conf-file.html#conf-require-sigs>
  and <https://nix.dev/guides/recipes/add-binary-cache.html>.

Thus “cache by `flake.lock + OS + arch`” is refuted as a sufficient design.
Prefer cache.nixos.org plus a dedicated signed Cachix/Attic/Nix cache if local
outputs justify one. Fork PRs receive read-only substitution and no cache write
token; trusted main/release jobs may publish. Verify the configured public key
and keep `require-sigs=true`. A GitHub cache can still hold non-sensitive
download/evaluator data if every restored byte is treated as untrusted, but it
should not be the integrity boundary for `/nix/store`.

The current NixOS configuration's nix-community substituter has no matching
nix-community trusted key, so it is mostly an availability/noise problem under
default signature enforcement, not unsigned-code acceptance. Darwin does have
that key. Remove dead/obsolete substituters or configure a deliberate matching
key; never solve cache misses with `require-sigs=false`.

### G. Action SHA pinning is upheld, but it is conditional and not the main
current supply-chain risk

If GitHub Actions are added, full-length action SHA pinning is the correct
baseline. GitHub calls a full commit SHA the only immutable action reference
and recommends verifying that the SHA belongs to the expected action
repository:
<https://docs.github.com/en/actions/reference/security/secure-use#using-third-party-actions>.

The earlier priority needs narrowing:

- Today there are no actions to pin.
- A read-only workflow over a public repository with no secrets has a much
  smaller blast radius than a deployment workflow.
- Installer credentials, cache signing keys, host identities, or write tokens
  must never be available to `pull_request` code, and untrusted code must never
  run under `pull_request_target`.
- Pinning does not make an action trustworthy; the pinned source still needs
  review and a deliberate update transaction.

The larger active supply-chain defect is the runtime installer path documented
in Wave 2: current `nixos-anywhere` disables host authentication and can fetch a
mutable kexec archive without an approved content digest. Workflow pinning does
not repair either boundary.

### H. Update provenance is better than Wave 2's harshest wording, but update
selection still lacks review

The committed state is reproducible in the relevant narrow sense: every flake
input node is locked, and local theme updaters write an exact commit URL plus a
prefetched content hash. Querying an upstream “latest commit” endpoint is the
**selection policy**, not the final build identity. Once reviewed and committed,
the revision/hash prevents the same lock/source declaration from silently
resolving to different bytes.

What is missing is governance and compatibility proof:

- broad `nix flake update` can mix unrelated trust domains;
- “latest” is not evidence that a commit is reviewed, released, compatible, or
  non-malicious;
- no required job builds the resulting host closures or summarizes the diff;
- main is unprotected, so even a future update workflow could be bypassed.

A per-input/trust-domain update PR with before/after revisions, source hashes,
release notes, closure diff, and matching platform gates is high signal.
Requiring every upstream Git commit to carry a locally validated GPG signature
would be a stronger policy but is not generally available across all current
inputs and is not necessary for reproducibility. The trust root is the reviewed
repository change plus pinned hash; signature/attestation requirements should
be reserved for the destructive installer artifacts and any project-owned
cache publication.

### I. GC/rollback conclusions are upheld; continuous whole-store verification
is not the cost-effective fix

The Linux clean app deletes every eligible generation older than seven days
and refreshes the boot loader. Darwin automatically uses 30 days while its
manual app uses seven. A time threshold alone guarantees neither a minimum
number of prior known-good generations nor successful reboot into one. That is
an operational rollback risk, especially alongside the independently proved
100 MiB ESP capacity problem.

CI can test retention logic, fail-closed ESP budgeting, and VM rollback. It
cannot prove a laptop's firmware will select the previous entry after a bad
update. Keep at least a count **and** duration of known-good generations, retain
the old lock/closure through a canary window, and perform a real reboot/rollback
drill before GC.

Running `nix store verify --all` on every nightly job is low signal and can be
very expensive; Nix already verifies hashes/signatures as it imports
substitutes. Prefer scoped `nix store verify --recursive` for release closures,
newly published project-cache paths, or an integrity incident. The official
command distinguishes content integrity from trust:
<https://nix.dev/manual/nix/2.23/command-ref/new-cli/nix3-store-verify>.

### J. Physical qualification is mandatory; cryptographic signing of every
record is optional for this single-operator repo

The conclusion that CI/VMs cannot establish hardware readiness is fully upheld.
No hosted runner or QEMU Disko test proves the target PCI/USB IDs, firmware
blobs, rfkill state, WPA association/reconnect, GPU acceleration, suspend,
external displays, audio, Bluetooth, EFI variable writes, disk serial, or a
firmware boot-menu rollback.

A per-host evidence record tied to hardware IDs, Facter/hardware report, disk
identity, config revision, closure path, kernel/firmware versions, and test date
is required for a **supported host** claim. For a single trusted operator, a
tracked Git record and commit identity are sufficient auditability; an offline
signature on every physical evidence JSON is defense-in-depth, not a minimum.
An offline-signed installer manifest is more defensible because it authorizes a
destructive operation and binds an out-of-band host key and disk identity.

The earlier wording “signed physical-host evidence” is therefore downgraded.
The evidence itself, expiration/invalidation rules, and honest unsupported
status are mandatory; a separate signing ceremony is optional unless multiple
operators, an untrusted control plane, or formal non-repudiation requires it.

## Claim disposition

| Claim | Disposition | Reason |
|---|---|---|
| No workflow currently exists | **UPHELD (high confidence)** | Local tree/history and remote workflow API all show zero; Actions itself is enabled. |
| Lack of CI makes the config invalid | **REFUTED** | Nix and local gates can work without GitHub; absence is an evidence/discipline gap, not a semantic failure. |
| Current exported checks are insufficient | **UPHELD (high)** | Only three lightweight checks; production Disko install test is red and invisible. |
| Every manual/integration test should be in default PR `nix flake check` | **DOWNGRADED** | Heavy checks must be addressable but explicitly tiered, or the fast/nightly split collapses. |
| `allowUnsupportedSystem` creates a current false green | **UPHELD (executed, high)** | Strict evaluation fails on x86-only Google Chrome in aarch64 Linux. |
| `allowBroken` creates a current false green | **DOWNGRADED** | Dangerous blanket bypass, but strict-broken all-system evaluation passed; no current dependency was identified. |
| No formatter is a high-severity defect | **REFUTED** | Missing developer interface/style gate; not a portability/runtime failure. |
| The `options.json` warning can be fixed by updating Nixpkgs | **REFUTED at review date** | Open upstream issue; master still has the context-discard boundary and Nix 2.33 warning. |
| Warning handling should fail on new warnings | **UPHELD** | Use classified exact exceptions; literal zero stderr is currently unrealistic. |
| Cache should be keyed by lock + OS + arch | **REFUTED as sufficient** | Does not cover source/tool identity or trust; use store paths and signed Nix substitution. |
| Cache writes must be trusted-only | **UPHELD** | PR caches are untrusted/readable; no cache/deploy credentials in fork PRs. |
| Actions should use immutable full SHAs | **UPHELD if Actions are used** | Official GitHub guidance; still requires source review and least privilege. |
| All four native platforms must build on every PR | **DOWNGRADED/conditional** | Required only for outputs the project continues to claim; otherwise retire/quarantine the unsupported output. Nightly alone cannot justify a merge-time support claim. |
| Update outputs lack reproducible identity | **REFUTED** | Lock revisions/NAR hashes and fixed-output hashes do pin committed bytes. Selection/review and compatibility are the actual gaps. |
| Seven-day generation cleanup guarantees rollback | **REFUTED** | It can leave no previous known-good generation; physical reboot remains necessary. |
| CI can prove “works on any machine” | **REFUTED** | It proves reproducible config/build/VM properties only; unknown hardware needs intake and physical evidence. |
| Strict installer and verified local kexec gates are necessary | **UPHELD (critical)** | Destructive SSH target authentication/artifact identity are outside ordinary flake CI and remain unresolved. |

## Minimal high-signal gate set

The following is intentionally smaller than Wave 2's maximal matrix while
still blocking every concrete false green found so far.

### Gate 0 — incident and policy blockers (before calling any workflow green)

1. Revoke/regenerate the confirmed tracked application credential externally,
   remove it from current tracked/runtime state, and record only redacted
   incident metadata. CI cannot perform revocation.
2. Remove `allowBroken`; remove `allowUnsupportedSystem` and make x86-only
   packages such as Google Chrome conditional or unsupported-host outputs
   explicit.
3. Repair the production Disko test fixture so the faithful bootstrap secret
   contract is staged; keep a separate assertion that production disk devices
   contain no placeholder and match a declared by-id contract.
4. Block the current insecure `nixos-anywhere` path pending strict host-key
   authentication and an exact locally verified kexec artifact. This is a
   release/install gate, not merely a lint check.

### Gate 1 — required fast PR/pre-push gate (one Linux job, read-only)

- `git diff --check`.
- `nix flake check --all-systems --no-build --show-trace` with an exact warning
  allowlist; fail on an omitted claimed system, new warning, or unchecked
  project output.
- Explicitly build the three lightweight exported checks once on x86 Linux;
  source-only checks need not be rebuilt four times merely because `perSystem`
  duplicates them.
- Export/run the bounded pure configuration, shell, bootstrap-helper,
  lifecycle, and secret-current-tree tests. Keep mutation tests explicit and
  bounded; the earlier execution log did not record a terminal result after the
  first eight killed mutants.
- Run a pinned broad secret scanner against the current tree/diff with fully
  redacted, mode-0600 output. Establish one full-history baseline after incident
  containment; scan new commits on PRs and rerun full history on scanner-rule
  changes or a schedule rather than paying for the same immutable history every
  job.
- Assert no global broken/unsupported escape hatch and no insecure package
  exception without owner, issue, and expiry.

### Gate 2 — claimed-platform native realization

For every platform still documented as supported, require its native closure
build before merge or release:

- x86_64 Linux: NixOS toplevel plus standalone Home Manager activation package;
- aarch64 Linux: same **only after** the host is made genuinely ARM-aware;
- aarch64 Darwin: nix-darwin system on an Apple Silicon runner;
- x86_64 Darwin: either a frozen 26.05-compatible lane with a retirement date
  or remove the rolling-support claim.

GitHub currently offers public standard labels `ubuntu-24.04`,
`ubuntu-24.04-arm`, `macos-26`, and `macos-26-intel`; public standard runners
are free/unlimited but have only 14 GiB SSD, so closure size may require a
signed binary cache and careful build selection. Official runner inventory:
<https://docs.github.com/en/actions/reference/runners/github-hosted-runners>.

Do not build every exposed package variant if it is not part of a supported
host or documented package API. Do build every package that the host closure or
published support claim depends on. If a native lane is unaffordable or cannot
fit, label that platform `experimental/not verified` or remove the output; do
not convert a skipped runner to PASS.

### Gate 3 — scheduled/change-triggered Linux integration

- Faithful x86 Disko install test including bootstrap file ordering, reboot,
  and negative placeholder/disk identity assertions.
- ESP capacity/ENOSPC test that proves an old entry remains bootable.
- Niri/session/portal/lock/notification/OBS VM tests.
- Full bootstrap mutation suite in isolation.
- Full-history redacted secret scan and an update rehearsal in a disposable
  checkout.

Run aarch64 Disko only when there is an actual supported ARM UEFI host profile;
the current architecture-named generic PC output does not justify duplicating
an expensive VM merely to paint a matrix green.

### Gate 4 — installer/release test

On installer/Disko/helper/kexec changes and before a destructive release:

- known-good host key succeeds; unknown/changed key fails before key upload or
  disk write;
- kexec file digest mismatch fails before upload/execution;
- disk model/serial/size/by-id mismatch fails before Disko;
- exact extra-file ownership/order succeeds;
- install, reboot, final identity, login, and rollback succeed on a sacrificial
  VM/disk.

For one trusted operator, a repository-reviewed manifest plus an out-of-band
verified host fingerprint and exact archive digest can be the minimum. An
offline signature is strongly recommended when the authorization crosses an
untrusted workstation/control plane or involves multiple operators.

### Gate 5 — physical host acceptance (never reported as CI PASS)

Record on every concrete host after relevant kernel, firmware, disk, boot,
network, session, or hardware-profile changes:

- exact PCI/USB IDs and bound kernel drivers;
- firmware/microcode load and missing-blob log review;
- Wi-Fi scan, WPA2/WPA3 association, DHCP/DNS, suspend/reconnect and reboot;
- GPU acceleration, Niri, portals, lock, notifications, Kitty/GTK/Qt theme,
  wallpaper and audio/Bluetooth/input behavior;
- disk/ESP identity and headroom;
- cold boot, previous-generation selection, and successful rollback.

The record must include config commit, closure, kernel/firmware version, test
date, and invalidation rules. A Git commit is sufficient provenance for this
single-owner repo; a separate signature is optional defense-in-depth.

## Minimal workflow security envelope

If implemented in GitHub Actions:

```yaml
permissions:
  contents: read
concurrency:
  group: ci-${{ github.workflow }}-${{ github.ref }}
  cancel-in-progress: true
```

- Pin `actions/checkout`, the Nix installer, and every third-party action to a
  reviewed full SHA.
- Use `pull_request`, not `pull_request_target`, for repository code.
- Give PR jobs no secrets, write token, install identity, deployment key, or
  binary-cache write credential.
- Publish only from protected trusted branches; add branch/ruleset protection
  so required checks actually gate main.
- Use normal trusted Nix substitution. If GitHub cache is used for auxiliary
  data, treat every restored file as attacker-controlled and store no secrets.
- Keep action/source-pin updates separate and reviewed; immutable does not mean
  benign.

## Residual manual evidence after every green gate

Even the complete minimal set does **not** verify:

- a machine whose hardware IDs/profile have never been inventoried;
- proprietary/non-redistributable firmware absent from the closure;
- Secure Boot, legacy BIOS, Apple T2/Silicon NixOS, ARM SBC/U-Boot/device-tree,
  NVIDIA PRIME, RAID/LUKS, fingerprint/IPU6, or other unimplemented classes;
- target firmware/NVRAM behavior or an already occupied dual-boot ESP;
- Wi-Fi credentials and network availability after first boot;
- an actual rollback after mutable application/database schema changes; or
- external credential revocation/account review.

Those remain **not verified**, not CI failures and not implicit support.

## Sources

- Current repository files and full local Git history at the revision above.
- Wave 2 execution logs and Disko/ESP, installer-trust, secret-remediation, and
  CI lifecycle artifacts in this research session.
- Nix flake check semantics:
  <https://nix.dev/manual/nix/2.19/command-ref/new-cli/nix3-flake-check>
- Nixpkgs package-problem policy:
  <https://nixos.org/manual/nixpkgs/unstable/#chap-packageconfig>
- Nix store signature policy:
  <https://nix.dev/manual/nix/2.21/command-ref/conf-file.html#conf-require-sigs>
- Custom binary caches:
  <https://nix.dev/guides/recipes/add-binary-cache.html>
- Store verification:
  <https://nix.dev/manual/nix/2.23/command-ref/new-cli/nix3-store-verify>
- GitHub action pinning:
  <https://docs.github.com/en/actions/reference/security/secure-use#using-third-party-actions>
- GitHub cache security:
  <https://docs.github.com/en/actions/concepts/workflows-and-actions/dependency-caching#cache-security>
- GitHub hosted runner inventory:
  <https://docs.github.com/en/actions/reference/runners/github-hosted-runners>
- Nixpkgs option-context issue:
  <https://github.com/NixOS/nixpkgs/issues/485682>

## EXPAND

- **LEAD:** after production remediation, execute the proposed minimal Gate 1
  and Gate 2 with cold/warm timings and actual 14 GiB runner headroom — **WHY:**
  determines whether every claimed native platform can honestly remain a
  required merge gate — **ANGLE:** cost/evidence ratio, no skipped-success.
- **LEAD:** complete a strict-platform package inventory beyond the first
  Google Chrome failure — **WHY:** evaluation stops at the first unsupported
  package, so additional x86-only aarch64 selections may remain — **ANGLE:**
  remove the global escape hatch and enumerate each necessary host conditional.
- **LEAD:** reconcile the production Disko bootstrap fixture with the helper's
  real extra-files/chown ordering — **WHY:** the current production install test
  is red and the isolated test intentionally bypasses the contract — **ANGLE:**
  faithful dummy secret, no real credential, fail-closed negative controls.
- **LEAD:** test a project-owned signed Nix cache only if native build timings
  justify it — **WHY:** adding cache credentials and actions increases supply
  chain surface — **ANGLE:** measure first, least privilege, PR read-only.

## CLAIMS

- **W3-CI-01 (executed, high):** There has never been a tracked workflow in the
  observed repository history; the public remote has zero workflows, Actions
  enabled, and no main protection/ruleset.
- **W3-CI-02 (executed, high):** Disabling `allowBroken` alone preserves
  all-system no-build evaluation; disabling `allowUnsupportedSystem` exposes
  x86-only Google Chrome in the aarch64 Linux host.
- **W3-CI-03 (executed/session, high):** The three exported checks pass, while
  the production Disko install test is red and outside their surface.
- **W3-CI-04 (source/upstream, high):** The `options.json` warning remains an
  open upstream issue on current master; “update to a fixed pin” is not an
  available immediate remedy at review time.
- **W3-CI-05 (primary docs, high):** Full action SHAs and read-only untrusted
  jobs are valid future baselines, but no action workflow exists today and this
  does not repair installer trust.
- **W3-CI-06 (primary docs, high):** A lock/OS/arch GitHub cache key is not a
  sufficient Nix integrity contract; store-path identity plus trusted cache
  signatures is the correct boundary.
- **W3-CI-07 (reasoned, high):** CI should gate reproducible evaluation/build/VM
  properties; physical hardware acceptance remains a separate per-host record.
- **W3-CI-08 (reasoned, medium-high):** A cryptographic signature on every
  physical evidence record is optional for this single trusted operator, while
  evidence content/invalidation and destructive installer authorization remain
  mandatory.
