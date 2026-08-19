# Causal-skeptic Wave 1: recurring bootstrap ownership validator failure

## Bottom line

The leading explanation is **not failed ownership transfer**. It is a validator/NSS ordering bug:

1. The helper passes numeric `--chown var/lib/nixos-bootstrap 0:0` (`bin/nixos-anywhere-bootstrap-password.sh:73-80`).
2. Pinned nixos-anywhere extracts extra files, then performs fatal recursive chown before `nixos-install` (`/nix/store/bgdvalr7cyy8sg8qv53hklzbcdfzp0h1-source/src/nixos-anywhere.sh:876-916`).
3. Pinned nixpkgs d407951 creates only target `/etc`, `/etc/NIXOS`, and `mtab`, then chroots and runs activation; it does not create passwd/group first (`/nix/store/ifpab9hxqmk2biwy594da8ipxzsp3y4s-source/pkgs/by-name/ni/nixos-install/nixos-install.sh:298-325`; `.../nixos-enter/nixos-enter.sh:94-108`).
4. The generated system orders `bootstrapPasswordHash` before `users` and `etc` (`/nix/store/8282w9asajxj0sa1bwzkz1fyplz4a7v9-nixos-system-nixos-26.11.20260705.d407951/activate:34,108,170`).
5. The validator compares **names**, `%U:%G:%a`, to `root:root:700` (`modules/nixos/bootstrap-password.nix:49`), although target NSS databases do not yet exist.

### Executed minimal faithful repro

Using bubblewrap as UID/GID 0, the exact generated activation script, the exact coreutils store binary, an empty target `/etc`, and a directory already set to numeric `0:0` mode `700`:

```text
rc=1
BEFORE numeric=0:0 named=UNKNOWN:UNKNOWN mode=700
bootstrap password hash validation failed: expected root:root mode 0700 on /var/lib/nixos-bootstrap
```

On the same fixture:

```text
named=UNKNOWN:UNKNOWN:700 predicate_rc=1
numeric=0:0:700 predicate_rc=0
```

This exactly reproduces the live error without any chown failure, wrong mode, wrong chroot, or later mutation. Numeric predicates `%u:%g:%a == 0:0:700` and `%u:%g:%a == 0:0:600` are the decisive correction.

## Ranked hypotheses and decisive disconfirmation

| Rank | Hypothesis | Status / evidence | Decisive experiment |
|---|---|---|---|
| 1 | `%U/%G` name resolution fails before target passwd/group exist | **Confirmed sufficient cause; very high likelihood actual cause.** Exact generated activation reproduces identical error with numeric metadata correct. Pinned install source proves no passwd/group are created before activation. | After a live failure, compare `stat -c '%u:%g:%U:%G:%a' /mnt/var/lib/nixos-bootstrap` and check `/mnt/etc/passwd`, `/mnt/etc/group`. Expected: `0:0:UNKNOWN:UNKNOWN:700`, databases absent/incomplete. Then use numeric validator in a fresh install. |
| 2 | User actually ran stale helper / omitted `--chown` | Low, still a runtime-provenance gap. Current and active temp helper SHA-256 both equal `b5a3c2de...`; previous leader verification showed the temp checkout had the new helper. The pasted retry log does not echo argv or helper hash. | Emit a non-secret run nonce, helper SHA, pinned revision, and parsed chown map before transfer; persist nonce in target diagnostics. |
| 3 | Pinned `--chown` mapping does not execute or is mispaired | **Refuted for this invocation shape.** Parser stores path/ownership at lines 341-345; one short mapping is formatted and run fatally at lines 883-886. Team transfer repro corrected dir+file recursively. Upstream has an end-to-end numeric chown test. `pr -2t` long-path/many-map truncation is real but irrelevant to one 23-character path. | Instrument/mock `runSsh` with the exact one-entry array (already reproduced); on live target insert pre-install numeric stat after the chown command. |
| 4 | Tar/repeated install leaves wrong mode or local UID ownership | Historical possibility but **refuted for current short-path pipeline**. Pinned tar uses `--no-same-owner`; exact team repro of repeated extraction restored mode 700, and explicit chown restored numeric 0:0. | Exact tar stream into a pre-existing target directory followed by the pinned chown (already passed); live pre-install numeric stat. |
| 5 | Validator sees installer ISO `/var/lib`, not target `/mnt/var/lib` | **Refuted.** `nixos-install` calls `nixos-enter --root /mnt`; `nixos-enter` executes `chroot /mnt $system/activate`. | Put distinguishable marker tuples in ISO and target paths, then run `nixos-enter --root`; source/call-chain already decisive. |
| 6 | A later nixos-install phase mutates metadata after chown | Low and unnecessary: identical error reproduced before any later mutation. Source between chown and activation contains no operation on this path. | Capture numeric stat immediately after chown and at validator entry; if unchanged, refuted live. |
| 7 | Actual mode differs (umask, ACL, tar semantics) | Possible only because current message suppresses actual tuple, but lower than NSS: local exact pipeline yields 700 and empty-NSS exact activation already reproduces failure with 700. ACLs do not change `%a` basic mode. | `stat -c '%u:%g:%a'`, `getfacl`, and `namei -om` on `/mnt/...` after failure. |
| 8 | `stat` itself fails (path traversal, missing binary/library, I/O error) | Low. Generated script executes store-pinned stat; directory existence/type checks passed first. Still observationally conflated by command substitution and the generic error. | Capture stat stderr and exit code separately before comparing its output. |
| 9 | Idmapped/user-namespace filesystem maps numeric zero unexpectedly | Very low on ordinary ext4 Disko root, but numeric actuals are absent from log. | Compare `stat %u:%g`, `findmnt -o TARGET,FSTYPE,OPTIONS`, and `/proc/self/uid_map` in installer and chroot. |
| 10 | The pasted output is from an earlier run rather than the new retry | Low but not disprovable from the excerpt: no command line, timestamp, nonce, or phase beginning is included. | Add run ID to helper output and transferred marker; log full phase start/end. |

