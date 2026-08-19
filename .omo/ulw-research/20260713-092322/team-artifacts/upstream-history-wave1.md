# Upstream history: nixos-anywhere extra-files ownership and NixOS install activation

Accessed: **2026-07-13**. Scope: official upstream source, commits, PRs, issues,
tests, and manuals only. Baselines: `nixos-anywhere`
`4dfb813db065afb0aba1f61658ef77993d382db1`; target NixOS/nixpkgs
`d407951447dcd00442e97087bf374aad70c04cea`.

## Executive result

The historical ownership bug is real, but the pinned nixos-anywhere revision
contains both fixes: extraction uses GNU tar `--no-same-owner`, and every
requested `--chown` is applied recursively **after extraction and before
`nixos-install`**. The upstream VM test proves one short `--chown` mapping is
effective after reboot. Therefore the runtime fact that explicit
`--chown var/lib/nixos-bootstrap 0:0` did not change a validator failure is
strong counterevidence to a simple transfer-ownership failure.

The highest-probability alternative is name-based validation during early
activation: `%U:%G` is a name lookup, whereas `%u:%g` is numeric. Peer C's
exact chroot experiment separately demonstrated correct `0:0` rendering as
`UNKNOWN:UNKNOWN` while target NSS databases are unavailable. That matches an
important upstream precedent: nixpkgs' short-lived install-root check used
numeric `%u:%g` for the decision and `%U:%G` only in its diagnostic.

At exact nixpkgs `d407951`, ordinary activation failure has an indirect fatal
path. `nixos-enter` chroots into `/mnt`, runs `$system/activate`, and explicitly
ignores its status with `|| true`. However, successful activation normally
creates `/run/current-system` only at the end. A validator `exit 1` before that
line leaves the link absent; the embedded install command then executes
`/run/current-system/bin/switch-to-configuration boot` and hard-fails with
ENOENT. Thus the ignored activation status does not make the install robust to
early activation failure; the later command converts it into a fatal failure.

## Pinned mechanics and timeline

1. **2022: ownership and permissions deliberately separated.** PR #15 removed
   rsync archive preservation so remote extra files would default to root
   ownership. Commit `f44e1b2` then restored permission preservation with
   rsync `-p`, because modes were expected to survive.
   - <https://github.com/nix-community/nixos-anywhere/pull/15>
   - <https://github.com/nix-community/nixos-anywhere/commit/f44e1b20703f2c77e8e52d201ebfebe2fcb6ce9e>

2. **2024-05: tar migration caused a real ownership regression.** PR #325
   replaced rsync with tar. Issue #326 reports `/etc` and `/etc/ssh` becoming
   `1000:users`, breaking the installed system/sshd. PR #327 fixed it by adding
   `--no-same-owner`; affected users confirmed the fix.
   - <https://github.com/nix-community/nixos-anywhere/pull/325>
   - <https://github.com/nix-community/nixos-anywhere/issues/326>
   - <https://github.com/nix-community/nixos-anywhere/pull/327>
   - Fix commit: <https://github.com/nix-community/nixos-anywhere/commit/09f1f8306b560c7c407aa53f91247924a33edb60>

3. **2024-12: upload is known to run as target root.** Issue #431 showed a
   stale `sudo` decision from the pre-kexec environment could make extra-file
   upload fail after kexec. PR #434 removed sudo, stating there is no scenario
   where the target-side extraction is not root at that point. This is why
   `--no-same-owner` produces root-owned extracted entries.
   - <https://github.com/nix-community/nixos-anywhere/issues/431>
   - <https://github.com/nix-community/nixos-anywhere/pull/434>
   - <https://github.com/nix-community/nixos-anywhere/commit/685bbb233984a6ac9fba83353d0efc0f0212a4de>

4. **2025-02: explicit ownership post-pass.** PR #444 introduced `--chown`.
   Pinned source parses mappings into an associative array, extracts the tree,
   runs `chmod 755 /mnt`, then runs recursive chown commands, then invokes
   `nixos-install`.
   - PR: <https://github.com/nix-community/nixos-anywhere/pull/444>
   - Implementation: <https://github.com/nix-community/nixos-anywhere/commit/a54a9bdfaea199e2d539cf7b0fbbc8ffacc6a453>
   - Pinned order: <https://github.com/nix-community/nixos-anywhere/blob/4dfb813db065afb0aba1f61658ef77993d382db1/src/nixos-anywhere.sh#L876-L916>
   - Current docs say modes are copied, extracted ownership is root, and
     `--chown` changes it afterward: <https://github.com/nix-community/nixos-anywhere/blob/4dfb813db065afb0aba1f61658ef77993d382db1/docs/howtos/extra-files.md#L51-L84>

5. **The chown feature has an integration test.** Commit `a4ab782` performs an
   actual VM install with `--chown /home/user 1000:100`, boots the target, and
   asserts numeric ownership `1000:100` plus private-key mode `600`.
   - <https://github.com/nix-community/nixos-anywhere/commit/a4ab7821afd7a0024940be9d96d3cb394e2ba4fb>
   - Current test: <https://github.com/nix-community/nixos-anywhere/blob/4dfb813db065afb0aba1f61658ef77993d382db1/tests/from-nixos.nix#L30-L68>

