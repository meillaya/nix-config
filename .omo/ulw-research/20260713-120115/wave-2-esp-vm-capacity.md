# Wave 2 — Disko installTest and ESP capacity at exact pins

**Scope:** repository `e9f78180748f1feb428ffb20f9d932c5d9918a48`, root nixpkgs `d407951447dcd00442e97087bf374aad70c04cea`, Disko `ff8702b4de27f72b4c78573dfb89ec74e36abdf1`.

## Executive verdict

1. **The production `system.build.installTest` is currently red.** Formatting, mounting, repeated destroy/format/mount, and idempotence all execute against a 4 GiB QEMU disk, but installation aborts because the Disko VM fixture does not stage `/var/lib/nixos-bootstrap/mei-password.hash`. Exact failure: `bootstrap password hash validation failed: missing /var/lib/nixos-bootstrap/mei-password.hash`; the driver exits 1 before reboot. This output is not exported under the flake's `checks`, so normal `nix flake check` does not reveal it.
2. **A controlled test-only isolation of that runtime secret contract passes.** With only the bootstrap hash consumer/validator and hashed-password-file overridden inside `disko.tests.extraConfig`, the exact Disko layout formats, installs systemd-boot, reboots through OVMF, and reaches `local-fs.target`; the VM test reports success in **40.20 s**. This proves one-generation QEMU/OVMF viability, not production password staging or physical-firmware portability.
3. **The test masks the destructive-device placeholder.** Production evaluation and the generated production `diskoScript` contain literal `/dev/%DISK%`. Disko's `prepareDiskoConfig` rewrites every disk to `/dev/vdb` for install testing, so the green isolated VM cannot catch an unreplaced `%DISK%`.
4. **100 MiB and `configurationLimit = 42` are arithmetically incompatible in the conservative case.** The exact current kernel is 14,041,600 B and initrd 28,386,980 B: **42,428,580 B / 40.463 MiB per unique generation** before entries/bootloader/FAT metadata. An executed FAT image experiment fits two fully unique generations and fails on the third. Forty-two unique current-size payloads need 1,782,000,360 B (1,699.45 MiB) before safety reserve.
5. **Minimum defensible policy:** use a **1 GiB FAT32 ESP with `configurationLimit = 10`** for ordinary single-OS hosts, or a **2 GiB boot payload partition with limit 42** (prefer a 512 MiB ESP plus 2 GiB XBOOTLDR if interoperability/shared-ESP concerns matter). The latter is the minimum round binary size that covers 42 current full payloads plus approximately 20% headroom over the payload (17% of total capacity). Enforce this mechanically; do not rely on kernel/initrd deduplication.

## What was executed

### E1 — exact evaluation and derivation discovery

Executed:

```sh
nix eval --raw '.#nixosConfigurations.x86_64-linux.config.system.build.installTest.drvPath'
```

Result: `/nix/store/km2gvghhr5h3ghhxncw2pxxvyqd3b8si-vm-test-run-disko-nixos-disko.drv`.

Dry run: 63 local derivations plus 158 cache paths, 221.3 MiB download / 716.6 MiB unpacked. Full dry-run log: `wave-2-installtest-dryrun.log`.

### E2 — production installTest (failed, important)

Executed:

```sh
nix build --no-link -L --option max-jobs 2 \
  '.#nixosConfigurations.x86_64-linux.config.system.build.installTest'
```

Observed before failure:

- Disko created GPT partition 1 with `sgdisk --new=1:0:+100M --typecode=1:EF00` and partition 2 for root.
- `mkfs.vfat` and `mkfs.ext4` ran.
- mount/unmount and destroy-format-mount idempotence paths succeeded.
- the generated fixture used `/dev/vdb`.
- installation then invoked `switch-to-configuration boot` and failed with missing bootstrap password hash. A later `Failed to parse os-release` is downstream of activation aborting before `/etc` setup; it was not reproduced after isolating the hash contract.

Exact terminal failure is retained in `wave-2-installtest-build.log` and the Nix log for the derivation.

