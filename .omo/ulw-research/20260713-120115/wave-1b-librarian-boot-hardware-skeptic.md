# Wave 1B — Boot/hardware universality skeptic

Observer: `boot_hardware_skeptic`; 40+ searches, official/kernel/systemd/vendor docs, pinned nixos-hardware profile/issue mining; observed 2026-07-13.

## Verdict

One repository/module graph can span machines. One unchanged evaluated host closure/disk image cannot safely mean “any machine.” ISA, firmware boot contract, storage identity/topology, signing/encryption state and multiple device quirks are irreducibly per host.

## Counterexample matrix summary

- x86_64 ordinary UEFI/NVMe/SATA: conditional mainstream baseline after verified disk mapping and firmware assumptions.
- Legacy BIOS: unsupported by current systemd-boot-only policy; requires GRUB/BIOS layout.
- 32-bit EFI on 64-bit x86: unsupported/unproven by current loader.
- Secure Boot/TPM measured boot/encrypted unlock: absent; initrd TPM modules alone do not create those chains.
- AArch64 standards-based UEFI: conditional only. U-Boot/SBC/device-tree and Apple Silicon: unsupported by current output.
- Raspberry Pi 4, Apple T2, Apple Silicon, Microsoft Surface: concrete profiles require special kernels/firmware/DT/modules/quirks absent here.
- RAID/LVM/LUKS: generic modules do not describe topology/UUID/policy; absent from Disko.
- NVIDIA and hybrid PRIME: unsupported; generation/branch/PCI IDs are host facts. Intel/AMD basic KMS is conditional; legacy and media stacks vary.
- Wi-Fi: generic firmware/NetworkManager covers many adapters, not nonredistributable/extracted/calibration/vendor cases or location/device regulatory constraints.
- Audio/SOF, cameras/IPU6, fingerprint, Thunderbolt, specialized input, suspend/hibernate: conditional or absent; power-profiles cannot repair firmware/driver/device quirks.
- No swap means no ordinary hibernation target.

## Strongest generic counter-search

- `hardware.enableAllHardware` is an installer/live-image breadth profile, not a universal installed-host profile.
- Facter is the strongest per-target generator but current issues show gaps in Apple Silicon buses, Raspberry Pi, device trees, TPM, mounted filesystems, bcache, Wi-Fi capabilities, I2C input and idempotence.
- `nixos-generate-config` is target/mount-derived and cannot choose destructive future layout/model quirks.
- Pinned nixos-anywhere documents x86/default kexec, custom AArch64 image, wired/non-Wi-Fi constraints and target hardware generation.
- The existence/content of nixos-hardware profiles directly refutes zero-host-data universality.

## Primary sources

- https://nixos.org/manual/nixos/stable/
- https://www.freedesktop.org/software/systemd/man/latest/systemd-boot.html
- https://docs.kernel.org/arch/arm64/booting.html
- https://docs.kernel.org/next/arm64/arm-acpi.html
- https://docs.u-boot.org/en/latest/develop/bootstd.html
- https://asahilinux.org/docs/platform/open-os-interop/
- https://github.com/NixOS/nixos-hardware/tree/8efb4337e857949f4cfac86d12ef1066f417f31f
- https://github.com/nix-community/nixos-facter/issues
- https://github.com/nix-community/nixos-anywhere/blob/4dfb813db065afb0aba1f61658ef77993d382db1/README.md
- https://docs.kernel.org/admin-guide/md.html
- https://docs.kernel.org/gpu/amdgpu/module-parameters.html
- https://docs.kernel.org/admin-guide/pm/sleep-states.html

## Contradiction requiring execution resolution

The worker named `59e69648...` as the main nixpkgs pin, while earlier direct metadata and the exact-lock lane identify root `nixpkgs_3` as `d407951...`; `59e69648...` appears to be a helper/tool pin. Treat the worker's pin statement as unresolved until `flake.lock` root graph is executed and recorded. No synthesis may repeat it unqualified.

## Claim candidates

- Current config supports only a conditional mainstream PC UEFI baseline, not arbitrary x86 or ARM.
- BIOS/UEFI-bitness/Arm DT-U-Boot/Apple m1n1 are mutually incompatible boot contracts.
- Facter/all-hardware/install media improve breadth but do not eliminate target facts.
- Safe “one config” means one repository with architecture outputs, target-generated facts and reviewed host profiles.

## EXPAND
- LEAD: concrete target intake/Facter/DMI/PCI/USB/ACPI/DT data — WHY: only real hardware can close per-host claims — ANGLE: gather when each target exists.
- LEAD: exact ESP capacity — WHY: 100 MiB vs 42 generations remains likely, not quantified — ANGLE: built kernel/initrd/entry sizes.
- DEAD END: truly universal unchanged host closure/image — primary counterexamples refute it.
