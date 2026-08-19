# Wave 2 — faithful generated-activation GREEN proof design

## Evidence already executed (read-only)

No repository files were edited by this lane.

1. Before the numeric-owner change landed in the shared tree, `bash tests/bootstrap-password-lifecycle.sh` returned `1` at the new install-context case:

```text
valid-empty-target-nss expected=pass rc=1 verdict=FAIL
output=bootstrap password hash validation failed: expected root:root mode 0700 ...
```

2. With the current shared numeric-owner change, the same test returned `0`. Essential lines:

```text
valid-empty-target-nss expected=pass rc=0 verdict=PASS
wrong-mode expected=fail rc=1 verdict=PASS ... got 0:0:644
wrong-parent expected=fail rc=1 verdict=PASS ... got 0:0:777
consumer-mismatch-preserves-verifier=PASS rc=1
consumer-exact-sentinel-and-revalidation=PASS
```

3. Built the real changed target toplevel without altering the repository:

- `/nix/store/2fammh39xrhqy56jarvkvmhgfwf7idyp-nixos-system-nixos-26.11.20260705.d407951`
- built `activate` SHA-256 `ef15d96218231eec80b91f671fe281d8c351eeff63bf2ce6ac8ea4178480d192`
- actual generated order: validator line 34; users 112; consumer 124; specialfs 156; etc 178; `/run/current-system` link 231.
- actual deps remain validator `[]`, users `[bootstrapPasswordHash]`, consumer `[users]`.
- generated relevant span uses `%u:%g`, literals `0:0:700` / `0:0:600`, numeric `chown 0:0`, and `install -o 0 -g 0`; no `%U/%G` name dependency remains.

This proves the focused regression but not yet the complete `nixos-install → nixos-enter → activate → switch boot` chain. The following VM test is the necessary high-confidence GREEN gate.

## Required faithful VM integration harness

### Why a VM, not another user-namespace fragment test

The generated `users` fragment performs `chown` to all declared target UIDs/GIDs, while the generated `specialfs` fragment mounts/remounts devtmpfs, devpts, proc, tmpfs, ramfs, and sysfs. A one-ID rootless user namespace cannot faithfully execute these operations. Truncating the script before `specialfs`, or preconstructing `/etc/shadow`, would re-test fragments rather than the incident call chain. Use a NixOS VM with a real root mount namespace.

### Pin both sides

- **Runtime install tools:** nixpkgs `b77b3de8775677f84492abe84635f87b0e153f0f`, matching the 2026-05-28 nixos-images asset actually selected by nixos-anywhere `4dfb813`.
- **Target system:** the current flake target, nixpkgs `d407951447dcd00442e97087bf374aad70c04cea`, with the numeric fix.
- Use runtime `${runtimePkgs.nixos-install}`; its closure carries the exact runtime `${runtimePkgs.nixos-enter}`. Do not accidentally use the target flake's d407 install tools.

A test-only target override should replace `system.build.installBootLoader` with an executable that accepts the toplevel argument, verifies it, and atomically writes `/boot/proof-switch-reached`. This avoids hardware bootloader effects while proving that the exact `switch-to-configuration boot` executable was reached and its boot branch ran. It does not replace activation or switch-to-configuration.

### VM setup sequence

Inside an ephemeral NixOS test node, as root:

```bash
mount -t tmpfs -o mode=755 none /mnt
mkdir -p /mnt/{boot,etc,var/lib/nixos-bootstrap,nix}

# Place the complete d407 target closure in the root=/mnt local store,
# matching nixos-anywhere's remote-store=local?root=/mnt upload.
nix copy --no-check-sigs \
  --to 'local?root=/mnt' \
  "$TARGET_SYSTEM"

printf '%s\n' "$VALID_YESCRYPT" \
  > /mnt/var/lib/nixos-bootstrap/mei-password.hash
chown -R 0:0 /mnt/var/lib/nixos-bootstrap
chmod 0700 /mnt/var/lib/nixos-bootstrap
chmod 0600 /mnt/var/lib/nixos-bootstrap/mei-password.hash

# Assert the target is genuinely NSS-empty before installation.
test ! -e /mnt/etc/passwd
test ! -e /mnt/etc/group
test ! -e /mnt/etc/shadow

"$RUNTIME_NIXOS_INSTALL" \
  --no-root-passwd \
  --no-channel-copy \
  --system "$TARGET_SYSTEM" \
  > /tmp/install.log 2>&1
```

`nixos-install` must not be given `--no-bootloader`: the proof must traverse its real embedded `/run/current-system/bin/switch-to-configuration boot` command.

### Exact positive assertions

All must hold after exit 0:

