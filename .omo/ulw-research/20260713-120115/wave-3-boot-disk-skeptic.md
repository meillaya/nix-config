# Wave 3 — adversarial boot, disk, ESP, and rollback review

Research date: 2026-07-13  
Repository revision: `e9f78180748f1feb428ffb20f9d932c5d9918a48`  
Exact root Nixpkgs: `d407951447dcd00442e97087bf374aad70c04cea`  
Exact Disko: `ff8702b4de27f72b4c78573dfb89ec74e36abdf1`  
Scope: skeptical review and bounded research-only probes; no production edits and no physical destructive action.

## Bottom line

The central warning survives, but several formulations need tightening.

| Proposition challenged | Adversarial disposition |
|---|---|
| “A 100 MiB ESP is unsafe” | **Qualified true for the promised rollback/portability objective, false as an unconditional standards/install claim.** The exact ESP boots one generation and VFAT16 is permitted; it cannot guarantee even three unique current payloads or anything resembling 42 retained unique generations. |
| “The production `installTest` is meaningfully red” | **True as an unexported integration test result, not proof that nixos-anywhere installation itself is broken.** It catches an unstaged external bootstrap-file contract; it does not exercise the helper/nixos-anywhere staging path. |
| “1 GiB/10 or 2 GiB/42” | **1 GiB/10 is a sound conservative default. 2 GiB/42 is too close to the exact present measurement to be a durable invariant and contradicts an 80%-of-capacity gate.** `configurationLimit` is also per profile, and specialisations multiply payloads. |
| “`%DISK%` is fail-open” | **Refuted for the unresolved literal on this exact script.** `%` is not shell glob syntax; absent `/dev/%DISK%`, `sgdisk` exits nonzero under `set -e`. The serious risk is lack of an evaluation gate, QEMU rewriting that masks the placeholder, and a human substituting the wrong *real* disk. |
| “The boot update is transactional” | **Refuted.** Each file is temp+fsync+rename, but garbage collection precedes the set of writes, no aggregate space preflight exists, and `NIXOS_INSTALL_BOOTLOADER=1` removes `loader.conf` before the payload update. |
| “Seven-day GC and 42 boot generations form a rollback policy” | **Refuted.** They are independent, workload-dependent upper bounds. Deleting profile generations removes rollback roots; a boot-menu limit does not preserve them. |

## 1. What 100 MiB does and does not prove

The exact current kernel and initrd are:

- kernel: 14,041,600 B;
- initrd: 28,386,980 B;
- combined unique payload: **42,428,580 B / 40.463 MiB**.

The Wave 2 exact FAT experiment measured 104,634,368 usable bytes on the nominal 100 MiB FAT16 filesystem and executed these outcomes:

- two distinct kernel+initrd payloads fit;
- the third fails;
- three generations fit if the kernel is shared and only the initrd changes;
- 42 entry files fit when both kernel and initrd are shared.

That is strong evidence that `100M` cannot uphold a predictable rollback-depth objective under kernel/initrd churn. It is **not** evidence that the current layout cannot install or boot once: the isolated OVMF test did boot one generation from this layout. Nor is FAT16 itself a specification violation. The Boot Loader Specification permits VFAT16/32 for the usual firmware-readable ESP/XBOOTLDR case, while the NixOS manual's 512 MiB FAT32 example is the more conservative interoperability baseline.

The exact NixOS builder deduplicates by destination path. `boot_path()` derives names from store paths, and `write_boot_files()` skips a destination already seen. Consequently, config-only generations can share kernel/initrd and cost mainly a small entry file. Kernel updates, initrd changes, initrd-secret changes, device trees, extra initrds, and specialisations erode that benefit. Therefore the defensible sentence is:

> 100 MiB is not a reliable boot-payload budget for this repository's stated multi-machine and rollback objective; it is not inherently incapable of booting NixOS.

Evidence: `wave-2-esp-vm-capacity.md`, `esp-fat-model/allocation-scenarios.log`, exact generated builder `/nix/store/ybsdbv9rq4zdhh11sa6qalq5b2b602kb-systemd-boot/bin/systemd-boot`.

## 2. Capacity policy: reasonable default, wrong notion of a universal minimum

### Exact arithmetic

At the current measured payload size:

| Payload partition | 10 unique payloads | 42 unique payloads | Comment |
|---:|---:|---:|---|
| 512 MiB | 79.03% | 331.92% | Ten only barely meets an 80% gate before host growth/extra files. |
| 1 GiB | 39.51% | 165.96% | Strong ordinary-host headroom for ten. |
| 2 GiB | 19.76% | **82.98%** | Forty-two violates a “selected bytes ≤80% capacity” gate. |

