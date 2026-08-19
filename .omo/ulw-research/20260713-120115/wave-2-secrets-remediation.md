# Wave 2 — credential/history remediation, agenix, sync, SSH, bootstrap and Wi-Fi secrets

Observer: `wave2_secrets_remediation`; exact-pinned source audit plus redacted executable probes, observed 2026-07-13. This is a research artifact only. No production configuration was edited, no credential was authenticated, and no secret value is reproduced here.

## Executive verdict

The current repository has one confirmed live-looking Wallhaven API credential in a tracked Noctalia settings file. It is already public in Git history and has also been materialized into a world-readable Nix store source. The only safe assumption is that the credential is permanently disclosed. **Regenerate it immediately in Wallhaven account settings, review account-visible settings/private collections for unexpected access, and never reuse the old value.** Removing it from `main` or rewriting Git history cannot substitute for rotation.

The surrounding secret architecture is not ready for “install anywhere”:

1. `sync-secrets` compiles `${self}/secrets` into an immutable store destination and demonstrably fails instead of updating the checkout.
2. Standalone Home Manager's conditional plaintext `home.file` sources would copy any reachable Kavita/Calibre plaintext into the store. In a normal Git flake evaluation, the ignored files are absent from the archived flake, so the documented sync-to-checkout workflow is both ineffective and unsafe to “fix” by making plaintext visible to evaluation.
3. NixOS agenix currently has no active secrets and overrides the safe host-key-oriented default with the everyday login private key. A separate `id_ed25519_agenix` is created by Darwin tooling, but the agenix module does not use it.
4. Root and `mei` authorize the same SSH key; effective NixOS settings allow user password and keyboard-interactive SSH, while root remains reachable with that shared public key.
5. The bootstrap verifier is carefully staged and consumed, but consumption only removes the duplicate hash. The installed shadow password remains usable until it is changed or locked.
6. No Wi-Fi profile or credential is provisioned. NetworkManager can scan, but it cannot automatically join a protected network after first boot.

The right boundary is: public/tracked **ciphertext**, unique per-host decryption identities plus an offline recovery recipient, root-only runtime plaintext under `/run`, key-only non-root SSH, explicit first-login password rotation, and fail-closed tests that scan Git history, the evaluated closure, service logs and destination containment.

## Redacted exposure facts

### Confirmed credential

| Fact | Redacted evidence |
|---|---|
| Provider/type | Wallhaven API credential |
| Current tracked path | `modules/standalone-linux/config/noctalia/settings.json:855` |
| JSON key path | `wallpaper.wallhavenApiKey` |
| Shape | 32 alphanumeric characters |
| SHA-256 | `0ae7611982a35114a446b9c19ee5b00048b1f389dc49194fb66336f925674146` |
| Introducing commit | `024d78a7517a9743a3696d515f483f14c890308d` |
| Containing refs observed locally | `main`, `origin`, `origin/main` |
| Remote visibility | GitHub API reports `public`; zero GitHub forks at observation time, but clones/caches cannot be enumerated |
| Nix store exposure | The archived flake contains identical bytes in a `/nix/store/*-source` file with mode `0444`, owned by `root:root` |

The value was not printed into this report, was not sent to Wallhaven, and was not tested for validity. Wallhaven documents that its API key can expose account settings and private collections and that it can be regenerated at any time. That makes external regeneration the first effective containment action, not a source edit.

### Redacted scanner result

`gitleaks 8.30.1` was run against full Git history with `--redact=100` and a temporary report. It found two `generic-api-key` events:

- the confirmed Noctalia/Wallhaven event above; and
- a false positive on a public OpenPGP signing-key fingerprint in historical `modules/shared/home-manager.nix`.

A repository-specific Wallhaven-field rule was then tested in three isolated archives with mode-`0600` reports:

```text
clean findings=0 unredacted=0 report_mode=600
synthetic-leak findings=1 unredacted=0 report_mode=600
tracked-head findings=1 unredacted=0 report_mode=600
```

The OpenPGP false positive must receive a narrow fingerprint/path/rule allowlist. Do not broadly allowlist `home-manager.nix`, generic API-key findings, or arbitrary 40-hex strings.

## Immediate incident response