### E3 — controlled isolation (passed)

Research-only expression: `esp-fat-model/installtest-with-secret-contract-isolated.nix`. It changes no production source. It overrides, only inside the installed test system:

- `users.users.mei.hashedPasswordFile = null`
- password locked (`!`)
- bootstrap validator/consumer bodies to `true`

Executed:

```sh
nix build --impure --expr \
  'import ./.omo/ulw-research/20260713-120115/esp-fat-model/installtest-with-secret-contract-isolated.nix' \
  --no-link -L --option max-jobs 2
```

Result: **exit 0**. The log proves:

- FAT was `FAT16` at this size (`vdb1 vfat FAT16`).
- systemd-boot copied its EFI binary to both `EFI/systemd/systemd-bootx64.efi` and fallback `EFI/BOOT/BOOTX64.EFI`.
- OVMF displayed the NixOS entry and booted kernel 7.1.3.
- the VM mounted the ext4 root and the driver reached `local-fs.target`.
- total test-script time: 40.20 s.

Full log: `wave-2-installtest-isolated-build.log`.

**Boundary:** this deliberately does not prove the real nixos-anywhere extra-files/password choreography. It isolates the disk/boot contract after the production failure established that the current general test fixture cannot satisfy the secret contract.

### E4 — `%DISK%` blind spot (proved)

Executed production evaluation:

```sh
nix eval --raw \
  '.#nixosConfigurations.x86_64-linux.config.disko.devices.disk.vdb.device'
```

Output: `/dev/%DISK%`.

The built production format and all-in-one scripts contain literal `/dev/%DISK%`, including destructive `sgdisk` operations. By contrast, the exact install-test generated script `/nix/store/azzqdqbz3qd21ziq3vd07d0yafa829jw-disko-format/bin/disko-format` contains `/dev/vdb` because Disko `lib/tests.nix::prepareDiskoConfig` unconditionally replaces disk devices with its QEMU device list. Therefore this is a **structural false negative**, not just missing test coverage.

### E5 — exact FAT capacity and allocation experiments

Using exact pinned packages dosfstools 4.2 and mtools 4.0.49, an exactly 104,857,600-byte image was formatted using the same default `mkfs.vfat` behavior as Disko.

`fsck.fat -vn` reported:

- FAT16, 512-byte logical sectors, 2,048-byte clusters
- 4 reserved sectors, two 102,400-byte FATs
- data begins at byte 223,232
- 51,091 clusters / **104,634,368 usable bytes (99.787 MiB)**
- filesystem metadata overhead: 223,232 B before directory allocation

The exact current boot payload is:

| Artifact | Bytes | Evidence |
|---|---:|---|
| Linux 7.1.3 `bzImage` | 14,041,600 | store `stat` |
| initrd | 28,386,980 | store `stat` |
| combined | **42,428,580** | computed |
| systemd-boot x64 EFI binary | 154,112 | store `stat`; installed twice |

Executed allocation outcomes (systemd-boot binaries, loader directories/conf, and entry files included):

| Scenario | Successful retained payloads | Remaining after success | Next attempt |
|---|---:|---:|---|
| unique kernel + unique initrd per generation | 2 | 19,443,712 B | generation 3 fails (`Disk full`) after its kernel copy |
| one shared kernel + unique initrd | 3 | 5,097,472 B | generation 4 fails |
| shared kernel + shared initrd, 42 distinct entries | 42 | 61,790,208 B | fits |

Artifacts and raw output: `esp-fat-model/{fsck-initial.log,allocation-scenarios.log,esp-*.img}`.

## Modeled retention economics

### Current Type #1 behavior

The exact `boot.json` references separate kernel and initrd files; systemd-boot's builder hashes/copies those into `EFI/nixos` and writes Type #1 loader entries. It deduplicates by destination path. Therefore config-only rebuilds may share kernel and initrd, but kernel upgrades and initrd-changing rebuilds consume new payloads. This workload uses no specialisations today. Each specialisation can add another payload and makes generation-only limits insufficient.

