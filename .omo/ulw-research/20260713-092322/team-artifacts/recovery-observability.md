# Recovery observability after first-install activation failure

Scope: commands for a root shell in the still-running NixOS ISO. These do not
print the password hash. The observation block is read-only. The repair and
retry blocks are separately labelled because they mutate target metadata or
system state.

## Ranked decision tree

1. **Capture evidence before any retry.** A retry can replace metadata, consume
   the verifier, or add enough `/etc` state to hide the first-activation bug.
2. **If `/mnt` or `/mnt/boot` is not mounted, stop.** Identify the existing
   filesystems with `lsblk`; mounting the already-created filesystems is safe,
   but running Disko in its default `disko` mode is destructive.
3. **Compare ISO-host and target-chroot stat views.** If the host view is
   `uid=0 gid=0 owner=root group=root`, while the target-chroot view is
   `uid=0 gid=0 owner=UNKNOWN group=UNKNOWN`, metadata is correct. `chown 0:0`
   cannot repair name resolution. The current generated activation script is
   defective because it compares `%U:%G`; rebuild it to compare `%u:%g` with
   `0:0`, upload the new closure, and run only the install phase.
4. **If numeric IDs or modes are wrong**, and both objects are real directory /
   regular file (not symlinks), the narrowly-scoped metadata repair below is
   safe. Re-observe afterward. For this repository's current name-based
   validator, however, correcting numeric ownership alone is insufficient on a
   genuinely fresh root with no passwd/group database.
5. **If type, symlink status, verifier shape, or mount source is wrong, do not
   chmod/chown through it.** Re-stage a fresh verifier through the reviewed
   workflow and run a non-formatting recovery (`--phases install` when `/mnt`
   is already mounted; `--disko-mode mount --phases disko,install` otherwise).
6. **Never rerun the helper unchanged as a “retry”.** Pinned nixos-anywhere
   defaults to `kexec,disko,install,reboot`; its `disko` phase formats/zaps.

## Safe observation block (ISO root)

