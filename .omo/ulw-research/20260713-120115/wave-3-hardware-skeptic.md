# Wave 3 — adversarial hardware-universality skeptic

Observer: `wave3_hardware_skeptic`; research-only; no production edits; observed
2026-07-13.  This pass deliberately tried to falsify the stronger conclusions in
the official-docs, boot/hardware, exact-lock, and host-intake lanes.  It inspected
the exact root Nixpkgs input `d407951447dcd00442e97087bf374aad70c04cea`, evaluated
both current NixOS outputs, inspected the realized x86 kernel-module and firmware
closures, and countersearched primary NixOS, Linux, systemd, and Arm sources.

## Bottom line

The absolute claim **“one unchanged closure cannot span diverse hardware” is
false**.  A Linux distribution installer is precisely a broad kernel, initrd,
firmware, and userspace superset, and NixOS' exact `hardware.enableAllHardware`
module is used by installation CDs, netboot, and SD images.  The current realized
x86 closure likewise contains runtime modules for several Intel/Realtek/Qualcomm
Wi-Fi families and Intel/AMD/nouveau graphics.  A single closure can therefore
span many machines **inside a declared compatibility class**.

What survives scrutiny is narrower and more useful: one closure cannot erase
differences in ISA, firmware boot protocol, destructive disk selection/topology,
proprietary driver policy, or device quirks.  The current outputs are plausible
generic templates for a bounded class, not proof of “any machine.”  Concrete host
leaves are an assurance, identity, and exception-management boundary; they are
not a physical prerequisite for Linux to boot.  Facter and `nixos-hardware` are
optional evidence/configuration mechanisms, not mandatory ingredients on every
host.

## Counterevidence executed against the earlier thesis

### 1. The current closure is substantially more generic than its six explicit modules suggest

Exact evaluation of `x86_64-linux` produced 43 initrd-available modules, not just
the six written at `modules/nixos/system.nix:17`.  NixOS defaults add common
storage, USB, HID, RAID, EFI, and filesystem modules.  The evaluated list includes
AHCI, NVMe, `sd_mod`, USB mass storage, ext4, EFI variables, and common PATA/SATA.
The realized Linux 7.1.3 module tree contains, among others:

- `iwlwifi`, `rtw88_core`, `rtw89_core`, and `ath11k_pci`;
- `amdgpu`, `i915`, `xe`, and `nouveau`;
- `ahci`, `nvme`, `virtio_pci`, `hv_storvsc`, and `vmxnet3`.

The last three virtual-platform drivers are present in the root filesystem module
tree but not necessarily in the current initrd, so their existence does not prove
that a virtio/Hyper-V root device can be mounted.  It does prove that ordinary
non-root hardware drivers are largely runtime-selected rather than requiring a
per-host closure.

The closure also contains ten redistributable firmware derivations, including
`linux-firmware-20260622`, SOF/ALSA firmware, Realtek firmware, and wireless
regulatory data.  This directly refutes “microcode false / all-firmware false
means Wi-Fi or graphics cannot work.”  It does not cover firmware excluded by
license, vendor extraction/calibration, or an out-of-tree driver.

### 2. `enableAllHardware` demonstrates a real generic-closure pattern, but not universality

Applying `hardware.enableAllHardware = true` as an exact-pin counterfactual to
the current x86 output expands `boot.initrd.availableKernelModules` from 43 to
102.  The 59 additions are mainly old SATA/PATA/SCSI controllers, UAS/SD, Virtio,
VMware, Hyper-V, and several untested legacy paths.  Exact source:

https://github.com/NixOS/nixpkgs/blob/d407951447dcd00442e97087bf374aad70c04cea/nixos/modules/hardware/all-hardware.nix

That module is imported by the NixOS installation CD, netboot base, and SD-image
definitions.  Thus a broad unchanged NixOS closure is an intentional and useful
design for installation/recovery across diverse devices of one architecture.
The exact option description, however, says **“most hardware”**, its SCSI list is
explicitly incomplete, FireWire is untested, and the implementation enables only
redistributable firmware.  Its leading source comment saying “all firmware” is
therefore looser than its own code.  It does not choose BIOS vs UEFI, an ARM board
firmware/device tree, Secure Boot keys, a disk to erase, NVIDIA policy, or laptop
quirks.

The practical conclusion is not “always enable it.”  For the current mainstream
UEFI/SATA/NVMe class, most of its delta is irrelevant.  It is appropriate for a
separate installer/recovery image, or for an explicitly broad generic host where
the extra initrd size and dormant drivers are accepted.  It is not a substitute
for a support matrix.