## Strongest counter-hypotheses

- **Actual mode/UID is genuinely wrong on the target.** The live log cannot rule this out because it prints only the expected tuple. It loses to NSS ordering because the exact system reproduces the same message with numeric values correct, and both transfer source and executable repro show the new chown path works.
- **Chown silently failed.** It loses because upstream `runSsh` is under `set -e`; a failed chown would abort before `### Installing NixOS ###`, whereas the user reached that step.
- **Wrong chroot.** It loses to the pinned source call chain.
- **Destination substitution noise caused a partial closure/activation.** The retry no longer shows substitution errors; activation reaches the repo validator from the intended system closure. This is orthogonal.

## Observability defects

1. `fail "expected root:root mode 0700"` reports no actual named tuple, numeric tuple, stat exit status, or stderr. The phrase is an expectation, not evidence of actual ownership/mode.
2. The helper logs neither run identity nor parsed chown plan.
3. There is no snapshot at the key causal boundary: after transfer/chown and before `nixos-install`.
4. The user excerpt omits Disko and invocation provenance, so repeated-run and stale-log hypotheses cannot be closed from it alone.
5. Name-based validation makes metadata correctness depend on mutable NSS state; numeric ownership is the security property and should be observed directly.

## CLAIMS

- CLAIM: Numeric UID/GID 0 and mode 700 can fail the current validator on a fresh target because `%U:%G` resolves `UNKNOWN:UNKNOWN` before passwd/group exist. — RISK: high — PROOF: exact generated activation + exact coreutils execution; pinned nixpkgs source ordering — COUNTER: wrong metadata/chown tested independently — STATUS: confirmed sufficient cause, live confirmation pending.
- CLAIM: The repeated live message does not prove actual root ownership or mode 0700; it contains only a hard-coded expected-value string. — RISK: high — PROOF: `modules/nixos/bootstrap-password.nix:49-50` and raw user transcript line 1254 — STATUS: confirmed.
- CLAIM: Ordinary pinned extra-files transfer plus the explicit one-entry chown does not explain the recurrence. — RISK: normal — PROOF: pinned source, fatal ordering, exact transfer team repro, upstream e2e numeric chown test — STATUS: strongly disconfirmed.
- CLAIM: The switch-to-configuration ENOENT is downstream of the validator abort, not a separate cause. — RISK: normal — PROOF: generated activate exits at bootstrap before later activation creates current-system; pinned nixos-enter ignores activation failure and proceeds — STATUS: confirmed.

## EXPAND

- LEAD: Capture the live post-failure numeric/named tuple and target NSS files — WHY: closes the remaining gap between a proven sufficient cause and the actual target state — ANGLE: `/mnt` stat + `/mnt/etc/{passwd,group}` immediately after failure.
- LEAD: Fresh-install verification with numeric predicates — WHY: proves end-to-end disappearance of the cause and reaches users/consume steps — ANGLE: run the helper after changing both directory and file checks from `%U:%G` to `%u:%g`.
- DEAD END: Generic tar ownership leakage — pinned `--no-same-owner` plus explicit fatal chown and exact repro exhaust this for the short one-entry mapping.
- DEAD END: Installer-root vs target-root ambiguity — pinned `nixos-enter --root /mnt` and chroot execution resolve it.
