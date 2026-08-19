# Wave 1 — Reference multi-host and Niri/Hyprland configurations

Observer: `reference_configs_desktop`; every named repo shallow-cloned and HEAD-pinned, import chains followed, 12 varied searches; accessed 2026-07-13.

## Pinned sources

| repository | SHA |
|---|---|
| IogaMaster/dotfiles | `7d51419991763c91f9bcefdd74a30cea60c01cce` |
| eljangus/Hyprland-Dotfiles | `6e77068ede967c377f156ec412174472f1abfae8` |
| khyryra/dotfiles | `ff6a648d96ba66ad5708a392713b771efe05098b` |
| NazariiPalahnii/nixos | `c6ec8d9cd8847ca903871a07127ae01214f5997f` |
| AdrielVelazquez/nixos-config | `4aef017b2ae10e26a77b6489763c6fa0d603de00` |
| QuackHack-McBlindy/dotfiles | `898a36d05b83273b48fa08ac8ba084ca95b4f1d8` |
| basnijholt/dotfiles | `a64ef2920fd9ca97410a6ded55e38176c32badcc` |
| kiriwalawren/nixflix | `141cfe004293aad221ab89ddacc4c30c7f6af2cf` |
| blkflth/blkedn | `b0e13cb1ad1066c970f63f9f5486e70826f1218c` |
| NotMugil/niri-dots | `af3326633c8186de329d428f8383da27a9695b19` |
| linuxmobile/kaku | `b062bf7886d4b6625cc619ca9299e8cc83a528bb` |
| ryan4yin/nix-config | `c44aa91e96d07f649d4a530a977c0b116793829b` |

## Findings

1. Current repo's Den/aspect architecture is stronger and more explicit than most references. The immediate gap is exported verification: semantic Niri/config/bootstrap tests are not all in flake checks.
2. Highest-value transfer: a destructive-storage VM safety check and cutover preflight, following basnijholt's `runNixOSTest` concept while retaining declarative Home Manager ownership.
3. Export existing semantic evaluation tests first; then add VM tests and a CI matrix driven from `.#checks`, following nixflix's unit/VM separation without its network/sandbox exceptions.
4. Separate portable Niri policy from host hardware. Adriel exposes typed render/DRM/brightness/dGPU values; Ryan uses a host `niri-hardware.kdl` fragment. Current Den aspects can express this without new frameworks.
5. Niri config can be split by concern (`config`, `binds`, `layout`, `rules`, optional `hardware`) while remaining store-deployed. Bind overlay titles/grouping improve discoverability.
6. Facter is useful only after concrete heterogeneous hardware exists; do not add another abstraction without a consumer.
7. Reference anti-patterns are common: stale install docs, missing tracked hardware files, local/private inputs, default/public credentials, hashes in store, duplicated module attributes, hard-coded home/monitor paths, recursive hidden discovery, imperative Dotbot ownership, disabled/sandboxless tests, and dead Niri modules.
8. The requested rice/unixporn configs are useful interaction catalogs, not correctness/security/portability foundations.

## Priority candidates

- P0 export semantic eval/bootstrap tests as flake checks.
- P0 Disko VM safety test.
- P1 CI matrix derived from exported checks.
- P1 declarative Niri fragment split.
- P1 host-specific Niri hardware boundary.
- P2 overlay titles/bind grouping and a tighter cutover runbook.
- Defer Facter, Stylix, niri-flake or SOPS migration until concrete need; no new dependency is justified by these comparisons alone.

## Source examples

- https://github.com/basnijholt/dotfiles/blob/a64ef2920fd9ca97410a6ded55e38176c32badcc/configs/nixos/flake.nix#L305-L320
- https://github.com/kiriwalawren/nixflix/blob/141cfe004293aad221ab89ddacc4c30c7f6af2cf/tests/unit-tests/default.nix#L17-L46
- https://github.com/kiriwalawren/nixflix/blob/141cfe004293aad221ab89ddacc4c30c7f6af2cf/tests/vm-tests/default.nix#L7-L36
- https://github.com/AdrielVelazquez/nixos-config/blob/4aef017b2ae10e26a77b6489763c6fa0d603de00/modules/home-manager/niri/default.nix#L27-L67
- https://github.com/ryan4yin/nix-config/blob/c44aa91e96d07f649d4a530a977c0b116793829b/home/linux/gui/niri/default.nix#L28-L39
- https://github.com/blkflth/blkedn/blob/b0e13cb1ad1066c970f63f9f5486e70826f1218c/rice/niri/keybinds.nix#L8-L155

## EXPAND
none — all named repositories plus three independent Niri references converged on the same transferable patterns and anti-patterns.
