# Activation context — Wave 1 exact call-chain report

## Executive verdict

The bootstrap validator reads the **installed target filesystem**, not the installer ISO root: `nixos-anywhere` copies to outer `/mnt`, the runtime `nixos-install` calls `nixos-enter --root /mnt`, and `nixos-enter` executes the target profile's `activate` under `chroot /mnt`. Thus target `/var/lib/nixos-bootstrap` means outer `/mnt/var/lib/nixos-bootstrap`.

The observed pair of failures is one chain:

1. the target `activate` reaches `bootstrapPasswordHash` before the `users` fragment;
2. a fresh target has no `/etc/passwd` or `/etc/group` yet, so `stat -c %U:%G` can report numeric UID/GID 0 as `UNKNOWN:UNKNOWN`;
3. the validator compares that name rendering with literal `root:root` and calls `exit 1`;
4. `nixos-enter` deliberately ignores the activation failure (`|| true`), then executes the bootloader command;
5. the aborted activation never reaches its final `ln -sfn ... /run/current-system`, so `/run/current-system/bin/switch-to-configuration` is absent and produces the downstream ENOENT.

This reconciles the transfer lane's proof that the final target inode is numeric `0:0`, mode `700`, with the validator's hard-coded `root:root:700` rejection.

## Exact versions

