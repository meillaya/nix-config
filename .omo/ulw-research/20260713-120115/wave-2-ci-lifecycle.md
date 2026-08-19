# Wave 2 — CI, proof matrix, update, and rollback lifecycle

Research date: 2026-07-13  
Repository revision: `e9f78180748f1feb428ffb20f9d932c5d9918a48`  
Scope: research and bounded verification only; no production configuration was edited.

## Verdict

The repository has a good start on structural and bootstrap-password regression
testing, but its current green surface is **not evidence that the declared
systems build, boot, activate, find hardware, or provide a working desktop**.
There is no GitHub workflow, only three lightweight checks are exported, the
most important semantic and installer tests are manual, and native coverage is
absent for three of the four declared systems. Global
`allowBroken = true`/`allowUnsupportedSystem = true` further converts package
porting errors into false greens.

The right acceptance model is not one enormous “works anywhere” check. It is a
proof ladder:

1. pure, fail-closed repository and option assertions on every PR;
2. native builds on all four declared systems;
3. Linux VM boot/install/session tests;
4. strict-transport sacrificial installation tests;
5. canary activation and rollback drills;
6. physical-host evidence for firmware, Wi-Fi, GPU, audio, suspend, boot and
   the actual disk topology.

An absent, skipped, timed-out, emulated-only, or `--no-build` lane must be
reported as **not verified**, never converted to PASS.

## 1. Current output and verification inventory

### Declared systems and entities

`modules/flake/systems.nix:2-7` declares:

- `x86_64-linux`
- `aarch64-linux`
- `aarch64-darwin`
- `x86_64-darwin`

`modules/entities/hosts.nix:6-38` produces two NixOS configurations, two
nix-darwin configurations, and two standalone Home Manager configurations:

| Output | Current names |
|---|---|
| `nixosConfigurations` | `x86_64-linux`, `aarch64-linux` |
| `darwinConfigurations` | `aarch64-darwin`, `x86_64-darwin` |
| `homeConfigurations` | `standalone-linux`, `standalone-linux-aarch64` |

Every per-system output set exists on all four systems. Exact observed names:

- Linux apps: `build-switch`, `clean`, `home-news`, `home-switch`,
  `search-pkgs`, `sync-secrets`, `update`.
- Darwin apps: `build`, `build-switch`, `check-keys`, `clean`, `copy-keys`,
  `create-keys`, `search-pkgs`, `update`.
- Checks on every system: `dendritic-apps`, `dendritic-architecture`,
  `dendritic-boundaries`.
- The default dev shell exists on every system.
- Four local packages exist on Linux; Darwin exposes those plus the Darwin
  application overlays.

This is output existence, not output realization. `nix flake show` filters
foreign-system children on the current x86_64 Linux host.

### Exported checks versus actual test entrypoints

Only these three checks are exported (`modules/flake/checks.nix:3-35`):

1. `tests/dendritic-architecture.sh`
2. `tests/dendritic-boundaries.sh`
3. `tests/dendritic-apps.sh`

Six executable regression entrypoints are not exported:

1. `nix-instantiate --eval --strict tests/dendritic-config-eval.nix`
2. `bash tests/dendritic-shells.sh`
3. `bash tests/bootstrap-password-install-helper.sh`
4. `bash tests/bootstrap-password-lifecycle.sh`
5. `bash tests/bootstrap-password-mutations.sh`
6. `bash tests/bootstrap-password-secret-scan.sh`

`tests/bootstrap-password-config-eval.nix` is a test helper consumed by the
bootstrap suite, not an independent entrypoint. The Disko-generated
`config.system.build.installTest` is also not exported. There are no NixOS
`pkgs.testers.runNixOSTest` session/portal/network tests.

The three current checks are repeated for each `perSystem`, but this does not
make them platform proofs. They mostly inspect source files and paths. In
particular, the ARM and Darwin copies do not build the corresponding host
configuration or test a native activation.

### CI and formatting surface

