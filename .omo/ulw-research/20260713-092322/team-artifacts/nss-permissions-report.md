# NSS / numeric-ownership / mode investigation

## Result

The staged inode can be numerically **UID 0, GID 0, mode 0700** and still fail the exact predicate because GNU `stat` formats `%U` and `%G` through NSS. On the fresh target, the validator runs before the classic `users` activation fragment creates `/etc/passwd` and `/etc/group`; GNU stat therefore emits `UNKNOWN:UNKNOWN:700`, not `root:root:700`.

This is deterministic for the reported first install. The new upstream `chown -R 0:0` is correct but cannot fix a name-resolution predicate.

## Exact production ordering evidence

Repository predicate (`modules/nixos/bootstrap-password.nix:49`):

```sh
test "$(.../stat -c '%U:%G:%a' "$hash_dir")" = "root:root:700" \
  || fail "expected root:root mode 0700 on $hash_dir"
```

It never prints the actual tuple, so the combined error does **not** prove the owner or mode was wrong.

Exact evaluation:

```sh
nix eval --raw \
  .#nixosConfigurations.x86_64-linux.config.system.activationScripts.script \
  > /tmp/nss-activation.sh
rg -n 'Activation script snippet (bootstrapPasswordHash|users|consumeBootstrapPassword|etc)' \
  /tmp/nss-activation.sh
```

Output:

```text
29:#### Activation script snippet bootstrapPasswordHash:
103:#### Activation script snippet users:
115:#### Activation script snippet consumeBootstrapPassword:
165:#### Activation script snippet etc:
```

The graph explains the order: this repo sets `users.deps = [ "bootstrapPasswordHash" ]`; locked nixpkgs makes `etc` depend on users/groups/specialfs. Locked root input is nixpkgs `d407951447dcd00442e97087bf374aad70c04cea`, local source `/nix/store/ifpab9hxqmk2biwy594da8ipxzsp3y4s-source`.

Relevant locked nixpkgs facts:

- `nixos/modules/misc/ids.nix:49-50,391-392`: root UID and GID are 0.
- `nixos/modules/config/users-groups.nix:842-860`: user `root`, UID 0, primary group `root`; group `root`, GID 0.
- `nixos/modules/config/users-groups.nix:885-900`: the classic `users` activation fragment runs the passwd/group updater.
- `nixos/modules/config/nsswitch.nix:145-177`: eventual nsswitch puts `files` first.
- Current eval: root uid `0`, root group `"root"`, root gid `0`.

Fresh-root construction is decisive:

- locked `pkgs/by-name/ni/nixos-install/nixos-install.sh:298-325` creates only target `/etc/NIXOS` and `/etc/mtab` before `nixos-enter`;
- locked `nixos-enter.sh:61-94` bind-mounts dev/sys/proc and resolver only—not installer passwd/group/nsswitch;
- `nixos-enter.sh:96-113` executes `chroot "$mountPoint" "$system/activate"` (preliminary failure ignored), then chroots the requested command;
- `switch-to-configuration boot` activates again and propagates the failure. Since the early fragment exits before `users`, both passes still lack target passwd/group.

## Exact RED reproduction using the evaluated activation

Command constructed a fresh chroot with only `/etc/NIXOS`, the exact evaluated activation, the Nix store, and a staged correct inode:

```sh
unshare -Urmpf --mount-proc sh /tmp/run-exact-activation-repro.sh
```

The script did:

```sh
mkdir -p "$root"/{nix/store,etc,var/lib/nixos-bootstrap}
mount --bind /nix/store "$root/nix/store"
touch "$root/etc/NIXOS"
printf '%s\n' '$y$j9T$abcdefghijklmnop$0123456789012345678901234567890123456789012' \
  > "$root/var/lib/nixos-bootstrap/mei-password.hash"
chmod 700 "$root/var/lib/nixos-bootstrap"
chmod 600 "$root/var/lib/nixos-bootstrap/mei-password.hash"
chown -R 0:0 "$root/var/lib/nixos-bootstrap"
cp /tmp/nss-activation.sh "$root/activate"
chroot "$root" "$nix_bash/bin/bash" /activate
```

Output:

```text
pre outside: 0:0:root:root:700
target NSS: .../etc/passwd: No such file or directory
             .../etc/group: No such file or directory
bootstrap password hash validation failed: expected root:root mode 0700 on /var/lib/nixos-bootstrap
activation rc=1
post outside: 0:0:root:root:700
```

Thus the actual inode remained correct across the exact failure.

## NSS matrix: every relevant name-lookup outcome

A chroot with the config's GNU coreutils 9.11 and a correct 0:0/0700 inode produced:

