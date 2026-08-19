# Wave 3 — `/run` counter-search verdict

## Verdict
`--extra-files` staged `/run` is rejected. nixos-install uses boot action without activation, and first boot mounts tmpfs over on-disk `/run` before users activation. `/var/lib` is the supported persistent path.

## Sources
- https://github.com/nix-community/nixos-anywhere/blob/4dfb813db065afb0aba1f61658ef77993d382db1/src/nixos-anywhere.sh#L876-L916
- https://github.com/NixOS/nixpkgs/blob/4d6a0fd222021d945d463b10bdba629861b6c506/pkgs/by-name/ni/nixos-install/nixos-install.sh#L310-L325
- https://github.com/NixOS/nixpkgs/blob/4d6a0fd222021d945d463b10bdba629861b6c506/nixos/modules/system/boot/stage-2-init.sh#L134-L141
- https://github.com/nix-community/nixos-anywhere/blob/4dfb813db065afb0aba1f61658ef77993d382db1/tests/from-nixos.nix#L30-L62

## CONTRADICTION RESOLUTION
- Wave-1 `/run` recommendation refuted.
- Wave-2 `/var/lib` recommendation independently confirmed.

## EXPAND
- DEAD END: Both initrd implementations, install boot action, stage2 activation, and integration test checked; no open lead.
