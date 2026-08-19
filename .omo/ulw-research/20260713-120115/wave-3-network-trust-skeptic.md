# Wave 3 — adversarial network, SSH, Wi-Fi, host-intake and secret skeptic

**Research date:** 2026-07-13  
**Repository revision:** `e9f78180748f1feb428ffb20f9d932c5d9918a48`  
**Exact root Nixpkgs:** `d407951447dcd00442e97087bf374aad70c04cea`  
**Exact/current nixos-anywhere:** `4dfb813db065afb0aba1f61658ef77993d382db1`  
**Scope:** adversarial re-check only. No production source was edited. No credential value was displayed, copied, tested, or reproduced.

## Executive result

The two most serious installer trust findings survive adversarial review, but
both need narrower wording:

1. **SSH server authentication is genuinely disabled by the exact and current
   nixos-anywhere CLI, and its documented `--ssh-option` cannot turn it back on.**
   This is critical for a root, disk-destructive install over an adversarial or
   untrusted network. The likelihood is much lower on a physically controlled
   point-to-point link or authenticated VPN, and a console-local install removes
   this network boundary entirely.
2. **The default kexec artifact is mutable and unchecked, but that risk is
   conditional.** It is not fetched when nixos-anywhere recognizes an already
   booted NixOS installer, and it is not used in install-only recovery. The
   successful physical-ISO path described in this repository therefore avoids
   this particular artifact gap even though it still has the SSH-host-key gap.

Several broader formulations do **not** survive:

- “Wi-Fi is unsupported” is true only for nixos-anywhere's default remote/kexec
  contract. It is false for the installed NixOS output: NetworkManager,
  wpa_supplicant and redistributable firmware are present. A machine showing
  only `lo` and `docker0` lacks a usable kernel network device; an absent saved
  SSID cannot explain an absent interface.
- The Facter/NetworkManager/dhcpcd collision is real at the exact pin and still
  present at Nixpkgs `HEAD`, but it is a **prospective enrollment bug**, not a
  current runtime bug: this repository does not yet import a Facter report and
  the evaluated current output has no dhcpcd unit.
- Reusing one key for root and the normal user is bad policy, but its incremental
  privilege impact is smaller than first stated because the user is already in
  `wheel`, `docker`, and Nix `trusted-users`, all deliberately privileged trust
  boundaries. It still bypasses user attribution, PAM and sudo controls.
- The tracked Wallhaven API credential is a real public-history disclosure and
  must be regenerated. The provider's API v1 documentation describes basic GET
  access to settings/private collections/NSFW results, not account mutation, so
  this is a **medium confidentiality credential exposure**, not demonstrated
  account takeover. No validity test was performed.
- Agenix risk is currently latent: `age.secrets` evaluates to an empty set. The
  configured everyday-login identity is undesirable future coupling, but the
  current bootstrap helper stages only a password verifier and wallpapers, not
  an agenix private identity.

## Adversarial method

I tried to falsify each earlier claim using all of the following:

- cloned the current upstream default branches rather than trusting earlier
  snapshots;
- queried current issue/release metadata;
- inspected exact pinned and current source for option order, installer
  detection, kexec download, key continuity, network restoration and Facter
  DHCP behavior;
- executed a fresh `ssh -G` option-order control;
- evaluated the repository's current OpenSSH settings, authorized-key sets,
  groups, Nix trusted users, active age secrets and generated services;
- separated direct-ISO, default-kexec, custom-kexec, install-only and installed
  runtime claims instead of treating them as one path; and
- looked for lower-complexity mitigations that fit an attended personal laptop
  install before accepting fleet-grade signed-manifest machinery.

Current upstream observations:

