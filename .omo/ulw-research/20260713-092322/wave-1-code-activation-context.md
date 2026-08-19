# Wave 1 — Activation Context (live digest)

- Exact d407951 `nixos-install.sh:310-325` invokes `nixos-enter --root /mnt`.
- `nixos-enter.sh:104` chroots `/mnt` and executes `/nix/var/nix/profiles/system/activate`; absolute validator paths therefore resolve inside target `/mnt`, not the ISO root.
- `nixos-enter` ignores activate failure, then tries `/run/current-system/bin/switch-to-configuration boot`; failed activation never creates the current-system symlink, explaining the downstream ENOENT.

## EXPAND
- LEAD: inspect target `/etc/passwd` and `/etc/group` availability/name mapping at first activate — WHY: numeric metadata may be right while `%U:%G` resolves differently — ANGLE: activation ordering and NSS.
