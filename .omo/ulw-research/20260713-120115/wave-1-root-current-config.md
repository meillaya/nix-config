# Wave 1 — Root direct repository/evaluation observations

Observed 2026-07-13 from the committed repository at `e9f78180748f1feb428ffb20f9d932c5d9918a48`.

## Key findings

- The flake declares x86_64-linux and aarch64-linux NixOS hosts, plus both Darwin architectures and standalone Linux Home Manager outputs. Both NixOS hosts include the same workstation/storage/Niri aspects; there is no per-device hardware module boundary in the entity declaration.
- Both NixOS evaluations enable systemd-boot with EFI-variable writes, redistributable firmware, wireless regulatory data, NetworkManager, the NixOS wireless service, graphics, Bluetooth, Niri, PipeWire, power-profiles-daemon, OpenSSH, polkit, and exactly one login session (`niri`).
- Both evaluations leave all-firmware, Intel microcode, AMD microcode, fwupd, rtkit, automatic garbage collection, and automatic upgrades disabled.
- The AArch64 evaluation inherits a broad generic initrd-module list and EFI/systemd-boot policy. That evaluates but does not establish compatibility with arbitrary ARM boot firmware or boards.
- The current Disko file contains a single destructive disk layout and the installer workflow expects the operator to replace/override the device identifier.
- Current source contains substantial Linux-specific theme mutation and portal restart logic, while Darwin has a separate system package/font layer and shared Home Manager shell/Kitty configuration.

## Evidence

- `verify-current-config.json`: executed Nix evaluation of both NixOS outputs.
- `current-source-anchors.txt`: numbered source snapshots for flake, entity/aspect composition, system, Niri, Linux Home Manager, Disko, and checks.
- Direct search found relevant configuration in `modules/nixos/system.nix`, `modules/nixos/niri.nix`, `modules/linux/home-manager.nix`, `modules/entities/hosts.nix`, `modules/aspects/hosts/nixos-workstation.nix`, and `modules/flake/checks.nix`.

## EXPAND
- LEAD: Determine why both `networking.networkmanager.enable` and evaluated `networking.wireless.enable` are true and whether this is intentional backend wiring or competing supplicants — WHY: duplicate wireless managers can prevent reliable scanning — ANGLE: inspect evaluated units/options and NixOS module source.
- LEAD: Verify microcode defaults and whether `hardware.cpu.{intel,amd}.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware` is still recommended/current — WHY: both evaluated false despite portability goal — ANGLE: pinned nixpkgs module source and built closure.
- LEAD: Prove systemd-boot/EFI and the current Disko scheme across BIOS, removable EFI, ARM SBC, VM, and WSL — WHY: one boot/storage policy cannot be universal — ANGLE: official platform docs and reference configs.
- LEAD: Audit fwupd, rtkit, GC, update strategy, and recovery defaults — WHY: day-one operation includes firmware updates, real-time audio policy, and disk health — ANGLE: official module definitions and operational sources.
