# Wave 1 — Root Direct Investigation

## Findings
- The active temp helper and main helper are byte-identical (`b5a3c2de...ae98`), so the repeated failure used the patched arguments.
- Latest target output omits the earlier destination substitution errors, independently showing `--no-substitute-on-destination` took effect.
- Root flake Nixpkgs is `d407951447dcd00442e97087bf374aad70c04cea`; helper `59e6964` pins mkpasswd only.
- Generated system is `/nix/store/8282w9...-nixos-system-nixos-26.11.20260705.d407951`; its `activate` script hardcodes `/var/lib/nixos-bootstrap` and contains the validator before users.
- The active temp Disko target remains the intended stable Micron by-id path.
- Faithful tar extraction over an existing mode-0755 directory restores the source mode 0700; local user ownership remains 1000:1000 because the extractor is non-root. Root extraction behavior still needs a root-mapped experiment.
- Only a single ext4 root filesystem plus vfat boot exists; no separate `/var`, persistence, or tmpfiles rule for the bootstrap path was found.

## Sources
- Repository current diff and active temp checkout.
- `flake.lock` root input.
- Generated system closure `activate`.
- GNU tar runtime experiment (temporary artifact removed by trap).

## EXPAND
- LEAD: inspect exact d407951 `nixos-install.sh` and generated switch implementation — WHY: determine absolute path/chroot context — ANGLE: call chain and mount namespace.
- LEAD: run root-mapped tar/chown/stat experiment — WHY: distinguish mode from name-resolution behavior — ANGLE: user namespace or NixOS VM.
- LEAD: capture actual target stat tuple without another destructive retry — WHY: current validator combines ownership and mode — ANGLE: ISO console/SSH diagnostic.
