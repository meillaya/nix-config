# Wave 1 — Official NixOS/Nix/nixpkgs/upstream documentation

Observer: `official_nixos_docs`; accessed 2026-07-13; 40+ distinct searches plus full-page and sitemap retrieval.

## Findings

1. Stable manual is NixOS 26.05. `nixos-generate-config` observes the current machine and mounted target, writes a machine-specific `hardware-configuration.nix`, does not enable installed Wi-Fi by default, and may need explicit root-storage initrd modules. A generated file from machine A is not a universal hardware profile.
2. `hardware.enableAllHardware` supplies a broad architecture-conditional installer-style storage/initrd baseline and redistributable firmware. Its own source says its primary use is installer CDs and notes incomplete/untested classes. It means “most,” not literal universal hardware.
3. `hardware.enableRedistributableFirmware` adds linux-firmware and related packages and defaults wireless-regdb on, but cannot cover legally non-redistributable/vendor-only firmware, calibration data, missing kernel drivers, or unsupported devices.
4. Intel and AMD microcode updates are false by default and early loading is recommended by kernel documentation. Per-host Facter can select the matching vendor precisely.
5. NixOS Facter is strong per-machine evidence for CPU/GPU/NIC/storage/boot/virtualization, not a live universal report reusable unchanged across machines.
6. Boot policy must be split by class: BIOS requires GRUB; systemd-boot is UEFI-only; ARM may require U-Boot/device-tree/vendor boot flows; broken NVRAM, 32-bit EFI, Secure Boot, and Apple firmware are distinct cases.
7. NetworkManager with its default wpa_supplicant backend is the safest generic interactive desktop baseline. iwd remains documented experimental/feature-incomplete for the NetworkManager backend. Standalone competing wireless managers should not be enabled simultaneously.
8. Regulatory data starts restrictive and is intersected with device/AP/userspace hints. Ship the database, but do not hard-code one country for a globally roaming configuration.
9. Generic Mesa belongs in a shared baseline; NVIDIA PRIME IDs, NVIDIA branch/open-module policy, legacy AMD selection, and specialized media/OpenCL stacks are host-specific.
10. Bluetooth/PipeWire need explicit policy; `security.rtkit.enable = true` is the documented audio baseline. Combo-radio coexistence, SOF/ALSA DSPs, codecs, login-session ownership, and unusual controllers remain hardware-specific.
11. Aggressive power tuning is not universal. TLP itself documents possible device, boot, freeze, suspend, and resume regressions from driver power-saving defects.
12. A flake/lock reproduces software inputs, not hardware/firmware/partition/mutable state. Offline immediate use requires the target architecture’s realized closure and retained boot-tested generations.
13. `nix-collect-garbage -d` destroys old generations and rollback ability; rollback does not restore mutable `/var`, firmware/NVRAM, partitions, DB migrations, or all bootloader state.

## Primary sources

- https://nixos.org/manual/nixos/stable/
- https://github.com/NixOS/nixpkgs/blob/nixos-26.05/nixos/modules/hardware/all-hardware.nix
- https://github.com/NixOS/nixpkgs/blob/nixos-26.05/nixos/modules/hardware/all-firmware.nix
- https://nixos.org/manual/nixos/stable/#sec-nixos-facter
- https://nix-community.github.io/nixos-facter/
- https://www.kernel.org/doc/html/latest/arch/x86/microcode.html
- https://wireless.docs.kernel.org/en/latest/en/developers/regulatory.html
- https://www.networkmanager.dev/docs/api/latest/NetworkManager.conf.html
- https://nixos.org/manual/nixpkgs/stable/
- https://nixos.org/guides/how-nix-works/
- https://nix.dev/concepts/flakes.html
- https://nix.dev/manual/nix/2.34/command-ref/nix-collect-garbage
- https://wiki.nixos.org/wiki/Graphics
- https://wiki.nixos.org/wiki/Bluetooth
- https://wiki.nixos.org/wiki/PipeWire
- https://wiki.nixos.org/wiki/Laptop

## Claim candidates

- Declarative reproducibility is not automatic physical-hardware portability.
- `enableAllHardware` is an installer-style generic baseline, not a universal switch.
- Redistributable firmware improves coverage but cannot cover every device.
- Facter should be generated/selected per host.
- NetworkManager+wpa_supplicant is the current conservative generic desktop baseline.
- Generic Mesa is broadly shared; NVIDIA/hybrid and legacy GPU policy is host-specific.
- Rollback covers declarative generations, not all machine state.
- Locked inputs improve reproducibility but may pin kernels/firmware too old for new hardware.

## EXPAND
- LEAD: Facter report reuse/schema/hotplug/release migration — WHY: define safe per-host detection lifecycle — ANGLE: upstream nixos-facter guarantees.
- LEAD: Secure Boot/TPM/key enrollment/removable fallback — WHY: a major portable boot class remains open — ANGLE: current official guidance and Lanzaboote/upstream systemd.
- LEAD: x86 BIOS/UEFI/32-bit EFI and ARM UEFI/U-Boot/device-tree matrix — WHY: current outputs overpromise by architecture name alone — ANGLE: primary platform docs.
- LEAD: offline closure transfer/cache/installation workflow — WHY: source-only USB cannot guarantee day-one packages/firmware — ANGLE: executed nix copy/store proof.
- LEAD: GPU generation/driver/firmware/32-bit matrix — WHY: graphics is the largest hardware-specific desktop boundary — ANGLE: current modules and vendor tables.
- LEAD: current nixos-hardware counterexamples — WHY: quantify classes that generic profiles do not solve — ANGLE: profile mining.