These steps are deliberately ordered. Source cleanup before credential rotation leaves the actual capability usable.

1. **Regenerate the Wallhaven API key now in the authenticated Wallhaven account settings.** Do not paste the old or new value into a terminal, issue, commit, chat, command argument, or URL. Wallhaven says the key can be regenerated at any time.
2. **Review the Wallhaven account**, especially browsing settings, private collections, and any unexpected account changes. The API documentation shows that authenticated keys can read user settings and access the owner's private collections. If anything else looks suspicious, rotate the account password and review active sessions using the provider's available controls.
3. **Remove the field value from the current tracked Noctalia file** and from mutable Noctalia runtime state/backups. The declarative value should be empty or supplied only from a runtime secret path if Noctalia gains a safe file-based interface. Never commit the regenerated key.
4. **Run both full-history and current-tree scanners**, with fully redacted mode and mode-`0600` reports. The gate should fail until the current tracked value is gone; history findings are then explicitly handled as revoked historical incidents rather than silently ignored.
5. **Inventory local copies without trying to mutate `/nix/store`**: working trees, old clones, USB backups, editor backups, Noctalia mutable state and build machines. Garbage collection may eventually remove unrooted local store paths, but it is not an erasure guarantee and says nothing about other hosts or caches.
6. **Decide whether to rewrite history** only after rotation and a coordinated impact review. Rotation is mandatory; rewrite is policy-dependent and cannot make the old value private again.

## History-remediation decision

### Minimum safe response: rotate, remove from current source, record the incident

This is the recommended baseline for a revocable, scoped API key:

- invalidate the credential externally;
- remove it from the current branch and runtime state;
- add preventive scanner gates;
- retain only redacted incident metadata (path, commit, type, length, digest, dates);
- treat every historical copy as public forever.

This avoids destabilizing all commit IDs while actually removing the capability. It does **not** make the old bytes disappear.

### Optional coordinated rewrite

GitHub documents `git-filter-repo --sensitive-data-removal` for sensitive history, but also documents substantial side effects. A rewrite changes commit IDs, invalidates signatures, disrupts open PR references, requires force-pushing every affected ref, and can be undone by a collaborator merging an old clone. Forks, unobservable clones, archives, Nix store copies and third-party caches can retain the old bytes. GitHub Support generally treats rotation as the mitigation for revocable credentials.

Use a rewrite only when policy, non-revocable data, or a broader exposure justifies the coordination cost. If selected:

1. freeze pushes and back up refs securely;
2. use a root-only replacement specification that never appears in shell history;
3. rewrite every affected branch/tag, verify with a redacted full-history scanner, and force-push deliberately;
4. invalidate or recreate open PR branches;
5. tell every collaborator to discard/re-clone rather than merge old history;
6. ask known fork owners to remove old objects; and
7. keep the credential revoked permanently.

The current GitHub API reports zero forks, but that is not evidence of zero clones or caches.

## Current exact security state

### SSH

Evaluation of `nixosConfigurations.x86_64-linux` produced:

| Property | Current result |
|---|---|
| `services.openssh.enable` | `true` |
| `openFirewall` | `true` |
| `PasswordAuthentication` | `true` |
| `KbdInteractiveAuthentication` | `true` |
| `PermitRootLogin` | `"prohibit-password"` |
| root authorized-key count | 1 |
| `mei` authorized-key count | 1 |
| root/user key sets | identical |
| shared public-key fingerprint | `SHA256:QMzHpXOpwFAPvK24YIvO5mCTl7M+V1kN0E7RZFENXkg` |

`prohibit-password` is not “no root login”; it allows root public-key login. The same external private key therefore reaches both the normal account and root. Nixpkgs' exact module defaults password and keyboard-interactive authentication to true unless explicitly disabled.

### Agenix

Exact evaluation produced:

```text
age.identityPaths = [ "/home/mei/.ssh/id_ed25519" ]
age.secrets = { }
```

The pinned agenix revision is `b027ee29d959fda4b60b57566d64c98a202e0feb`. Its NixOS default, when OpenSSH is enabled, is to use generated RSA/Ed25519 **host keys**. This repo overrides that with an everyday user login key. The Darwin create/copy scripts create `~/.ssh/id_ed25519_agenix`, but `modules/darwin/secrets.nix` also points at `id_ed25519`, so the purported separation is currently unused.