- `git ls-files '.github/**'` returned nothing: there is no workflow.
- `nix fmt -- --check` exited 1 because no `formatter.x86_64-linux` exists.
- `bash -n` accepted all tracked scripts in `apps/`, `bin/`, and `tests/`.
- There is no exported shellcheck/shfmt/static-analysis gate.
- The documentation asks for `nix flake check --all-systems`
  (`docs/architecture/dendritic.md:115-128`) but does not explain that foreign
  derivations require matching builders. `--all-systems --no-build` only proves
  evaluation.

## 2. Executed observations

### Bounded successes

On the research host:

| Probe | Result | What it proves |
|---|---:|---|
| `nix flake check --no-build --show-trace` | rc 0, 27 s | current-system output schema/evaluation only |
| `bash tests/bootstrap-password-install-helper.sh` | rc 0 | mock staging, argument, ownership, cleanup, signal and negative cases |
| `bash tests/bootstrap-password-lifecycle.sh` | rc 0 | activation verifier/consumer lifecycle cases |
| `bash tests/bootstrap-password-secret-scan.sh` | rc 0 | only the scanner's enumerated password/hash/private-key patterns |
| `nix fmt -- --check` | rc 1 | formatter output is absent |

The secret scan's green result must not be generalized to “no secrets.” It
looks for a narrow family of password hashes/options and private-key markers;
it does not detect arbitrary service/API credentials. The separate security
lane found a non-empty tracked application credential without reproducing its
value. A real secret scanner needs broad token detectors plus full-history
scanning, and the credential must be revoked independently of CI.

### Warnings are evidence, not decoration

The successful current-system no-build check emitted:

1. `denful` is an unchecked output;
2. `aarch64-linux`, `aarch64-darwin`, and `x86_64-darwin` were omitted as
   incompatible systems;
3. an `options.json` derivation references the pinned Nixpkgs source after
   string context was discarded and “may stop working in the future.”

`--all-systems --no-build` evaluates the foreign configurations and packages,
but still skips package/configuration realization. It emitted the same
`options.json` warning for both Linux configurations and still reported
`denful` unchecked. Another research lane observed rc 0; this lane reproduced
the full evaluation stream, but the final process status artifact was lost to
the bounded runner wrapper, so the local rerun is recorded as evaluation
evidence rather than an independent PASS.

The `options.json` warning points at the exact root Nixpkgs source
`d407951447dcd00442e97087bf374aad70c04cea`. Its implementation in
`nixos/lib/make-options-doc/default.nix:210-245` passes JSON produced with
`builtins.unsafeDiscardStringContext` into a derivation. It is an upstream/pin
compatibility debt surfaced by current Nix 2.33, not proof of a working docs
closure. Either update to a fixed pin or explicitly disable NixOS option docs
when they are not shipped. Until fixed, allowlist the exact warning fingerprint
with an upstream issue, owner, and expiry; fail on any other warning.

### Bounded/incomplete probes

Full NixOS toplevel re-evaluation, the three check builds, the complete mutation
suite, and the shell-runtime suite were stopped after concurrent Nix evaluation
and build contention exceeded the useful bound. The already-realized x86_64
system closure is documented in Wave 1, but this lane does not claim a fresh
full build. These are **not verified in this lane**, not failures and not
passes. CI must give them isolated runners and explicit job timeouts.

## 3. Sources of false green

### Global package-policy bypasses

`lib/nixpkgs.nix:41-47` globally sets:

```nix
allowUnfree = true;
allowBroken = true;
allowInsecure = false;
permittedInsecurePackages = [ "pnpm-10.29.2" ];
allowUnsupportedSystem = true;
```

