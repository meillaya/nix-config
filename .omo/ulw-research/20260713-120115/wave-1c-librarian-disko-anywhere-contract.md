# Wave 1C — exact Disko / nixos-anywhere install contract

Research date: 2026-07-13  
Repository revision audited: `e9f78180748f1feb428ffb20f9d932c5d9918a48`  
Scope: research only. No production source was changed. No credential values were read into or reproduced in this report.

## Executive verdict

The current install path has several strong pieces: exact Git revisions for the password generator and `nixos-anywhere`, private tmpfs staging, strict local shape/mode checks for the password verifier and wallpapers, numeric ownership before activation, local closure building, and an install-only recovery procedure. Those pieces are covered by a substantial mock test.

It is **not yet a fail-closed or fully reproducible destructive installer**:

1. Disk selection is an imperative dirty-tree replacement of `/dev/%DISK%`. The helper neither requires the replacement nor binds the chosen path to independently observed target identity. A leftover placeholder fails before useful work, but a wrong *valid* device is destroyed without a second check or prompt.
2. `nixos-anywhere` puts `UserKnownHostsFile=/dev/null` and `StrictHostKeyChecking=no` before all caller-supplied SSH options. OpenSSH uses the first value, so `--ssh-option` cannot restore strict checking. This is a hard MITM boundary for a root, disk-destructive protocol.
3. The exact pinned `nixos-anywhere` source uses a GitHub release URL for its default kexec image and downloads/executes it without checking a digest. The release is mutable. Pinning the tool commit therefore does not pin all code executed during a kexec install. The repo's documented direct-ISO path skips kexec, but the helper itself does not enforce that precondition.
4. `--vm-test` validates a synthetic QEMU disk and boot, not the physical disk path or hardware. Disko deliberately replaces configured devices with `/dev/vd*`, so the VM derivation evaluates even while the production config still contains `/dev/%DISK%`. It also cannot test `--extra-files` or generated hardware configuration.
5. `--phases install` assumes `/mnt` is already the correct mounted target. Upstream performs no mount/source/fingerprint preflight before copying a closure and invoking `nixos-install`.
6. Upstream explicitly says Wi-Fi networks are unsupported for the remote contract. A Wi-Fi-only laptop can work when booted into a suitable installer and manually associated first, but that is not an upstream reliability guarantee and a kexec transition does not preserve WPA credentials.

The safe design target is: a reviewed per-host install manifest (architecture, target disk stable ID plus serial/size/model, expected SSH host key, hardware report, boot mode), a locally built content-pinned kexec image or a verified physical ISO, a strict-host-key-capable installer fork/wrapper, an exported Disko VM check, and mandatory live preflight immediately before the destructive phase.

## Method and source coverage

I ran 12 materially distinct web searches covering: nixos-anywhere VM tests; phases; extra-files; ownership; host-key behavior; kexec checksums; kexec failures; Disko VM tests; Disko disk overrides; nixos-images release artifacts; Determinate ISO behavior; and current open installation issues. Search-engine results were treated only as discovery. Claims below are grounded in full primary sources cloned or opened directly.

Exact upstream snapshots inspected:

| Project | Revision inspected | Release relation |
|---|---:|---|
| nix-community/disko | `ff8702b4de27f72b4c78573dfb89ec74e36abdf1` | upstream HEAD on research date; 80 commits after `latest`; repo's exact flake pin |
| nix-community/nixos-anywhere | `4dfb813db065afb0aba1f61658ef77993d382db1` | upstream HEAD on research date; 88 commits after `1.13.0`; helper's exact pin |
| nix-community/nixos-images | `803f28511c7d5f39f2537c342122fd94b8e1d519` | upstream HEAD on research date |
| DeterminateSystems/nixos-iso | `a70e0d77485720fd4623318998e3bb397e41dca2` | upstream HEAD and tag `v3.21.5` |

