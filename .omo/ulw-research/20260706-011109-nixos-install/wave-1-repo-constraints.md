# Wave 1: repo constraints

Findings:
- Remote: https://github.com/Meillaya/nix-config.git
- Current branch: main, clean and aligned with origin/main.
- NixOS outputs: `x86_64-linux`, `aarch64-linux`.
- Disko module is imported into `nixosConfigurations`.
- Disko disk key is `vdb`.
- Disko device in repo is placeholder `/dev/%DISK%`, so fresh destructive install must override device from CLI or use a branch with a concrete disk path.
- Layout is GPT, 100M EFI mounted `/boot`, ext4 root mounted `/`.
- User is `mei`; password must be set after install if not declared.
- Desktop currently includes LightDM/BSPWM plus Niri/Noctalia; if graphical boot blanks, TTY + rollback/debug path remains necessary.

EXPAND:
- LEAD: Remote install via nixos-anywhere may reduce typing but needs a way to provide the concrete disk path — WHY: user's current blocker is disk identification/typing — ANGLE: inspect nixos-anywhere options and whether `--disk` passthrough exists.