```bash
ROOT=/mnt
BOOT=$ROOT/boot
DIR=$ROOT/var/lib/nixos-bootstrap
HASH=$DIR/mei-password.hash
PROFILE=$ROOT/nix/var/nix/profiles/system

printf '%s\n' '=== identity/kernel/block devices ==='
date -Is
id
uname -a
lsblk -o NAME,PATH,TYPE,SIZE,FSTYPE,LABEL,UUID,PARTUUID,MOUNTPOINTS

printf '%s\n' '=== target mounts ==='
findmnt -R -o TARGET,SOURCE,FSTYPE,FSROOT,OPTIONS --target "$ROOT" || true
for p in "$ROOT" "$BOOT" "$DIR" "$HASH"; do
  printf '\n-- mount containing %s --\n' "$p"
  findmnt -T "$p" -o TARGET,SOURCE,FSTYPE,FSROOT,OPTIONS || true
done
mountpoint "$ROOT" || true
mountpoint "$BOOT" || true

printf '%s\n' '=== pathname components (do not follow symlinks) ==='
namei -l -x -n "$DIR" "$HASH" || true

printf '%s\n' '=== ISO-host metadata view ==='
for p in "$ROOT/var" "$ROOT/var/lib" "$DIR" "$HASH"; do
  stat -c 'path=%n type=%F mode=%a raw=%f uid=%u gid=%g owner=%U group=%G dev=%D inode=%i links=%h size=%s mount=%m name=%N' -- "$p" || true
done
command -v getfacl >/dev/null && getfacl -cp -- "$DIR" "$HASH" || true
command -v lsattr  >/dev/null && lsattr -d -- "$DIR" "$HASH" || true

printf '%s\n' '=== verifier shape only; content is never printed ==='
if [ -f "$HASH" ] && [ ! -L "$HASH" ]; then
  printf 'bytes='; wc -c < "$HASH"
  printf 'lines='; wc -l < "$HASH"
  printf 'last-byte-decimal='; tail -c 1 "$HASH" | od -An -tuC | tr -d '[:space:]'; echo
  if grep -Eqx '^\$y\$[./A-Za-z0-9]+\$[./A-Za-z0-9]{1,86}\$[./A-Za-z0-9]{43}$' "$HASH"; then
    echo 'format=yescrypt'
  elif grep -qx '!' "$HASH"; then
    echo 'format=consumed-sentinel'
  else
    echo 'format=INVALID'
  fi
else
  echo 'format=NOT-A-REAL-REGULAR-FILE'
fi

printf '%s\n' '=== target system profile and generations ==='
for p in "$PROFILE" "$ROOT"/nix/var/nix/profiles/system-*-link; do
  [ -e "$p" ] || [ -L "$p" ] || continue
  stat -c 'path=%n type=%F mode=%a uid=%u gid=%g owner=%U group=%G name=%N' -- "$p" || true
  printf 'readlink(%s)=' "$p"; readlink -- "$p" || true
done

# Resolve the profile inside the target root. Unlike `readlink -f $PROFILE`,
# this cannot accidentally resolve an absolute /nix/store target in the ISO.
SYSTEM=$(chroot "$ROOT" /nix/var/nix/profiles/system/sw/bin/readlink -e /nix/var/nix/profiles/system) || SYSTEM=
printf 'target-system=%s\n' "$SYSTEM"
case "$SYSTEM" in
  /nix/store/*-nixos-system-*) ;;
  *) echo 'target system profile is missing or unexpected'; SYSTEM= ;;
esac

if [ -n "$SYSTEM" ]; then
  stat -c 'path=%n type=%F mode=%a uid=%u gid=%g owner=%U group=%G' \
    "$ROOT$SYSTEM" "$ROOT$SYSTEM/activate" "$ROOT$SYSTEM/bin/switch-to-configuration"
  sha256sum "$ROOT$SYSTEM/activate"
  grep -nE '^#### Activation script snippet (bootstrapPasswordHash|users|consumeBootstrapPassword):' \
    "$ROOT$SYSTEM/activate" || true
  sed -n '/^#### Activation script snippet bootstrapPasswordHash:/,/^#### Activation script snippet users:/p' \
    "$ROOT$SYSTEM/activate"

  printf '%s\n' '=== target-chroot NSS/metadata view (no activation is run) ==='
  chroot "$ROOT" "$SYSTEM/sw/bin/stat" -c \
    'path=%n type=%F mode=%a raw=%f uid=%u gid=%g owner=%U group=%G dev=%D inode=%i links=%h size=%s mount=%m name=%N' \
    /var/lib/nixos-bootstrap /var/lib/nixos-bootstrap/mei-password.hash || true
  chroot "$ROOT" "$SYSTEM/sw/bin/getent" passwd 0 || echo 'target-getent-passwd-0=MISSING'
  chroot "$ROOT" "$SYSTEM/sw/bin/getent" group 0  || echo 'target-getent-group-0=MISSING'

  printf '%s\n' '=== target store registration (read-only query) ==='
  nix path-info --store "$ROOT" "$SYSTEM" || true
fi
```

Do **not** use `nixos-enter` for the second stat view: its implementation runs
the target activation script before executing the requested command and ignores
that activation's exit status. Plain `chroot` above runs only `stat`/`getent`.

## Narrow metadata repair (mutating, only after observation)

```bash
DIR=/mnt/var/lib/nixos-bootstrap
HASH=$DIR/mei-password.hash
if [ -d "$DIR" ] && [ ! -L "$DIR" ] && [ -f "$HASH" ] && [ ! -L "$HASH" ]; then
  chown 0:0 -- "$DIR" "$HASH"
  chmod 0700 -- "$DIR"
  chmod 0600 -- "$HASH"
else
  echo 'refusing repair: expected real directory and real regular file' >&2
  exit 1
fi
stat -c 'path=%n type=%F mode=%a uid=%u gid=%g owner=%U group=%G' "$DIR" "$HASH"
```

This changes metadata only. It deliberately does not recurse or replace data.
It cannot fix `UNKNOWN:UNKNOWN` when numeric IDs are already `0:0`.

## Safe non-formatting retry after a corrected closure is available