The pinned agenix documentation is explicit:

- encrypted `.age` files may enter the Nix store;
- decrypted secrets default to `/run/agenix/<name>`;
- private identity paths must be runtime strings, not Nix paths; and
- reading a decrypted secret with `builtins.readFile` can put cleartext in the world-readable store.

### Local ignored “secrets”

Three ignored Calibre files are currently present under a mode-`0755` `secrets/` directory and are themselves mode `0644`. No obvious token/password field names were found in these three JSON files, but the permissions and sync behavior are unsuitable for a directory that is documented to contain private material. The directory should be `0700`; plaintext files should normally be `0600`.

## Safe per-host agenix design

### Recipient model

Use three distinct key roles:

1. **login key** — authorizes the non-root SSH user; never decrypts fleet secrets;
2. **per-host agenix identity** — unique to one machine, root-readable, no password prompt, never authorizes SSH login; and
3. **offline recovery recipient** — kept off the target and included on every secret so a lost host can be rekeyed.

Do not share one decryption private key across all hosts. Compromise of one laptop should not decrypt other hosts' Wi-Fi, API or service secrets.

A CLI-only recipient file can express the mapping without importing private data into Nix:

```nix
let
  recovery = "age1...OFFLINE-RECOVERY-PUBLIC-RECIPIENT...";
  laptop = "age1...LAPTOP-PUBLIC-RECIPIENT...";
  desktop = "age1...DESKTOP-PUBLIC-RECIPIENT...";
in {
  "hosts/laptop/wifi.nmconnection.age".publicKeys = [ laptop recovery ];
  "hosts/desktop/service.env.age".publicKeys = [ desktop recovery ];
}
```

Only public recipients and ciphertext are tracked. Use `agenix --rekey` whenever a recipient is added or removed.

### First-install identity provisioning

The usual host-key approach has a first-install chicken-and-egg problem: the host key normally exists only after the target has booted, but Wi-Fi may be needed on first boot. Two valid patterns are:

- **Preferred one-pass install:** generate a dedicated host agenix identity offline on the trusted working machine, add its public recipient, encrypt the host secrets, and transfer only the private identity to `/var/lib/agenix/identity` with owner `root:root`, mode `0400`, over an already authenticated installer channel. Never represent the private identity as a Nix path.
- **Safer two-phase bootstrap when installer trust is not yet repaired:** install without target secrets, boot locally, generate/verify the host identity, add its public recipient and rekey, then perform the full deployment over verified SSH.

The current nixos-anywhere host-authentication defect must be fixed before transferring any private identity. A secret manager cannot repair a MITM-vulnerable transport.

### NixOS module shape

Per-host policy should select ciphertext by explicit host identity, never by ambient `$USER`, `$HOME`, or a generic architecture output:

```nix
{ config, ... }:
{
  age.identityPaths = [ "/var/lib/agenix/identity" ];

  age.secrets.wifi-keyfile = {
    file = ../../secrets/hosts/laptop/wifi.nmconnection.age;
    mode = "0600";
    owner = "root";
    group = "root";
    path = "/run/NetworkManager/system-connections/laptop-wifi.nmconnection";
    symlink = false;
  };
}
```

For ordinary services, prefer the default `config.age.secrets.<name>.path` under `/run/agenix`, mode `0400`, and configure the service to read the file at runtime. Do not interpolate contents into a generated unit, environment, option value, command argument or `pkgs.writeText`.

`symlink = false` is justified above only because NetworkManager applies strict checks to connection files and the destination is ephemeral `/run`. Add explicit same-boot cleanup on configuration removal; agenix warns that non-symlink destinations otherwise become the operator's cleanup responsibility.

## NetworkManager secret injection

### Preferred: decrypt a complete keyfile directly into `/run`

Encrypt the whole `.nmconnection` file, including SSID if its disclosure matters. The decrypted runtime file should be `root:root` mode `0600` under `/run/NetworkManager/system-connections`; NetworkManager documents that keyfiles may contain plaintext secrets and therefore ignores files writable/readable by non-root users or groups.

The encrypted file can contain:

```ini
[connection]
id=laptop-wifi
type=wifi
autoconnect=true

[wifi]
mode=infrastructure
ssid=REDACTED-RUNTIME-VALUE

[wifi-security]
key-mgmt=wpa-psk
psk=REDACTED-RUNTIME-VALUE

[ipv4]
method=auto

[ipv6]
method=auto
```

A root oneshot should run after `NetworkManager.service`, load/reload that exact runtime path, emit no file contents, and remove the path on stop. It should be ordered before `network-online.target` and retrigger when the **encrypted** input changes. Never call `nmcli ... password "$PSK"`; command-line secrets are observable.

### Supported alternative: `ensureProfiles.environmentFiles`

At exact root nixpkgs revision `d407951447dcd00442e97087bf374aad70c04cea`, `networking.networkmanager.ensureProfiles` supports literal `$VARIABLE` placeholders plus runtime `environmentFiles`. Its service uses `envsubst`, writes profiles into `/run/NetworkManager/system-connections`, sets `UMask = "0177"`, and reloads NetworkManager. An agenix file can therefore supply only `WIFI_PSK=...` at runtime while the Nix expression contains `$WIFI_PSK`.

This is a supported NixOS interface, but systemd's own documentation warns that environment variables are generally unsuitable for secrets. The oneshot is root-only and short-lived, yet the complete encrypted-keyfile design avoids putting the PSK in a process environment at all and is the stronger default.

In either design:

- no SSID/PSK is in Nix source or a generated store file;
- no secret is logged;
- the runtime keyfile is root-only and ephemeral;
- profile loading is tested at boot and on switch;
- Wi-Fi failure never causes a fallback to a committed password; and
- an interactive `nmcli --ask`/desktop secret agent remains available for unknown networks.

## Repairing `sync-secrets`

### Executed failure proof

A synthetic local Git repository was supplied to the current app. The result was:

```text
sync-current-exit=23
rsync destination=/nix/store/<HASH>-source/secrets/
failure=Operation not permitted / Permission denied
working-tree-file-created=no
```

The generated app script literally contains `/nix/store/<HASH>-source/secrets/`. Its success message claims `./secrets`, but its destination is not the caller's checkout.

### Correct runtime contract

Do not interpolate `${self}` into any writable destination. At runtime the app should:

1. set `umask 077`;
2. take an explicit `--dest WORKTREE` or derive the root with `git -C "$PWD" rev-parse --show-toplevel`;
3. canonicalize the root and reject `/nix/store/*`, non-Git directories, missing `flake.nix`, and a `secrets` symlink/path that escapes the root;
4. create temporary clone/staging directories mode `0700`;
5. avoid echoing the repository URL because it may contain user information or credentials;
6. use SSH or a credential helper, not an access token embedded in the URL/argument;
7. validate the incoming manifest and file types before replacement;
8. preserve tracked `secrets/README.md` and write only beneath the selected worktree's real `secrets/` directory;
9. set plaintext directory/file modes to `0700`/`0600`; and
10. fail atomically, leaving the previous destination intact.

The app must distinguish two data classes:

- **`.age` ciphertext:** safe to track and feed to agenix; preferred for NixOS and Home Manager.
- **plaintext application state:** never feed it through `home.file.source`, a Nix path, `builtins.readFile`, or a flake input. If an application cannot consume an agenix runtime path, install/copy it at activation/runtime outside Nix evaluation with mode `0600`, or improve the application integration.

The current standalone module's `home.file` declarations are not a safe plaintext transport. Normal Git-flake archiving omits ignored local files, so the declarations do not see files synced into the checkout; exposing those files to Nix would make their contents store inputs. Replace this split-brain design rather than merely making the ignored path visible.

## SSH and bootstrap hardening

### Target SSH policy

```nix
{
  services.openssh.settings = {
    PermitRootLogin = "no";
    PasswordAuthentication = false;
    KbdInteractiveAuthentication = false;
    PubkeyAuthentication = true;
  };

  users.users.root.openssh.authorizedKeys.keys = [ ];
  users.users.mei.openssh.authorizedKeys.keys = [ "ssh-ed25519 ...USER-LOGIN-PUBLIC-KEY..." ];
}
```