### 3. Generic AArch64 is a genuine counterexample to “ARM always needs a board profile”

The official NixOS ARM documentation describes generic builds as first-class and
says an upstream-supported board plus suitable platform firmware may run the
generic system.  Arm SystemReady exists specifically so unmodified generic OS
images can install across compliant Arm machines:

- https://wiki.nixos.org/wiki/NixOS_on_ARM/en
- https://www.arm.com/architecture/system-architectures/systemready-compliance-program

This refutes the absolute claim that every AArch64 target requires a custom
kernel, U-Boot module, or device tree in this repository.  A SystemReady-class
AArch64 machine with UEFI/ACPI, an EFI stub, and supported storage can plausibly
use the same generic systemd-boot flow as the current output.

It does **not** rescue the present name `aarch64-linux` as a promise of general
ARM support.  The current output evaluates to systemd-boot plus EFI variable
writes, 40 mostly PC-style initrd modules, and the same GPT/ext4 layout.  NixOS'
official ARM page separately says SBC-class systems commonly use U-Boot and
device trees; the installation page says Raspberry Pi devices cannot use the
generic AArch64 ISO and need SD images.  Apple Silicon and many consumer SBCs
therefore remain outside this output's defensible class.

### 4. Microcode is an important update policy, not a universal boot prerequisite

Both x86 microcode options are false in the current evaluation.  The Linux
microcode documentation says the kernel facility updates CPU microcode early so
CPU issues can be fixed before kernel boot observes them; it does not say an OS
microcode payload is required for every CPU to start.  Platform firmware normally
loads some CPU microcode before the kernel.  Exact host-vendor selection remains
the cleanest policy, but the earlier evidence should describe this as a
security/stability/errata gap rather than proof that generic x86 will not boot.

Primary source:
https://www.kernel.org/doc/html/latest/arch/x86/microcode.html

### 5. Facter and `nixos-hardware` are neither necessary nor sufficient

The NixOS manual's traditional `nixos-generate-config` path, a reviewed manual
hardware configuration, and an all-hardware superset are valid alternatives to
Facter.  Machines whose root controller is already in the initrd and whose
devices use mainline runtime drivers can boot without any Facter report.  More
strongly, this research session's exact synthetic evaluation found that Facter
0.4.4 enables per-interface DHCP and can start `dhcpcd` beside NetworkManager
unless `hardware.facter.detected.dhcp.enable = false`.  Mandating Facter without a
role-specific ownership rule can reduce correctness.

Likewise, `nixos-hardware` describes itself as profiles that optimize settings
and cover hardware quirks.  Its own setup example imports both an exact-model
profile and a hardware configuration; it does not claim every NixOS host needs a
profile:

https://github.com/NixOS/nixos-hardware

Therefore:

- a concrete host leaf is **required by the proposed high-assurance repository
  contract**, not required by Linux physics;
- a sanitized Facter report is a useful enrollment snapshot, but optional and
  pin-sensitive;
- an exact `nixos-hardware` profile is optional and should be imported only after
  inspecting its settings and confirming the model;
- a host with no special quirks can legitimately use shared generic hardware
  policy plus a tested root/boot configuration.

## Claim disposition

| Claim under challenge | Disposition | Reason |
|---|---|---|
| One unchanged closure cannot span diverse bare metal | **Refuted as absolute** | Installer/all-hardware closures and generic kernel runtime modules span many devices within one ISA/boot/storage compatibility class. |
| The current generic x86 output is not portable | **Downgraded** | It is plausibly portable across a bounded mainstream 64-bit UEFI PC class; it is not portable across all x86 boot, storage, GPU, and firmware classes, and no multi-machine physical test exists. |
| The current AArch64 output is not portable | **Downgraded, still high risk** | Generic SystemReady/UEFI Arm is real, so a narrow class is plausible. SBC/U-Boot/DT/Apple support is absent and no physical target is verified. |
| Every installed machine needs a concrete host leaf | **Downgraded** | Not needed for generic kernel boot; needed to make support claims auditable, name hosts, bind storage/boot decisions, contain exceptions, and retain physical test evidence. |
| Every host needs Facter | **Refuted** | Traditional generated/manual configs and generic supersets work; exact Facter introduces a NetworkManager/DHCP conflict unless constrained. |
| Every matching model needs `nixos-hardware` | **Refuted** | It is an optional quirks/optimization layer. Exact matching plus source review is required when used. |
| `enableAllHardware` solves universality | **Upheld as false** | It adds broad initrd coverage only; exact source is incomplete and does not solve boot firmware, disk topology, proprietary drivers, or quirks. |
| Disabled OS microcode prevents generic x86 operation | **Refuted** | It is a serious errata/security freshness gap, not generally a boot prerequisite. |
| Disabled `enableAllFirmware` means Wi-Fi cannot work | **Refuted** | Redistributable firmware is enabled and realized; many adapters can work. Nonredistributable/vendor-specific cases remain unsupported. |
| Generic Mesa policy can be shared | **Upheld with limits** | Current module tree includes Intel/AMD/nouveau drivers and graphics userspace; proprietary NVIDIA, PRIME routing, legacy branches, compute/media acceleration, and device quirks remain host-specific. |
| Aggressive power policy should be universal | **Upheld as false** | Generic power-profiles-daemon may be shared where its drivers cooperate, but suspend, thermals, hibernation, wake, and vendor platform profiles require physical validation. |