On the ISO, pass the **newly uploaded corrected** logical store path to
`nixos-install`. Do not resolve the existing profile and mistake its old broken
closure for the corrected one:

```bash
ROOT=/mnt
SYSTEM=/nix/store/REPLACE-WITH-CORRECTED-nixos-system-nixos-VERSION
case "$SYSTEM" in /nix/store/*-nixos-system-*) ;; *) exit 1;; esac
test -x "$ROOT$SYSTEM/activate" || exit 1
nix path-info --store "$ROOT" "$SYSTEM" || exit 1
nixos-install --root "$ROOT" --no-root-passwd --no-channel-copy --system "$SYSTEM"
```

This is the upstream-supported idempotent installer retry and does not invoke
Disko, but it **does** rerun activation and bootloader installation. Do not use
the old closure for the numeric-0/name-UNKNOWN case: it contains the same broken
name comparison. Upload/build the corrected closure first, set/install that
closure, then verify the sentinel and `/etc/shadow` state without printing the
shadow entry.

If the corrected closure is being supplied from the working computer, pinned
nixos-anywhere supports a non-formatting phase retry while the existing target
filesystems remain mounted:

```bash
env -u SSH_AUTH_SOCK nix run github:nix-community/nixos-anywhere/4dfb813db065afb0aba1f61658ef77993d382db1 -- \
  --flake .#x86_64-linux --target-host root@TARGET \
  --ssh-option IdentityAgent=none --build-on local \
  --phases install --no-substitute-on-destination \
  --option max-jobs 1 --option cores 1
```

That command reuses the verifier already on `/mnt`; it does not format. If the
filesystems are not mounted, use the pinned tool's documented recovery path
`--disko-mode mount --phases disko,install` instead (with the same remaining
flags). `mount` mode is unavailable with `--store-paths`. Verify the device
configuration before even a mount-mode recovery.

## Failure-state proof

* Exact pinned nixos-install sets `/mnt/nix/var/nix/profiles/system` before
  entering activation, then creates only `/mnt/etc/NIXOS` and `/mnt/etc/mtab`.
* Exact pinned nixos-enter runs `$system/activate || true` before its requested
  command. Therefore an activation error may be followed by a later error and
  its exit status is not independently preserved.
* The generated activation script orders `bootstrapPasswordHash` before `users`.
  On a fresh target there is no target passwd/group database yet.
* A local bubblewrap experiment using the generated target `stat` binary, an
  empty `/etc`, and a real `uid=0 gid=0 mode=600` file produced:
  `uid=0 gid=0 U=UNKNOWN G=UNKNOWN type=regular empty file mode=600`.
* Pinned nixos-anywhere defaults to all phases and calls the Disko script in
  destructive default mode. Its source and separated-phase integration test
  explicitly support `--phases install`; its repair documentation prescribes
  `--disko-mode mount` to mount existing filesystems and run nixos-install.

## CLAIMS

1. Numeric `0:0` plus target-chroot `UNKNOWN:UNKNOWN` decisively disproves a
   transfer/chown failure and proves the current `%U:%G` check cannot pass in
   that fresh NSS state. Confidence: high.
2. The observation block is non-destructive and does not disclose the verifier.
   Plain `chroot ... stat` is essential because `nixos-enter -c stat` activates
   first. Confidence: high.
3. `nixos-install --system` is idempotent and skips disk partitioning, while an
   unchanged nixos-anywhere/helper retry is destructive by default. Confidence:
   high from exact source and man page.
4. A corrected closure comparing `%u:%g` to `0:0`, followed by install-only or
   mount+install recovery, is safer than adding ad-hoc passwd/group files merely
   to satisfy name lookup. Confidence: high.

## EXPAND

* Capture the target's real output from the observation block before changing
  anything; it will discriminate metadata transfer from NSS-name resolution.
* After rebuilding the numeric validator, run a faithful fresh-root test with
  empty target `/etc/passwd` and `/etc/group`, not merely host-side activation.
* Document `--phases install` / `--disko-mode mount` in the operator guide and
  make the helper accept an explicit safe recovery mode; never silently change
  its destructive default install semantics.
