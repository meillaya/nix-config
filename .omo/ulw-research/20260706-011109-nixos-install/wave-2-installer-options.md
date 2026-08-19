# Wave 2: installer option evidence

Sources:
- Disko disko-install docs: https://github.com/nix-community/disko/blob/master/docs/disko-install.md
- nixos-anywhere docs: https://nix-community.github.io/nixos-anywhere/quickstart.html
- Determinate NixOS ISO docs: https://docs.determinate.systems/guides/nixos-isos/
- NixOS manual stable install section: https://nixos.org/manual/nixos/stable/

Findings:
- `disko-install` fresh-install syntax supports `--flake <flake>#<attr> --disk <disk-name> <disk-device>`; this directly matches repo disk key `vdb`.
- `disko-install` combines Disko partitioning and `nixos-install` into one step.
- `nixos-anywhere` installs over SSH and is unattended after launch, but its help exposes `--flake`, `--target-host`, build options, extra files, phases, and disko mode; it does not expose a `--disk` passthrough option.
- Determinate NixOS ISO exists for x86_64-linux and aarch64-linux and has flakes enabled by default, but it is an installer environment, not a custom Niri/Noctalia image.
- NixOS manual says flake installs use `nixos-install --flake path#name`; if a declared user exists, set its password via `nixos-enter --root /mnt -c 'passwd alice'` before reboot.

EXPAND:
- LEAD: Low-RAM install should avoid building on laptop where possible — WHY: user hit OOM/no-space earlier — ANGLE: prefer `--max-jobs 1 --cores 1`, zram/swap, or nixos-anywhere build-on-local from stronger machine.
- LEAD: Disk identification remains the riskiest human step — WHY: user had repeated difficulty identifying disk — ANGLE: propose a copy-paste menu that selects stable `/dev/disk/by-id` and excludes USB/loop/zram.