## Narrowest truthful current support matrix

“Supported” below means **configuration evidence makes the class plausible**.
Only the isolated QEMU/Disko path has actually booted in this research; no row is
a substitute for a physical acceptance run.

| Machine class | Current status | Boundaries |
|---|---|---|
| x86_64 desktop/laptop, 64-bit UEFI, Secure Boot off, GPT, one SATA-AHCI or NVMe disk, ext4, ordinary USB input | **Conditional mainstream baseline** | Operator must replace `%DISK%` safely; firmware must execute systemd-boot/EFI stub; 100 MiB ESP is operationally unsafe for retained generations; no physical matrix test. |
| Same class with Intel/AMD integrated graphics and in-kernel Mesa driver | **Conditional desktop baseline** | Kernel modules/userspace exist; Niri, external displays, suspend, media acceleration, and device firmware still require runtime checks. |
| Same class with Wi-Fi whose in-kernel driver uses included redistributable firmware (e.g. common Intel/Realtek/Qualcomm families) | **Conditional local-config baseline** | Scanning is plausible, not proven for each adapter; no installed SSID/credential handoff, so immediate remote reconnect is not promised. |
| NVIDIA discrete GPU | **Basic nouveau may be possible; not supported as a performance workstation** | Proprietary branch/open-module policy, PRIME bus IDs, hybrid routing, CUDA and suspend are absent. Do not label every NVIDIA machine wholly unbootable, but do not promise the intended desktop. |
| x86_64 QEMU using a SATA-compatible root path | **VM-tested indirectly** | The isolated Disko install test reached boot. Current direct virtio-root coverage is not proven because Virtio storage is absent from its normal initrd list. |
| AArch64 SystemReady-class UEFI/ACPI machine with supported AHCI/NVMe/USB root | **Plausible, unverified template** | No physical boot. Secure Boot, NVRAM behavior, graphics, radios, and exact firmware remain open. The output name must not imply all ARM. |
| Legacy BIOS, 32-bit EFI, Secure Boot-required x86 | **Unsupported by current boot policy** | Needs a distinct GRUB/EFI-bitness/signing policy. |
| ARM SBC/U-Boot/device-tree image, Raspberry Pi generic ISO, Apple Silicon, mobile/embedded board | **Unsupported/unmodeled** | Requires platform-specific image, firmware, DT/U-Boot/m1n1/kernel and often storage decisions. |
| RAID/LVM/LUKS/ZFS root, multiple candidate disks, hibernation | **Unsupported by current Disko leaf** | One ext4 root, no swap/encryption/topology; a generic kernel module does not describe destructive layout or resume identity. |
| Broadcom/B43/FaceTime/Xone or other nonredistributable/extracted firmware; out-of-tree Wi-Fi | **Unsupported unless explicitly enrolled** | `enableAllFirmware` is false and is itself only a small bounded list. Driver/kernel compatibility must be tested. |
| Surface/T2/Framework quirks, IPU6/fingerprint/WWAN, Thunderbolt docks, unusual audio/SOF, specialty input | **Unverified/host-exception class** | Some may work generically; support cannot be claimed without target evidence and, where applicable, reviewed profiles. |
| Hyper-V/VMware/Virtio/Xen/cloud image as a generic VM class | **Unverified** | Several runtime drivers exist, but root-initrd, guest agents, console, boot firmware, and image layout vary. A VM role or all-hardware recovery output is the honest boundary. |
| i686/ARM32/RISC-V/PowerPC/s390x/LoongArch | **No output / unsupported** | Repository declares only x86_64-linux and aarch64-linux. |

## Missing classes the earlier matrix should add

The earlier lanes already covered BIOS, EFI bitness, Secure Boot, SBCs, Apple,
RAID/LUKS, NVIDIA/hybrid, Wi-Fi firmware, audio/cameras/fingerprint/Thunderbolt,
and hibernation.  Add these explicit categories so “any machine” cannot silently
expand again:

