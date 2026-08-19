# Wave 1 — Deployment media, WSL/server/VM roles, Dendritic architecture

Observer: `deployment_images_roles`; 13+ searches, all requested pages, SCALE transcript, eight repos plus wiki cloned and SHA-pinned; accessed 2026-07-13.

## Findings

1. Highest-value architecture is one source tree with many explicit outputs: shared features, OS class, role, hardware/virtualization target, and host identity/state. One universal NixOS module is an anti-pattern.
2. Deployment artifacts should project a named host output (`.#host`), not duplicate policy. Official `nixos-rebuild build-image`/`image.modules` supports this model. Implicit hostname/default selection has built the wrong target in real Hyper-V usage.
3. Choose media by constraints: local ISO, nixos-anywhere for reachable remote servers, pinned kexec/rescue when necessary, provider images for VMs/cloud, NixOS-WSL `.wsl` imports for WSL, and nix-darwin for macOS.
4. nixos-anywhere integrates kexec/Disko/install/reboot and offers `--vm-test`, but Disko is destructive, default kexec is x86-oriented, and target RAM/network/kexec prerequisites apply.
5. `nixos-images` provides separate ISO/kexec/netboot artifacts with useful recovery features, but has Secure Boot/RAM/root prerequisites and open issues around cryptsetup, AArch64, IMA, network preservation, firmware, and key options. Pin release and digest; do not execute `latest` root pipelines blindly.
6. A two-stage bootstrap is safer: minimal boot/storage/SSH/identity/recovery first, full workstation/server role after reachability validation. Dustin Lyons' workflow offers strong UX/build-before-switch patterns but is a workstation template, not universal payload.
7. WSL is a distinct platform: Windows owns kernel/network/storage; no Disko, bootloader, laptop power, or native hardware modules. Current upstream uses `.wsl` artifacts and WSL-specific activation workarounds.
8. Server generations do not roll back mutable DB/media/credentials/migrations. Backups, restore tests, monitoring and storage remain server concerns; Nix-declared OCI containers are compatible with this model.
9. Dendritic's durable idea is feature-first, class-specific composition. Its own guidance warns against vocabulary proliferation/fanaticism. Den adds entities/policies/quirks but recent issues show abstraction/maturity risk; retain current Den only with checks for every host/class.
10. Determinate ISO intentionally changes the Nix distribution and adds FlakeHub tooling; it is not a neutral replacement. Icicle is a distro-installer product with unresolved install/storage issues, not fleet configuration management.

## Pinned primary sources

- mightyiam/dendritic `586e1138ca380c10d14535acac3fbc8f2779401a`
- Dendritic FAQ wiki `3768e8d0eaeb0405a5983fc2013eff3f286e6a24`
- nix-community/nixos-images `803f28511c7d5f39f2537c342122fd94b8e1d519`
- dustinlyons/nixos-config `24dddbd9a86c22b3d85420c41ac82c2ad0020faa`
- nix-community/NixOS-WSL `7348d3f38ab1bd6abe156a923fab6f43656b168f`
- LGUG2Z/nixos-wsl-starter `780c583f22046e238306d24c99cf09cd02d8f1aa`
- denful/den `1614f6f8ed435c5bb257408bf91fd662f9aac43e`
- DeterminateSystems/nixos-iso `a70e0d77485720fd4623318998e3bb397e41dca2`
- snowfallorg/icicle `f0ab516239943a3f3d58ee792d3951152caad28c`
- https://nixos.org/manual/nixos/stable/
- https://nix-community.github.io/nixos-anywhere/
- https://www.socallinuxexpo.org/scale/21x/presentations/case-nix-home-server/
- https://sakurakat.systems/posts/hyperv-shenanigans/

## Claim candidates

- Immediate usability improves when every target is a named output consumed explicitly.
- Boot, disk, networking, virtualization and privileged services must be platform/role/host specific.
- nixos-anywhere is a strong remote-server default only where its prerequisites/trust boundary hold.
- WSL requires its own platform module and artifact.
- Build/image/install commands should always name `.#host` and use pinned revisions/digests.
- System-generation rollback does not cover mutable application state.
- Custom installer media should remain optional products, not canonical config architecture.

## EXPAND
- LEAD: exact-lock Hyper-V/VHDX `nixos-rebuild build-image` coverage — WHY: official image support varies by revision/provider — ANGLE: inspect project pin image modules/tests.
- LEAD: signed Secure Boot recovery/install path — WHY: common ISO/kexec paths require disabling Secure Boot — ANGLE: UKI/Lanzaboote/custom keys for concrete firmware.