Nixpkgs normally rejects broken packages and packages whose declared platforms
do not include the host. The global overrides intentionally suppress both
guards ([Nixpkgs global configuration](https://nixos.org/manual/nixpkgs/unstable/#chap-packageconfig)).
They must be false in production and CI. A real exception must name one package,
one host, an owner, reason, upstream issue, and expiry. `allowUnfree` should be a
reviewed `allowUnfreePredicate` inventory rather than a blanket switch. The
single insecure exception needs the same expiry discipline and a test that
fails when it is no longer necessary.

### Evaluation is not a native build or activation

- `--no-build` proves evaluation only.
- Foreign-system evaluation on x86_64 Linux does not prove Darwin frameworks,
  app bundles, launchd activation, or ARM binaries.
- QEMU Disko tests rewrite physical disk paths to virtio disks and cannot prove
  the selected by-id, controller firmware, Secure Boot, NVRAM, Wi-Fi or GPU.
- The architecture-named `aarch64-linux` configuration inherits a PC-style
  UEFI/systemd-boot layout. Evaluation is not evidence that an arbitrary ARM
  board boots.
- Home Manager evaluation is not evidence that files activate without
  collisions or that macOS registers fonts/apps with native services.
- App schema checks do not execute the apps.

### Darwin-specific masking

`modules/darwin/base.nix:45-53` disables the uninstaller and
`system.checks.verifyNixPath`. Both have comments, but suppression is still an
unverified surface. The pinned Nixpkgs warns that 26.05 is the last
`x86_64-darwin` release. `allowUnsupportedSystem` cannot restore definitions,
binary caches, or maintainership after removal. Either:

1. freeze Intel Darwin on a dedicated 26.05-compatible input, test it natively,
   and publish a retirement date; or
2. remove the Intel support claim.

The current rolling `nixos-unstable` root cannot honestly promise indefinite
Intel Darwin support.

## 4. Required CI architecture

### Workflow security baseline

Use `pull_request`, never `pull_request_target`, for code execution. Set:

```yaml
permissions:
  contents: read
concurrency:
  group: ci-${{ github.workflow }}-${{ github.ref }}
  cancel-in-progress: true
```

Pin every action, including checkout and the Nix installer, to a full 40-byte
commit SHA. GitHub identifies full-SHA pinning as the immutable action interface
([secure use](https://docs.github.com/en/actions/reference/security/secure-use)).
Fork PRs receive no secrets, no cache-write token, no deployment credentials,
and no persistent self-hosted runner. Restore-only caches may be used, but
GitHub warns that caches are readable by PRs and are not signed
([cache security](https://docs.github.com/en/actions/reference/workflows-and-actions/dependency-caching)).
Only trusted `push`/scheduled jobs may write the binary cache.

### Gate A — fast PR, all-system evaluation (target: under 10 minutes)

Run on `ubuntu-24.04`:

```bash
git diff --check
nix flake metadata --json > evidence/flake-metadata.json
nix flake show --json > evidence/flake-show.json
nix flake check --all-systems --no-build --show-trace \
  2>evidence/flake-check-warnings.log
nix fmt -- --check
```

After exporting the missing tests, `nix flake check --no-build` must enumerate
all expected check names. Add pure assertions for:

- exact host/config/home/app/check inventory;
- no `%DISK%` in installable host outputs;
- per-host architecture, boot mode, stable disk selector, hardware report and
  Wi-Fi handoff contract;
- `allowBroken == false`, `allowUnsupportedSystem == false`, and no unexpired
  exception without metadata;
- every `tests/*` entrypoint is owned by an exported check;
- no duplicate desktop authorities (notification daemon, locker, portal,
  Noctalia unit owner);
- expected package/firmware/session/portal values.

Treat stderr as a warning budget. New warnings fail. A temporary exact
`options.json` fingerprint may be accepted only with expiry. An omitted system,
missing runner, timeout, or skipped matrix child blocks the merge for any
platform the repository claims to support.

### Gate B — native PR matrix (builds, not activation)

Use current explicit runner labels, not mutable `*-latest` labels:

| Nix system | Current runner | Mandatory builds |
|---|---|---|
| `x86_64-linux` | `ubuntu-24.04` | checks, NixOS closure, standalone HM, local packages |
| `aarch64-linux` | `ubuntu-24.04-arm` | same, natively |
| `aarch64-darwin` | `macos-26` | checks, nix-darwin closure, local packages |
| `x86_64-darwin` | `macos-26-intel` | frozen 26.05 lane or explicit retirement |

GitHub's current hosted-runner reference lists these architectures and labels
([runner reference](https://docs.github.com/en/actions/reference/runners/github-hosted-runners)).
On each native runner:

```bash
nix flake check -L
nix build --no-link ".#checks.${SYSTEM}.dendritic-architecture" \
  ".#checks.${SYSTEM}.dendritic-boundaries" \
  ".#checks.${SYSTEM}.dendritic-apps"
```

Linux additionally builds:

```bash
nix build --no-link \
  ".#nixosConfigurations.${SYSTEM}.config.system.build.toplevel"
nix build --no-link \
  ".#homeConfigurations.${HOME_NAME}.activationPackage"
```

Darwin additionally builds, on the matching native architecture:

```bash
nix build --no-link ".#darwinConfigurations.${SYSTEM}.system"
```

Build every exported local package explicitly or retain full native
`nix flake check` package realization. Smoke-test non-destructive app interfaces:

```bash
nix run ".#search-pkgs" -- --help
nix run ".#update" -- --help
nix run ".#clean" -- --help
nix run ".#home-switch" -- --help       # Linux
```

Expected evidence is the realized store path and closure size for each output,
Nix/Nixpkgs revision, runner OS/architecture, substitution/build counts, and
warning log. A dry-run is useful for cost prediction but cannot replace the
realization:

```bash
nix build --dry-run --no-link "$ATTR" 2>evidence/plan.log
nix build -L --no-link "$ATTR" 2>evidence/build.log
```

### Gate C — nightly Linux integration

Run on native Linux builders with KVM and enough disk/RAM. Export and build each
Disko install test:

```bash
nix build -L --no-link \
  ".#nixosConfigurations.x86_64-linux.config.system.build.installTest"
nix build -L --no-link \
  ".#nixosConfigurations.aarch64-linux.config.system.build.installTest"
```

These must become named `checks`, but remain clearly labelled “synthetic disk.”
Also add `pkgs.testers.runNixOSTest` tests; the NixOS manual documents this as
the out-of-tree VM-test interface
([NixOS tests](https://nixos.org/manual/nixos/stable/#sec-nixos-tests)). Test:

- boot reaches `multi-user.target` and the display manager;
- NetworkManager backend and `wpa_supplicant` DBus wiring;
- Niri session unit starts with software rendering;
- exactly one notification authority and one lock authority;
- expected portals own their DBus interfaces;
- Noctalia command/schema compatibility;
- OBS launcher resolves to an installed executable;
- wrong/missing bootstrap verifier and wrong mount sources fail closed;
- rollback generation boots after a deliberately failing next generation.

Nightly also runs every bootstrap mutation test in isolation, full-tree plus
Git-history secret scanning, `nix store verify`, and an update rehearsal in a
throwaway checkout.

### Gate D — strict installer and release candidate

The current pinned nixos-anywhere disables host-key checking and may execute an
unverified mutable kexec asset. It is not eligible for a release gate until the
strict transport design from Wave 1C is implemented.

On sacrificial VMs and disks, require:

1. known-good host key succeeds;
2. unknown/changed key fails before key upload, closure transfer, or disk write;
3. a local, exact-revision, digest-verified kexec artifact is accepted;
4. digest mismatch fails before execution;
5. disk serial/model/size/by-id mismatch fails before Disko;
6. `--extra-files` and numeric chown occur before activation;
7. full install, reboot, final-host-key continuity, SSH and user login succeed;
8. install-only recovery rejects missing/wrong `/mnt` and succeeds on exact
   root/ESP sources;
9. previous known-good system remains bootable.

The exact upstream interfaces and blind spots are documented in
`wave-1c-librarian-disko-anywhere-contract.md`. No release is promoted when a
destructive test is skipped merely because it is expensive.

### Gate E — manual physical-host qualification

VMs cannot prove firmware or hardware. Each concrete host profile needs a signed
evidence record before “supported” status. Commands include:

```bash
uname -a
cat /etc/os-release
cat /sys/firmware/efi/fw_platform_size 2>/dev/null || true
lsblk -e7 -o NAME,PATH,TYPE,SIZE,MODEL,SERIAL,WWN,TRAN,RM,FSTYPE,MOUNTPOINTS
lspci -nnk
lsusb
rfkill list
nmcli general status
nmcli device status
nmcli -f IN-USE,SSID,BSSID,FREQ,RATE,SIGNAL,SECURITY device wifi list
journalctl -b -k | grep -Ei 'firmware|microcode|iwlwifi|ath|brcm|rtw|amdgpu|nouveau|nvidia'
systemctl --failed --no-pager
systemctl --user --failed --no-pager
```

Physical acceptance requires:

- cold boot and reboot, including selecting the previous boot generation;
- internal storage, ESP headroom and controller driver;
- Wi-Fi scan, WPA2/WPA3 association, DHCP, DNS, reconnect after suspend and
  reboot, plus a wired recovery path where claimed;
- firmware load with no missing-blob errors and microcode appropriate to CPU;
- GPU accelerated Niri, external display, brightness, suspend/resume, audio,
  Bluetooth and input devices;
- Niri lock/unlock, notification, screenshot/screencast portal, file chooser,
  Kitty theme/font, GTK/Qt theme, wallpaper and Noctalia;
- `nixos-rebuild test`, `boot`, reboot, health check, then `switch`;
- rollback plus restore of mutable application data from backup.

Record exact PCI/USB IDs, firmware versions, kernel, closure path and commit.
Passing one Intel laptop does not qualify Broadcom, Realtek, NVIDIA, Apple T2,
Surface, ARM SBC, legacy BIOS, Secure Boot, RAID or LUKS classes. Unsupported
classes stay explicit.

## 5. Update and provenance lifecycle

### Current behavior

The root lock has 18 nodes and pins Git revisions/NAR hashes. The actual root
Nixpkgs is `d407951447dcd00442e97087bf374aad70c04cea`; transitive `nixpkgs` nodes
must not be mistaken for it. `nix run .#update` does two broad operations:

1. `nix flake update`, all inputs unless names are supplied;
2. local update scripts, including three “latest commit” API queries followed by
   fixed-output hash prefetch (`modules/flake/apps.nix:282-525`).

The resulting file is content-pinned, but selection of “latest” is not reviewed
provenance. No workflow tests the diff, emits release notes, or opens a bounded
update PR.

### Required update transaction

1. Start from clean protected main in a disposable checkout.
2. Update one trust domain at a time: core Nixpkgs/modules, desktop shell,
   installer/Disko, overlays, or theme assets. Do not mix them into an
   unreviewable mega-update.
3. Emit a machine-readable before/after ledger: input name, owner/repo/ref,
   exact old/new revision, old/new NAR hash, tag relation, release notes/security
   advisories, and local fixed-output URL/hash.
4. Verify every selected commit belongs to the expected upstream repository;
   final state must contain exact revisions/hashes, never mutable branch URLs as
   execution identity.
5. Run Gates A–C. Installer or Disko changes require Gate D. Platform changes
   require the matching native/physical gate.
6. Build closure diffs before activation:

   ```bash
   nix store diff-closures "$OLD_SYSTEM" "$NEW_SYSTEM"
   nix path-info -Sh "$NEW_SYSTEM"
   ```

7. Promote to one canary with `nixos-rebuild test`; run health probes; create a
   boot generation; reboot; only then switch. Darwin uses a native build and a
   canary `darwin-rebuild switch` with a retained previous generation.
8. Keep the previous lock file, closure, installer artifact, boot generation and
   mutable-data backup through the rollback window. Promote remaining hosts in
   waves, never simultaneously.

Update PRs must never auto-merge merely because evaluation is green. Required
jobs use `continue-on-error: false`; quarantine is nightly-only, requires an
issue/owner/expiry, and cannot satisfy release promotion.

## 6. GC, ESP, rollback, and storage policy

The current lifecycle is inconsistent:

- Linux has no automatic GC, but `apps/*-linux/clean:33-41` deletes system
  generations older than seven days and then rewrites the bootloader.
- Darwin automatically deletes older-than-30-day generations
  (`modules/darwin/base.nix:21-25`), while the manual clean app uses seven days.
- systemd-boot permits 42 entries (`modules/nixos/system.nix:10-15`) on a Disko
  ESP of only 100 MiB. The entry limit is not a capacity guarantee.

Official Nix documentation warns that deleting old generations makes rollback
impossible and can affect multiple profiles
([`nix-collect-garbage`](https://nix.dev/manual/nix/2.34/command-ref/nix-collect-garbage)).
Replace time-only cleanup with a retention invariant: keep at least N known-good
system generations **and** a minimum rollback duration, plus the last release
closure/lock. Do not GC a canary or release candidate before physical reboot and
rollback succeed.

Pre-GC evidence:

```bash
df -h /nix /boot
df -i /nix /boot
sudo nix-env --profile /nix/var/nix/profiles/system --list-generations
nix profile history
nix-store --gc --print-dead > evidence/gc-dead.txt
bootctl status
find /boot/EFI/Linux /boot/loader/entries -maxdepth 1 -type f -printf '%s %p\n' 2>/dev/null
```

After GC and bootloader refresh, verify current and previous known-good entries,
ESP free-space headroom, cold boot, and rollback. GC frees immutable store data;
it does not roll back mutable `/var`, databases, firmware/NVRAM, disk layout, or
user data. Those require tested backups/restores.

## 7. Cost controls without weakening proof

- Cancel superseded PR runs.
- Run the fast all-system no-build gate before native builds.
- Use explicit 10/45/120 minute timeouts for eval/native/VM lanes; timeout means
  not verified and blocks the relevant claim.
- Cache by `flake.lock` + OS + architecture. Use signed Nix binary caches rather
  than opaque tarred `/nix/store` caches. PRs restore only; trusted main/nightly
  may push.
- Build each derivation once and pass store paths/artifacts downstream; do not
  rebuild the same closure in every job.
- Run x86 and ARM/Darwin native jobs in parallel, but serialize destructive
  installer and physical canary jobs per host.
- Use change classification only to add gates, not remove them: a docs-only diff
  may skip heavy realization, but changes to `flake.lock`, overlays, modules,
  apps, tests, installer docs/helper or assets require their owning lanes.
- Schedule expensive Disko/session/update tests nightly and before release;
  require a recent green commit-matching result for promotion.
- Persist logs, closure sizes, warnings, revisions and hardware manifests as
  evidence artifacts with retention longer than the rollback window.

## 8. Minimum implementation order

1. Remove global broken/unsupported bypasses; annotate/narrow unfree and insecure
   exceptions.
2. Export all six current manual test entrypoints and both Disko install tests.
3. Add a formatter and pinned shell static-analysis checks.
4. Add secure GitHub workflows with the four native runner lanes.
5. Make warning budget zero, resolving or expiring the `options.json` warning.
6. Add NixOS VM tests for session/network/portal/rollback and strict installer
   transport integration.
7. Define concrete host profiles and a durable physical qualification manifest.
8. Replace seven-day destructive cleanup with evidence-backed retention and
   exercised rollback policy.

## Evidence boundaries

**Directly observed:** output names; three exported checks; absence of workflows
and formatter; global Nixpkgs policy; current cleanup settings; rc/timing and
warnings from the current no-build check; passing helper/lifecycle/narrow secret
tests; current lock revisions/NAR hashes; no fresh tracked production diff.

**Supported by primary documentation:** `nix flake check` schema and no-build
semantics ([Nix manual](https://nix.dev/manual/nix/2.18/command-ref/new-cli/nix3-flake-check));
out-of-tree NixOS VM tests; broken/unsupported package policy; GC rollback loss;
current GitHub native runner labels; action pinning/cache trust guidance; the
exact pinned Disko/nixos-anywhere sources linked by Wave 1C.

**Not verified here:** a fresh full x86 closure build under isolated resources;
complete mutation and shell-runtime suites; any native ARM/Darwin build; full
Disko QEMU execution; strict installer transport; final activation on any
physical host; firmware, Wi-Fi, GPU, suspend, Niri or rollback on target
hardware.

## EXPAND

1. Implement the exported check surface and measure cold/warm time and closure
   size on all four native runner types.
2. Resolve the pinned Nixpkgs `options.json` context warning or prove an explicit
   documentation-disable path removes it without losing desired local docs.
3. Audit all referenced packages under strict `allowBroken=false` and
   `allowUnsupportedSystem=false`; create no blanket exceptions.
4. Build both Disko install tests and exercise ESP exhaustion/retention over
   multiple generations.
5. Implement Niri/session/portal/notification/lock VM tests, then compare them
   with a physical GPU/portal qualification run.
6. Implement strict-host-key and verified-kexec installer tests, including
   changed-key and digest-mismatch negative controls.
7. Design the signed physical-host evidence schema and automatic expiration when
   the kernel, firmware, lock revision, disk manifest or hardware IDs change.
8. Rehearse update, canary, reboot, rollback and mutable-data restore as one
   release drill.

## CLAIMS

- **C1 (high):** The repository declares four systems but currently exports only
  three lightweight checks per system and no CI workflow. Evidence:
  `modules/flake/systems.nix:2-7`, `modules/flake/checks.nix:3-35`, empty
  `git ls-files '.github/**'`.
- **C2 (high):** Six executable regression entrypoints and both Disko install
  tests are outside the exported check surface. Evidence: `tests/` inventory,
  `modules/flake/checks.nix`, and the exact Disko evaluation in Wave 1C.
- **C3 (high):** Current `nix flake check --no-build` exited 0 in 27 seconds but
  omitted three foreign systems, left `denful` unchecked, and warned about an
  unreliable `options.json` context. Therefore it is not a portability proof.
- **C4 (high):** Global `allowBroken=true` and
  `allowUnsupportedSystem=true` suppress Nixpkgs' normal platform/problem
  guards. Evidence: `lib/nixpkgs.nix:41-47` and the Nixpkgs global-configuration
  manual.
- **C5 (high):** `nix fmt -- --check` currently fails because no formatter is
  exported. Evidence: executed rc 1, missing `formatter.x86_64-linux`.
- **C6 (high):** Bootstrap helper, lifecycle and narrow secret-pattern suites
  passed locally, but the secret scan is not a general credential scanner and
  none is exported through flake checks. Evidence: executed commands and test
  implementation.
- **C7 (high):** Foreign evaluation and Disko VM tests cannot prove physical
  firmware, disk identity, Wi-Fi, GPU, EFI/NVRAM or native Darwin activation.
  Evidence: output semantics and exact Disko VM device rewriting from Wave 1C.
- **C8 (high):** The current Intel Darwin claim is time-bounded: Nixpkgs says
  26.05 is the last supported release, and a global unsupported-package override
  cannot restore removed platform support. Evidence: exact evaluation warning
  and Nixpkgs release policy.
- **C9 (high):** Current Linux manual cleanup deletes older-than-seven-day
  generations before rewriting the bootloader, while the ESP is 100 MiB and the
  entry limit is 42. This is neither a guaranteed rollback window nor an ESP
  capacity proof. Evidence: `apps/*-linux/clean:33-41`,
  `modules/nixos/system.nix:10-15`, Disko layout in Wave 1C.
- **C10 (high):** A defensible “works immediately” claim requires separate
  native-build, VM, strict-installer, rollback and physical-hardware evidence;
  skipped or timed-out lanes must remain not verified. Evidence: limits of each
  executed/evaluated layer and official NixOS testing documentation.
