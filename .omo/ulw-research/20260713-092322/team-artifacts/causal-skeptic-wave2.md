# Causal-skeptic Wave 2: adversarial review of numeric ownership fix

## Verdict

**PASS with verification hardening requested.** I could not falsify the change from `%U:%G` / `root:root` to `%u:%g` / `0:0`. Numeric comparison is the actual Linux privilege invariant, removes install-time NSS dependence, and is strictly stronger than name comparison. The code consistently changes pre-users ownership operations to numeric IDs and improves validator diagnostics by printing the actual numeric tuple.

## Executed adversarial evidence

### Name predicate can accept a non-root inode

Using `nss_wrapper`, exact target coreutils 9.11, a mode-700 inode owned by numeric `1000:1000`, and an NSS database mapping the names `root:root` to those IDs:

```text
exact_coreutils named=root:root:700 old_rc=0 numeric=1000:1000:700 new_rc=1
```

The old name predicate accepted the nonzero owner. The numeric predicate rejected it. Thus the change closes an NSS spoof/alias acceptance class rather than weakening security.

### Exact new generated activation passes the original failure boundary

Built current dirty tree:

```text
/nix/store/2fammh39xrhqy56jarvkvmhgfwf7idyp-nixos-system-nixos-26.11.20260705.d407951
```

In an empty-NSS bwrap target with correct numeric metadata:

```text
BEFORE numeric=0:0 named=UNKNOWN:UNKNOWN mode=700
```

The exact new `activate` produced zero `bootstrapPasswordHash` failures and proceeded to the `users` fragment. Later user-namespace mount/user failures were fixture limitations outside the validator.

### Wrong numeric owner is rejected with actionable output

An `unshare --map-auto` fixture created correct modes but owner/group `1234:2345`. The emitted validator returned:

```text
rc=1 output=bootstrap password hash validation failed: expected numeric owner 0:0 mode 0700 on /var/lib/nixos-bootstrap; got 1234:2345:700
```

### Direct regression suite

`bash tests/bootstrap-password-lifecycle.sh` passed, including the empty target NSS case, strict mode cases, symlink cases, sentinel lifecycle, and consumer preservation.

## Security review

- UID 0 is the kernel privilege identity; the string `root` is merely NSS presentation. Numeric validation is the correct security boundary.
- GID 0 is likewise the exact ownership group intended by the transferred `0:0` and standard NixOS root group.
- Numeric `chown 0:0` and `install -o 0 -g 0` avoid lookup failures and malicious/incorrect NSS aliases.
- Exact modes still reject group/other access and special-bit variants (`700`/`600` comparisons are exact).
- Symlink checks, regular-file checks, yescrypt grammar, newline constraints, and sentinel/shadow confirmation remain unchanged.
- Namespace/idmapped installs interpret UID 0 relative to the activation namespace. That is appropriate for containerized NixOS; the real nixos-anywhere ext4 target is not idmapped. This is not a new practical weakness.
- TOCTOU, hardlink, ACL/xattr, and privileged-root attacker concerns predate the change and are not widened by numeric metadata checks.

## Observability review

Improvements:

- Validator now distinguishes stat failure (`could not inspect`) from tuple mismatch.
- Tuple mismatch includes actual numeric UID, GID, and mode without exposing verifier contents.
- Error text no longer claims a named `root:root` fact that was never observed.

Remaining gaps:

1. Consumer-side `hash_dir_meta=$(stat ...)` lacks an explicit stat-failure branch; a stat error becomes a generic mismatch with an empty value. Mirror the validator's `|| ... could not inspect` handling.
2. Helper still emits no run nonce, helper SHA, pin, or post-chown boundary snapshot. The fixed validator makes those unnecessary for this incident, but future transfer failures remain difficult to attribute.
3. Full live target confirmation is still absent; exact generated activation is strong local proof, not physical-host proof.

## Test-review findings

1. **Mutation suite source-of-truth hazard:** `tests/bootstrap-password-mutations.sh` uses `tree=$(git write-tree)`, which archives the index. Current changes are unstaged, so running it now tests the old indexed tree, not this numeric/NSS fix.
2. No lifecycle case currently uses correct modes with a deliberately nonzero UID/GID, despite numeric ownership being the new primary invariant. `unshare --map-auto --setuid 0 --setgid 0` can produce portable `1234:2345` fixtures in this environment.
3. `valid-empty-target-nss` covers an existing verifier only. It does not cover the empty-NSS missing-verifier migration path that executes numeric `install` and `chown`. Add a separate missing-existing-unlocked fixture with empty NSS and assert created `0:0:700`/`0:0:600` metadata.
4. A mutation that changes `%u:%g` back to `%U:%G` should be killed explicitly by the empty-NSS case.

## CLAIMS

- CLAIM: Numeric ownership validation is stronger than name validation because name mapping can make a nonzero UID/GID render as `root:root` — RISK: high — PROOF: executed exact-coreutils NSS-spoof fixture — STATUS: confirmed.
- CLAIM: Current numeric validator accepts correct `0:0` metadata without target NSS and rejects nonzero numeric ownership with an actual-tuple diagnostic — RISK: high — PROOF: exact generated activation plus `unshare --map-auto` adversarial fixture — STATUS: confirmed.
- CLAIM: Numeric pre-users `install`/`chown` introduces no identified security regression relative to named operations — RISK: high — COUNTERSEARCH: namespaces, aliases, idmapped mounts, modes, ACLs, symlink/TOCTOU, nonstandard root group — STATUS: supported; physical target verification outstanding.
- CLAIM: The current mutation suite can give false confidence when changes are unstaged because it snapshots the index — RISK: normal — PROOF: shell source and current git state — STATUS: confirmed.

## EXPAND

- LEAD: Add wrong-UID and wrong-GID lifecycle fixtures with correct modes — WHY: locks the new core security invariant — ANGLE: `unshare --map-auto`, numeric `chown`, exact diagnostic assertions.
- LEAD: Add empty-NSS missing-verifier migration fixture — WHY: covers numeric pre-users creation/chown, not only numeric stat — ANGLE: separate fixture with unlocked shadow and absent hash directory.
- LEAD: Make mutation materialization include the intended worktree/staged change and add a `%u`→`%U` mutant — WHY: prevents green mutation results against stale code — ANGLE: explicit temporary index or staged-tree precondition.
- LEAD: Mirror explicit stat-failure handling in consumer — WHY: preserves the newly improved causal observability after users activation — ANGLE: distinguish inspection failure from tuple mismatch.
- DEAD END: Numeric comparison weakens root ownership security — executed NSS-spoof counterexample shows the opposite.