1. Arm SystemReady SR/ES/IR as distinct generic Arm compatibility bands, rather
   than treating all AArch64 as SBC-specific or all AArch64 as generic UEFI.
2. Virtual roots and cloud images: Virtio, Xen/EC2, Hyper-V Gen1/Gen2, VMware,
   serial console, guest agents, and cloud-init are separate from bare metal.
3. SAS/HBA and legacy enterprise storage; `enableAllHardware` calls SCSI coverage
   incomplete.
4. Chromebooks/coreboot/depthcharge, mobile/tablet boot, eMMC/UFS, and vendor NVMe
   controllers.
5. Resource floors: low-RAM/low-disk machines and headless servers can boot Linux
   yet are poor fits for this large Niri workstation closure.
6. Old/legacy GPU generations and kernel regressions caused by always selecting
   `linuxPackages_latest`; “newest” is not uniformly “most compatible.”
7. eGPU, multi-GPU, docks, hotplug-only devices, and displays absent during a
   Facter scan.
8. Enterprise Wi-Fi/802.1X, WWAN and regulatory-domain operation; seeing an SSID
   is not the same as an authenticated, legally configured connection.

## Recommended wording correction

Replace any synthesis sentence like “one unchanged closure cannot work on
diverse machines” with:

> A single architecture-specific closure can intentionally cover many machines
> that share a compatible firmware, boot, root-storage, and driver contract.
> This repository currently has a plausible mainstream x86 UEFI template and an
> unverified generic-UEFI AArch64 template, not universal machine support.
> Concrete host leaves record destructive choices, exceptions, and physical test
> evidence; Facter and exact-model hardware profiles are optional inputs to that
> assurance process, not universal prerequisites.

## Evidence and residual uncertainty

Primary/evaluated anchors:

- exact `all-hardware.nix` and `all-firmware.nix` at root pin `d407951...`;
- exact current x86/aarch64 Nix evaluations and realized x86 module/firmware
  closure;
- https://nixos.org/manual/nixos/stable/ (installation, profiles, Facter,
  hardware generation);
- https://wiki.nixos.org/wiki/NixOS_on_ARM/en;
- https://wiki.nixos.org/wiki/NixOS_on_ARM/Installation;
- https://www.arm.com/architecture/system-architectures/systemready-compliance-program;
- https://www.kernel.org/doc/html/latest/arch/x86/microcode.html;
- https://github.com/NixOS/nixos-hardware.

Not verified: boot on two distinct physical x86 machines, any physical AArch64
machine, NVIDIA/Nouveau behavior, actual Wi-Fi association, suspend/resume,
firmware update, and failure behavior on incompatible boot/storage classes.
Those absences cap confidence even where the static compatibility case is strong.

## EXPAND

- LEAD: execute one unchanged generic x86 closure on two physically different
  UEFI machines (Intel and AMD, different NIC/GPU/storage) — WHY: this is the
  decisive counterexample/proof boundary — ANGLE: boot, root mount, local login,
  Niri, Wi-Fi, audio, suspend, rollback.
- LEAD: execute the current AArch64 output on a named SystemReady-certified
  UEFI/ACPI target — WHY: turns a standards-based plausible class into evidence —
  ANGLE: bootaa64 EFI, NVRAM/removable path, storage, graphics/network.
- LEAD: build a separate all-hardware recovery/install output — WHY: retain broad
  discovery and rescue without pretending the installed workstation is every
  machine — ANGLE: exact initrd delta, size, VM root variants, physical USB boot.
- DEAD END: proving universal hardware support from evaluation/closure contents
  alone — static presence cannot prove firmware execution or physical behavior.

## CLAIMS

- **High confidence:** the absolute “one closure cannot span diverse hardware”
  claim is refuted; compatibility-class-scoped generic closures are real.
- **High confidence:** Facter and `nixos-hardware` are optional and neither is
  sufficient; concrete host leaves are an assurance architecture, not a boot
  prerequisite.
- **High confidence:** current x86 is best described as a conditional mainstream
  64-bit UEFI/SATA-or-NVMe/ext4 baseline, not as wholly nonportable or universal.
- **Medium confidence:** current AArch64 could fit a narrow SystemReady/UEFI class,
  but without physical execution it remains only a template.
- **High confidence:** missing microcode is a security/errata freshness defect,
  not general proof of boot failure.
- **High confidence:** hardware outside the declared matrix must fail the support
  claim, not be silently assumed covered by a latest kernel or broad firmware.