- `nix-community/nixos-anywhere` `HEAD` is still the repository's exact pin,
  `4dfb813...`; issue [#552](https://github.com/nix-community/nixos-anywhere/issues/552)
  is open with no linked fix.
- The current `nixos-images` default branch is `803f285...`; its kexec runner
  still preserves host keys and IP address/route state, not Wi-Fi association
  state.
- Nixpkgs `HEAD` observed as `cc3e2ba...` still gives Facter-detected
  interfaces `useDHCP = mkDefault true`; NetworkManager still disables only the
  global `networking.useDHCP`; dhcpcd still starts when any interface explicitly
  has `useDHCP = true`.

## Claim-by-claim verdict

| Earlier claim | Adversarial result | Final rank |
|---|---|---|
| Appended strict SSH options cannot override insecure defaults | Fresh `ssh -G` control and unchanged current upstream source reproduce it exactly | **UPHELD — critical when network-adversarial; high on ordinary LAN due consequence** |
| Default kexec downloads mutable, unchecked root code | Source and mutable release metadata uphold it; direct installer detection and install-only phases bypass it | **UPHELD, NARROWED — high only when kexec actually runs** |
| nixos-anywhere supports no Wi-Fi | Exact requirements explicitly say it does not; default kexec image restores L3 state via networkd but no Wi-Fi credential/link owner | **UPHELD for default remote/kexec contract** |
| The installed output has no Wi-Fi support | Exact evaluation has NetworkManager, one DBus-controlled wpa_supplicant and redistributable firmware | **REFUTED** |
| Missing Wi-Fi profile explains only `lo`/`docker0` | A missing profile prevents association; it does not remove the WLAN netdev | **REFUTED — suspect driver/firmware/device/rfkill/firmware-policy first** |
| Facter plus NetworkManager starts dhcpcd too | Exact and current source plus the earlier executed minimal evaluation confirm it | **UPHELD but PROSPECTIVE — not present in current output** |
| `--copy-host-keys` solves installer trust | It can preserve identity across phases, but cannot authenticate the initially observed key | **REFUTED as trust-root; UPHELD as continuity mechanism** |
| `--copy-host-keys` is generally unreliable | Upstream has a VM integration assertion for full continuity; issue #598 is incomplete/anecdotal, while #604 is an explicit impermanence destination limitation | **DOWNGRADED — verify every install; do not call generically broken** |
| Shared root/user key creates a broad root path | Exact evaluation confirms identical authorization and direct root login | **UPHELD fact, DOWNGRADED marginal severity because user is already root-equivalent** |
| Bootstrap verifier is safely consumed | Duplicate verifier becomes `!` only after shadow equality and strong ownership/shape checks | **UPHELD** |
| Bootstrap password is rotated/expired | The shadow hash remains valid until the user changes it; SSH password and keyboard-interactive auth both evaluate true | **REFUTED — rotation is not implemented** |
| Current agenix secrets expose runtime plaintext | `age.secrets` is empty | **REFUTED for current activation; latent design risk remains** |
| `sync-secrets` updates the checkout | Generated app writes to `${self}/secrets`, an immutable store source | **UPHELD operational defect; not itself a current secret disclosure** |
| Wallhaven credential exposure proves account takeover | Official API v1 is documented as basic GET access; private settings/collections may be read, but no write endpoint was established | **DOWNGRADED from high takeover to medium confidentiality; regeneration still mandatory** |

## 1. SSH MITM finding survives unchanged upstream

The exact/current script initializes:

```text
UserKnownHostsFile=/dev/null
StrictHostKeyChecking=no
```

before parsing any `--ssh-option`; parsing appends caller values. See
[initialization](https://github.com/nix-community/nixos-anywhere/blob/4dfb813db065afb0aba1f61658ef77993d382db1/src/nixos-anywhere.sh#L63-L70)
and [parsing](https://github.com/nix-community/nixos-anywhere/blob/4dfb813db065afb0aba1f61658ef77993d382db1/src/nixos-anywhere.sh#L236-L243).
OpenSSH uses the first obtained value for most settings
([`ssh_config(5)`](https://man.openbsd.org/ssh_config)). A fresh local control
produced:

```text
no then yes  -> stricthostkeychecking false; userknownhostsfile /dev/null
yes then no  -> stricthostkeychecking true;  userknownhostsfile <private test file>
```

Upstream's own comment at
[`uploadSshKey`](https://github.com/nix-community/nixos-anywhere/blob/4dfb813db065afb0aba1f61658ef77993d382db1/src/nixos-anywhere.sh#L560-L567)
recognizes the same first-value rule to override `IdentitiesOnly`; it simply has
not applied that rule to caller host-authentication options. Issue #552 remains
open.

### What changes the severity

- **Untrusted LAN/public route:** critical consequence and plausible active
  attacker; do not run the current helper.
- **Home LAN:** lower likelihood, unchanged consequence. “Trusted LAN” is an
  operational risk acceptance, not cryptographic server authentication.
- **Pre-authenticated WireGuard/point-to-point VPN:** the outer channel can
  authenticate the peer and materially mitigate network MITM even though SSH is
  misconfigured. This is valid defense, but the current repo does not provision
  such an installer tunnel.
- **Direct local console:** no remote SSH protocol, so this finding disappears.

The smallest correct code fix is not a signed-manifest subsystem: patch the
exact nixos-anywhere source so caller trust options precede defaults (or add a
strict mode), then pin the installer's ED25519 fingerprint from the physical
console into a private temporary known-hosts file. Test negative mismatch and
positive match before any password hash, wallpaper or Disko command crosses the
connection.

## 2. Kexec finding is real but conditional

The exact/current `runKexec` selects a GitHub release URL, then streams it via
`wget`/`curl` or uploads a local download and extracts/executes it without
checking a digest
([source](https://github.com/nix-community/nixos-anywhere/blob/4dfb813db065afb0aba1f61658ef77993d382db1/src/nixos-anywhere.sh#L700-L816)).
The current `nixos-25.11` release reports `immutable: false`; its assets expose
GitHub-computed SHA-256 metadata, while the images release builder still uses
`gh release upload --clobber`
([source](https://github.com/nix-community/nixos-images/blob/803f28511c7d5f39f2537c342122fd94b8e1d519/build-images.sh#L37-L55)).

The available GitHub asset digest helps an operator verify bytes only if an
expected digest is independently approved and fixed before download. The exact
nixos-anywhere program never queries or verifies it, so it does not repair the
default contract.

However, `runKexec` returns immediately when the target's `/etc/os-release`
identifies a NixOS installer, unless `--force-kexec` is set
([source](https://github.com/nix-community/nixos-anywhere/blob/4dfb813db065afb0aba1f61658ef77993d382db1/src/nixos-anywhere.sh#L700-L703)).
Detection is a simple `ID=nixos` plus `VARIANT_ID=installer` check
([source](https://github.com/nix-community/nixos-anywhere/blob/4dfb813db065afb0aba1f61658ef77993d382db1/src/get-facts.sh#L6-L14)); it is a
path selector, not a security attestation. Nevertheless, a physically booted,
verified official/custom installer means the mutable kexec artifact is not part
of that transaction.

Low-complexity choices, in increasing assurance:

1. boot a verified physical ISO and never force kexec;
2. commit an expected flat SHA-256 for one reviewed release asset, download and
   verify once, then pass the verified local file through `--kexec`;
3. build the archive from an exact `nixos-images` revision through Nix and pass
   the local store file;
4. for unattended/fleet work, bind revision, source NAR, flat archive digest,
   target host key and disk identity in a signed manifest.

Options 1–3 are sufficient for an attended personal laptop; option 4 is not a
prerequisite for every home install.

## 3. `--copy-host-keys` narrows transitions; it does not establish trust

The current kexec runner copies `/etc/ssh/ssh_host_*` into the appended initrd
before kexec
([source](https://github.com/nix-community/nixos-images/blob/803f28511c7d5f39f2537c342122fd94b8e1d519/nix/kexec-installer/kexec-run.sh#L58-L78)).
Its VM test explicitly asserts the ED25519 public key is unchanged across
kexec
([test](https://github.com/nix-community/nixos-images/blob/803f28511c7d5f39f2537c342122fd94b8e1d519/nix/kexec-installer/test.nix#L129-L174)).
With `--copy-host-keys`, nixos-anywhere then copies the installer's keys to
`/mnt/etc/ssh` before activation
([source](https://github.com/nix-community/nixos-anywhere/blob/4dfb813db065afb0aba1f61658ef77993d382db1/src/nixos-anywhere.sh#L893-L911)).
Its full install VM test asserts that identity again after boot
([test](https://github.com/nix-community/nixos-anywhere/blob/4dfb813db065afb0aba1f61658ef77993d382db1/tests/from-nixos.nix#L36-L64)).

That is meaningful positive evidence, so “copy-host-keys is generally broken”
is too strong. The residuals are narrower:

- issue [#598](https://github.com/nix-community/nixos-anywhere/issues/598) has
  incomplete reproduction and reports activation-time mismatch; treat it as a
  reason to verify, not proof of 50/50 behavior;
- issue [#604](https://github.com/nix-community/nixos-anywhere/issues/604)
  demonstrates a real impermanence boundary: the fixed `/etc/ssh` destination
  may be discarded when the durable keys live under `/persist`;
- on a direct live ISO, preserving the ISO's ephemeral key forever may be the
  wrong identity policy even if copying works perfectly; and
- continuity of an unauthenticated key can continuously preserve an attacker's
  key. It never makes the initial observation trustworthy.

For an ordinary non-impermanent laptop, out-of-band verify the installer key,
use `--copy-host-keys`, stop before reboot, and compare the staged public key to
the approved fingerprint. For impermanence or an intentionally new durable
identity, stage pre-generated host keys directly into the real persistent
destination using private tmpfs and authenticated transport.

## 4. Wi-Fi verdict split into three contracts

### Default nixos-anywhere remote/kexec: unsupported

The exact/current requirements say plainly that nixos-anywhere does not support
Wi-Fi networks
([requirements](https://github.com/nix-community/nixos-anywhere/blob/4dfb813db065afb0aba1f61658ef77993d382db1/docs/requirements.md#L21-L25)).
The default kexec image forces NetworkManager off and reconstructs networkd
units from IP addresses/routes. Its runner captures addresses and routes but no
wpa_supplicant, IWD or NetworkManager profile. Thus a Wi-Fi-only SSH path can
die at kexec even if association worked before it.

This is not an absolute Linux limitation. A physical installer can be joined to
Wi-Fi locally and used without kexec, or a custom installer can include an
appropriate radio owner and credential handoff. Those are attended/custom
exceptions, not support supplied by the default remote path.

### Installed NixOS output: the generic stack is present

The current output evaluates with NetworkManager and a single
DBus-controlled wpa_supplicant backend, no IWD and no dhcpcd. The exact Nixpkgs
module intentionally enables this backend when NetworkManager owns wireless
([exact source](https://github.com/NixOS/nixpkgs/blob/d407951447dcd00442e97087bf374aad70c04cea/nixos/modules/services/networking/networkmanager.nix#L687-L702)).
The realized closure also contains redistributable firmware and wireless-regdb.

Therefore:

- no saved profile means “cannot automatically associate,” not “no interface”;
- a hard/soft rfkill can disable radio but normally does not prove the driver is
  missing;
- only `lo` and `docker0` strongly shifts diagnosis toward PCI/USB enumeration,
  driver binding, missing firmware, unsupported/nonredistributable firmware,
  kernel regression, platform quirk, or a disabled device; and
- the repository's lack of `pciutils`, `usbutils`, `iw`, `rfkill` and `ethtool`
  in the installed diagnostic surface materially hindered recovery. These tools
  should be a small host-recovery package set, not ad-hoc internet downloads.

### Immediate usability must include a non-Wi-Fi escape hatch

For every enrolled laptop, test at least one of: built-in Ethernet, a named USB
Ethernet adapter, phone USB tether, or local console plus a pre-copied closure.
Unknown Wi-Fi credentials should be entered locally through `nmtui`/`nmcli
--ask`; do not commit a PSK. If first-boot autoconnect is required, stage a
root-only NetworkManager keyfile only after SSH transport authentication is
fixed, or decrypt an age-encrypted per-host profile into `/run`.

## 5. Facter + NetworkManager claim upheld, but it is not a current bug

At exact Nixpkgs, the Facter networking module gives every detected physical
interface `useDHCP = mkDefault true`
([exact source](https://github.com/NixOS/nixpkgs/blob/d407951447dcd00442e97087bf374aad70c04cea/nixos/modules/hardware/facter/networking/default.nix#L24-L68)).
NetworkManager sets global `networking.useDHCP = false`, but dhcpcd enables when
any interface has `useDHCP == true`
([exact dhcpcd source](https://github.com/NixOS/nixpkgs/blob/d407951447dcd00442e97087bf374aad70c04cea/nixos/modules/services/networking/dhcpcd.nix#L19-L24)).
The earlier minimal exact-pin evaluation realized both NetworkManager and
dhcpcd. Current Nixpkgs `HEAD` retains all three expressions, so no newer
upstream semantic change refutes the finding.

But the current repo has no `hardware.facter.reportPath`; exact service
evaluation shows NetworkManager and wpa_supplicant only. The correct conclusion
is an enrollment assertion:

```nix
hardware.facter.detected.dhcp.enable = false;
networking.networkmanager.enable = true;
```

for a NetworkManager workstation, plus a check that `systemd.services` contains
no dhcpcd. A server role may deliberately make a different exclusive ownership
choice. Facter remains useful for device/driver/microcode facts; it must not
silently choose a second L3 owner.

## 6. Installed SSH and bootstrap authentication

Exact evaluation gives:

- `PermitRootLogin = "prohibit-password"`;
- `PasswordAuthentication = true`;
- `KbdInteractiveAuthentication = true`;
- identical authorized-key sets for root and the normal user; and
- the normal user in `wheel`, `docker`, `networkmanager` and Nix
  `trusted-users`.

The duplicate root authorization remains undesirable: it bypasses normal-user
logging, password-protected sudo, PAM policy and account-specific restrictions.
But the same private-key compromise already reaches multiple root-equivalent
interfaces through the normal account. A complete hardening story must decide
whether this is an intentionally trusted administrator. Removing only the root
key while leaving unrestricted Docker and Nix trusted-user authority is useful
defense-in-depth, not a strong least-privilege boundary.

The bootstrap activation logic itself is careful. It validates a single
yescrypt verifier, numeric root ownership, modes and ordering; it replaces the
duplicate file with `!` only after `/etc/shadow` contains the exact verifier
(`modules/nixos/bootstrap-password.nix:10-124`). What it does **not** do is
expire, rotate or lock the actual shadow password. With mutable users, that
password remains until the user changes it, and current SSH accepts it.

Lowest-risk personal-host sequence:

1. keep the first password only long enough for one attended local login;
2. require a change at first login (`chage -d 0`) after install;
3. prove local login, sudo and normal-user key login;
4. set SSH password and keyboard-interactive auth false and root login `no`;
5. retain a documented physical/recovery path before locking any password.

Do not automatically lock the only sudo-capable account before proving recovery.

## 7. Runtime-secret findings recalibrated

### Current tracked provider credential

A non-empty provider API credential is tracked in a Noctalia settings file and
is present in public history/store material. No value or validity test was used
here. The official [Wallhaven API v1 documentation](https://wallhaven.cc/help/api)
says the key grants basic GET access to user settings, NSFW results and private
collections and can be regenerated. No documented mutation endpoint was found.

Final classification: current medium confidentiality exposure, potentially
sensitive depending on private collections/settings; not demonstrated account
control. Regenerate it first, review provider activity, remove current copies,
then decide whether history rewriting is worth its coordination cost.

### Agenix

`age.secrets` evaluates to `{}`. `modules/nixos/secrets.nix:5-7` configures the
everyday SSH identity as a future decryption identity, but no current secret is
activated and the bootstrap helper does not stage that private key. The correct
claim is conditional: before enabling age secrets, use a unique per-host
recipient plus recovery recipient and keep decrypted material in runtime paths.
There is no current active agenix plaintext to remediate.

### `sync-secrets` and standalone plaintext

The generated `sync-secrets` app interpolates `${self}/secrets` as its rsync
destination (`modules/flake/apps.nix:231-280`), so it targets an immutable Nix
store source. This is a confirmed functionality defect. It does not by itself
publish a new secret because the write fails. Making ignored plaintext visible
to Nix is not the fix: Nix source coercion can put it in the store. The minimal
repair is an explicit/canonical runtime worktree destination, tracked
ciphertext, and runtime decryption/copy outside evaluation.

## Minimal operational contract without fleet-grade overengineering

For this user's next attended laptop install, the smallest defensible contract
is:

1. **Boot a checksum-verified physical NixOS/custom ISO.** Prefer console-local
   installation or a physically controlled direct Ethernet link. This avoids
   default kexec entirely.
2. **Patch/pin nixos-anywhere's SSH option order before using it remotely.** At
   the laptop console, record the ED25519 host fingerprint; make a private
   known-hosts file and prove mismatch fails before invoking the helper.
3. **Create one named host leaf.** Commit a sanitized exact-pin Facter report or
   reviewed hardware configuration, a stable by-id Disko target, explicit boot
   mode and architecture. For NetworkManager, disable Facter's DHCP owner.
4. **Keep wipe confirmation attended.** Immediately before Disko, compare
   by-id resolution, model, serial/WWN where available, size, transport,
   removability and mount ancestry. A signed manifest is optional for this
   attended case; a reviewed host-local record is not.
5. **Bake recovery tools and a network escape hatch.** Include pciutils,
   usbutils, iw, rfkill, ethtool and NetworkManager CLI; test USB Ethernet or
   tethering. A repository on USB without the target closure/firmware is not an
   offline recovery image.
6. **Use `--copy-host-keys` only after authenticating the starting key.** Stop
   before reboot and compare the staged final public fingerprint. Do not
   preserve a disposable ISO key unless it is intentionally the durable host
   identity.
7. **First boot is attended.** Verify hardware, Wi-Fi scan/association,
   NetworkManager-only ownership, SSH policy, password rotation, sudo, and
   rollback before declaring the host enrolled.

Use the signed, expiring install manifest from Wave 2 only for unattended
installs, repeated fleet work, hostile networks or strong auditability. It is a
good high-assurance design, but not the minimum fix for one physical laptop.

## Residual physical tests — repository evidence cannot replace these

### Hardware and Wi-Fi

Run from a console with the recovery tools already in the closure; capture only
non-secret output:

```text
uname -m
cat /etc/os-release
ip -br link
find /sys/class/net -maxdepth 1 -mindepth 1 -printf '%f\n'
lspci -nnk
lsusb -t
rfkill list
iw dev
nmcli radio all
nmcli -f DEVICE,TYPE,STATE,CONNECTION device
systemctl is-active NetworkManager wpa_supplicant dhcpcd
journalctl -b -k --no-pager   # review driver, firmware and rfkill failures
```

Acceptance:

- exact WLAN controller/USB ID and bound driver recorded;
- WLAN netdev exists before judging NetworkManager profiles;
- no unresolved firmware-load errors;
- regulatory domain is correct;
- NetworkManager is the sole L3 owner and dhcpcd is absent;
- scans show networks, association/DHCP/DNS work, autoconnect survives reboot;
- suspend/resume and rfkill toggle do not lose the adapter; and
- tested Ethernet/tether fallback works.

### Installer identity and artifact

- compare console-derived ED25519 fingerprint with the private known-hosts
  record before the first helper command;
- deliberately use a wrong fingerprint and prove the patched helper stops;
- if kexec is used, compare the local file's flat SHA-256 with a pre-approved
  value and prove a one-byte mutation stops before upload;
- compare host fingerprint before kexec, after kexec, staged under `/mnt`, and
  after final boot;
- verify direct installer detection actually skipped the kexec download rather
  than assuming it did.

### Disk/host intake

- compare Facter with `lspci -nnk`, `lsusb`, `lsblk`, `/dev/disk/by-id`, boot
  mode and `nixos-generate-config --show-hardware-config`;
- verify the selected stable disk ID, resolved node, model, serial/WWN, size,
  transport, removable bit and descendants immediately before Disko;
- prove the running ISO/USB and every mounted valuable filesystem are excluded;
- verify generated initrd contains the actual root/storage driver;
- boot the installed generation and at least one rollback generation.

### SSH, password and secrets

- `sshd -T` must show the intended final root/password/keyboard-interactive
  policy;
- normal-user key login and sudo must succeed before console access is closed;
- root key login and password SSH must fail after hardening;
- `passwd -S`/`chage -l` must prove the bootstrap password was changed or
  deliberately locked without revealing any hash;
- provider-side credential regeneration and activity review remain external
  actions and were not verified;
- redacted current-tree/full-history secret scans must report metadata only;
- when agenix is later enabled, prove plaintext absent from the target closure,
  logs, argv and environment, and prove runtime owner/mode/cleanup.

## Evidence boundary

**Directly verified here:** current upstream hashes; current issue/release
states; exact/current source semantics; fresh SSH first-value experiment; exact
Nix evaluation of current services, SSH settings, key-set equality, privileged
groups, trusted users and empty active age-secret set; official provider API
scope; no production diff caused by this lane.

**High-confidence inference:** a missing Wi-Fi profile cannot remove a WLAN
netdev; an authenticated VPN or console-local path removes/reduces the network
MITM precondition; default kexec cannot preserve a Wi-Fi link when it restores
only L3 state into networkd; user-key compromise already crosses root-equivalent
Docker/Nix authority in this exact policy.

**Not verified:** the user's physical WLAN controller/driver/firmware; live
rfkill/regulatory state; an end-to-end patched strict-host install; actual
`--copy-host-keys` behavior on this laptop; any provider-side credential
rotation; post-install password aging; a physical Facter report; USB Ethernet;
Wi-Fi across suspend; or a sacrificial destructive install.

## EXPAND

- LEAD: physical WLAN intake — WHY: only `lo`/`docker0` cannot be resolved from
  generic config — ANGLE: PCI/USB ID, driver, firmware journal, rfkill, kernel
  comparison and fallback adapter.
- LEAD: minimal strict-source patch — WHY: current upstream HEAD still defeats
  caller host-key options — ANGLE: reorder SSH arguments, bounded retries,
  mismatch/continuity integration test without a fleet manifest.
- LEAD: direct-ISO console workflow — WHY: simultaneously removes unchecked
  kexec and network MITM — ANGLE: checksum, USB closure/cache, local Disko
  preflight and rollback proof.
- LEAD: first-boot acceptance — WHY: firmware, radio, suspend and auth are
  physical runtime properties — ANGLE: one executable redacted checklist stored
  per named host.
- LEAD: provider rotation — WHY: source cleanup cannot revoke a disclosed API
  key — ANGLE: authenticated user action and activity review; never test the old
  credential.

## CLAIMS

- **C-W3-N1 (confirmed, critical conditional):** exact/current
  nixos-anywhere places disabled host verification before caller options, and
  OpenSSH first-value semantics makes appended strict options ineffective.
- **C-W3-N2 (confirmed, high conditional):** default kexec executes a mutable
  release artifact without digest verification; a recognized direct NixOS
  installer or install-only phase avoids that artifact path.
- **C-W3-N3 (confirmed):** `--copy-host-keys` provides tested identity
  continuity, not initial identity authentication; impermanence and disposable
  ISO keys require explicit destination/identity policy.
- **C-W3-N4 (confirmed and narrowed):** upstream default remote/kexec Wi-Fi is
  unsupported, while the installed output has a coherent generic
  NetworkManager+wpa_supplicant+redistributable-firmware stack.
- **C-W3-N5 (confirmed):** only `lo` and `docker0` cannot be caused merely by a
  missing SSID profile; physical controller/driver/firmware/rfkill/kernel
  diagnosis remains mandatory.
- **C-W3-N6 (confirmed, prospective):** importing a Facter report into the
  NetworkManager role without disabling Facter DHCP starts dhcpcd at exact pin
  and current Nixpkgs; the current no-Facter output does not have this collision.
- **C-W3-N7 (confirmed with downgraded marginal severity):** root and the normal
  user authorize the same key, but the normal user already has root-equivalent
  Docker/Nix/admin boundaries; remove direct root login as part of complete SSH
  hardening, not as a standalone least-privilege claim.
- **C-W3-N8 (confirmed):** verifier-file consumption is robust, but the installed
  shadow password is neither rotated nor expired and SSH password methods remain
  enabled.
- **C-W3-N9 (confirmed and recalibrated):** the tracked provider key is a current
  medium confidentiality disclosure under documented read-only API v1 scope;
  no account takeover or current validity was established, and regeneration is
  still required.
- **C-W3-N10 (confirmed latent):** current agenix activates no secrets; everyday
  login-key coupling becomes a risk only when secrets are enabled. The current
  `sync-secrets` store-destination bug is functional, not by itself a new leak.