The builder selects the newest `configurationLimit` generations, garbage-collects unreferenced EFI payloads **before** writing selected files, then writes oldest-to-newest. There is no capacity preflight or transactional rollback. ENOSPC can therefore leave partially populated selected generations and reduce rollback safety.

### UKI distinction

The exact pin exposes a buildable UKI output, but the active `boot.json`/systemd-boot path does **not** install it; the observed OVMF boot command names a separate initrd in `EFI/nixos`. A UKI packages stub + kernel + initrd + metadata into one EFI image. It improves integrity/measured-boot composition but not capacity: its embedded command line contains the generation-specific `/nix/store/.../init`, so normally every generation gets a distinct approximately 40+ MiB image and cannot share a kernel/initrd as separate Type #1 files can. Do not adopt UKI as an ESP-space fix.

### Capacity policies

- Present 100 MiB / limit 42: worst-current payload demand is 16.99 times the nominal partition; executed capacity is two full unique generations.
- Official NixOS manual example reserves 512 MiB and explicitly formats FAT32. At current payload size, 10 unique generations consume ~404.63 MiB before small fixed costs, leaving only ~20% on 512 MiB.
- **Recommended normal policy:** 1 GiB FAT32 and limit 10. Ten current unique payloads consume ~39.5% of 1 GiB, leaving meaningful growth and dual-boot/vendor headroom.
- **If 42 is a hard requirement:** 2 GiB payload space. Forty-two current unique payloads are 1,699.45 MiB; 20% reserve raises the requirement to ~2,039.34 MiB, so 2 GiB is the smallest conventional binary size that barely satisfies 20% headroom over the modeled payload (about 17% of total capacity remains). Prefer separate XBOOTLDR for payloads while retaining a conservative 512 MiB ESP.
- Any specialisation count greater than zero must enter the budget formula: `generationLimit × (1 + maxSpecialisationsPerGeneration) × conservativePayloadBytes` unless measurement proves sharing.

The UEFI 2.10 specification requires firmware support for EFI FAT12/FAT16/FAT32 and says the variant follows media size, so the observed FAT16 image is not by itself nonconforming. Nevertheless, the NixOS manual's installation example is a stronger interoperability baseline: 512 MiB ESP formatted explicitly with `mkfs.fat -F 32`.

Primary references:

- NixOS installation manual (512 MiB ESP, explicit FAT32): https://nixos.org/manual/nixos/stable/#sec-installation-manual
- UEFI 2.10 media/filesystem requirements: https://uefi.org/specs/UEFI/2.10/13_Protocols_Media_Access.html
- Exact Disko test implementation (local exact pin): `/nix/store/w2c23ykc12mswlg8hrrjzb5gv9gvkzwq-source/lib/tests.nix`
- Exact NixOS systemd-boot builder: `/nix/store/ifpab9hxqmk2biwy594da8ipxzsp3y4s-source/nixos/modules/system/boot/loader/systemd-boot/systemd-boot-builder.py`

## Fail-closed design

### Evaluation gates

1. **No placeholder gate:** assert every evaluated `disko.devices.disk.*.device` is an absolute `/dev/disk/by-id/...` or explicitly approved VM device and contains no `%...%`. This must run on the production config, not the rewritten Disko test config.
2. **Declared topology gate:** make ESP size and generation policy typed host inputs, not free-form text patched after clone. Assert UEFI hosts use at least 1 GiB/10 or the explicitly selected 2 GiB/42 profile; assert FAT `extraArgs = [ "-F" "32" ]` for the conservative profile.
3. **Architecture/boot-mode gate:** systemd-boot/ESP profiles must assert UEFI x86_64/aarch64 contract; legacy BIOS and SBC boot flows require separate host profiles.

### Build gates exported as flake checks