The user login key, host server key, per-host agenix identity, and offline recovery key are separate. If remote root break-glass access is genuinely required, use a separate offline key with `from=`, forced-command/no-forwarding restrictions and an explicit incident procedure; do not silently reuse the everyday user key.

Validate the generated server configuration with `sshd -T`, not only Nix option values. Test successful user-key login in a second session before closing the install console.

### Bootstrap password lifecycle

The current tests strongly validate tmpfs staging, yescrypt shape, owner/mode, symlink rejection, exact shadow installation, atomic replacement and cleanup. The relevant suites all passed during this audit. However, replacing `/var/lib/nixos-bootstrap/mei-password.hash` with `!` only removes the duplicate verifier. It does not invalidate the real hash installed into `/etc/shadow`.

The safe lifecycle is:

1. disable SSH password and keyboard-interactive authentication from the installed generation;
2. after successful first activation, mark the bootstrap password for change at next local login (`chage -d 0 mei`) exactly once;
3. require the user to replace it with a distinct durable local/sudo password;
4. verify `passwd -S mei`/`chage -l mei` without printing a hash;
5. after non-password recovery and sudo are proven, optionally lock the password with `passwd -l mei` if the chosen policy is key/FIDO-only; and
6. retain a documented console/recovery path before locking.

Do **not** automatically lock the only sudo-capable user's password before a working key, FIDO/PAM method, console recovery and privilege escalation path have been verified. A forced first-login change is safer than indefinite bootstrap reuse and safer than an unconditional lockout.

## Executable redacted test contracts

### T1 — current tree and full-history secret scan

Pin `gitleaks` through nixpkgs and run both modes with a root/private temp directory:

```bash
umask 077
report=$(mktemp)
gitleaks git --redact=100 --report-format json --report-path "$report" .
test "$(stat -c %a "$report")" = 600
jq -e 'all(.[]; .Secret == "REDACTED")' "$report"
```

Add a custom field rule for `wallhavenApiKey` plus repository policy checks for non-placeholder `TokenKey`, Wi-Fi PSK and other known application-secret fields. Test each rule with:

- an empty/placeholder fixture that must pass;
- a synthetic alphanumeric fixture that must fail;
- the tracked tree; and
- full Git history.

Never print `Match`, `Secret`, entropy input or source-line content. CI should emit rule ID, path, line, commit and a redacted marker only. Exact allowlists must be reviewable and narrow.

### T2 — no plaintext in the Nix closure or logs

An executed synthetic proof generated a random runtime-only PSK, encrypted a full keyfile with a disposable age identity, added only ciphertext to the store, decrypted to a mode-`0600` runtime path, and compared the round trip. It reported:

```text
synthetic-age-runtime-proof: store_plaintext=no logs_plaintext=no roundtrip=yes runtime_mode=600 store_mode=444 store_requisites=1
```

The production integration test should follow the same pattern without placing the synthetic cleartext in a Nix expression or test derivation:

1. the outer test harness creates a root-only pattern file at runtime;
2. it encrypts outside Nix evaluation and deploys only ciphertext;
3. it queries the exact target closure with `nix-store -qR`;
4. `grep -Fqf "$pattern_file"` scans each closure path and returns only pass/fail;
5. it scans `journalctl` for the agenix/NetworkManager units the same way; and
6. it verifies runtime owner/mode/path and actual NetworkManager profile activation.

The secret/pattern must never be passed as an argument or printed. A failed scan reports only the offending store path or unit, not matching text.

### T3 — `sync-secrets` destination containment

Use a synthetic source repository and two temporary Git worktrees:

- invoke from the selected worktree root and a nested subdirectory;
- assert that expected files appear only under `<selected-root>/secrets`;
- assert mode `0700` directories and `0600` plaintext files;
- assert tracked `secrets/README.md` remains unchanged;
- reject explicit `/nix/store/...`, a non-Git destination, `secrets -> outside` symlink, FIFO/device/symlink source entries, and missing repo arguments;
- simulate clone, validation and rsync failures and prove the previous destination is byte-identical;
- capture stdout/stderr and assert a credential-bearing synthetic URL is never reproduced; and
- optionally use `strace -f -e trace=%file` to assert all non-temporary write syscalls stay under the canonical selected worktree.

### T4 — agenix recipient isolation

Generate disposable `host-a`, `host-b` and recovery identities. Prove:

- host A decrypts only A + shared secrets;
- host B decrypts only B + shared secrets;
- recovery decrypts all intended secrets;
- the login private key decrypts none;
- removing A from the recipient map and rekeying prevents the old A identity from decrypting; and
- no private identity path appears in `nix-store -qR`, the evaluated JSON, build logs or Git.

### T5 — NixOS VM/runtime network test

Boot a NixOS VM with a disposable NetworkManager access point or network namespace. Assert:

- agenix decrypts before profile loading;
- the profile path is under `/run`, `root:root`, mode `0600`;
- NetworkManager loads it and reaches `activated` without an interactive secret agent;
- switch/rekey reloads the profile;
- removal deletes/unloads it in the same boot;
- no PSK occurs in the closure, process command line, environment dump or journal; and
- a wrong secret fails closed without copying a fallback credential into source.

### T6 — SSH/password lifecycle test

In the NixOS VM and on each real host acceptance checklist:

```text
sshd -T: permitrootlogin no
sshd -T: passwordauthentication no
sshd -T: kbdinteractiveauthentication no
root authorized keys: zero
normal-user authorized key login: succeeds
root login with every key: fails
password SSH: fails
first local bootstrap login: requires password change
post-change local login/sudo: succeeds
bootstrap verifier path: contains only consumed marker or is removed by the finalized state machine
```

Run the existing bootstrap lifecycle, helper, secret-scan and mutation suites as regression gates. They passed in this audit, but new mutation cases must kill the `chage`/lock marker, SSH-hardening and cleanup steps to prove those additions are actually enforced.

## Prioritized implementation sequence

| Priority | Action | Exit evidence |
|---|---|---|
| P0 external | Regenerate Wallhaven key and review account | Old key recorded as revoked by provider; no validity test from tooling |
| P0 repository | Remove current value and mutable copies | Custom current-tree scan returns zero |
| P0 gate | Add pinned redacted full-history/current scanner | clean/leak controls 0/1; precise OpenPGP false-positive allowlist |
| P0 SSH | Disable root/password/keyboard-interactive SSH; remove root shared key | `sshd -T` and VM login matrix |
| P1 agenix | Per-host identity + offline recovery; tracked ciphertext/runtime plaintext | recipient-isolation and closure/log tests |
| P1 Wi-Fi | Per-host encrypted runtime NetworkManager keyfile | first-boot VM activation and removal/rekey tests |
| P1 bootstrap | Force one-time password change; optional verified lock | VM `chage`/login/sudo/recovery matrix |
| P1 sync | Runtime worktree destination; fail-closed containment | synthetic worktree/strace/rollback tests |
| P1 standalone HM | Remove plaintext `home.file` secret transport | evaluated closure scan and runtime activation test |
| P2 history | Decide coordinated history rewrite after rotation | written decision; if selected, every ref rescanned and collaborators re-cloned |

## Primary sources

