# Wave 1 — Repository hardware/install audit

Observer: `repo_hw_install`; read-only repository, Nix evaluation, and git-history audit; observed 2026-07-13.

## Ranked findings

1. **Critical:** both NixOS entities are architecture-named generic outputs using the same workstation aspect (`modules/entities/hosts.nix:7-15`; `modules/aspects/hosts/nixos-workstation.nix:3-13`). No concrete `hardware-configuration.nix`, nixos-hardware profile, device tree, or host hardware leaf exists in current or historical source, although `modules/nixos/README.md:33-53` documents that intended boundary.
2. **Critical:** the AArch64 output clones PC-style UEFI/systemd-boot/GPT/ext4 policy (`modules/nixos/system.nix:8-21`; `modules/nixos/disk-config.nix:10-28`). No U-Boot, extlinux, device tree, SD-image, Raspberry Pi, Apple Silicon, or board firmware policy exists. Documentation saying “ARM hardware” is broader than implementation.
3. **Critical:** clean checkout Disko uses `/dev/%DISK%`; install safety depends on an imperative, untracked replacement. No typed host disk value or evaluation assertion rejects the placeholder.
4. **High:** storage is 100 MiB ESP plus unencrypted ext4 root, no swap. This conflicts operationally with a 42-generation systemd-boot retention limit and lacks encryption, hibernation, snapshot, trim/SMART, recovery, or topology policy.
5. **High:** the recorded AMD migration inventory includes AMD microcode, Radeon Vulkan/OpenCL/32-bit graphics, Btrfs/GRUB, and richer hardware tooling, but the current NixOS host does not encode those requirements. Both microcode options evaluate false; GPU-specific policy is commented only.
6. **High:** first-boot Wi-Fi has NetworkManager, redistributable firmware, and regdb, but no installed connection profile/credential transfer. A Wi-Fi-only remote install can lose reachability after reboot until local login/configuration.
7. **High:** the installer helper accepts a flake parameter while hard-coding user `mei`, verifier path, UID:GID 1000:100, and mandatory wallpaper staging. Its interface is more general than its payload contract.
8. **High:** pinned install helper is strong on tool pins, tmpfs secret handling, agent isolation, metadata, TTY, and cleanup, but the guide documents upstream strict-host-key relaxation and therefore an active-network MITM boundary.
9. **High:** one embedded key is authorized for both root and `mei`; SSH is globally enabled without explicit root-login/password/forwarding/allowed-user policy.
10. **Medium:** generic firmware, graphics, Bluetooth, PipeWire, UPower and power-profiles exist, but fwupd, rtkit, host microcode, specialized GPU/media, fingerprint, Thunderbolt, TPM tooling, SMART/fstrim, printing and host power policy are absent.
11. **Medium:** architecture-named hostnames collide across multiple same-architecture machines.
12. **Medium:** detailed bootstrap suites are not all exposed as flake checks; ARM validation lacks boot/storage/firmware assertions.

## Evidence anchors

- `modules/entities/hosts.nix:7-15`
- `modules/aspects/hosts/nixos-workstation.nix:3-13`
- `modules/nixos/README.md:33-53`
- `modules/nixos/system.nix:3-27,70-100,235-267`
- `modules/nixos/niri.nix:13-27`
- `modules/nixos/disk-config.nix:4-33`
- `bin/nixos-anywhere-bootstrap-password.sh:16-107`
- `docs/service-notes/nixos-anywhere-disko-install.md:27-30,68-86,235-301,394-410,543-562`
- `docs/machine-audits/entropyos-cachyos-migration-audit-2026-04-24.md:214-237`
- `tests/dendritic-config-eval.nix:73-115`
- `modules/flake/checks.nix:3-34`
- commits `af306e4`, `e9f7818`

## Claim candidates

- Current NixOS outputs are generic architecture templates, not hardware-complete hosts.
- ARM output is only plausible for matching UEFI ARM systems, not ARM generally.
- Clean checkout is intentionally not install-ready while `%DISK%` remains.
- Storage/boot retention is under-specified and likely ESP-capacity constrained.
- Wi-Fi-only remote install may become unreachable after reboot without a connection profile.
- Helper is specialized to the `mei`/1000:100 contract despite arbitrary flake syntax.
- Bootstrap secret handling is more thoroughly verified than hardware/boot/network paths.
- Direct root SSH authorization is global baseline policy.

## EXPAND
- LEAD: collect intended target hardware probes — WHY: no evidence-backed hardware leaf exists — ANGLE: PCI/USB/CPU/storage/boot/TPM/Wi-Fi/audio/GPU logs.
- LEAD: identify intended AArch64 machine class — WHY: ISA alone cannot choose bootloader/device tree/kernel/firmware — ANGLE: UEFI server/laptop vs SBC/Apple Silicon.
- LEAD: quantify built kernel+initrd footprint against 100 MiB ESP and 42 generations — WHY: validate operational risk — ANGLE: built system boot artifacts.
- LEAD: inspect pinned nixos-anywhere host-key behavior and pinning options — WHY: active-network MITM boundary — ANGLE: exact revision SSH call chain.
- LEAD: test/provision first reboot on Wi-Fi-only hardware — WHY: no profile transfer — ANGLE: declarative protected NM profile vs explicit Ethernet/local-console prerequisite.
- LEAD: decide whether audited `entropyos` is a future NixOS host — WHY: concrete AMD requirements are missing — ANGLE: hardware leaf and acceptance matrix.
- LEAD: inspect deployed ESP/generation state — WHY: eval/build do not prove boot retention — ANGLE: bootctl, df, generation and EFI audit.
- DEAD END: tracked real hardware-configuration.nix; none current or historical.
- DEAD END: historical microcode/LUKS/swap/hibernation/device-tree/Secure Boot implementation; none.
- DEAD END: Disko evolution; placeholder 100 MiB ESP/ext4 scheme unchanged since initial commit.
