# Wave 2: pre-users ownership-operation audit

## Execution boundary

The evaluated order is `bootstrapPasswordHash -> users -> consumeBootstrapPassword -> etc`. Therefore every operation in `bootstrapPasswordHash.text` executes before the target account database is created. Function bodies declared there are also pre-users when invoked. `consumeBootstrapPassword` is post-users by dependency.

## Mandatory numeric conversions

All four pre-users name-dependent command sites must become numeric:

| Repo line | Current operation | Reachability | Required form / reason |
|---|---|---|---|
| `modules/nixos/bootstrap-password.nix:36` | `chown root:root "$tmp"` | `write_sentinel`, invoked when an unlocked existing account lacks the verifier | `chown 0:0`; empty target NSS otherwise returns `invalid user: root:root` |
| `:45` | `install -d -o root -g root -m 0700` | missing directory with an existing unlocked account | `install -d -o 0 -g 0 -m 0700`; names are unavailable before users |
| `:49` | `stat -c '%U:%G:%a' ... == root:root:700` | unconditional directory validation; immediate reported failure | `%u:%g:%a == 0:0:700` |
| `:59` | `stat -c '%U:%G:%a' ... == root:root:600` | unconditional file validation after directory passes | `%u:%g:%a == 0:0:600`; otherwise it becomes the next fresh-install failure |

There are four syntactic pre-users sites; the install and stat sites each carry independent owner and group semantics, so both UID and GID must be numeric. `mktemp`, `chmod`, `mv`, `test -r/-d/-f`, and file content validation do not require NSS.

### Reported-path reachability

The staged extra-files directory/file already exist on the fresh target, so the reported attempt does not execute lines 36 or 45. It reaches line 49 immediately and fails named reverse lookup. After fixing only line 49 it will reach and fail line 59. Lines 36/45 are latent reinstall/migration failures and still violate the pre-users boundary, so they must not remain name-based.

### Post-users operations

`consumeBootstrapPassword` depends on `users`, so its line 103 named stat and line 107 named chown are not the cause:

- `:103`: `%U:%G:%a == root:root:700`
- `:107`: `chown root:root "$tmp"`

They are not mandatory for the minimal causal fix because classic `users` has established root/root. Nevertheless converting them to `%u:%g:%a == 0:0:700` and `chown 0:0` is recommended: the security invariant is numeric, it removes alias/NSS-source fragility, avoids reintroducing the bug if dependencies change, and makes the module internally consistent. The human-readable failure messages may continue to say `root:root`; strings do not perform lookup.

## Exact regression assertions

### 1. Empty-target-NSS positive validator

Evaluate the real validator, then run it in the existing root user/mount namespace with these three files bind-mounted:

```text
/etc/passwd       empty
/etc/group        empty
/etc/nsswitch.conf:
  passwd: files
  group: files
  shadow: files
```

Continue binding the fixture shadow and `/var/lib` as the lifecycle test already does. Explicit `files` prevents a host `nss-systemd` fallback from synthesizing root and masking the regression.

Required assertions:

```text
empty-nss-existing-valid: rc == 0
inside namespace directory metadata: %u:%g:%a == 0:0:700
inside namespace file metadata:      %u:%g:%a == 0:0:600
```

This proves correct numeric ownership passes without any target names.

### 2. Empty-target-NSS creation/sentinel branch

Run the existing `missing-existing-unlocked` case under the same empty NSS mounts. This branch exercises both numeric creation operations (`install` and `write_sentinel` chown).

Required assertions:

```text
empty-nss-missing-existing-unlocked: rc == 0
directory: %u:%g:%a == 0:0:700
file:      %u:%g:%a == 0:0:600
file bytes exactly "!\n"
```

A regression to either `install -o root -g root` or `chown root:root` must make this case fail with invalid user/group.

### 3. Independent owner and group negatives

Use a user namespace with two mapped IDs (current user -> inner 0, one subordinate UID/GID -> inner 1), or a NixOS VM running as real root. Construct otherwise-valid fixtures and assert all four fail:

```text
dir uid 1 gid 0 mode 700 -> reject
dir uid 0 gid 1 mode 700 -> reject
file uid 1 gid 0 mode 600 -> reject
file uid 0 gid 1 mode 600 -> reject
```

The local supported command shape was verified:

```sh
unshare --user \
  --map-users 0:$UID:1 --map-users 1:100000:1 \
  --map-groups 0:$(id -g):1 --map-groups 1:100000:1 \
  --setuid 0 --setgid 0 ...
```

Do not silently skip these assertions when subordinate mappings are unavailable; use a VM test instead. They prove UID and GID are checked independently, rather than merely testing the mode.

### 4. Preserve existing mode and symlink negatives

Existing cases must continue to reject:

```text
dir 0:0 mode 777
file 0:0 mode 644
file final-component symlink
dir final-component symlink
missing/malformed/empty/multiline/non-newline hash
```

Numeric ownership changes must not weaken these orthogonal checks.

### 5. Mutation controls

Add mutations that independently revert:

1. directory `%u` to `%U`;
2. directory `%g` to `%G`;
3. file `%u` to `%U`;
4. file `%g` to `%G`;
5. pre-users `chown 0:0` to `root:root`;
6. pre-users `install -o 0` to `-o root`;
7. pre-users `install -g 0` to `-g root`.

The empty-NSS positive/creation cases must kill all seven. Existing wrong-mode/symlink mutations remain separately protected.

### 6. Generated activation/config assertions

Evaluate `bootstrapPasswordHash.text` and assert:

- it contains two numeric stat comparisons, exactly `0:0:700` and `0:0:600`;
- it contains no `%U` or `%G`;
- it contains no executable `chown root:root`, `-o root`, or `-g root`;
- `users.deps` still contains `bootstrapPasswordHash`;
- `consumeBootstrapPassword.deps == [ "users" ]`.

If post-users operations are deliberately left named, scope the “no name operations” assertion to validator text only; if the recommended consistency conversion is adopted, assert the consumer text is numeric too.

## CLAIMS

- **Must change:** both pre-users stat predicates, pre-users sentinel chown, and pre-users fallback install owner/group.
- **Must test:** correct 0:0 metadata succeeds with passwd/group absent; missing-dir/sentinel creation also succeeds; wrong UID and wrong GID independently fail; existing mode/symlink/content rejection remains.
- **Recommended, not causally required:** numericize consumer line 103/107 after users for consistency and future-ordering safety.
- **Test-environment requirement:** force `passwd/group: files` while hiding passwd/group; otherwise nss-systemd may synthesize root and produce a false pass.

## EXPAND

- Prefer a small NixOS VM regression if portable subordinate-ID mappings are unavailable; do not omit wrong-owner/group negatives.
- Make failure diagnostics print both numeric and named tuples, but compare only numeric fields.
- Add mutation coverage for each UID/GID field and each pre-users name-based creation operation.
