# Wave 1B — Exact locked hardware/network/boot/maintenance semantics

Observer: `exact_lock_hw_net`; exact store source, raw SHA matches, Nix eval, generated unit and closure inspection; observed 2026-07-13.

## Exact environment

- Root nixpkgs is `nixpkgs_3@d407951447dcd00442e97087bf374aad70c04cea`, NixOS `26.11.20260705.d407951`, not the transitive `.nodes.nixpkgs@59e696...` trap.
- Nix 2.33.4 (Determinate Nix 3.18.1); realized x86 toplevel `/nix/store/2skzh1yk3bzz5g30zxf6ngcai78m3vci-nixos-system-nixos-26.11.20260705.d407951`; kernel 7.1.3.

## Findings

1. `enableAllHardware=false`; default initrd has 43 modules, counterfactual all-hardware has 102 (+59 mainly legacy/storage/virtualization). This option changes early-boot breadth, not all kernel drivers and not all firmware.
2. Redistributable firmware and wireless-regdb are realized exactly (linux-firmware, Intel/Realtek/etc, ALSA/SOF/DVB and regdb). Broadcom/B43/xone/FaceTime nonredistributable extras are absent despite `allowUnfree` policy.
3. Intel and AMD microcode are false; no microcode image is prepended or present in closure. Generator/Facter would add a target-specific default, but repo does not import it.
4. `networking.wireless=true` is intentional NetworkManager wiring: exact module sets wpa_supplicant D-Bus controlled, no autodetected interfaces. Generated services contain NetworkManager and one global wpa_supplicant backend, but no iwd/connman/systemd-networkd/dhcpcd service. This is not manager competition.
5. Wi-Fi driver/firmware/manager stack covers observed AX200 class, but no `ensureProfiles`/SSID credentials exist. Fresh system can scan/configure locally; association and post-reboot remote reachability remain unproven.
6. wireless-regdb is enabled through multiple exact definitions and realized files.
7. fwupd service/package/timer are absent; OS firmware blobs are not platform firmware updating.
8. PipeWire ALSA/Pulse/WirePlumber and 32-bit ALSA plugin are enabled; rtkit and 32-bit graphics are disabled. Absence of rtkit does not itself prove broken audio.
9. systemd-boot `configurationLimit=42` limits boot entries per profile, not system generations/store roots; named profiles can add more entries.
10. Automatic GC and auto-upgrade are disabled; no timers exist. A dormant nix-gc service definition is not automatic execution.

## Primary exact sources

- https://github.com/NixOS/nixpkgs/blob/d407951447dcd00442e97087bf374aad70c04cea/nixos/modules/hardware/all-hardware.nix
- https://github.com/NixOS/nixpkgs/blob/d407951447dcd00442e97087bf374aad70c04cea/nixos/modules/hardware/all-firmware.nix
- https://github.com/NixOS/nixpkgs/blob/d407951447dcd00442e97087bf374aad70c04cea/nixos/modules/services/networking/networkmanager.nix#L687-L703
- https://github.com/NixOS/nixpkgs/blob/d407951447dcd00442e97087bf374aad70c04cea/nixos/modules/services/networking/wpa_supplicant.nix
- https://github.com/NixOS/nixpkgs/blob/d407951447dcd00442e97087bf374aad70c04cea/nixos/modules/hardware/cpu/amd-microcode.nix
- https://github.com/NixOS/nixpkgs/blob/d407951447dcd00442e97087bf374aad70c04cea/nixos/modules/hardware/cpu/intel-microcode.nix
- https://github.com/NixOS/nixpkgs/blob/d407951447dcd00442e97087bf374aad70c04cea/nixos/modules/services/hardware/fwupd.nix
- https://github.com/NixOS/nixpkgs/blob/d407951447dcd00442e97087bf374aad70c04cea/nixos/modules/services/desktops/pipewire/pipewire.nix
- https://github.com/NixOS/nixpkgs/blob/d407951447dcd00442e97087bf374aad70c04cea/nixos/modules/system/boot/loader/systemd-boot/systemd-boot-builder.py

## Claim resolution

- Refuted erroneous main-pin identification: root mapping, metadata, revision and 13 byte-matched modules prove d407951.
- Confirmed NetworkManager+wpa process stack is designed backend control, not duplicate managers.
- Confirmed redistributable firmware/regdb present; all-firmware extras/microcode absent.
- Confirmed boot-entry limit is not GC; automatic GC/upgrades absent.
- Confirmed 32-bit audio support without 32-bit graphics/rtkit.

## EXPAND
none — exact-pin source/eval/unit/closure scope converged; physical activation remains separate.