6. **There is no merged source fix after the configured pin.** A full clone's
   `origin/main` and HEAD were both `4dfb813` on 2026-07-13. The only PRs
   created afterward (#669-#672) are open dependency bumps; no issue was filed
   after the pin, and no ownership/chown implementation PR exists after it.
   - Pin/HEAD commit: <https://github.com/nix-community/nixos-anywhere/commit/4dfb813db065afb0aba1f61658ef77993d382db1>
   - Open dependency bump: <https://github.com/nix-community/nixos-anywhere/pull/672>

## GNU tar and stat semantics

- GNU tar documents `--no-same-owner` as “do not attempt to preserve” archive
  ownership on extraction. For root this changes the default; extracted files
  remain owned by the extracting user (root here). Modes are a separate tar
  attribute and nixos-anywhere does not pass `--no-same-permissions`.
  <https://www.gnu.org/savannah-checkouts/gnu/tar/manual/html_node/Attributes.html>
- The GNU tar manual also explains that archive owner names and IDs are stored
  separately and name lookup normally occurs during ownership restoration;
  `--no-same-owner` prevents that restoration path.
  <https://www.gnu.org/software/tar/manual/tar.html>
- GNU coreutils documents `%u`/`%g` as numeric owner IDs and `%U`/`%G` as owner
  names. A validator that requires `root:root` from `%U:%G` is therefore an NSS
  assertion in addition to an inode-ownership assertion.
  <https://www.gnu.org/savannah-checkouts/gnu/coreutils/manual/html_node/stat-invocation.html>

## NixOS install and activation at exact `d407951`

- `nixos-install` sets the target system profile, creates `/mnt/etc/NIXOS`, and
  calls `nixos-enter --root "$mountPoint"` for bootloader/switch work.
  <https://github.com/NixOS/nixpkgs/blob/d407951447dcd00442e97087bf374aad70c04cea/pkgs/by-name/ni/nixos-install/nixos-install.sh#L294-L325>
- `nixos-enter` bind-mounts `/dev`, `/sys`, and `/proc`, then chroots into the
  target. Before executing the requested command it runs the target
  `$system/activate`, but uses `|| true`; finally it `exec chroot`s the command.
  <https://github.com/NixOS/nixpkgs/blob/d407951447dcd00442e97087bf374aad70c04cea/pkgs/by-name/ni/nixos-enter/nixos-enter.sh#L63-L113>
- The generated activation wrapper creates `/run/current-system` only after
  all activation fragments, then exits with their aggregate status. An early
  validator `exit 1` prevents this finalization.
  <https://github.com/NixOS/nixpkgs/blob/d407951447dcd00442e97087bf374aad70c04cea/nixos/modules/system/activation/activation-script.nix#L64-L81>
- Exact switch-to-configuration-ng runs pre-switch checks unless
  `NIXOS_NO_CHECK=1`, runs the bootloader for `boot`, then exits on `boot`
  before the later normal activation invocation.
  <https://github.com/NixOS/nixpkgs/blob/d407951447dcd00442e97087bf374aad70c04cea/pkgs/by-name/sw/switch-to-configuration-ng/src/main.rs#L1823-L1855>
- Upstream issue #480 independently confirms activation runs during
  nixos-anywhere installation; a user's activation test observed hostname
  `nixos-installer`. This proves installer namespaces/UTS context, not host
  filesystem rooting, because the source above proves `chroot /mnt`.
  <https://github.com/nix-community/nixos-anywhere/issues/480#issuecomment-2692427523>
- NixOS documentation says activation snippets run on every boot/system switch
  and must be idempotent. The manual explicitly permits fixing a failed install
  and rerunning `nixos-install` with `/mnt` mounted.
  <https://nixos.org/manual/nixos/unstable/index.html#sec-activation-script>
  <https://nixos.org/manual/nixos/stable/#sec-installation-manual-installing>

## NixOS ownership-check precedent

Nixpkgs commit `aa822ab` briefly made `nixos-install` reject a non-root-owned
install root. Crucially, its logic compared numeric `stat -c '%u:%g'` with
`0:0`; `%U:%G` appeared only in the message. The motivating real-world issue
reported unsafe systemd path transitions and a broken graphical session from
non-root `/` ownership.

- Issue: <https://github.com/NixOS/nixpkgs/issues/432261>
- Add check: <https://github.com/NixOS/nixpkgs/commit/aa822ab65720cdd8beb04a52bc60aae15d13d609>
- PR discussion: <https://github.com/NixOS/nixpkgs/pull/432399>

The check was reverted three days later by `005433b`: it blocked Hydra image
builds, and maintainers noted that non-root-owned directories can be valid
image/chroot targets. Thus non-root ownership is hazardous for a real root
filesystem but not a universally invalid `nixos-install` input.

- Revert: <https://github.com/NixOS/nixpkgs/commit/005433b926e16227259a1843015b5b2b7f7d1fc3>
- Rationale: <https://github.com/NixOS/nixpkgs/pull/432399#issuecomment-3180397075>
- Heuristic objection: <https://github.com/NixOS/nixpkgs/pull/432399#issuecomment-3185474300>

## Repeated installs and extra-files edge reports

- The official NixOS manual endorses rerunning `nixos-install` after correcting
  configuration/network failures; this is the supported retry boundary.
- Open nixos-anywhere issue #283 includes a user report that extracting an
  extra-files tree over an existing mounted/symlinked `/persist` produced
  `tar: Cannot open: File exists`; their workaround was separate `disko`,
  manual copy, then `install` phases. This is evidence for a special existing
  path/type collision, not evidence that tar cannot merge normal directories.
  <https://github.com/nix-community/nixos-anywhere/issues/283#issuecomment-2541763033>
- Re-running the whole default nixos-anywhere workflow is distinct from
  re-running only `nixos-install`: default phases include disko formatting.
  <https://github.com/nix-community/nixos-anywhere/blob/4dfb813db065afb0aba1f61658ef77993d382db1/docs/howtos/disko-modes.md>

## Counter-searches and negative findings

Sixteen distinct GitHub issue searches covered exact and variant terms:
`extra-files`, `chown`, `no-same-owner`, `ownership`, `nixos-install failed`,
`activation`, `preSwitchChecks`, `reinstall`, `failed to activate`, `stat uid
gid`, `already exists install`, `repeat installation`, and four nixpkgs
activation/switch variants. Separate exact searches covered `pr -2t`, `chown
path`, all chown PRs, and PRs/issues created after 2026-07-01.

- No upstream issue/PR reports the `pr -2t` serialization/truncation hazard
  independently found by peer A.
- No upstream ownership/chown fix exists after `4dfb813`.
- No upstream report matches this exact bootstrap hash validator symptom.
- The one short `var/lib/nixos-bootstrap` mapping is below the empirically
  observed `pr` truncation threshold and does not exercise many-mapping
  pairing, so that implementation bug is not a fit for the present fact.
- The upstream `--chown` integration test is strong counterevidence to a
  blanket “chown ordering is broken” hypothesis; it does not prove every path,
  shell/coreutils version, or repeated-install topology.
- Historical issue #326 is strong evidence that transfer ownership once broke
  installs, but its exact cause is absent at the pin because `--no-same-owner`
  is present and documented.

## Observation candidates

- **O-D1:** pinned source extracts extra files as root without restoring archive
  owners, then applies requested recursive chowns before nixos-install.
- **O-D2:** upstream VM test validates a single short chown mapping numerically
  after boot.
- **O-D3:** correct numeric ownership and name rendering are distinct facts;
  upstream install-check precedent uses numeric IDs for the decision.
- **O-D4:** exact d407 activation is chrooted to target but early activation
  failure status is swallowed by nixos-enter.
- **O-D5:** there are no merged nixos-anywhere implementation commits after the
  configured pin as of the access date.

## CLAIMS

- **SUPPORTED (high):** Explicit `--chown var/lib/nixos-bootstrap 0:0` not
  changing the validator result makes a simple inode-owner transfer bug
  unlikely. Primary support: pinned order, GNU tar semantics, integration test;
  counter-search found no post-pin ownership regression.
- **SUPPORTED (high):** A `%U:%G == root:root` validator can reject a correct
  numeric `0:0` inode when target NSS is not yet available. Primary support:
  coreutils format definitions and nixpkgs numeric-check precedent; peer C
  supplied executed exact-chroot confirmation.
- **SUPPORTED (high):** At nixpkgs d407, an early activation validator failure
  is indirectly fatal despite `nixos-enter`'s `|| true`: it prevents the final
  `/run/current-system` link, so the next required switch command fails ENOENT.
- **SUPPORTED (normal):** Retrying only nixos-install against an intact mounted
  target is officially supported; rerunning default nixos-anywhere may format
  disks again and is a different operation.
- **PARTIAL:** `pr -2t` is an unreported upstream implementation hazard for long
  paths/many mappings, but it does not fit this short single mapping.

## EXPAND

- **LEAD:** Capture the lines immediately after the validator message —
  **WHY:** confirm the predicted downstream `/run/current-system/bin/
  switch-to-configuration: No such file or directory` failure — **ANGLE:**
  rerun with `--debug`, preserve full ssh/nixos-install transcript.
- **LEAD:** Inspect the validator's exact `stat` format and activation dependency
  ordering relative to the `users` snippet — **WHY:** decides whether
  `UNKNOWN:UNKNOWN` is expected before target passwd/group creation — **ANGLE:**
  inspect generated `$system/activate` and `system.activationScripts` DAG.
- **LEAD:** Run target-side numeric `stat -c '%u:%g %a'` immediately before
  nixos-install — **WHY:** decisively separates transfer metadata from NSS
  display — **ANGLE:** phase split or instrumented pinned script.
- **DEAD END:** post-`4dfb813` ownership fix search — current main is the pin;
  only dependency bump PRs exist after it.
- **DEAD END:** exact upstream `pr -2t`/bootstrap-validator report — no issue or
  PR found after dedicated searches.