```bash
# 1. Exact known failure signatures disappeared.
! grep -Fq 'bootstrap password hash validation failed:' /tmp/install.log
! grep -Fq '/run/current-system/bin/switch-to-configuration: No such file or directory' /tmp/install.log

# 2. The activation tail ran and target view has the executable.
chroot /mnt test -L /run/current-system
chroot /mnt test "$(readlink -f /run/current-system)" = "$TARGET_SYSTEM"
chroot /mnt test -x /run/current-system/bin/switch-to-configuration

# 3. Classic users activation ran after validation.
chroot /mnt getent passwd root >/dev/null
chroot /mnt getent passwd mei >/dev/null
chroot /mnt getent group root >/dev/null
chroot /mnt getent group shadow >/dev/null

# 4. The intended verifier reached mei's shadow entry without printing it.
chroot /mnt awk -F: -v expected="$VALID_YESCRYPT" \
  '$1 == "mei" && $2 == expected { ok=1 } END { exit !ok }' /etc/shadow

# 5. Consumer ran after users and replaced only the duplicate verifier.
test "$(stat -c '%u:%g:%a' /mnt/var/lib/nixos-bootstrap)" = '0:0:700'
test "$(stat -c '%u:%g:%a' /mnt/var/lib/nixos-bootstrap/mei-password.hash)" = '0:0:600'
test "$(od -An -tx1 /mnt/var/lib/nixos-bootstrap/mei-password.hash | tr -d '[:space:]')" = '210a'

# 6. switch-to-configuration boot actually ran, beyond mere path existence.
test -f /mnt/boot/proof-switch-reached
```

Use direct `chroot` only for passive postconditions. Never use `nixos-enter` for observations because it auto-activates and ignores that activation result.

### Generated-artifact assertions before runtime

The test derivation must inspect the built `$TARGET_SYSTEM/activate`, not only module values:

```bash
v=$(grep -n '^#### Activation script snippet bootstrapPasswordHash:' "$TARGET_SYSTEM/activate" | cut -d: -f1)
u=$(grep -n '^#### Activation script snippet users:' "$TARGET_SYSTEM/activate" | cut -d: -f1)
c=$(grep -n '^#### Activation script snippet consumeBootstrapPassword:' "$TARGET_SYSTEM/activate" | cut -d: -f1)
r=$(grep -n 'ln -sfn .* /run/current-system' "$TARGET_SYSTEM/activate" | cut -d: -f1)
test "$v" -lt "$u" && test "$u" -lt "$c" && test "$c" -lt "$r"
sed -n "${v},${c}p" "$TARGET_SYSTEM/activate" | grep -Fq "stat -c '%u:%g:%a'"
! sed -n "${v},${c}p" "$TARGET_SYSTEM/activate" | grep -Eq "stat -c '.*%[UG]"
```

Also evaluate deps exactly: validator `[]`, users contains `bootstrapPasswordHash`, consumer equals `[users]`.

## Causal mutation controls

A GREEN integration test should be paired with these focused controls:

1. **Name-rendering mutant:** change `%u:%g`/`0:0` back to `%U:%G`/`root:root` in a temporary materialized tree. Expected: NSS-empty validator failure, no `/run/current-system`, no boot marker, followed by switch ENOENT. This recreates the original causal chain.
2. **Ordering mutant:** remove `bootstrapPasswordHash` from `users.deps`. Existing mutation test must kill it; generated order assertion independently fails.
3. **Mode mutants:** 0644 file and 0777 directory remain rejected with reported numeric metadata.
4. **Ownership mutant:** UID or GID nonzero remains rejected even though NSS names are absent.
5. **Consumer mismatch mutant:** shadow contains a different verifier; consumer exits nonzero and original verifier is preserved.
6. **Tail/switch control:** remove or suppress the test bootloader marker; VM test must fail even if validation/users/consumer pass. This prevents a false GREEN that stops before the downstream command.

## What success proves

A single passing VM test establishes, under the exact two pinned nixpkgs revisions, all incident-relevant transitions:

`numeric 0:0/700 staged under /mnt` → `runtime nixos-install profile set` → `runtime nixos-enter chroot activation` → `validator succeeds with empty NSS` → `users installs exact shadow hash` → `consumer writes !\\n` → `activate creates /run/current-system` → `embedded switch-to-configuration boot executes test bootloader`.

## CLAIMS
- CLAIM: The current focused lifecycle suite is GREEN after numeric validation and retains wrong-mode, wrong-directory-mode, consumer mismatch, sentinel, symlink and format rejection coverage — RISK: normal — SOURCES: executed `tests/bootstrap-password-lifecycle.sh`; generated d407 target artifact — COUNTER: pre-fix run reproduced failure — PRIMARY: command output `/tmp/wave2-current-green.out`.
- CLAIM: A rootless fragment harness cannot faithfully prove full generated activation due target UID/GID chowns and special filesystem mounts — RISK: normal — SOURCES: generated `activate`; `update-users-groups.pl`; generated mounts script — COUNTER: rootless bwrap is valid only for the NSS/stat subclaim — PRIMARY: exact d407 built artifacts.
- CLAIM: The specified VM gate proves disappearance of both original errors and execution of every causal stage, including the real switch boot branch — RISK: high — SOURCES: runtime b77 nixos-install/nixos-enter; target d407 generated activation/switch — COUNTER: requires execution before final merge, design alone is not completion — PRIMARY: exact source call chain.

## EXPAND
- LEAD: Implement/run the pinned b77-runtime/d407-target NixOS VM test and archive `/tmp/install.log` with secret-safe assertions — WHY: closes the only remaining full-chain execution gap — ANGLE: test-engineer lane.
- LEAD: Add name-rendering full-chain mutant or, at minimum, retain the captured pre-fix empty-NSS RED output beside the GREEN artifact — WHY: proves the test fails for the exact original cause — ANGLE: mutation control.
- DEAD END: running the whole generated activation under a one-ID user namespace; target UID/GID chowns and special filesystem remounts make it unfaithful.