1. Export the exact `config.system.build.installTest`, with a **test-only dummy bootstrap hash staged through a mechanism faithful to nixos-anywhere**, so disk + bootstrap + activation + boot are all tested rather than disabling the contract.
2. Add a negative check that the raw production `diskoScript` contains no `%DISK%` and names the expected by-id device.
3. Add a payload-budget derivation that `stat`s the realized kernel, initrd, any device tree/extra initrds, all specialisations and extra EFI files. Fail if conservative retained bytes exceed 80% of declared boot payload capacity. For UKI profiles, measure the realized UKI instead.
4. Add an ENOSPC VM test: prefill the ESP beyond the safety threshold and prove activation exits **before** deleting/writing existing boot entries; then verify the prior generation still boots.

### Runtime/install gates

Before destructive Disko:

- resolve the by-id path; require exactly one whole non-removable target; show model/serial/capacity; reject root/live media and an unreplaced placeholder;
- require explicit target-host mapping and re-check immediately before wipe.

Before every bootloader update:

- verify `/boot`/XBOOTLDR is the intended mounted filesystem and its size meets declared policy;
- inventory referenced and reclaimable EFI files, calculate bytes required by the complete selected set plus reserve;
- abort before upstream garbage collection if the post-GC selected set cannot fit;
- preserve and boot-test the last known-good entry.

After install/rebuild:

- `bootctl status`, enumerate entries, verify default target;
- assert filesystem type/profile (FAT32 for conservative ESP), free-space reserve, no orphan `*.tmp`, and actual entry targets exist;
- reboot the VM/physical test host and prove root + boot mount + `local-fs.target`.

## Limits / not proved

- The passing test used OVMF/KVM and one generation; it does not cover quirky physical firmware, Secure Boot, legacy BIOS, aarch64 SBC firmware, dual boot, power loss, or an ESP already containing another OS.
- The FAT allocation model reproduces allocation accurately but does not execute the NixOS builder across 42 real Nix profile generations. Its two/three-generation thresholds are experimentally validated; the 42-full-payload policy is arithmetic modeling.
- Exact initrd sizes change with hardware modules, firmware, encryption, secrets, microcode, and kernel choices. Current size is a floor for this evaluated host, not a universal bound.

## EXPAND

- **W2-ESP-E1:** Implement and run a faithful `disko.tests.extraConfig` bootstrap fixture that stages a syntactically valid dummy yescrypt hash with production owner/mode/consumption behavior; export the installTest as a flake check.
- **W2-ESP-E2:** Run a real systemd-boot ENOSPC test with 2–4 actual generations and forced initrd churn, verifying last-known-good preservation and orphan-temp behavior.
- **W2-ESP-E3:** Decide policy: 1 GiB/10 standard vs 512 MiB ESP + 2 GiB XBOOTLDR/42; test migration of an existing 100 MiB partition without data loss.
- **W2-ESP-E4:** Add host-declared disk identity and prove placeholder rejection before any destructive command.

## CLAIMS

- **C-ESP-01 (executed, high):** Production x86_64 `system.build.installTest` fails because its VM fixture lacks the required bootstrap password hash.
- **C-ESP-02 (executed, high):** With only that runtime secret contract isolated in test config, exact Disko formatting, systemd-boot installation, OVMF reboot, and `local-fs.target` pass.
- **C-ESP-03 (executed/source, high):** Disko installTest rewrites `/dev/%DISK%` to `/dev/vdb`; it cannot detect the production placeholder.
- **C-ESP-04 (executed, high):** Default `mkfs.vfat` on the exact 100 MiB layout yields FAT16 with 104,634,368 usable bytes.
- **C-ESP-05 (executed, high):** The current 100 MiB image holds two unique current kernel+initrd generations and fails on the third; it holds three if only initrds churn.
- **C-ESP-06 (source/arithmetic, high):** `configurationLimit = 42` limits selected generations, not bytes or specialisation count, and cannot guarantee capacity on 100 MiB.
- **C-ESP-07 (modeled policy, medium-high):** 1 GiB/10 is a defensible ordinary-host minimum; 2 GiB is the smallest conventional binary payload partition covering 42 exact-current full payloads with about 20% headroom over the modeled payload (17% of total capacity).
- **C-ESP-08 (source/observed, high):** The active boot path installs separate kernel/initrd Type #1 artifacts, not the available UKI build output.