- Project target NixOS: root flake input is `flake.lock` node `nixpkgs_3`, SHA `d407951447dcd00442e97087bf374aad70c04cea`; evaluated version `26.11.20260705.d407951`. The plain lock node `nixpkgs` at `59e6964...` is **not** the root flake input; the helper uses `59e6964...` only for `mkpasswd` (`bin/nixos-anywhere-bootstrap-password.sh:18,58`).
- `nixos-anywhere`: helper pin `4dfb813db065afb0aba1f61658ef77993d382db1` (`bin/...sh:19,73`), described upstream as `1.13.0-88-g4dfb813`, commit date 2026-07-01.
- Runtime installer image selected by that pin: source `nixos-anywhere.sh:709-715` downloads the `nixos-images` `nixos-25.11` noninteractive x86 tarball. The asset in effect before the reported 2026-07-13 incident was uploaded 2026-05-28 by [workflow run 26572181097](https://github.com/nix-community/nixos-images/actions/runs/26572181097), at `nixos-images` SHA `c8118f10321884499eea93fd66ff593f151316e1`, asset digest `sha256:64020c75b021a2e3f72418d1f1bfa975fcd391f57dee38ab3aef639991edc860`. Its stable lock is nixpkgs `b77b3de8775677f84492abe84635f87b0e153f0f`, version `25.11.20260522.b77b3de`.
- Local research host Nix: Determinate Nix 3.18.1 / Nix 2.33.4. This is the local builder/client, not necessarily the installer image's Nix daemon version.

## Call chain and path rooting

1. Repo helper builds target system locally (`--build-on local`) and passes `--extra-files "$stage" --chown var/lib/nixos-bootstrap 0:0`: `bin/nixos-anywhere-bootstrap-password.sh:71-83`.
2. Pinned nixos-anywhere locally builds `system.build.toplevel` (`src/nixos-anywhere.sh:952-960`), runs kexec/disko/install in that order (`:1009-1063`).
3. It uploads the closure to a Nix store rooted at `/mnt`: `nix copy --to ssh://...?remote-store=local?root=/mnt` (`:863-873`).
4. It streams the extra-files tar into `tar -C /mnt ... --no-same-owner`, then applies the requested recursive chown to `/mnt/$file` (`:876-886`). There is no intervening repo-controlled metadata mutation before `nixos-install` (`:888-916`).
5. Remote `nixos-install --no-root-passwd --no-channel-copy --system <target-system>` is the **installer image's** executable, not one from the target flake (`:888-916`).
6. Exact runtime nixpkgs `b77b3de` sets `/mnt/nix/var/nix/profiles/system` to that target system first (`nixos-install.sh:228-233`), creates only `/mnt/etc/NIXOS` and `/mnt/etc/mtab` (`:235-247`), and calls `NIXOS_INSTALL_BOOTLOADER=1 nixos-enter --root /mnt ...` (`:247-262`). It does not create target passwd/group first.
7. Runtime `nixos-enter` creates a private mount+UTS namespace (`nixos-enter.sh:8-18`), bind-mounts `/dev`, `/sys`, `/proc` under target (`:61-65`), then runs `chroot "$mountPoint" "$system/activate" ... || true` (`:96-109`). Absolute path `/var/lib/...` is therefore target `/mnt/var/lib/...`; the installer hostname/UTS identity does not change this filesystem-root fact.
8. It then `exec chroot "$mountPoint" "${command[@]}"` (`:111-113`). The embedded command rbinds chroot `/` to its `/mnt` only for absolute evaluation-time bootloader paths, then calls `/run/current-system/bin/switch-to-configuration boot` (`nixos-install.sh:247-260`).

Primary permalinks:

- [nixos-anywhere 4dfb813 install pipeline](https://github.com/nix-community/nixos-anywhere/blob/4dfb813db065afb0aba1f61658ef77993d382db1/src/nixos-anywhere.sh#L843-L919)
- [runtime nixos-install b77b3de](https://github.com/NixOS/nixpkgs/blob/b77b3de8775677f84492abe84635f87b0e153f0f/pkgs/by-name/ni/nixos-install/nixos-install.sh#L228-L262)
- [runtime nixos-enter b77b3de](https://github.com/NixOS/nixpkgs/blob/b77b3de8775677f84492abe84635f87b0e153f0f/pkgs/by-name/ni/nixos-enter/nixos-enter.sh#L8-L18)
- [runtime nixos-enter chroot/ignored activate b77b3de](https://github.com/NixOS/nixpkgs/blob/b77b3de8775677f84492abe84635f87b0e153f0f/pkgs/by-name/ni/nixos-enter/nixos-enter.sh#L94-L113)

## Generated target activation ordering

Evaluated and built from the dirty working tree at target nixpkgs `d407951`:

- built system: `/nix/store/8282w9asajxj0sa1bwzkz1fyplz4a7v9-nixos-system-nixos-26.11.20260705.d407951`
- built activate SHA-256: `d9d91e195eaea61d1cd4dabcaa8b41ce32677414b7a71ace4427324393496694`
- order in built `activate`: `binsh` line 21; `bootstrapPasswordHash` line 34; `users` line 108; `consumeBootstrapPassword` line 120; `specialfs` line 148; `etc` line 170; final `/run/current-system` link line 223.
- evaluated deps: `bootstrapPasswordHash=[]`; `users=["bootstrapPasswordHash"]`; `consumeBootstrapPassword=["users"]`.
- target module anchors: validator name comparison at `modules/nixos/bootstrap-password.nix:42-60`; forced predecessor relationship at `:83-89`.
- stock classic users fragment creates passwd/group via `update-users-groups.pl` only in `users` (nixpkgs `d407951`, `nixos/modules/config/users-groups.nix:885-903`). Stock `etc` itself depends on users/groups/specialfs (`nixos/modules/system/etc/etc-activation.nix:14-18`).
- activation generator only creates `/run/current-system` after all fragments (`nixos/modules/system/activation/activation-script.nix:68-81`). The module's `fail(){ exit 1; }` therefore bypasses this tail.

Primary permalinks:

- [activation generator d407951](https://github.com/NixOS/nixpkgs/blob/d407951447dcd00442e97087bf374aad70c04cea/nixos/modules/system/activation/activation-script.nix#L52-L81)
- [classic users activation d407951](https://github.com/NixOS/nixpkgs/blob/d407951447dcd00442e97087bf374aad70c04cea/nixos/modules/config/users-groups.nix#L885-L903)
- [dependency ordering algorithm d407951](https://github.com/NixOS/nixpkgs/blob/d407951447dcd00442e97087bf374aad70c04cea/lib/strings-with-deps.nix#L129-L181)

## Executed rootless namespace proof

A `bwrap --unshare-all --uid 0 --gid 0` harness bound a fresh target root containing numeric uid/gid `0:0`, directory mode 700 and file mode 600, plus the exact target coreutils 9.11 store closure. With empty target `/etc/passwd` and `/etc/group`, exact `stat` output was:

```text
dir=UNKNOWN:UNKNOWN:0:0:700
file=UNKNOWN:UNKNOWN:0:0:600
```

After adding only target-root entries `root:x:0:0:...` and `root:x:0:`, the same inodes rendered:

```text
dir=root:root:0:0:700
file=root:root:0:0:600
```

This confirms the name-rendering failure independently of transfer metadata; numeric `%u:%g` remains `0:0` in both cases.

## Contradictions resolved

- **“Activation runs on installer because hostname says nixos-installer.”** It runs in a private UTS/mount namespace but under `chroot /mnt`; UTS hostname and filesystem root are separate. Installer-hostname observations do not imply ISO-root path resolution.
- **“The closure or switch executable is missing.”** The target system closure contains `bin/switch-to-configuration`; nixos-install has already set the target system profile. Only `/run/current-system` is missing because the activation tail did not execute.
- **“The chown did not work.”** Transfer lane proved exact postpass ends at numeric `0:0/700`; the validator compares NSS names, not numeric IDs.
- **“Bootloader installed, then validator ran.”** The log prints `installing the boot loader...` before entering `nixos-enter`; actual target activation happens inside `nixos-enter` before the embedded switch-to-configuration can install the bootloader. The message is a phase banner, not proof the bootloader action completed.

## Recovery interface note for adjacent lane

After correcting the validator/config and ensuring the newly built system closure is uploaded, the supported full retry is the same `nixos-install --no-root-passwd --no-channel-copy --system <new-system>` from the installer environment; it resets the target profile then replays activation and bootloader. `nixos-enter -c ...` is not a passive diagnostic because `nixos-enter` automatically activates first and ignores that status. Do not treat a direct old profile path as the corrected closure.

## CLAIMS
- CLAIM: Validator absolute paths resolve in target `/mnt`, not ISO root — RISK: high — SOURCES: nix-community/nixos-anywhere@4dfb813; NixOS/nixpkgs@b77b3de — COUNTER: installer-hostname evidence refuted as UTS-vs-chroot confusion — PRIMARY: exact upstream source plus executed generated script.
- CLAIM: The switch ENOENT is downstream of validator `exit 1` preventing `/run/current-system` creation — RISK: high — SOURCES: NixOS/nixpkgs@b77b3de; NixOS/nixpkgs@d407951 — COUNTER: target closure inspected and contains switch executable — PRIMARY: exact upstream source and built store artifact.
- CLAIM: Fresh-target numeric root ownership can fail literal `root:root` validation before users activation — RISK: high — SOURCES: repo generated activation; NixOS/nixpkgs@d407951 — COUNTER: rootless isolated target with and without NSS entries — PRIMARY: built activation and executed bwrap harness.
- CLAIM: Actual target NixOS is d407951/26.11, runtime installer is b77b3de/25.11; 59e6964 is only mkpasswd — RISK: normal — SOURCES: local flake.lock/eval; nixos-images@c8118f1; GitHub Actions/release API — COUNTER: checked root input mapping rather than lock node names — PRIMARY: flake lock and upstream workflow artifacts.

## EXPAND
- LEAD: Capture the failed target's direct `chroot /mnt stat -c '%U:%G:%u:%g:%a'` and `getent passwd 0/group 0` without `nixos-enter` — WHY: incident-specific final confirmation without auto-activation side effects — ANGLE: recovery/observability lane.
- LEAD: Add a regression harness that evaluates/runs validator in an NSS-empty target root and uses numeric `%u:%g` — WHY: current lifecycle tests run under host NSS and miss install-time chroot ordering — ANGLE: implementation/test planning after research.
- DEAD END: wrong filesystem root; exact runtime chroot source refutes it.
- DEAD END: missing target closure; built system contains switch executable and profile is set before activation.