```text
no_etc_files              0:0:UNKNOWN:UNKNOWN:700
empty_passwd_group        0:0:UNKNOWN:UNKNOWN:700
passwd_root_only          0:0:root:UNKNOWN:700
root_both                 0:0:root:root:700
alias_admin_wheel         0:0:admin:wheel:700
alias_first_dupes         0:0:admin:wheel:700
root_first_dupes          0:0:root:root:700
systemd_only_nomodule     0:0:UNKNOWN:UNKNOWN:700
compat_only_nomodule      0:0:root:root:700
files_then_systemd        0:0:root:root:700
systemd_then_files        0:0:root:root:700
```

Coreutils 9.11 `src/stat.c:1562-1576` calls `getpwuid`/`getgrgid` and substitutes literal `UNKNOWN` on NULL; `%u/%g` emit numbers. Missing nsswitch does not import host identities into a chroot; glibc falls back to file-based lookup. Duplicate numeric identities return the first matching file entry, so aliases (`admin`, `wheel`) also make the literal predicate fail even though the inode is 0:0.

Pre-users creation by name has the same flaw: in empty `/etc`, `chown root:root /probe` exits 1 (`invalid user: 'root:root'`); `chown 0:0 /probe` succeeds. Therefore all pre-users ownership operations should be numeric, including `write_sentinel` chown and the fallback `install -o/-g`, even though those branches are not what triggered this staged first-install failure.

## Filesystem and permission counter-search

### Mode / umask

Activation globally sets umask 0022 (`activation-script.nix:65-67`). Explicit `install -m 0700` and `chmod 0600/0700` override the relevant umask effects. Lab:

```text
umask 022; mkdir d        -> 755
umask 077; mkdir d        -> 700
umask 077; mkdir -m 0700  -> 700
umask 000; mkdir -m 0700  -> 700
```

The transfer lab separately proved pinned tar plus explicit chown leaves 0:0, 700/600 before nixos-install. Wrong mode is therefore disconfirmed for this run.

### ACLs

POSIX ACL group-class permissions are reflected in `%a` through the ACL mask:

```text
initial:                         700
setfacl -m u:nobody:r-x d:       750
chmod 0700 d:                    700 (named entry remains, effective ---)
default ACL then mkdir child:    750
```

An effective extra-access ACL normally changes `%a`, and the validator correctly rejects it. Mode 700 can conceal only ineffective named ACL entries; ACLs cannot explain the observed false negative when `%a` is actually 700. Explicit archive mode/chmod also dominates normal umask, though an inherited default ACL can alter newly created modes before explicit chmod.

### Symlinks

GNU stat defaults to the link inode (`777`) unless `-L`; the module first rejects a final-component symlink with `test ! -L`. This is intentional and not the staged real-directory case. An ancestor path mount/symlink race could redirect the lookup, but no evidence supports it.

### Mount / namespace semantics

- Plain bind mounts preserve device/inode/uid/gid/mode.
- Ordinary ext4/tmpfs/btrfs and overlay copy-up labs preserved 0:0 and 700/600.
- ID-mapped mounts can translate viewed IDs (lab translated to overflow 65534), but nixos-enter uses an ordinary chroot and ordinary rbinds, not an idmapped mount/user namespace.
- NFS root-squash/NFSv4 idmapping and FUSE can fabricate/mutate ownership or mode; repo Disko uses a local ext4 root, so these require undocumented custom `/var` mounts and are very-low-probability alternatives.
- Capabilities, xattrs, SELinux labels, timestamps, and file contents do not affect `%U:%G:%a`.
- Race/path disappearance/I/O/stat failure also makes command substitution unequal, but the stable repeated error and unchanged staged inode provide no evidence for it.

### Group-0 naming

NixOS defines GID 0 as `root`, not `wheel`. BSD-like `wheel` GID 0 or a duplicate/alias first in NSS would fail `%G == root`; that does not describe the eventual evaluated NixOS database. On the fresh target the actual result is lookup absence (`UNKNOWN`), not an alternate configured group.

## NSS-module and libc boundary semantics

Additional dynamic/static counter-tests do not weaken the production conclusion:

- With a compatible `libnss_systemd.so.2` discoverable, dynamic glibc can synthesize UID/GID 0 as `root:root` for `passwd: systemd` / `files systemd`, even with empty files. Without the module in the runtime loader path it falls through to `UNKNOWN`.
- NSS source ordering/action clauses matter: `files [NOTFOUND=return] systemd` preserves `UNKNOWN`; `files [SUCCESS=continue] systemd` can replace a file alias with systemd's synthesized root; NixOS eventual `files`-first behavior normally preserves real file rows.
- Static musl coreutils ignores glibc NSS DSOs/nsswitch module selection and directly reads passwd/group, yielding `UNKNOWN` when absent.
- strace in the dynamic lab showed opens of nsswitch, passwd, the compatible nss-systemd DSO and group; the static run opened only passwd/group.