- [GitHub: Removing sensitive data from a repository](https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/removing-sensitive-data-from-a-repository)
- [GitHub: Push protection](https://docs.github.com/en/code-security/concepts/secret-security/push-protection)
- [GitHub: Custom secret patterns](https://docs.github.com/en/code-security/reference/secret-security/custom-patterns)
- [Wallhaven API v1 documentation](https://wallhaven.cc/help/api)
- [Pinned agenix README](https://github.com/ryantm/agenix/blob/b027ee29d959fda4b60b57566d64c98a202e0feb/README.md)
- [Pinned agenix NixOS/Darwin module](https://github.com/ryantm/agenix/blob/b027ee29d959fda4b60b57566d64c98a202e0feb/modules/age.nix)
- [Pinned Nixpkgs NetworkManager module](https://github.com/NixOS/nixpkgs/blob/d407951447dcd00442e97087bf374aad70c04cea/nixos/modules/services/networking/networkmanager.nix)
- [Pinned Nixpkgs OpenSSH module](https://github.com/NixOS/nixpkgs/blob/d407951447dcd00442e97087bf374aad70c04cea/nixos/modules/services/networking/ssh/sshd.nix)
- [NetworkManager keyfile reference](https://networkmanager.dev/docs/api/latest/nm-settings-keyfile.html)
- [NetworkManager settings/secret flags](https://networkmanager.dev/docs/api/latest/nm-settings-nmcli.html)
- [systemd execution environment warning](https://www.freedesktop.org/software/systemd/man/systemd.exec.html)
- [NixOS manual: Secure Shell Access](https://nixos.org/manual/nixos/stable/#sec-ssh)
- [OpenSSH `sshd_config(5)`](https://man.openbsd.org/sshd_config)

## Not verified

- The exposed credential's validity was intentionally not tested.
- External rotation/account review cannot be performed from this repository audit.
- No private secret repository was cloned or inspected.
- No public-history rewrite, force push, store garbage collection or production source edit was performed.
- Zero GitHub forks does not prove zero clones, mirrors, caches or screenshots.
- No live laptop was available for `sshd -T`, shadow aging, NetworkManager, journal or Wi-Fi association tests.
- The synthetic age/store proof validates the boundary primitive, not yet this repository's absent production agenix/Wi-Fi integration.

## EXPAND

- LEAD: provider-side Wallhaven regeneration and account review — WHY: source edits cannot revoke capability — ANGLE: user performs authenticated provider action; tooling never tests old key.
- LEAD: authenticated installer transport for per-host identity staging — WHY: a MITM can steal the agenix private identity — ANGLE: vendor/patched nixos-anywhere with strict pinned host fingerprints.
- LEAD: first-boot encrypted NetworkManager VM — WHY: ordering, keyfile acceptance and same-boot removal are runtime properties — ANGLE: agenix activation + NetworkManager namespace/AP test.
- LEAD: standalone Home Manager plaintext boundary replacement — WHY: current ignored sync is ineffective, while making it visible risks store disclosure — ANGLE: tracked ciphertext + agenix HM or runtime copy outside evaluation.
- LEAD: bootstrap forced-change state machine — WHY: sentinel consumption does not rotate the shadow password — ANGLE: one-shot `chage`, recovery verification and mutation tests.
- LEAD: full repository security gate — WHY: default generic scanning has a known OpenPGP false positive and provider-specific blind spots — ANGLE: pinned gitleaks + exact allowlist + semantic field scanner.

## CLAIMS

- **C-S1 (confirmed, critical):** a 32-character Wallhaven API credential is tracked at the redacted path above, present since commit `024d78a...`, reachable on public refs, and materialized into a mode-`0444` Nix store source. Evidence: Git object/current/store digest equality; GitHub repository visibility; custom redacted scan.
- **C-S2 (confirmed):** credential rotation must precede source/history cleanup. Evidence: Wallhaven documents regeneration; GitHub says revoke/rotate first and describes rewrite limitations.
- **C-S3 (confirmed):** current `sync-secrets` cannot update the working checkout because `${self}` resolves to a store source. Evidence: generated script inspection and synthetic execution exit 23 with no worktree file.
- **C-S4 (confirmed, high):** current standalone plaintext secret declarations are an invalid boundary: ignored files are unavailable in normal Git-flake source, while any plaintext made into a Nix source can enter the world-readable store. Evidence: Git ignore/archive behavior, module source coercion, pinned agenix warning.
- **C-S5 (confirmed, high):** root and `mei` accept the same SSH key while password and keyboard-interactive SSH remain enabled for the user. Evidence: exact Nix evaluation and key-set equality.
- **C-S6 (confirmed):** current agenix is inactive and coupled to the everyday login identity; the separate Darwin agenix key is unused by module configuration. Evidence: exact evaluation plus module/script paths.
- **C-S7 (confirmed):** bootstrap verifier consumption removes the copied verifier but does not rotate or lock the installed shadow password. Evidence: activation script semantics and passing lifecycle tests.
- **C-S8 (executed primitive proof):** age ciphertext can reside in the store while runtime plaintext remains mode `0600` and absent from the ciphertext closure/logs. Evidence: disposable random round-trip `store_plaintext=no`, `logs_plaintext=no`, `roundtrip=yes`.
- **C-S9 (design, high confidence):** unique per-host agenix identities, offline recovery recipients, `/run` plaintext and direct encrypted NetworkManager keyfiles eliminate the current login-key/store/environment coupling. Pending: repository implementation plus NixOS VM and live-host verification.