Forty-two present payloads total 1,782,000,360 B (1,699.448 MiB). Multiplying by 1.2 requires 2,138,400,432 B (2,039.338 MiB), leaving only 9,083,216 B (8.66 MiB) inside a 2 GiB partition for entry files and all model error. That is “20% over current payload,” not 20% free capacity, and is too brittle to call a durable minimum.

The proposed Wave 2 statements “2 GiB/42” and “fail when selected bytes exceed 80%” cannot both hold: exact present payload demand is already 82.98% of 2 GiB. An 80% cap requires at least 2,227,500,450 B (2.074 GiB) before fixed/foreign/extra content; a conventional **3 GiB** XBOOTLDR is a materially safer round policy if 42 full unique payloads is truly required. Better still, use a realized-byte gate and reduce retention rather than canonizing a fixed partition size.

### `configurationLimit = 42` is not a global count

The exact builder applies `CONFIGURATION_LIMIT` separately to the main system profile and to every name under `/nix/var/nix/profiles/system-profiles/`:

```python
gens = get_generations()
for profile in get_profiles():
    gens += get_generations(profile)
```

It then adds every specialisation for every selected generation. Thus a correct upper-bound model must sum:

- selected generations in the main profile;
- selected generations in every system profile;
- every specialisation per selected generation;
- distinct kernels, initrds, initrd-secret outputs, device trees, and extra initrds;
- boot-manager/extra files and foreign/shared-partition occupants.

The configured value 42 alone cannot bound bytes or even total menu entries.

### Policy recommendation

- **Ordinary UEFI single-OS host:** 1 GiB FAT32 ESP, limit 10, dynamic 70–80% preflight, no specialisations/profiles omitted from accounting. This is conservative, not a universal mathematical minimum.
- **Shared ESP or a hard large retention objective:** 512 MiB ESP at `/efi` plus a same-disk VFAT XBOOTLDR at `/boot`; size the XBOOTLDR from realized worst-case bytes. Use 3 GiB rather than 2 GiB if retaining 42 present-size unique payloads is a real requirement.
- **Do not make fixed sizes the proof.** The proof is “the complete selected set plus reserve fits before deletion or write.”

The Boot Loader Specification's installer logic says an existing ESP that is large enough—illustratively at least 1 GiB—may serve as `$BOOT`; otherwise an XBOOTLDR can be created. It requires XBOOTLDR on the same disk as the ESP and recommends `/efi` + `/boot` when both exist. The exact NixOS module implements this with `boot.loader.efi.efiSysMountPoint = "/efi"` and `boot.loader.systemd-boot.xbootldrMountPoint = "/boot"`.

Primary references:

- [Boot Loader Specification: partitions, capacity selection, and XBOOTLDR](https://uapi-group.org/specifications/specs/boot_loader_specification/)
- [NixOS installation manual: 512 MiB FAT32 UEFI example](https://nixos.org/manual/nixos/stable/#sec-installation-manual)
- exact NixOS module: `/nix/store/ifpab9hxqmk2biwy594da8ipxzsp3y4s-source/nixos/modules/system/boot/loader/systemd-boot/systemd-boot.nix`

## 3. ENOSPC behavior is file-atomic, not update-transactional

The exact builder performs this order:

1. update/install systemd-boot;
2. enumerate selected generations/profiles/specialisations;
3. `garbage_collect(boot_files)`;
4. `write_boot_files(...)` oldest-to-newest in enumeration order;
5. write `loader.conf` through a temp file and rename;
6. replace extra files;
7. `syncfs()` in `finally`.

`CopyWriter` and `ContentsWriter` use a temp file, `fsync`, and rename, which prevents a partially written file from replacing a same-path final file. They do **not** make the complete generation set atomic. `garbage_collect()` removes anything outside the selected root set before the new files are known to fit. `CopyWriter` also has no exception cleanup around its temporary file.

A bounded research harness imported the **exact generated builder**, called its real `garbage_collect()` and `write_boot_files()`, and injected `ENOSPC` inside the real `CopyWriter`'s copy operation:

- when the prior generation remained selected, its kernel/entry and old `loader.conf` survived, while a partial `*.tmp` remained;
- when the prior generation was outside the selected roots, GC removed its kernel/entry before the new copy failed, leaving only the stale `loader.conf` and a partial temp file.

Artifacts:

- `wave-3-boot-disk-enospc-harness.py`
- `wave-3-boot-disk-enospc-harness.log`

This is an exact control-flow probe, not a mounted-FAT power-loss test. It proves deletion/write ordering and temp-file leakage; it does not claim firmware behavior after the synthetic failure.

There is an additional repository-specific hazard: `apps/x86_64-linux/clean` always runs:

```sh
sudo nix-collect-garbage --delete-older-than 7d
sudo nixos-rebuild boot --flake ".#${flake_target}" --install-bootloader
```

`--install-bootloader` sets `NIXOS_INSTALL_BOOTLOADER=1`. In that mode the exact builder unlinks `loader.conf` **before** `bootctl install`, GC, and payload writes. Thus the cleanup path has a weaker failure state than an ordinary rebuild. systemd-boot can often sort entries without a loader config, but that is not an acceptable transactional oracle—especially if the only prior entry was just removed from the selected root set.

Required test: prefill a real VM FAT filesystem, retain a known-good boot, execute both ordinary rebuild and `--install-bootloader` paths, force ENOSPC at multiple write phases, reboot, and assert the known-good entry remains selectable and bootable. A unit/control-flow harness alone is insufficient.

## 4. `%DISK%`: fail-closed literal, unsafe workflow

The production evaluation and generated script contain `/dev/%DISK%`. The exact shell expands the word to itself because `%` has no Bash wildcard meaning:

```text
expanded=</dev/%DISK%> exists=no
```

A guarded, non-destructive invocation of the exact `sgdisk` against that absent literal returned **rc 4** with “specified file does not exist.” The generated destructive section is under `set -efux`, so this unresolved literal does not silently choose another disk. Artifact: `wave-3-placeholder-sgdisk.log`.

That refutes the narrow phrase “placeholder fails open.” It does **not** vindicate the design:

- Disko's test preparation rewrites every configured disk to `/dev/vd*`, so the VM test cannot detect the placeholder.
- There is no pure assertion that installable production outputs use an approved stable selector.
- The documented text-replacement workflow can replace the placeholder with a wrong but valid `/dev/sdX` or by-id path, which *will* be wiped.
- A path alone does not prove model, serial, size, non-removability, or exclusion of the live/root device.

The right correction is declarative host disk identity plus an evaluation assertion and a destructive-time serial/model/capacity oracle. Do not describe the current unresolved literal as fail-open; describe the **human replacement and untested identity process** as unsafe.

## 5. What the red and green Disko tests actually mean

### Red production-derived output

The exact command building
`nixosConfigurations.x86_64-linux.config.system.build.installTest` exits 1. Before failure it successfully executes format, mount, unmount, destroy/reformat, idempotence, closure registration, and target profile setup. It then invokes target activation and fails on:

```text
bootstrap password hash validation failed: missing /var/lib/nixos-bootstrap/mei-password.hash
```

This is meaningful because the generated test output for the production configuration is not self-contained. It should be red if exported today. It does **not** demonstrate that the repository's real helper/nixos-anywhere flow is red: nixos-anywhere copies extra files before installation, while Disko's generic install test does not know that external contract.

The proper fix is a faithful test fixture that stages a non-secret dummy hash with exact owner/mode/path and verifies consumption/cleanup. Silencing the validator is causal isolation, not final coverage.

### Green isolated output

The research-only override disables the bootstrap-hash consumer/validator and locks the user password. It proves:

- the 100 MiB FAT layout can format;
- systemd-boot can install in QEMU/OVMF;
- one generation can reboot and reach `local-fs.target`.

It does not prove:

- production bootstrap staging or cleanup;
- the physical by-id disk selector (`prepareDiskoConfig` rewrites it to `/dev/vdb`);
- boot under Secure Boot, legacy BIOS, quirky UEFI, 32-bit EFI, ARM SBC firmware, or dual boot;
- capacity under multiple generations or ENOSPC;
- host-specific storage, encryption, RAID, swap/hibernate, controller firmware, or power-loss recovery;
- a network/nixos-anywhere/SSH transaction.

The exact Disko test also imports QEMU guest instrumentation, forces `hardware.enableAllFirmware = false`, forces removable/graceful EFI behavior, binds the host Nix store through 9p, creates a uniform 4096 MiB virtio disk, disables substituters, and boots OVMF. Those are good deterministic test mechanics, not physical portability evidence.

Evidence: exact Disko `lib/tests.nix`, `wave-2-installtest-build.log`, `wave-2-installtest-isolated-build.log`.

## 6. XBOOTLDR, UKI, GRUB, BIOS, and Secure Boot are distinct profiles

### XBOOTLDR

XBOOTLDR is the strongest layout for a large Linux rollback budget or a shared/vendor ESP because it moves kernels/initrds/entries out of the small/shared ESP. It is not universally required and does not create space automatically. It adds a third partition, two mountpoints, same-disk/type constraints, and migration state. The exact builder explicitly warns that if `xbootldrMountPoint` is later unset, old XBOOTLDR entries are not automatically cleaned. Migration needs a VM test and a physical firmware acceptance test.

### UKI / Secure Boot

UKI improves integrity and Secure Boot composition; it is not an ESP-capacity optimization. A UKI generally embeds kernel, initrd, command line, and generation-specific init. Upstream describes its single-file atomic-update benefit, but retaining many distinct generations still consumes many full images. The exact active repo is not using UKIs.

Direct exact-output inspection found both the systemd-boot EFI binary and current kernel PE Security Directory equal to zero, and the configuration has no Lanzaboote option/module. Therefore the present output must not claim Secure Boot readiness. A signed UKI/Lanzaboote profile needs separate keys, enrollment, recovery, capacity accounting, and physical verification. The official NixOS Wiki documents Lanzaboote as a UEFI/systemd-boot path and explicitly warns that key management has no single perfect solution.

References:

- [Unified Kernel Image specification](https://uapi-group.org/specifications/specs/unified_kernel_image/)
- [Official NixOS Wiki: Lanzaboote](https://wiki.nixos.org/wiki/Lanzaboote)

### BIOS / GRUB / board firmware

The current Disko GPT has only an ESP and ext4 root, and the active boot loader is UEFI-only systemd-boot. It cannot be labeled “any machine.” At minimum:

- legacy BIOS needs a separate MBR or GPT BIOS-boot/GRUB profile;
- UEFI GRUB is an alternative, but merely swapping boot loaders while keeping the ESP mounted at `/boot` does not fix payload capacity; a layout that lets GRUB read kernel/initrd from ext4 is a different design;
- ARM SBCs may need U-Boot, device trees, vendor firmware, or board-specific images rather than the PC-style generic UEFI profile;
- Secure Boot is a separate signed-artifact profile, not a boolean extension of this output.

The NixOS manual explicitly distinguishes BIOS GRUB from UEFI systemd-boot/GRUB. These should be typed host profiles and separately tested, not auto-detected during destructive installation.

## 7. Garbage collection and rollback are currently mismatched

`nix-collect-garbage --delete-older-than 7d` deletes old generations in discovered profiles before collecting unreachable store paths. The Nix manual warns that deleting previous configurations makes rollback to them impossible. The precise time rule retains the generations active at the boundary, so “everything older than seven days” is not a simple count guarantee; the surviving count depends on rebuild frequency and activation history.

`configurationLimit = 42` only controls which still-existing generations/profiles are copied to the boot menu. It does not preserve a profile generation or store closure. Conversely, the seven-day rule can leave many generations after a busy week—far more than a small ESP can hold under payload churn—or very few after a quiet week. The current combination therefore supplies neither:

- a minimum rollback depth;
- a maximum byte budget;
- nor a known-good recovery guarantee.

A defensible lifecycle must declare separate objectives:

1. **store/profile retention:** e.g. keep the current generation, a tested known-good generation, and a count/time policy;
2. **boot payload retention:** byte-budget the exact selected boot artifacts;
3. **recovery:** retain a verified external installer/recovery artifact independent of the system profile;
4. **evidence:** periodically boot the known-good entry and rehearse rollback.

Beware that using additional `system-profiles` to preserve canaries also causes the current builder to select up to `configurationLimit` generations from each profile, increasing boot-partition pressure. The capacity oracle must enumerate them rather than assume 42 total.

Primary reference: [Nix `nix-collect-garbage` manual](https://nix.dev/manual/nix/latest/command-ref/nix-collect-garbage).

## 8. Adversarial acceptance gates

### Must be fail-closed before destructive installation

1. Every concrete host declares architecture, firmware mode, boot-loader profile, disk serial/model/minimum size, stable by-id, and expected topology.
2. Pure evaluation rejects `%...%`, `/dev/sdX` for physical hosts, missing selector, incompatible systemd-boot/BIOS combinations, and undeclared XBOOTLDR/ESP mounts.
3. On the target, resolve the selector immediately before wipe; require exactly one whole device, show and compare serial/model/size, reject live/root/removable media, and require an explicit host-to-disk binding.

### Must be checked before every boot update

1. Verify `/boot` and `/efi` are the declared mounted filesystems.
2. Enumerate the exact complete selected artifact set across main/profile/specialisation entries.
3. Compute reclaimable bytes and required final bytes plus a reserve; abort **before GC** if it cannot fit.
4. Do not use `--install-bootloader` during routine cleanup unless the boot manager itself needs reinstalling.
5. Preserve a selected known-good entry and fail if the transaction would remove it.

### Required executable tests

1. Export the production-derived Disko install test with faithful dummy bootstrap-file staging.
2. Add an independent evaluation check for the raw production disk selector; do not rely on Disko's rewritten VM device.
3. Run an actual FAT ENOSPC matrix for ordinary rebuild and `--install-bootloader`, injecting failures before/after GC, during kernel/initrd/entry/loader-conf writes, then reboot.
4. Test 1 GiB/10 and the chosen XBOOTLDR/large-retention profile with forced unique initrds, profiles, and specialisations.
5. Test migration from the current 100 MiB two-partition layout. Growing/moving partitions is destructive and cannot be declared safe from a fresh-install VM alone.
6. Keep BIOS/GRUB, ordinary UEFI, XBOOTLDR, Secure Boot, and board-specific ARM as separate CI/physical evidence lanes.

## Residual uncertainty

- No physical firmware, ESP already shared with another OS, power-loss injection, BIOS host, Secure Boot enrollment, or ARM board was exercised.
- The ENOSPC harness used the exact control flow but injected the error on a normal temporary filesystem rather than exhausting mounted VFAT.
- Payload sizes are exact for this one realized x86_64 configuration and date. Hardware modules, microcode, encryption, initrd secrets, device trees, kernel updates, or specialisations can increase them.
- A 3 GiB XBOOTLDR/42 recommendation is a conservative response to the present measurement, not proof of arbitrary future sufficiency; only a runtime realized-byte gate can supply that proof.

## EXPAND

- **W3-BD-E1:** Execute a real NixOS VM ENOSPC/power-cut matrix against the exact instantiated systemd-boot builder, including routine and `--install-bootloader` modes, then prove prior-generation bootability.
- **W3-BD-E2:** Model and execute capacity with two system profiles, multiple specialisations, device tree, extra initrd, and extra files; verify the gate counts all artifacts.
- **W3-BD-E3:** Build and boot separate ordinary-UEFI, XBOOTLDR, legacy-BIOS/GRUB, and signed Secure-Boot profiles; record which physical machine classes each supports.
- **W3-BD-E4:** Define a count-plus-known-good GC policy and rehearse rollback after the seven-day boundary without using an unverified external network dependency.
- **W3-BD-E5:** Test a safe migration plan from the existing 100 MiB ESP. If in-place partition movement cannot be proven power-loss safe, require backup/reinstall rather than promise automatic migration.

## CLAIMS

- **C-W3-BD-01 (executed, high):** The exact 100 MiB layout boots one isolated QEMU/OVMF generation but experimentally holds only two fully unique present kernel+initrd payloads; “unsafe” is a rollback-budget claim, not an absolute bootability claim.
- **C-W3-BD-02 (executed/arithmetic, high):** Forty-two present unique payloads use 82.98% of 2 GiB, so 2 GiB/42 conflicts with an 80%-capacity gate and has negligible model-error margin.
- **C-W3-BD-03 (exact source, high):** `configurationLimit` applies separately to the main profile and every system profile; specialisations further multiply entries, so 42 is not a global artifact or entry cap.
- **C-W3-BD-04 (exact source + synthetic fault, high):** The builder garbage-collects before writing, performs per-file rather than set-level atomic replacement, and can leave an orphan temp file on ENOSPC. A selected prior generation survives the tested control flow; an unselected one does not.
- **C-W3-BD-05 (exact source, high):** In install-bootloader mode the builder unlinks `loader.conf` before payload completion; the repository's Linux `clean` app always selects that mode after GC.
- **C-W3-BD-06 (executed, high):** The unresolved literal `/dev/%DISK%` does not shell-expand and exact `sgdisk` exits nonzero against its absent path; the placeholder itself is fail-closed in the observed environment.
- **C-W3-BD-07 (exact source/executed, high):** Disko's VM test rewrites physical devices to virtio, uses OVMF/QEMU guest overrides, and does not stage the external bootstrap hash; it cannot prove the physical selector or nixos-anywhere choreography.
- **C-W3-BD-08 (exact output, high):** The active systemd-boot/kernel outputs have empty PE Security Directories and no Lanzaboote configuration; current Secure Boot readiness is unproved and should be treated as absent.
- **C-W3-BD-09 (source, high):** The seven-day garbage-collection command can remove rollback generations, while `configurationLimit` only limits boot-menu copying; together they do not define rollback depth.
- **C-W3-BD-10 (source/inference, medium-high):** 1 GiB/10 is a conservative ordinary UEFI policy aligned with the Boot Loader Specification's illustrative “large enough” threshold, while XBOOTLDR is preferable for shared ESPs or high retention but adds migration/topology obligations.