These are container/chroot portability boundaries. The exact evaluated activation reproduction is authoritative for this system: before `etc`, its real coreutils/glibc runtime emitted the failure. No final-system nsswitch or compatible systemd NSS setup was yet established.

Upstream precedent also separates correctness from display: nixpkgs commit `aa822ab65720cdd8beb04a52bc60aae15d13d609` implemented an installer ownership check with numeric `stat -c '%u:%g' == 0:0` while using `%U:%G` only in the diagnostic. The check was later reverted because non-root-owned installation roots can be intentional, not because numeric stat was unreliable.

## Test blind spot

`tests/bootstrap-password-lifecycle.sh:40` runs each fixture under `unshare -Ur -m` while retaining host `/etc/passwd` and `/etc/group`. Host-owned uid/gid 1000 fixtures are mapped to namespace 0 and host NSS supplies the literal root names:

```text
outside:           1000:1000 mei:mei:700
inside unshare -Ur:   0:0 root:root:700
```

So the test unintentionally manufactures the expected owner and exercises working host NSS. It cannot detect an early target with absent passwd/group. This is why local lifecycle tests passed.

## Ranked causal assessment

1. **Near-certain / directly reproduced:** pre-users `%U/%G` lookup returns `UNKNOWN/UNKNOWN` in the fresh target chroot. Exact evaluated activation plus correct inode reproduces the exact error.
2. **Ruled out for reported attempt:** extraction/chown failure or wrong numeric ownership. Pinned pipeline uses fatal `set -e`; transfer experiment shows 0:0 after explicit numeric chown.
3. **Low:** actual mode mutation/default ACL/race after transfer. Direct transfer evidence showed 700/600; exact reproduction needs none.
4. **Very low:** alternate uid0/gid0 alias, nscd/systemd NSS behavior, idmapped bind, NFS/FUSE. These can fail the literal predicate in other deployments but conflict with the evaluated fresh ext4/chroot path.
5. **Not causes when numeric tuple is truly 0:0:700:** ordinary umask, plain bind, ordinary overlay/local filesystems, capabilities/xattrs/labels.

## Recommended boundary-safe fix and diagnostics

The invariant is numeric ownership, so validate numeric metadata:

```sh
stat -c '%u:%g:%a' == 0:0:700
stat -c '%u:%g:%a' == 0:0:600
```

Use numeric ownership operations in every fragment that can run before `users`:

```sh
chown 0:0
install -o 0 -g 0
```

Keep the helper's `--chown var/lib/nixos-bootstrap 0:0` exactly numeric; pinned nixos-anywhere itself recommends numeric UID:GID for this option.

Decisive non-destructive target diagnostic:

```sh
stat -c '%u:%g:%a %U:%G %A %n' /mnt/var/lib/nixos-bootstrap \
  /mnt/var/lib/nixos-bootstrap/mei-password.hash
chroot /mnt /nix/var/nix/profiles/system/sw/bin/stat \
  -c '%u:%g:%a %U:%G %A %n' /var/lib/nixos-bootstrap \
  /var/lib/nixos-bootstrap/mei-password.hash
ls -l /mnt/etc/{passwd,group,nsswitch.conf} 2>&1
```

Expected pre-fix discriminator: outside ISO may print `root:root`; direct target chroot prints `UNKNOWN:UNKNOWN`, while both numeric fields are `0:0` and modes 700/600.

## CLAIMS

- **Proved:** exact numeric 0:0/mode700 fails the exact evaluated validator in a fresh target chroot solely because `%U/%G` become `UNKNOWN/UNKNOWN`.
- **Proved:** validator precedes both `users` and `etc`; nixos-install/nixos-enter do not bind/copy installer passwd/group into the target.
- **Proved:** final NixOS identity is root UID 0 and group root GID 0; the issue is timing, not a different final identity.
- **Proved:** current lifecycle tests mask the bug through `unshare -Ur` plus host NSS.
- **Proved:** ordinary umask/bind/local filesystem semantics cannot explain this failure; ACL/idmap/network filesystem alternatives are boundary caveats, not the reported cause.
- **Conclusion:** compare numeric IDs and make pre-users ownership commands numeric.

## EXPAND

- Add a regression that runs the validator with target passwd/group absent and correctly owned 0:0 fixtures; assert numeric checks pass.
- On the failed target, capture the outside-vs-chroot numeric/name diagnostic above before recovery to preserve live corroboration.
- If the implementation is changed, audit all three name-based stat sites (`:49`, `:59`, `:103`) and both name-based ownership sites (`:36/:107`, `:45`), not only the first directory predicate.
