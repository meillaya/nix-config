# Wave 2 — strict SSH identity and verified kexec/install trust

Date: 2026-07-13  
Scope: W1C-L4/L5 only; exact `nixos-anywhere` revision `4dfb813db065afb0aba1f61658ef77993d382db1`, current upstream, OpenSSH host identity, kexec identity transitions, and a signed/content-addressed per-host install manifest. No production files were changed.

## Executive verdict

**The current install helper is not safe against an active network attacker, even when the caller supplies `--ssh-option StrictHostKeyChecking=yes` and a private known-hosts file.** The exact pinned/current `nixos-anywhere` initializes SSH arguments with `UserKnownHostsFile=/dev/null` and `StrictHostKeyChecking=no`, then appends caller options. OpenSSH uses the first value obtained for most directives, so the insecure values win. Upstream issue [#552](https://github.com/nix-community/nixos-anywhere/issues/552) remains open, and `origin/main` was the same commit as the repo pin at this review date. There is no merged/current fix.

**The default kexec path is also not artifact-bound.** At runtime the exact script selects a GitHub release URL, streams/downloads it, and extracts it without a checksum or signature. The `nixos-images` release workflow uses `gh release upload --clobber`; a release tag/filename is therefore not immutable provenance. Pinning the `nixos-anywhere` Git revision does not pin the bytes fetched from that release URL.

A defensible installation requires a small, reviewed patch/fork of the exact `nixos-anywhere` source plus a fail-closed wrapper. The wrapper must verify an offline-signed, content-addressed per-host manifest **before the first network connection**, build the kexec archive locally from an exact source revision and source NAR hash, compare its flat SHA-256 to the signed manifest, strictly authenticate every SSH phase, verify the target disk facts before Disko, split install and reboot, and verify the installed host key before reboot. `--copy-host-keys` can preserve one identity across all stages, but it must be checked because [#598](https://github.com/nix-community/nixos-anywhere/issues/598) is open; it also should not accidentally make an ephemeral ISO key permanent.

## What was verified directly

### 1. Exact/current `nixos-anywhere` defeats caller attempts to restore strict checking

The exact source initializes:

```bash
declare -a sshArgs=(
  "-o" "IdentitiesOnly=yes"
  "-i" "$tempDir/nixos-anywhere"
  "-o" "UserKnownHostsFile=/dev/null"
  "-o" "StrictHostKeyChecking=no"
)
```

and `--ssh-option` later performs `sshArgs+=("-o" "$2")`. See the pinned [initialization](https://github.com/nix-community/nixos-anywhere/blob/4dfb813db065afb0aba1f61658ef77993d382db1/src/nixos-anywhere.sh#L70) and [argument parser](https://github.com/nix-community/nixos-anywhere/blob/4dfb813db065afb0aba1f61658ef77993d382db1/src/nixos-anywhere.sh#L240-L243). The same array is used by direct `ssh`, `ssh-copy-id`, and `NIX_SSHOPTS` for Nix store transfers; the problem is not confined to one probe.

The OpenBSD/OpenSSH manual states that command-line options are read before user/system files and, unless noted otherwise, the **first specified value** for each directive is used ([`ssh_config(5)`, lines 11–20](https://man.openbsd.org/ssh_config)). Local execution confirmed:

| Command-line order | Effective `ssh -G` value |
|---|---|
| `StrictHostKeyChecking=no`, then `yes` | `false` |
| `StrictHostKeyChecking=yes`, then `no` | `true` |
| `UserKnownHostsFile=/dev/null`, then `/tmp/strict-kh` | `/dev/null` |
| `UserKnownHostsFile=/tmp/strict-kh`, then `/dev/null` | `/tmp/strict-kh` |

This exactly reproduces upstream open issue [#552](https://github.com/nix-community/nixos-anywhere/issues/552). As of this review:

- `git ls-remote ... refs/heads/main` returned `4dfb813db065afb0aba1f61658ef77993d382db1`, identical to the local helper pin.
- #552 was open, last updated 2025-06-12.
- searches of current PRs found no PR that fixes #552 for the CLI. Terraform SSH-option work does not repair the CLI's initial ordering.

The repo already states this risk at `docs/service-notes/nixos-anywhere-disko-install.md:27-30`, but `bin/nixos-anywhere-bootstrap-password.sh:98-109` still invokes the affected release. `--ssh-option IdentityAgent=none` fixes agent selection, not server authentication.

### 2. Retry loops are unbounded

The exact source repeats `ssh-copy-id` forever until it succeeds ([`uploadSshKey`](https://github.com/nix-community/nixos-anywhere/blob/4dfb813db065afb0aba1f61658ef77993d382db1/src/nixos-anywhere.sh#L534-L573)). After kexec, it waits indefinitely for the old endpoint to disappear and the installer endpoint to return ([`runKexec`](https://github.com/nix-community/nixos-anywhere/blob/4dfb813db065afb0aba1f61658ef77993d382db1/src/nixos-anywhere.sh#L818-L841)). Reboot waiting is also unbounded. This explains repeated connection/reset/authentication output and means a wrong or rotated host key can leave automation spinning rather than failing within a known time.

`ConnectTimeout=10` limits one connection attempt; it does not bound the surrounding `until`/`while` loop.

### 3. Default kexec bytes are mutable and unverified

The exact `runKexec` chooses:

```text
https://github.com/nix-community/nixos-images/releases/download/nixos-25.11/
  nixos-kexec-installer-noninteractive-${isArch}-linux.tar.gz
```

then uses target `wget`, target `curl`, or local `curl`, and extracts the stream/file without comparing a digest ([pinned source](https://github.com/nix-community/nixos-anywhere/blob/4dfb813db065afb0aba1f61658ef77993d382db1/src/nixos-anywhere.sh#L709-L816)). No `sha256`, signature, or attestation check occurs.

The exact `nixos-images` source documents mutable “latest”/release downloads and its release builder uses `gh release upload --clobber` ([build script at the exact images revision](https://github.com/nix-community/nixos-images/blob/45c188c452d274e003c9acc6b43fab911fa6cfa5/build-images.sh#L20-L55)). Therefore HTTPS plus a tag/filename authenticates GitHub transport at that instant, not immutable artifact identity approved in advance.

### 4. An exact local kexec build is supported

The pinned custom-kexec documentation explicitly supports `--kexec <local path>` and shows building the archive through the `nixos-images` flake ([exact how-to](https://github.com/nix-community/nixos-anywhere/blob/4dfb813db065afb0aba1f61658ef77993d382db1/docs/howtos/custom-kexec.md)). A local file is uploaded rather than downloaded by the target.

The exact `nixos-anywhere` lock pins `nixos-images` to:

- revision: `45c188c452d274e003c9acc6b43fab911fa6cfa5`
- source NAR hash: `sha256-UFSWbDEltShkthOfvlAyxDq4L7dLHcsuJzHbgu79lHM=`

Independent `nix flake prefetch` reproduced that source hash. It also produced the exact `nixos-anywhere` source NAR hash:

- revision: `4dfb813db065afb0aba1f61658ef77993d382db1`
- source NAR hash: `sha256-UwamW3kYf/7vSsYq2VRb3VBq8A1hvOiLzXVnJeKVS38=`

Both URLs with explicit `?narHash=` were accepted by `nix flake metadata` and resolved to the expected revisions. The `nixos-images` module constructs the archive deterministically as a Nix derivation from kernel, initrd, `kexec`, `ip`, and the run script ([exact module](https://github.com/nix-community/nixos-images/blob/45c188c452d274e003c9acc6b43fab911fa6cfa5/nix/kexec-installer/module.nix#L51-L63)).

The safe build pattern is:

```bash
images_ref='github:nix-community/nixos-images/45c188c452d274e003c9acc6b43fab911fa6cfa5?narHash=sha256-UFSWbDEltShkthOfvlAyxDq4L7dLHcsuJzHbgu79lHM%3D'
out=$(nix build --no-link --print-out-paths \
  "$images_ref#packages.x86_64-linux.kexec-installer-nixos-stable-noninteractive")
archive="$out/nixos-kexec-installer-noninteractive-x86_64-linux.tar.gz"

nix store verify "$out"
archive_sha256=$(sha256sum "$archive" | awk '{print $1}')
archive_sri=$(nix hash file --type sha256 "$archive")
archive_nar=$(nix path-info --json "$out")
```

The exact build completed successfully in this lane and `nix store verify` returned success. Realized evidence:

- store path: `/nix/store/20z841wgl8qyp8lfr6sr5hk53a2szzdw-kexec-tarball`
- derivation: `/nix/store/6k6a5ni5gs9cm86sbnfc6af58qwgr1im-kexec-tarball.drv`
- archive size: `474121676` bytes
- archive flat SHA-256 hex: `0a40a2f342b732350fddbaec7d50f06d98e3e954b5936f22f475e5d06a82307c`
- archive SRI: `sha256-CkCi80K3MjUP3brsfVDwbZjj6VS1k28i9HXl0GqCMHw=`
- output NAR hash: `sha256-OUSpyPmk2J+ipZVJqbTFqUlcp9o0/k80PNWIdk7SrUU=`
- output NAR size: `474122008` bytes
- top-level archive members: `kexec/{initrd,bzImage,run,kexec,ip}`
- trust status: locally built/`ultimate: true`, no independent store signature; the signed manifest therefore remains the per-host approval binding.

These exact bytes are a reproducibility fixture for this source revision and evaluator state, not a universal forever-current image. A later deliberate update must rebuild, re-test, and sign a new digest.

The Nix store path alone should not be treated as a portable flat-file checksum. Record both Nix path/NAR metadata and the archive's bytewise SHA-256; the signed manifest binds the latter to exactly what `--kexec` receives. Nix's official manual explains that `nix store verify` checks recorded contents and trust ([manual](https://nix.dev/manual/nix/2.18/command-ref/new-cli/nix3-store-verify)); Nix's hash documentation distinguishes flat file hashes from recursive/NAR hashes ([manual](https://releases.nixos.org/nix/nix-2.24.0/manual/command-ref/nix-hash.html)).

### 5. Host keys normally flow pre-kexec → installer → installed system, but the last step needs proof

The exact kexec run script copies existing `/etc/ssh/ssh_host_*` into the appended initrd before calling kexec ([exact `kexec-run.sh`](https://github.com/nix-community/nixos-images/blob/45c188c452d274e003c9acc6b43fab911fa6cfa5/nix/kexec-installer/kexec-run.sh#L65-L78)). Its VM test asserts that the ED25519 public host key before kexec equals the key after kexec ([exact test](https://github.com/nix-community/nixos-images/blob/45c188c452d274e003c9acc6b43fab911fa6cfa5/nix/kexec-installer/test.nix#L129-L174)). This is good evidence that a supported custom kexec image intentionally preserves the identity.

`nixos-anywhere --copy-host-keys` copies the installer `/etc/ssh/ssh_host_*` into `/mnt/etc/ssh`, skipping a destination file that already exists ([exact install code](https://github.com/nix-community/nixos-anywhere/blob/4dfb813db065afb0aba1f61658ef77993d382db1/src/nixos-anywhere.sh#L893-L911)). Its NixOS integration test asserts identity continuity after install. However:

- upstream issue [#598](https://github.com/nix-community/nixos-anywhere/issues/598), “option --copy-host-keys not working,” remains open and contains reports of identity mismatch during secret activation;
- [#604](https://github.com/nix-community/nixos-anywhere/issues/604) documents the mismatch with impermanence/persistent key locations;
- if the starting environment is a live installer with an ephemeral key, `--copy-host-keys` can preserve the wrong long-term identity by design.

Therefore `--copy-host-keys` is a convenience, not the acceptance test. Stop before reboot and compare `/mnt/etc/ssh/*.pub` against the signed final-stage keys. For impermanence, verify the actual persistent destination. If a new durable host identity is desired, generate it out of band, keep the private key encrypted and staged only in private tmpfs, include only the public key in the manifest, transfer the key tree with `--extra-files`, and verify it before reboot. Never put a private host key in the manifest or Nix store.

## Required trust contract

### Trust root

Use a dedicated offline/working-machine ED25519 signing key. Commit or otherwise distribute only an `allowed_signers` file; protect the signer private key outside Git. OpenSSH's built-in signing interface avoids another dependency:

```bash
ssh-keygen -Y sign -f "$SIGNING_KEY" -n nixos-install-manifest manifest.json
ssh-keygen -Y verify \
  -f allowed_signers \
  -I trusted-installer \
  -n nixos-install-manifest \
  -s manifest.json.sig < manifest.json
```

The namespace is mandatory domain separation. Sign the exact canonical bytes and never rewrite/reformat after signing. Name the immutable manifest by its flat digest, e.g. `manifests/<sha256>.json`; a human-friendly host pointer may refer to that digest. The signature authenticates approval; the content-addressed name detects accidental substitution and prevents a mutable filename from silently changing meaning.

A Git commit SHA is an identifier, not by itself the local trust root. Both reviewed upstream commits carried GitHub merge signatures, but the local clone could not validate them because the GitHub public key was not present. The explicitly pinned source NAR hashes plus the locally trusted manifest remove dependence on a mutable branch/tag and record the exact approved source tree.

### Minimal manifest schema

The manifest should contain no password, private key, token, or Wi-Fi secret. At minimum:

```json
{
  "schema": 1,
  "installId": "random-nonce",
  "host": "laptop-name",
  "issuedAt": "RFC3339",
  "expiresAt": "RFC3339-short-window",
  "target": {
    "address": "10.0.0.248",
    "port": 22,
    "arch": "x86_64-linux",
    "bootMode": "uefi"
  },
  "disk": {
    "byId": "/dev/disk/by-id/<stable-id>",
    "model": "expected model",
    "serial": "expected serial",
    "wwn": "expected WWN-or-null",
    "sizeBytes": 256000000000,
    "logicalSectorBytes": 512,
    "physicalSectorBytes": 4096
  },
  "ssh": {
    "preKexec": ["ssh-ed25519 AAAA..."],
    "installer": ["ssh-ed25519 AAAA..."],
    "final": ["ssh-ed25519 AAAA..."]
  },
  "kexec": {
    "nixosAnywhereRev": "4dfb813db065afb0aba1f61658ef77993d382db1",
    "nixosAnywhereSourceNarHash": "sha256-UwamW3kYf/7vSsYq2VRb3VBq8A1hvOiLzXVnJeKVS38=",
    "nixosImagesRev": "45c188c452d274e003c9acc6b43fab911fa6cfa5",
    "nixosImagesSourceNarHash": "sha256-UFSWbDEltShkthOfvlAyxDq4L7dLHcsuJzHbgu79lHM=",
    "package": "kexec-installer-nixos-stable-noninteractive",
    "archiveSha256": "64 lowercase hex characters",
    "archiveSRI": "sha256-...",
    "storePath": "/nix/store/...-kexec-tarball",
    "narHash": "sha256-..."
  },
  "flake": {
    "revision": "exact local config revision",
    "lockDigest": "sha256 of flake.lock"
  }
}
```

`address` is routing, not identity. The trusted public host key is identity. `ssh-keyscan` may collect a candidate but **must not establish trust**; compare the SHA-256 fingerprint out of band at the target console/BMC/provider console before signing the manifest. A disk `/dev/sdX` name is not sufficient; the wrapper must resolve the signed by-id path and compare multiple independent properties immediately before Disko. Missing serial/WWN is not a wildcard: require a documented alternate fingerprint and a fresh approval.

### Strict per-stage known-host files

Generate stage-specific private files from signed public keys, using unique `HostKeyAlias` values such as:

```text
install/<installId>/pre
install/<installId>/installer
install/<installId>/final
```

Then every SSH-family command must receive, **before any weaker/default value**:

```text
-o UserKnownHostsFile=<private-stage-file>
-o GlobalKnownHostsFile=/dev/null
-o StrictHostKeyChecking=yes
-o HostKeyAlias=<stage-alias>
-o UpdateHostKeys=no
-o IdentityAgent=none
-o IdentitiesOnly=yes
-o ConnectionAttempts=1
-o ConnectTimeout=10
```

`UpdateHostKeys=no` prevents the live server from expanding the signed key set. `GlobalKnownHostsFile=/dev/null` ensures an unrelated global entry cannot satisfy the stage. The known-hosts directory and files must be mode 0700/0600 on tmpfs. Do not use `accept-new`, a shared mutable `~/.ssh/known_hosts`, or delete a changed key to make an error disappear.

If the exact images archive and `--copy-host-keys` are used, the expected pre/installer/final ED25519 keys may be identical. Still use distinct aliases so a later workflow can express an intentional transition, and remove the pre/installer files after success. If final keys are intentionally new, the manifest must explicitly bind both identities; never put both in one alias/file because that would continue accepting the obsolete key after transition.

## Minimal patch and wrapper design

The existing CLI cannot be repaired solely with arguments because of first-value wins. Patch the exact source rather than wrapping `ssh` on `PATH`.

### Patch requirements

1. **Require strict configuration inputs.** Fail if `NIXOS_ANYWHERE_KNOWN_HOSTS` or `NIXOS_ANYWHERE_HOST_KEY_ALIAS` is absent in the repo's hardened entry point.
2. **Place secure SSH directives first.** Remove built-in `/dev/null`/`no`; initialize `sshArgs` with the strict stage values above. User-provided `--ssh-option` comes later and cannot weaken them.
3. **Use the same array everywhere.** Preserve it for direct `ssh`, `ssh-copy-id`, and `NIX_SSHOPTS`; add tests for all three paths.
4. **Bound every transition loop.** Replace infinite `until`/`while` loops for key upload, post-kexec unreachable/reachable, and post-reboot unreachable with an attempt/deadline helper. Suggested defaults: 3 key-upload attempts, 90 seconds to disappear, 300 seconds to return after kexec, 180 seconds to disappear after reboot. Exit nonzero with stage/attempt/last SSH status. An external `timeout --foreground` should remain a final circuit breaker, not the only state machine.
5. **Reject remote/default kexec URLs in hardened mode.** Require a readable local regular file, non-symlink, owned by the invoking user/root, and compare its flat SHA-256 to the verified manifest before `nixos-anywhere` sees it. Pass that exact path with `--kexec`.
6. **Optionally verify after upload.** SSH transport already MAC-protects bytes after strict server authentication, but a patched `--kexec-sha256` that verifies the remote staging file before extraction gives an explicit storage/transfer invariant. Require a known SHA-256 tool at preflight and fail if unavailable; do not fall back to unchecked extraction.
7. **Split phases.** The wrapper, not `nixos-anywhere`, controls transitions and switches stage aliases/known-host files.

A `nix run github:...` of unpatched upstream must not remain as a fallback. Package the patch from the exact source revision+NAR hash, make the patch itself reviewable in this repo, and export a test that scans the realized script to prove the insecure defaults are absent and strict options precede caller options.

### Fail-closed phase order

1. Verify manifest filename digest, signature/identity/namespace, schema, expiry, one-time `installId`, and exact config revision/lock digest. Mark the nonce “in progress” in durable local state; refuse reuse unless an explicit signed recovery manifest authorizes it.
2. Build the exact local kexec archive. Run `nix store verify`; compare flat SHA-256/SRI/store metadata to the manifest. Refuse URLs.
3. Materialize the **pre** known-hosts file. Strictly connect using the pre alias and a dedicated install identity. If password bootstrap is unavoidable, perform one explicit strict `ssh-copy-id` pre-step with `NumberOfPasswordPrompts=1`, agent disabled, and an attached TTY; then require key-only/`BatchMode=yes` for the destructive workflow.
4. Over that authenticated session, collect `uname -m`, UEFI presence, and disk facts (`readlink -f`, `lsblk -b -dn -o NAME,PATH,MODEL,SERIAL,WWN,SIZE,LOG-SEC,PHY-SEC,TYPE`). Require exact manifest match and ensure the selected disk is not the install media/current working root unless explicitly represented and approved.
5. Run only `--phases kexec --kexec "$archive"` through the patched binary, with bounded waits. No Disko yet.
6. Materialize the **installer** known-hosts file and strictly verify the installer alias, expected host key, architecture, `VARIANT_ID=installer`, and disk fingerprint again. If identity continuity was expected and the key changed, abort; do not “refresh” it.
7. Run `--phases disko,install --copy-host-keys` (or the pre-generated final-key `--extra-files` path) with **no reboot**, still using the installer alias. The manifest/disk check must be the last gate immediately before Disko.
8. Verify mounted target keys in their actual persistent location, permissions, public-key fingerprints, installed toplevel/config revision, boot entry, and disk mount layout. If any final key is absent/wrong, abort while the installer remains reachable.
9. Trigger reboot explicitly with one strict installer-stage SSH command. Bound disappearance. Switch to the **final** alias/file; bound reachability. Verify `/etc/os-release`, hostname, expected final host key, and installed revision. Never accept the installer alias after this point.
10. Record success with manifest digest, realized store path, archive SHA-256, observed disk fingerprint, all public host-key fingerprints, and timestamps. Destroy tmpfs known-host files and decrypted/staged private material.

## Executable adversarial verification matrix

### Unit harness executed in this research lane

A temporary harness generated an ED25519 signing key, two host keys, a canonical manifest, and a fake archive. It exercised real `ssh-keygen -Y` and `sha256sum` commands. Results:

```text
PASS valid_signature
PASS tampered_signature_rejected
PASS correct_artifact_digest
PASS wrong_artifact_digest_rejected
PASS expected_key_enrolled
PASS wrong_host_key_rejected_by_fingerprint_gate
RESULT pass=6 fail=0
```

OpenSSH first-value behavior was also executed independently as documented above.

### Required wrapper tests

All cases are fail-before-Disko unless stated otherwise. Implement as shell/NixOS VM tests around the hardened wrapper; use ephemeral `sshd` instances with generated host keys and a fake phase driver for fast unit coverage, plus one full `nixos-anywhere --vm-test`/QEMU path.

| ID | Mutation / setup | Required assertion |
|---|---|---|
| M01 | Valid manifest, trusted signer, matching digest | preflight passes |
| M02 | Change one manifest byte after signing | signature verification nonzero; zero network calls |
| M03 | Sign with an unknown key or wrong `-I` | nonzero; zero network calls |
| M04 | Sign under a namespace other than `nixos-install-manifest` | nonzero; zero network calls |
| M05 | Expired manifest or reused `installId` | nonzero; zero network calls |
| K01 | Correct local archive and signed SHA-256 | kexec preflight passes |
| K02 | Append one byte to archive | digest mismatch; zero SSH calls |
| K03 | Replace archive with same filename from release URL | digest mismatch; zero SSH calls |
| K04 | Supply URL, FIFO, directory, or symlink as archive | rejected before SSH |
| S01 | Correct pre host key | strict probe succeeds |
| S02 | Missing pre key file/alias | client configuration failure; no TOFU prompt |
| S03 | Wrong pre host key | `REMOTE HOST IDENTIFICATION HAS CHANGED`; no retries beyond configured bound |
| S04 | Add `--ssh-option StrictHostKeyChecking=no` after strict defaults | `ssh -G` still reports `yes` |
| S05 | Add `--ssh-option UserKnownHostsFile=/dev/null` after strict defaults | `ssh -G` still reports signed stage file |
| S06 | Agent contains many unrelated keys | only dedicated identity offered; no “too many authentication failures” |
| T01 | kexec preserves expected host key | installer alias succeeds after expected transition |
| T02 | kexec endpoint returns with a different key | installer strict probe fails; Disko command count is zero |
| T03 | target never disappears | deadline exceeded with stage diagnostic; process tree terminated |
| T04 | target disappears but never returns | deadline exceeded; Disko command count is zero |
| D01 | arch differs from manifest | abort before Disko |
| D02 | boot mode differs from manifest | abort before Disko |
| D03 | by-id resolves to a different device or disappears | abort before Disko |
| D04 | serial/WWN/size/sector mismatch | abort before Disko |
| F01 | `/mnt` final host public key matches manifest | reboot gate passes |
| F02 | `--copy-host-keys` silently leaves/generates a different key | abort before reboot |
| F03 | final endpoint presents installer key when a planned rotation was signed | final alias rejects it |
| F04 | final endpoint presents correct signed final key | post-boot acceptance passes |

The key regression checks are directly executable without a server:

```bash
ssh -G \
  -o "UserKnownHostsFile=$stage_file" \
  -o GlobalKnownHostsFile=/dev/null \
  -o StrictHostKeyChecking=yes \
  -o "HostKeyAlias=$stage_alias" \
  -o UserKnownHostsFile=/dev/null \
  -o StrictHostKeyChecking=no \
  target.invalid |
  awk '/^(userknownhostsfile|stricthostkeychecking|hostkeyalias) /'
```

Expected: the first stage file, `true`/`yes`, and the stage alias. Reverse the secure/insecure order in a negative control and assert it fails, which locks the OpenSSH first-value reason for the patch.

For the full VM test, expose three public keys to the test driver: pre, expected installer, expected final. Make the fake/VM kexec stage optionally rotate its key and make the target install stage optionally omit/replace `/mnt/etc/ssh/ssh_host_ed25519_key`. Record an invocation log and assert that the first destructive Disko call occurs only after manifest, artifact, SSH, architecture, boot-mode, and disk gates have all emitted success.

## Prioritized recommendations

### P0 — before any further destructive install

1. Stop using unpatched `nixos-anywhere` on any network where an active attacker is in scope. “Trusted LAN” is a temporary operational restriction, not a fix.
2. Add the strict source patch and signed-manifest wrapper; export its tests through flake checks.
3. Require a local exact-revision kexec file and signed flat digest; prohibit the runtime release URL.
4. Split install from reboot and verify final host keys under `/mnt` before reboot.
5. Bound all SSH/key-upload/kexec/reboot loops and use a single dedicated install identity with agent disabled.

### P1 — trust lifecycle hardening

1. Define offline signer rotation/revocation and an append-only install receipt format.
2. Prefer per-host pre-generated durable host keys where lifecycle requirements allow; otherwise prove `--copy-host-keys` and account for impermanence paths.
3. Add a recovery-manifest type that authorizes a narrowly scoped install-only/mount-only action without reauthorizing Disko.
4. Make the disk fingerprint manifest machine-generated but human-approved at console before signing; never approve `/dev/sdX` alone.

## Limits and open evidence

- This lane did not run destructive installation on physical hardware.
- It executed source inspection, OpenSSH option resolution, Nix source-prefetch pin verification, manifest/digest signature tests, and the full exact local x86_64 stable noninteractive kexec derivation. The realized output and archive digests are recorded above.
- The upstream #598 reports are credible but not a deterministic proof that every exact-revision install loses keys; this report therefore requires an observed `/mnt` key acceptance test rather than claiming unconditional failure.
- A signed manifest is only as strong as its offline signer custody and the out-of-band procedures used to approve initial host/disk fingerprints.

## Primary evidence index

- Exact current `nixos-anywhere` source: https://github.com/nix-community/nixos-anywhere/blob/4dfb813db065afb0aba1f61658ef77993d382db1/src/nixos-anywhere.sh
- Open issue #552 (cannot override known-hosts/strict checking): https://github.com/nix-community/nixos-anywhere/issues/552
- Exact custom-kexec documentation: https://github.com/nix-community/nixos-anywhere/blob/4dfb813db065afb0aba1f61658ef77993d382db1/docs/howtos/custom-kexec.md
- Exact host-key copy documentation/code: https://github.com/nix-community/nixos-anywhere/blob/4dfb813db065afb0aba1f61658ef77993d382db1/docs/howtos/secrets.md
- Open issue #598 (`--copy-host-keys`): https://github.com/nix-community/nixos-anywhere/issues/598
- Open issue #604 (persistent/custom host-key destination): https://github.com/nix-community/nixos-anywhere/issues/604
- Exact `nixos-images` kexec implementation: https://github.com/nix-community/nixos-images/tree/45c188c452d274e003c9acc6b43fab911fa6cfa5/nix/kexec-installer
- Exact release build script: https://github.com/nix-community/nixos-images/blob/45c188c452d274e003c9acc6b43fab911fa6cfa5/build-images.sh
- OpenSSH first-value rules: https://man.openbsd.org/ssh_config
- Nix store verification: https://nix.dev/manual/nix/2.18/command-ref/new-cli/nix3-store-verify
- Nix flat/NAR hashing: https://releases.nixos.org/nix/nix-2.24.0/manual/command-ref/nix-hash.html

## EXPAND

- **W2-SSH-L1:** Implement and VM-test a stage-aware, strict-first patch against exact `nixos-anywhere` source; upstream issue #552 has no current fix.
- **W2-SSH-L2:** Empirically reproduce #598 under exact revision with (a) ordinary root, (b) NixOS ISO/no-kexec, (c) impermanence, and (d) pre-existing destination keys; use `/mnt` public-key acceptance as oracle.
- **W2-SSH-L3:** Design signer custody, nonce/replay database, manifest expiry, recovery-manifest authorization, and key rotation as an operational protocol.
- **W2-SSH-L4:** Promote the recorded exact local kexec flat SHA-256, SRI, NAR hash, store path, and size into a signed example manifest fixture, then reproduce it in isolated CI and explain any byte-level divergence.

## CLAIMS

- **C-W2-SSH-01 (confirmed, critical):** Exact/current `nixos-anywhere` forces `UserKnownHostsFile=/dev/null` and `StrictHostKeyChecking=no` before caller options; OpenSSH first-value semantics make `--ssh-option` unable to restore strict verification.
- **C-W2-SSH-02 (confirmed, high):** Key-upload, post-kexec, and reboot transition loops are not globally bounded by attempt count/deadline.
- **C-W2-SSH-03 (confirmed, critical):** Default runtime kexec download is not checked against a checksum/signature, and its release asset can be clobbered.
- **C-W2-SSH-04 (confirmed, high):** Exact `nixos-images` intentionally copies pre-kexec host keys into the installer initrd and tests identity continuity.
- **C-W2-SSH-05 (confirmed with upstream counterevidence, high):** `--copy-host-keys` is designed/tested to carry installer keys into the installed system, but open #598/#604 mean a fail-closed wrapper must verify the actual persistent `/mnt` public key before reboot.
- **C-W2-SSH-06 (confirmed, high):** Exact local kexec construction can be bound to source revision+source NAR hash and a signed flat archive digest, avoiding mutable runtime release downloads.
- **C-W2-SSH-07 (validated design, high confidence):** OpenSSH `ssh-keygen -Y` signatures plus a content-addressed manifest and stage-specific strict known-host files reject manifest tampering, wrong artifacts, and wrong host identities before destructive work.