The pinned nixos-anywhere lock in turn fixes Disko at the same `ff8702b…`, nixos-images source at `45c188c452d274e003c9acc6b43fab911fa6cfa5`, nixpkgs at `39b92caca76274e7673f27b09d6c3734df0ed931`, and nixos-stable at `1f01958ffb5b3545c96d9ef2f4e24c5e5e1eb846`. However, its runtime default kexec download does not use the locked nixos-images package; it uses a release URL.

Primary entry points:

- [nixos-anywhere exact installer script](https://github.com/nix-community/nixos-anywhere/blob/4dfb813db065afb0aba1f61658ef77993d382db1/src/nixos-anywhere.sh)
- [nixos-anywhere exact requirements](https://github.com/nix-community/nixos-anywhere/blob/4dfb813db065afb0aba1f61658ef77993d382db1/docs/requirements.md)
- [nixos-anywhere exact extra-files documentation](https://github.com/nix-community/nixos-anywhere/blob/4dfb813db065afb0aba1f61658ef77993d382db1/docs/howtos/extra-files.md)
- [nixos-anywhere exact recovery modes](https://github.com/nix-community/nixos-anywhere/blob/4dfb813db065afb0aba1f61658ef77993d382db1/docs/howtos/disko-modes.md)
- [nixos-anywhere exact custom-kexec documentation](https://github.com/nix-community/nixos-anywhere/blob/4dfb813db065afb0aba1f61658ef77993d382db1/docs/howtos/custom-kexec.md)
- [Disko exact NixOS module](https://github.com/nix-community/disko/blob/ff8702b4de27f72b4c78573dfb89ec74e36abdf1/module.nix)
- [Disko exact VM test implementation](https://github.com/nix-community/disko/blob/ff8702b4de27f72b4c78573dfb89ec74e36abdf1/lib/tests.nix)
- [Disko exact `disko-install` device mapping](https://github.com/nix-community/disko/blob/ff8702b4de27f72b4c78573dfb89ec74e36abdf1/install-cli.nix)
- [nixos-images kexec runtime](https://github.com/nix-community/nixos-images/blob/803f28511c7d5f39f2537c342122fd94b8e1d519/nix/kexec-installer/kexec-run.sh)
- [nixos-images release builder](https://github.com/nix-community/nixos-images/blob/803f28511c7d5f39f2537c342122fd94b8e1d519/build-images.sh)
- [Determinate NixOS ISO README](https://github.com/DeterminateSystems/nixos-iso/blob/a70e0d77485720fd4623318998e3bb397e41dca2/README.md)
- [Determinate NixOS ISO definition](https://github.com/DeterminateSystems/nixos-iso/blob/a70e0d77485720fd4623318998e3bb397e41dca2/flake.nix)

## Current repository contract

### Pins and inputs

- `flake.lock:83-101` pins Disko to `ff8702b4de27f72b4c78573dfb89ec74e36abdf1` with a NAR hash.
- `bin/nixos-anywhere-bootstrap-password.sh:19-20` pins `mkpasswd`'s nixpkgs to `59e69648d345d6e8fef86158c555730fa12af9de` and nixos-anywhere to `4dfb813db065afb0aba1f61658ef77993d382db1`.
- `modules/nixos/disk-config.nix:5-8` names the Disko disk `vdb` but sets its physical device to the literal `/dev/%DISK%`.
- `modules/nixos/disk-config.nix:12-27` creates a GPT with a 100 MiB vfat ESP and an ext4 root occupying the remainder. There is no swap, encryption, legacy-BIOS partition, recovery partition, or multi-disk policy in this layout.

The pins make source evaluation repeatable *if the input tree is identical*. The installation instructions intentionally dirty the tree by replacing the disk path (`docs/service-notes/nixos-anywhere-disko-install.md:256-301`). That disk selection is not recorded in the Git revision, lock file, or a durable install manifest, so the exact install intent cannot be reconstructed from commit `e9f7818…` alone.

### Helper behavior

`bin/nixos-anywhere-bootstrap-password.sh` does the following in the observed order:

1. Requires Linux `findmnt` and a tmpfs `XDG_RUNTIME_DIR` (`:21-29`).
2. Rejects a wallpaper source that is missing, symlinked, contains links/special files, exceeds 4 GiB, or cannot fit in tmpfs (`:30-51`).
3. Stages in a private runtime directory and cleans it on exit/signals (`:54-82`).
4. Produces and shape-validates one yescrypt verifier (`:84-95`).
5. Runs exact nixos-anywhere with local build, staged extra files, numeric chowns, no destination substitution, and one build job/core (`:97-110`). It unsets `SSH_AUTH_SOCK` and appends `IdentityAgent=none`.

This is locally disciplined. `bash tests/bootstrap-password-install-helper.sh` passed all positive, negative, cleanup, signal, interactive-TTY, pin, ownership, wallpaper, and hash-shape cases during this audit. The test is a mock of the `nix` command (`tests/bootstrap-password-install-helper.sh:18-108`); it proves argument/staging behavior, not a live SSH, Disko, boot, or activation transaction.

The helper has no checks for:

- the literal placeholder being absent;
- the selected disk path being `/dev/disk/by-id/...`;
- target device type, removability, serial, model, size, transport, or current mounts;
- installer architecture matching the flake output;
- UEFI availability or Secure Boot state;
- expected SSH host-key fingerprint;
- target being an installer rather than an arbitrary Linux host;
- a preflight VM test having passed for the exact dirty tree;
- a bounded retry count for SSH key upload.

### Is disk selection fail-closed?

Only in the narrowest leftover-placeholder case.

I built the exact current `config.system.build.diskoScript`. It retained `/dev/%DISK%` literally, unmounted `/mnt`, invoked disk deactivation, then called `sgdisk --clear`/partition creation on that path. The first unavoidable `sgdisk` failure exits under `set -e`, so the literal placeholder should not silently pick another disk. `%` is not a shell wildcard.

That does **not** make the workflow fail-closed. Once the text is replaced by any existing valid block path, nixos-anywhere directly executes the generated `diskoScript` (`nixos-anywhere.sh:843-860`). It does not invoke Disko's interactive CLI safety prompt. There is no second identity check between manual patching and wipe. A typo that names the USB, another internal disk, or a stale `/dev/sdX` is a valid destructive input.

Disko itself already has a better parameterization interface: `disko-install --disk NAME DEVICE` (`disko-install:7-24,131-139`), and `install-cli.nix:13-32` refuses to build if a mapping is absent. The local guide correctly notes that nixos-anywhere does not expose that switch (`docs/service-notes/nixos-anywhere-disko-install.md:68-86`). The right equivalent for nixos-anywhere is a per-host configuration or generated ephemeral module/manifest, not an unconstrained text substitution.

Minimum fail-closed preflight immediately before Disko should assert all of:

- exact stable by-id path and resolved block node exist;
- `lsblk` type is `disk`, not partition/loop/rom;
- expected serial, WWN, model, size range, and transport match a reviewed manifest;
- `RM=0` unless explicitly allowed;
- neither target nor descendants back the running installer, source USB, mounted valuable filesystems, or swap;
- architecture and UEFI/BIOS policy match the selected host output;
- the generated Disko script contains the expected path and contains no placeholder;
- an operator confirms a concise fingerprint such as `by-id + serial + size`, not only `/dev/sdX`.

## Exact upstream phase contract

`nixos-anywhere` initializes all four phases (`kexec,disko,install,reboot`) enabled (`src/nixos-anywhere.sh:27-31`). `--phases` clears them and enables only comma-separated recognized names (`:351-363`). Main executes them in that fixed order (`:1009-1067`).

### Kexec phase

- It is skipped automatically when facts say the target already is a NixOS installer (`:700-703`). This is the normal path described by this repo's guide.
- Otherwise, x86_64 and aarch64 use `https://github.com/nix-community/nixos-images/releases/download/nixos-25.11/nixos-kexec-installer-noninteractive-${isArch}-linux.tar.gz` (`:709-717`). Other architectures abort.
- The tarball is fetched by target `wget`/`curl` or local `curl`, extracted, and executed (`:765-816`). There is no SHA-256, signature, attestation, or Nix store-path check in this path.
- The kexec image saves authorized keys, SSH host keys, IP addresses, and routes into its initrd (`nixos-images/nix/kexec-installer/kexec-run.sh:35-78`) and restores network state after boot. It does not save Wi-Fi SSIDs or WPA credentials.
- Exact requirements conflict slightly: README says 1 GiB excluding swap; `docs/requirements.md:38-39` says 1.5 GiB. For reliable planning use the stricter 1.5 GiB floor plus headroom for Disko dependencies and uploaded closures.

As of the audit, GitHub reports the `nixos-25.11` release as `isImmutable: false`. Its x86_64 noninteractive asset had digest `sha256:64020c75b021a2e3f72418d1f1bfa975fcd391f57dee38ab3aef639991edc860`, but nixos-anywhere neither requests nor verifies that digest. The nixos-images release script uploads assets with `gh release upload --clobber` (`build-images.sh:52-55`). Therefore the URL is not a content identity. The exact tool pin points at 25.11 even though current nixos-images CI builds 26.05 and unstable (`.github/workflows/build.yml:13-18`).

Safer contract: build a kexec tarball through Nix from an exact nixos-images commit, verify its resulting store path/hash, and pass the local file with `--kexec`. The exact upstream custom-kexec guide demonstrates the local-store-file interface, but its example should itself be changed from an unpinned repository reference to an exact revision.

### Disko phase

- nixos-anywhere builds `system.build.${diskoMode}Script`; default `diskoMode=disko` (`:310-320,420-428`).
- `disko` means destructive destroy/format/mount. `mount` means mount existing filesystems. `format` creates/formats/mounts without the initial destroy path.
- The resulting store script is copied to the installer and executed directly (`:843-860`). There is no interactive wipe confirmation.
- `--no-disko-deps` reduces RAM use only when the installer already contains every required tool.

### Install, extra-files, chown, and host-key ordering

Actual implementation order in `nixosInstall` is:

1. copy/build the target system closure into the `/mnt`-rooted store (`:863-874`);
2. tar the contents of `--extra-files` over `/mnt`, with remote ownership initially forced to root (`:876-881`);
3. recursively apply every `--chown path uid:gid` under `/mnt` (`:883-886`);
4. optionally copy preserved installer host keys, but do not overwrite keys already supplied by extra-files (`:900-911`);
5. invoke `nixos-install`, which runs target activation (`:888-917`).

Thus the current bootstrap verifier and wallpaper files are present and numerically owned before activation. The upstream extra-files page's phrase “after installation” is imprecise; current code copies before `nixos-install`.

`--extra-files` copies the *contents* of one staged root tree and overwrites matching files. It does not accept source/destination pairs. Upstream issue [#283](https://github.com/nix-community/nixos-anywhere/issues/283) remains open because this is unintuitive, especially for existing mountpoints. The current repo's prepared root tree is the correct usage pattern.

### Reboot phase

Reboot unmounts ZFS layouts specially, schedules reboot, and waits until SSH becomes unreachable (`:921-935`). Omitting reboot leaves the installer environment running for inspection.

## VM test contract and blind spots

`--vm-test` only builds `${flakeAttr}.system.build.installTest` (`src/nixos-anywhere.sh:505-530`). It rejects store paths, remote builds, extra-files, disk-encryption-key upload, and generated hardware config (`:505-523,940-945`).

Disko defines `installTest` for a NixOS configuration at `module.nix:266-303`. Its test library intentionally rewrites each configured physical disk path to synthetic `/dev/vda`, `/dev/vdb`, etc. (`lib/tests.nix:11-69,107-127`), formats and mounts those virtual disks, installs the system, and boots it. This is excellent layout/boot regression coverage, but it cannot validate the production device ID.

Executed observations:

- `nix eval --raw .#nixosConfigurations.x86_64-linux.config.disko.devices.disk.vdb.device` returned `/dev/%DISK%`.
- The same tree successfully evaluated an `installTest` derivation at `/nix/store/km2gvghhr5h3ghhxncw2pxxvyqd3b8si-vm-test-run-disko-nixos-disko.drv`.
- `nix build ...installTest --dry-run` showed a large VM/boot closure, but the test was not executed in this lane.
- `nix eval --json .#checks.x86_64-linux --apply builtins.attrNames` returned only `dendritic-apps`, `dendritic-architecture`, and `dendritic-boundaries`; the Disko install test is not exported through flake checks.

Consequences:

- A green VM test does not mean the physical disk selector is present or correct.
- It does not validate firmware, actual storage controller, Secure Boot, physical UEFI NVRAM, Wi-Fi, or GPU.
- It does not exercise this helper's password/wallpaper transfer because `--vm-test` forbids extra-files.
- It should still become a mandatory CI check because it catches layout, bootloader, filesystem, and boot regressions that current checks miss.

## SSH trust and authentication contract

The exact pinned source initializes SSH arguments as:

```text
-o IdentitiesOnly=yes -i <temporary-key> -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no
```

(`src/nixos-anywhere.sh:63-70`). Caller `--ssh-option` values are appended later (`:240-243`). I empirically confirmed OpenSSH first-value behavior:

- `StrictHostKeyChecking=no` followed by `yes` resolved to `false`; `UserKnownHostsFile=/dev/null` followed by a trusted file resolved to `/dev/null`.
- Reversing the order resolved to strict checking and the trusted file.

Therefore the repo's warning at `docs/service-notes/nixos-anywhere-disko-install.md:27-30` is correct, and the advertised upstream `--ssh-option UserKnownHostsFile=...` cannot override these two baked defaults in this revision. A trusted network reduces exposure but does not make a disk-destructive root protocol cryptographically authenticated.

The local helper's `env -u SSH_AUTH_SOCK` and `IdentityAgent=none` are useful defenses against “too many authentication failures”. Upstream still deliberately puts `IdentitiesOnly=no` first during `ssh-copy-id` so password login can occur (`src/nixos-anywhere.sh:551-571`). It retries forever every three seconds. Current open issues include:

- [#629 Too many authentication failures](https://github.com/nix-community/nixos-anywhere/issues/629)
- [#635 temporary identity-file warning/failure](https://github.com/nix-community/nixos-anywhere/issues/635)
- [#615 ssh-copy-id too many arguments](https://github.com/nix-community/nixos-anywhere/issues/615)
- [#651 kexec_file_load failure on a current Hetzner/Ubuntu target](https://github.com/nix-community/nixos-anywhere/issues/651)

The helper mitigates agent flooding and preserves an interactive TTY, but it does not bound retries or solve upstream host authentication. A secure implementation needs an upstream change/fork that places caller trust options first (or offers a strict mode), an out-of-band verified installer host key, and preservation of that trusted key into the final system with `--copy-host-keys` or a deliberately staged host key.

## Wi-Fi and installer-image implications

Exact upstream requirements state: “Nixos-anywhere does not support wifi networks” (`docs/requirements.md:21-25`, also README `:79-81`). The remote workflow requires uninterrupted SSH reachability. The nixos-images kexec code preserves L3 addresses/routes but not Wi-Fi association credentials; kexec on a Wi-Fi-only host can sever the only control channel.

Three distinct cases must not be conflated:

1. **Wired existing Linux + kexec:** upstream's best-supported remote shape. Use a verified local kexec artifact and strict host authentication.
2. **Physical installer ISO + wired:** the repo's documented shape. nixos-anywhere detects the installer and skips kexec, avoiding the mutable kexec download.
3. **Physical installer ISO + Wi-Fi:** potentially workable after connecting locally and proving SSH plus internet stability, but outside the upstream guarantee. Prefer a NetworkManager/IWD-enabled installer and keep console access. Do not assume the connection survives a kexec transition.

nix-community/nixos-images provides an interactive ISO with IWD and `iwctl` instructions (`README.md:81-94`). Determinate's ISO supports x86_64 and aarch64 and differs from the standard minimal ISO by enabling flakes/Determinate Nix and NetworkManager (`README.md:1-41`; `flake.nix:56-111`). It is a full ISO, not a kexec tarball and not a transparent drop-in for the default kexec contract. Its `stable` download URLs are moving interfaces; the README does not provide a checksum workflow. If used, bind and verify a specific artifact rather than treating `stable/...` as immutable.

## Recovery contract

The repo's recovery instructions are directionally correct:

- `--phases install` omits Disko and reboot.
- It deliberately omits `--extra-files` but retains `--chown var/lib/nixos-bootstrap 0:0`, so an already staged verifier is re-owned before activation.
- If filesystems are no longer mounted, `--disko-mode mount` with the normal phases mounts existing filesystems, installs, and reboots. Combining `--disko-mode mount` with `--phases install` does not mount anything because the Disko phase is disabled.

The missing guarantee is executable preflight. With no kexec phase, nixos-anywhere simply assumes the destination is already the installer and changes the user to `root` (`src/nixos-anywhere.sh:983-987`). It still uploads a key and checks generic facts, but `nixosInstall` does not assert that `/mnt` is a mountpoint, that `/mnt/boot` is the expected ESP, or that sources match the intended disk. A manual `findmnt` in documentation is weaker than a required machine check. Recovery should abort unless the exact expected root/ESP sources and filesystem types match the reviewed manifest.

## Reproducibility ledger

| Element | Current status | Verdict |
|---|---|---|
| root flake inputs | locked with revisions/NAR hashes | strong |
| Disko source | exact `ff8702b…` | strong |
| nixos-anywhere source | exact `4dfb813…` | strong |
| mkpasswd source | exact nixpkgs `59e696…` | strong |
| disk selector | dirty text replacement, not durable | weak |
| hardware report | helper does not generate/import per-host report | weak |
| default kexec content | mutable release URL, no verification | critical gap when kexec runs |
| SSH server identity | disabled checking, caller cannot override | critical gap |
| extra-files content | local ephemeral tree; password intentionally ephemeral, wallpapers not manifest-hashed | acceptable for secret, incomplete audit trail for assets |
| Disko VM test | available but neither run by helper nor exported in `checks` | gap |
| recovery mounts | documented manual check, not enforced | gap |

## Prioritized remediation

### P0 — before another unattended destructive install

1. Stop using the pinned upstream binary on untrusted networks until strict host verification can be placed before upstream defaults. Patch/fork the exact source or obtain an upstream strict-host-key mode; do not rely on appended `--ssh-option`.
2. Make the helper refuse to run while `%DISK%` exists and require a reviewed install manifest containing by-id, resolved node, serial/WWN, model, size, transport, removable flag, boot mode, architecture, and expected host-key fingerprint.
3. Re-query and compare that manifest over the already authenticated SSH connection immediately before Disko. Print one concise destructive confirmation fingerprint.
4. For kexec, build a tarball from an exact nixos-images revision through Nix, verify/store its digest, pass the local file with `--kexec`, and record it in the manifest. Otherwise enforce that the target is already an installer so kexec cannot run.
5. Require wired networking for unattended installs. Treat Wi-Fi-only as an attended exception with console recovery and a purpose-built installer.

### P1 — make regressions observable

1. Export `config.system.build.installTest` as a flake check for each supported Linux host and run it in CI.
2. Add pure assertions: no `%DISK%`; supported disk layout; minimum ESP policy; no architecture output claims without a compatible boot policy.
3. Add integration tests for strict known-host success/failure, bounded authentication retries, local verified kexec, extra-files/chown before activation, and install-only recovery with correct/wrong/missing mounts.
4. Add a dry-run/preflight mode that performs every remote check and builds both Disko and system closures but cannot invoke the destructive script.

### P2 — replace architecture-named generic installs with host contracts

Create explicit host outputs. Each host imports a target-generated Facter report or hardware configuration, an explicit disk module, networking handoff, firmware policy, and boot policy. Shared modules can remain universal; device and boot facts cannot. Preserve the exact install manifest and evaluated flake revision with the machine's operations record.

## Evidence versus inference

**Direct evidence:** exact source lines and executed evaluations above; successful mock helper test; SSH `-G` first-value experiment; GitHub release immutability/digest metadata; current open issue states; generated current Disko script retaining the literal placeholder.

**High-confidence inference:** a leftover `%DISK%` fails on the first real Disko operation rather than selecting another device; a wrong valid path is wiped without confirmation; Wi-Fi credentials are not preserved across current kexec because only address/route/SSH files are injected; the dirty disk patch prevents revision-only reconstruction.

**Not verified in this lane:** full QEMU `installTest` execution; an end-to-end install on sacrificial physical hardware; Secure Boot; BIOS boot; ARM board boot; actual Wi-Fi survival; post-install SSH reachability; checksum/attestation mechanisms that may exist outside the four inspected repositories.

## EXPAND

1. Implement and adversarially test a strict-known-host nixos-anywhere patch/fork; verify both initial and post-kexec key continuity.
2. Design a signed/content-addressed per-host install manifest and a no-write preflight that binds disk serial/size/path, architecture, boot mode, and host key.
3. Build the exact Disko VM test and measure/repair the 100 MiB ESP under multiple retained generations.
4. Test a verified exact-revision kexec image on wired x86_64 and aarch64, including the open `kexec_file_load` failure class.
5. Test attended Wi-Fi install paths separately for official minimal ISO, nix-community IWD ISO, and Determinate NetworkManager ISO; do not generalize one result to kexec.
6. Exercise install-only recovery against missing, wrong, and correct `/mnt` sources and make wrong/missing mounts fail before closure transfer.

## CLAIMS

- **C1 (high):** The repo pins Disko to `ff8702b4de27f72b4c78573dfb89ec74e36abdf1` and its helper pins nixos-anywhere to `4dfb813db065afb0aba1f61658ef77993d382db1`. Evidence: `flake.lock:83-101`; `bin/nixos-anywhere-bootstrap-password.sh:19-20`.
- **C2 (high):** The production Disko device remains `/dev/%DISK%`, while Disko's VM test rewrites device paths to synthetic virtio disks. Consequently VM-test evaluation cannot validate physical disk selection. Evidence: `modules/nixos/disk-config.nix:5-8`; [Disko `lib/tests.nix:11-69`](https://github.com/nix-community/disko/blob/ff8702b4de27f72b4c78573dfb89ec74e36abdf1/lib/tests.nix#L11-L69).
- **C3 (high):** nixos-anywhere directly executes `system.build.diskoScript` without Disko CLI's interactive destruction confirmation. Evidence: [nixos-anywhere `src/nixos-anywhere.sh:843-860`](https://github.com/nix-community/nixos-anywhere/blob/4dfb813db065afb0aba1f61658ef77993d382db1/src/nixos-anywhere.sh#L843-L860).
- **C4 (high):** Extra files are copied and chowned after Disko and closure upload but before `nixos-install` activation. Evidence: [nixos-anywhere `src/nixos-anywhere.sh:863-917`](https://github.com/nix-community/nixos-anywhere/blob/4dfb813db065afb0aba1f61658ef77993d382db1/src/nixos-anywhere.sh#L863-L917).
- **C5 (high):** `--vm-test` cannot cover extra-files, disk-encryption-key transfer, remote builds, store paths, or hardware generation. Evidence: [nixos-anywhere `src/nixos-anywhere.sh:505-530,940-945`](https://github.com/nix-community/nixos-anywhere/blob/4dfb813db065afb0aba1f61658ef77993d382db1/src/nixos-anywhere.sh#L505-L530).
- **C6 (high):** The exact upstream SSH defaults disable host verification before caller options; appended options cannot override first-value OpenSSH settings. Evidence: [nixos-anywhere `src/nixos-anywhere.sh:63-70,240-243`](https://github.com/nix-community/nixos-anywhere/blob/4dfb813db065afb0aba1f61658ef77993d382db1/src/nixos-anywhere.sh#L63-L70) plus the executed `ssh -G` control experiment.
- **C7 (high):** The default kexec path downloads an unverified GitHub release tarball; the release assets are mutable and built with clobbering uploads. Evidence: [nixos-anywhere `src/nixos-anywhere.sh:709-816`](https://github.com/nix-community/nixos-anywhere/blob/4dfb813db065afb0aba1f61658ef77993d382db1/src/nixos-anywhere.sh#L709-L816); [nixos-images `build-images.sh:52-55`](https://github.com/nix-community/nixos-images/blob/803f28511c7d5f39f2537c342122fd94b8e1d519/build-images.sh#L52-L55); GitHub release metadata `isImmutable=false`.
- **C8 (high):** A direct NixOS installer causes the kexec phase to return immediately, so the mutable default artifact is not fetched in the repo's documented normal ISO workflow. Evidence: [nixos-anywhere `src/nixos-anywhere.sh:700-703`](https://github.com/nix-community/nixos-anywhere/blob/4dfb813db065afb0aba1f61658ef77993d382db1/src/nixos-anywhere.sh#L700-L703).
- **C9 (high):** Upstream explicitly does not support Wi-Fi networks for the remote install contract; current kexec persistence saves L3 networking and SSH material, not WPA credentials. Evidence: [requirements `:21-25`](https://github.com/nix-community/nixos-anywhere/blob/4dfb813db065afb0aba1f61658ef77993d382db1/docs/requirements.md#L21-L25); [kexec runtime `:35-78`](https://github.com/nix-community/nixos-images/blob/803f28511c7d5f39f2537c342122fd94b8e1d519/nix/kexec-installer/kexec-run.sh#L35-L78).
- **C10 (high):** `--phases install` does not mount or verify `/mnt`; it assumes kexec and mounting already happened. Evidence: [nixos-anywhere `src/nixos-anywhere.sh:983-987,1057-1063`](https://github.com/nix-community/nixos-anywhere/blob/4dfb813db065afb0aba1f61658ef77993d382db1/src/nixos-anywhere.sh#L983-L987) and `nixosInstall` above.
- **C11 (high):** The helper's local staging/shape/cleanup tests pass, but they mock `nix` and do not prove live remote behavior. Evidence: executed `bash tests/bootstrap-password-install-helper.sh`; mock implementation at `tests/bootstrap-password-install-helper.sh:18-108`.
- **C12 (medium-high):** Determinate's ISO is a useful direct-boot NetworkManager installer for x86_64/aarch64, not a verified replacement for nixos-anywhere's kexec artifact. Evidence: [README `:1-41`](https://github.com/DeterminateSystems/nixos-iso/blob/a70e0d77485720fd4623318998e3bb397e41dca2/README.md#L1-L41); [flake `:56-111`](https://github.com/DeterminateSystems/nixos-iso/blob/a70e0d77485720fd4623318998e3bb397e41dca2/flake.nix#L56-L111).
