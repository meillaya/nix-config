# Verification — Early activation NSS name resolution

## Claim
A numerically correct root-owned mode-0700 directory fails the current validator when `/etc/passwd` and `/etc/group` are not yet populated, because GNU stat name directives render `UNKNOWN`.

## Exact scenario
Generated the current activation validator from the flake, bound a fixture as `/var/lib`, bound empty files over `/etc/passwd` and `/etc/group` in a fresh user+mount namespace, and ran the validator.

## Output
```text
named=UNKNOWN:UNKNOWN:700 numeric=0:0:700
bootstrap password hash validation failed: expected root:root mode 0700 on /var/lib/nixos-bootstrap
validator_rc=1
repro_rc=1
```

## Environment
- NixOS configuration: x86_64-linux, nixpkgs d407951
- GNU stat from current host/Nix closure
- Linux user/mount namespace (`unshare -Ur -m`)
- Numeric metadata: uid=0 gid=0 mode=0700

## Verdict
CONFIRMED. The current name-based validator reproduces the user's exact error even though numeric ownership and mode are correct.

## Cleanup
Temporary `/tmp/ulw-nss-repro.*` fixture removed by EXIT trap.
