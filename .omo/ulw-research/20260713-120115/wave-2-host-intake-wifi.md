# Wave 2 — host/role/Facter intake and Wi-Fi handoff

**Scope.** This lane derives a target-intake architecture for the repository at
`e9f78180748f1feb428ffb20f9d932c5d9918a48`; it does not edit production
configuration. Upstream behavior is tied to the repository's actual root
Nixpkgs lock, `d407951447dcd00442e97087bf374aad70c04cea`, and its packaged
`nixos-facter` 0.4.4. Claims about future Nixpkgs revisions require re-testing.

## Executive decision

“Works on any machine” cannot mean one architecture-named NixOS closure with a
single bootloader, Disko layout, and generic set of modules. It can reasonably
mean:

1. one repository with shared policy and roles;
2. one concrete output per enrolled physical/virtual host;
3. a mandatory, non-destructive target intake before any Disko action;
4. a sanitized Facter snapshot plus a reviewed exact-model `nixos-hardware`
   profile where one exists;
5. explicit per-host boot, storage, proprietary-driver, radio, power, and
   suspend decisions; and
6. a test matrix that refuses to call a host ready until both build-time and
   physical runtime probes pass.

The current outputs do not meet that contract. `modules/entities/hosts.nix:7-15`
defines only `x86_64-linux` and `aarch64-linux`, and both select the same
`nixos-workstation` aspect. That aspect unconditionally includes one shared
storage profile (`modules/aspects/hosts/nixos-workstation.nix:3-13`), while the
shared NixOS baseline assumes systemd-boot/UEFI, a small generic initrd list, the
latest kernel, I2C and Ledger hardware (`modules/nixos/system.nix:8-27,235-245`).
The AArch64 output therefore describes an architecture, not a supported ARM
board/boot chain.

## Evidence from exact evaluation

I evaluated the current `x86_64-linux` output, rather than inferring from source:

| Property | Current result |
|---|---|
| `networking.hostName` | `nixos` |
| `nixpkgs.hostPlatform.system` | `x86_64-linux` |
| `networking.networkmanager.enable` | `true` |
| `networking.wireless.enable` | `true` (NetworkManager owns a DBus-controlled wpa_supplicant) |
| `networking.wireless.iwd.enable` | `false` |
| `hardware.enableRedistributableFirmware` | `true` |
| `hardware.enableAllFirmware` / `enableAllHardware` | both `false` |
| Intel / AMD microcode update | both `false` |
| wireless regulatory database | `true` |
| bootloader | systemd-boot, `efi.canTouchEfiVariables = true` |
| kernel | 7.1.3 from `linuxPackages_latest` |
| Facter report | absent |
| NetworkManager declarative profiles / secret entries | empty |

The current NetworkManager result is internally coherent: at the exact pin,
NetworkManager sets global `networking.useDHCP = false`, enables a DBus-controlled
wpa_supplicant when iwd is not selected, and stores imperative profiles in
`/etc/NetworkManager/system-connections`. See the exact
[`networkmanager.nix`](https://github.com/NixOS/nixpkgs/blob/d407951447dcd00442e97087bf374aad70c04cea/nixos/modules/services/networking/networkmanager.nix#L2901-L2946).
Thus `networking.wireless.enable = true` is not evidence of a second independent
Wi-Fi owner in this configuration.

### Newly demonstrated Facter + NetworkManager conflict

NixOS Facter is valuable, but its DHCP policy must be disabled for NetworkManager
roles. I instantiated the exact locked NixOS module set with a minimal Facter v2
report containing one Ethernet interface and `networking.networkmanager.enable =
true`. The evaluated result was:

```json
{
  "facter": true,
  "nm": true,
  "globalDHCP": false,
  "interfaceDHCP": true,
  "dhcpcdOption": true,
  "dhcpcdService": true,
  "microcode": true
}
```

Cause: the exact Facter module assigns per-interface `useDHCP = mkDefault true`,
while NetworkManager only forces the global default false. The dhcpcd module
starts if *any* interface explicitly enables DHCP. This gives two managers for
the same physical interface. The official Facter documentation says it
configures DHCP on detected interfaces, and the locked source confirms it;
NetworkManager separately owns DHCP. Therefore every NetworkManager host using
Facter needs:

```nix
hardware.facter.detected.dhcp.enable = false;
networking.networkmanager.enable = true;
```

and a regression assertion that `systemd.services` has no `dhcpcd`. A server
role using networkd/dhcpcd can make the opposite choice, but ownership must be
exclusive. This is an exact-pin empirical result, not a speculative warning.

## Concrete repository architecture

### Composition layers

Use four deliberately separate layers:

1. **Cross-machine policy** — Nix settings, common users, locale, SSH policy,
   fonts and theme assets. No bootloader, storage controller, GPU driver, radio,
   hardware daemon or power policy belongs here.
2. **Role** — e.g. `linux-workstation-niri`, `headless-server`, `vm-guest`.
   The workstation role owns NetworkManager, Niri, audio and desktop services.
   A network role must exist independently of the compositor so local/network
   recovery is not coupled to a graphical session.
3. **Host hardware leaf** — one named host, one sanitized Facter report, exact
   host platform, optional exact `nixos-hardware` model, initrd/driver overrides,
   microcode, GPU policy, radios, suspend/power quirks and assertions.
4. **Host storage/boot leaf** — Disko topology, UEFI/legacy/SBC boot mechanism,
   ESP/swap/hibernation/encryption decisions. Disk selection remains an
   attended install input; do not infer a destructive target from architecture.

A conceptual Den composition is:

```nix
# modules/entities/hosts.nix
x86_64-linux.laptop-model-serialless-name = {
  aspect = den.aspects.laptop-model-serialless-name;
  hostName = "laptop-model-serialless-name";
  users.mei = { };
};

# host aggregate
includes = [
  den.aspects.linux-workstation-niri
  den.aspects.laptop-model-serialless-name-hardware
  den.aspects.laptop-model-serialless-name-storage
];

# hardware leaf (shape only)
hardware.facter.reportPath = ./facter.sanitized.json;
hardware.facter.detected.dhcp.enable = false; # NetworkManager is sole owner
# imports = [ inputs.nixos-hardware.nixosModules.<exact-model> ];
```

Output names must be concrete host identities, not `x86_64-linux` and
`aarch64-linux`. Add an assertion that `hardware.facter.report.system` equals the
entity's system. Facter can set `nixpkgs.hostPlatform` with `mkDefault`, but it
must not silently select a different architecture from the output.

### Facter's boundary

The locked Nixpkgs documentation says a Facter report configures platform,
redistributable firmware and bare-metal microcode, storage/input initrd modules,
guest integration, graphics, detected-interface DHCP, Bluetooth, some
fingerprint readers and Intel IPU6 cameras. See the exact
[Facter module documentation](https://github.com/NixOS/nixpkgs/blob/d407951447dcd00442e97087bf374aad70c04cea/nixos/modules/hardware/facter/facter.md#what-gets-configured-module-hardware-facter-features)
and upstream [`nixos-facter` v0.4.4](https://github.com/nix-community/nixos-facter/tree/v0.4.4).
It does **not** safely decide:

- which physical disk to erase or the desired filesystem/encryption/swap layout;
- which bootloader to enable (the locked boot module only defaults GRUB's EFI
  support when the report says the scanner booted via UEFI);
- Secure Boot key/enrollment policy;
- an ARM board's U-Boot/firmware/device-tree/image pipeline;
- proprietary NVIDIA vs nouveau, or hybrid PRIME bus IDs (the locked graphics
  module explicitly removes `nouveau` and does not auto-select proprietary
  NVIDIA);
- nonredistributable Broadcom/B43 firmware;
- laptop power policy, hibernation sizing or verified suspend mode;
- complete dock/hotplug inventory when the device was absent during scanning.

The official NixOS manual likewise warns that root-filesystem initrd modules are
machine-specific and says `nixos-generate-config` normally discovers them
([manual installation](https://nixos.org/manual/nixos/stable/#sec-installation-manual)).
Use `nixos-generate-config --show-hardware-config` as an independent cross-check
of Facter's root/storage modules, not as a second unreviewed hardware authority.

### Facter privacy and reproducibility gate

A raw Facter report is not safe to commit to this public flake. Version 0.4.4
collects system/board/chassis/memory/disk/device serial fields and detailed
hardware resources. `reportPath` is a Nix path, so the report is copied into the
Nix store; a `.gitignore` rule alone does not make its contents private.

The intake pipeline should:

1. generate the raw report as root in a mode-0700 tmpfs directory using the
   **locked** package (`nixos-facter` 0.4.4), not an unpinned `nixpkgs#...`;
2. record the report schema version and tool version;
3. create a deterministic sanitized derivative, removing the entire unused
   `smbios` subtree at this exact Nixpkgs revision and recursively rejecting
   identifiers such as serial/asset/UUID/MAC/hardware-address fields;
4. retain vendor/device/subsystem IDs, class, driver modules, bus type, interface
   names, architecture, virtualization and UEFI facts needed by the locked
   modules;
5. reject the result if a forbidden-key/value scan finds a persistent identifier;
6. evaluate the host, run Facter's `debug.nvd`/`debug.nix-diff`, and compare the
   detected driver decisions with the raw report before destroying the raw file;
7. re-audit which report fields Nixpkgs consumes whenever the Nixpkgs pin changes.

Deleting `smbios` is justified only for the exact locked source: a source scan of
`nixos/modules/hardware/facter` found no consumer of `report.smbios`. Future
module revisions may change that.

### `nixos-hardware` profile selection

Add `NixOS/nixos-hardware` as a locked input only after enrollment identifies an
exact model. Its own README instructs flakes to import a named model module
([repository](https://github.com/NixOS/nixos-hardware)); the master observed in
this lane was `8efb4337e857949f4cfac86d12ef1066f417f31f`.

Selection rules:

- match manufacturer **and exact product/model**, then inspect the module;
- never select a “nearby” laptop merely by CPU generation;
- treat Facter as detected generic drivers and `nixos-hardware` as reviewed
  model quirks; diff their combined effects;
- do not stack broad common CPU/GPU profiles unless their settings are absent
  from, or intentionally override, Facter;
- record why the profile applies and the tested BIOS/firmware revision;
- a missing model profile is not failure: keep a host leaf with explicit quirks.

## Mandatory target intake

Run before patching Disko or installing. Raw outputs containing serials/MACs stay
local and are not pasted into public issues or committed.

### Facts required

| Domain | Required facts / decision |
|---|---|
| Identity | non-sensitive host name; manufacturer/product; BIOS/UEFI revision; Facter v2 snapshot date |
| Platform | `uname -m`; Facter `system`; bare metal/VM; x86_64 vs aarch64; for ARM, exact board and boot firmware |
| Boot | whether the installer was booted UEFI; EFI platform size; firmware UEFI capability; Secure Boot state; desired bootloader; ESP size/location; NVRAM write ability |
| Storage | `lsblk` topology; stable by-id candidates; controller and driver; RAID/LVM; desired LUKS/filesystem; swap/hibernation; explicit attended erase target |
| CPU | vendor/family/model; required Intel/AMD microcode; virtualization/IOMMU; thermals |
| PCI/USB | numeric vendor:device and subsystem IDs, bound driver and candidate module; USB VID:PID for Ethernet, radios, fingerprint, camera and dock |
| GPU/display | every GPU and bound driver; hybrid topology and bus IDs; internal/external displays; proprietary-driver decision; Wayland boot test |
| Network/radios | every Ethernet/WLAN/WWAN/Bluetooth controller, interface, driver, firmware messages, rfkill state and regulatory country; known fallback adapter |
| Firmware | missing-firmware kernel messages; redistributable closure baseline; each nonredistributable exception with device ID/license/reason |
| Power/suspend | chassis/battery; `/sys/power/mem_sleep`; suspend/resume result; wake devices; hibernation requirement and resume target; chosen power daemon |
| Peripherals | audio codec, touchpad/touchscreen, keyboard, webcam/IPU6, fingerprint, smartcard/ledger, Thunderbolt/dock, printer if required |

Minimum non-secret probe set on the live target is Facter plus `lspci -nnk`,
`lsusb`, `lsblk`, `/dev/disk/by-id`, `rfkill`, `nmcli device`, `iw dev`,
`journalctl -b -k` filtered for firmware/driver failures, `bootctl status`, Secure
Boot state, `/sys/power/mem_sleep`, and a suspend/resume trial. Do not rely on
`lspci` being preinstalled in the eventual closure; make hardware diagnostics an
explicit recovery package set or use the installer environment.

Facter detects whether the *running scanner* booted via UEFI, not whether the
machine is merely UEFI-capable. Enrollment must deliberately boot the installer
in the intended mode before recording the report.

## Firmware and driver policy

### Shared safe baseline

Keep `hardware.enableRedistributableFirmware = true` and the wireless regulatory
database for physical workstation roles. At the exact pin this includes
`linux-firmware`, Intel/Realtek/ALSA/SOF and other redistributable firmware.
Facter also defaults redistributable firmware and the correct Intel or AMD
microcode update on bare metal.

Do **not** use `hardware.enableAllHardware` as the installed-host solution. The
locked source describes it as primarily an installer-image profile and adds a
large catch-all initrd module list; it does not solve board boot chains, model
quirks, NVIDIA selection or every firmware license. The stable manual says the
same ([All Hardware profile](https://nixos.org/manual/nixos/stable/#sec-profile-all-hardware)).

### Nonredistributable opt-in

At this exact pin `hardware.enableAllFirmware = true` adds only a bounded set
including Broadcom Bluetooth, two B43 firmware generations, Xone dongle firmware
and x86 FaceTime HD firmware, and requires unfree allowance. It is not a generic
“all drivers work” switch. Prefer a host capability that names the exact package
or module, device PCI/USB ID, license consequence and regression test. Examples
such as Broadcom `wl` require `broadcom_sta` and matching kernel modules and must
be tested against the selected kernel; the NixOS manual shows that pattern in
its installer-image discussion.

The repository currently has global `allowUnfree = true`, `allowBroken = true`
and `allowUnsupportedSystem = true` (`lib/nixpkgs.nix:41-47`). That is the
opposite of a fail-closed portability baseline. Hardware exceptions should move
toward narrow `allowUnfreePredicate`/host policy; broken or unsupported packages
must not silently become the universal default.

## Network ownership and Wi-Fi handoff

### Installed-system baseline

Move NetworkManager ownership out of the Niri implementation module
(`modules/nixos/niri.nix:13-19`) into a workstation-network role. Required
settings/constraints:

- NetworkManager is sole L3/DHCP owner; set Facter detected DHCP off.
- Keep the user in `networkmanager`; keep a root/local TTY recovery path.
- Use the default wpa_supplicant backend unless a tested host capability selects
  iwd; do not configure both as independent owners.
- Do not bind profiles to interface names unless necessary; firmware/dock changes
  can change predictable names.
- Built-in Ethernet, USB Ethernet and phone USB tether should be auto-managed by
  NetworkManager. Enrollment records their driver/firmware and tests at least one
  as the no-Wi-Fi escape hatch.

The NixOS manual recommends NetworkManager plus user membership for desktop
Wi-Fi and documents `nmcli`/`nmtui`
([Networking](https://nixos.org/manual/nixos/stable/#sec-networking)).

### Default, lowest-risk handoff

Use wired Ethernet, a known-good USB Ethernet adapter, phone USB tethering, or a
local installer console for installation. On first boot, log in locally and run
`nmtui`/`nmcli` as the NetworkManager-authorized user. The resulting root-only
keyfile lives in `/etc/NetworkManager/system-connections`, outside the Nix store.
This is the safest default because the credential never leaves the target.
“Immediate usability” is satisfied by guaranteed console access and a tested
fallback adapter, not by embedding every site credential in the flake.

### Seamless installer-Wi-Fi-to-first-boot handoff

If the same Wi-Fi must reconnect before first login:

1. Connect in the live ISO with `nmtui` and prove DNS/routing.
2. Identify the single active system connection without displaying secrets.
3. Copy its root-owned keyfile over an authenticated, host-key-verified channel
   into a mode-0700 directory on **tmpfs** on the working computer. Do not use a
   shell argument, environment variable, debug trace or terminal output for the
   PSK.
4. Verify only metadata and structure: regular file, no symlink, owner, mode
   0600, expected SSID/UUID, autoconnect, and that a secret field exists. Never
   print the value.
5. Stage it through the installer's extra-files mechanism as
   `/etc/NetworkManager/system-connections/install-wifi.nmconnection`, owner
   `0:0`, mode `0600`. The exact Nixpkgs module declares this directory as the
   persistent keyfile path and creates it mode 0700
   ([source](https://github.com/NixOS/nixpkgs/blob/d407951447dcd00442e97087bf374aad70c04cea/nixos/modules/services/networking/networkmanager.nix#L1736-L1742)).
6. Ensure the connection is system-wide (`permissions` empty), autoconnecting,
   and has an NM-owned saved secret (`psk-flags = 0`). Agent-owned (`1`) or
   not-saved (`2`) credentials cannot reconnect unattended; the meanings are in
   NetworkManager's official
   [secret flags](https://networkmanager.dev/docs/api/latest/nm-settings-nmcli.html#secrets).
7. On first boot verify autoconnection without revealing the credential, then
   securely erase the working tmpfs staging directory through an unconditional
   trap.

This is a credential transfer and is safe only after fixing/avoiding the current
nixos-anywhere transport that disables strict host-key checking. Otherwise an
active LAN attacker can receive the profile. When authenticated transfer cannot
be guaranteed, fall back to local first-boot `nmtui`.

### Declarative long-term alternative

If declarative profiles are required, never write a literal PSK into Nix. The
manual explicitly warns that literal wireless keys become world-readable in the
Nix store and recommends runtime secret files
([manual warning](https://nixos.org/manual/nixos/stable/#sec-wireless-declarative)).
At the exact pin, `networking.networkmanager.ensureProfiles` supports
`environmentFiles`; it creates a root-only runtime profile in
`/run/NetworkManager/system-connections` with `envsubst` and UMask 0177
([exact source](https://github.com/NixOS/nixpkgs/blob/d407951447dcd00442e97087bf374aad70c04cea/nixos/modules/services/networking/networkmanager.nix#L2853-L2897)).
An agenix-decrypted `/run/agenix/...` environment file can therefore supply the
PSK without the value entering the Nix store. Alternatively, the locked module
also exposes `ensureProfiles.secrets.entries` backed by
`nm-file-secret-agent`; test service ordering before adopting it.

Negative rules:

- no `psk = "literal"`, password, private key or environment secret value in a
  Nix expression;
- no `builtins.readFile` of a plaintext secret (that still copies content into a
  derivation/store path);
- no actual credential in test fixtures; use a canary and prove it is absent from
  the closure;
- boot must reach a usable local TTY even if secret decryption or Wi-Fi fails;
- enterprise Wi-Fi must validate CA/domain matching; do not trade connectivity
  for disabling server authentication.

## Wired, USB Ethernet and offline closure

A physical fallback is mandatory for each enrolled laptop: built-in Ethernet,
a specifically tested USB Ethernet adapter, or USB tether. Record VID:PID,
driver and firmware, and test both the installer ISO and installed closure.
NetworkManager normally autoconfigures these without static interface names. For
a direct cable with no DHCP, assign temporary static addresses in the installer
and working computer; Internet is not necessary for SSH if the complete closure
is already local.

A USB containing only this Git repository is **not** an offline installation
artifact. A reproducible offline kit must contain:

1. a clean repository snapshot and lock file;
2. archived flake inputs;
3. the exact named host's fully built system closure;
4. the pinned nixos-anywhere/Disko installer tooling closure (or a custom ISO
   that contains the host's firmware and SSH bootstrap path);
5. metadata/checksums and enough free space;
6. a tested transport path between working computer and target.

A suitable preparation flow is conceptually:

```bash
host=concrete-host
store="file:///media/$USER/ventoy/nix-offline-store"
system=$(nix build --no-link --print-out-paths \
  ".#nixosConfigurations.$host.config.system.build.toplevel")
nix flake archive --to "$store" .
nix copy --to "$store" "$system"
# Also realize/copy the exact pinned installer command used by the helper.
nix path-info --store "$store" -r "$system" >/dev/null
nix build --offline --no-link \
  ".#nixosConfigurations.$host.config.system.build.toplevel"
```

The final test must be performed without network access and, ideally, from a
fresh/empty test store or VM; a successful `--offline` build against an already
warm normal store is not proof that the USB is complete. For a remote
nixos-anywhere run, build on the working machine and upload the complete closure
with destination substitution disabled. For a target-local install, import/copy
from the USB file store before Disko. The installer still needs a physical link
for remote SSH; direct Ethernet/static IP is sufficient.

## Acceptance and negative tests

### Evaluation/build gates per host

- named output exists and builds; entity system equals sanitized Facter system;
- report schema/tool version is expected and forbidden persistent identifiers
  are absent;
- raw Facter report is neither tracked nor referenced by a Nix path;
- Facter enabled; for NetworkManager roles, detected DHCP disabled,
  `networking.useDHCP = false`, no dhcpcd service, one Wi-Fi backend;
- correct bare-metal CPU microcode option is true;
- root/controller/input initrd drivers match Facter and the independent generated
  hardware config;
- exact bootloader and disk layout match enrolled boot mode; ARM board outputs
  have a real board boot path, not the x86 UEFI role;
- redistributable firmware/regdb present; `enableAllFirmware` false unless a
  documented host exception exists;
- proprietary GPU/Wi-Fi driver exception names device ID, package, kernel and
  license policy;
- no secret canary appears in flake source, derivations, closure strings or logs;
- offline kit can reconstruct/build the named host from a cold test environment.

### VM/negative scenarios

- missing report, wrong architecture, unsupported report version or raw serial
  key fails evaluation;
- synthetic Facter interface + NetworkManager must fail the test if it causes a
  dhcpcd unit (the demonstrated regression);
- BIOS VM rejects the UEFI/systemd-boot host profile; 32-bit EFI is not claimed
  by a 64-bit-only boot contract;
- absent/wrong Disko target fails before destructive phases;
- missing runtime Wi-Fi secret causes a clear NetworkManager service/profile
  failure but not a boot/login failure;
- profile with mode other than 0600, symlink, user ownership, agent-owned secret
  or no autoconnect is rejected by handoff validation;
- no detected WLAN interface or unresolved firmware error blocks the “Wi-Fi
  ready” claim rather than silently passing because NetworkManager is enabled.

### Physical post-install gates

- local TTY login before relying on graphical or network services;
- `lspci -nnk`/`lsusb` show expected drivers; kernel log has no unresolved
  required-firmware error;
- Ethernet DHCP, tested USB fallback, Wi-Fi scan/association/DNS, Bluetooth (if
  enrolled), rfkill and regulatory domain work;
- reboot preserves Wi-Fi autoconnect without prompting or leaking a secret;
- Niri session, graphics acceleration, audio, brightness/input and external
  display work;
- suspend/resume repeated with Wi-Fi reconnection, audio, input and display;
- hibernation tested only when the host has an explicit swap/resume design;
- unplug/replug dock/USB Ethernet and cold boot at least once.

A build or VM pass is necessary but never sufficient for firmware, radios,
power, suspend, display or device hotplug.

## Priority recommendations for the parent synthesis

1. **P0:** stop treating architecture outputs as hosts; require enrollment and
   concrete host leaves before another physical install.
2. **P0:** when adding Facter to NetworkManager hosts, disable Facter DHCP and
   assert dhcpcd is absent.
3. **P0:** do not commit a raw Facter report; sanitize persistent identifiers
   before it becomes a Nix path/store object.
4. **P0:** provide an authenticated Wi-Fi-profile handoff or default to local
   `nmtui`; never move a credential over the current host-key-disabled path.
5. **P1:** split shared role from boot/storage/hardware and add exact-model
   `nixos-hardware` only where reviewed.
6. **P1:** keep redistributable firmware as baseline; make nonredistributable
   firmware/driver exceptions per-host and narrow the current global unfree,
   broken and unsupported allowances.
7. **P1:** require a tested Ethernet/USB fallback and build a real offline closure
   kit, not merely a repository copy.
8. **P1:** make runtime hardware/suspend/network probes a host readiness record;
   CI cannot certify physical hardware it never sees.

## Sources and reproducibility anchors

- Repository revision: `e9f78180748f1feb428ffb20f9d932c5d9918a48`
- Root Nixpkgs lock: `d407951447dcd00442e97087bf374aad70c04cea`
- Packaged nixos-facter: v0.4.4, tag object observed as
  `a38166d79211bdae03c44ecda8a07328a942921f`
- [NixOS stable manual: installation/networking/Facter/profiles](https://nixos.org/manual/nixos/stable/)
- [Exact locked Facter module documentation](https://github.com/NixOS/nixpkgs/blob/d407951447dcd00442e97087bf374aad70c04cea/nixos/modules/hardware/facter/facter.md)
- [Exact locked Facter networking module](https://github.com/NixOS/nixpkgs/blob/d407951447dcd00442e97087bf374aad70c04cea/nixos/modules/hardware/facter/networking/default.nix)
- [Exact locked Facter firmware module](https://github.com/NixOS/nixpkgs/blob/d407951447dcd00442e97087bf374aad70c04cea/nixos/modules/hardware/facter/firmware.nix)
- [Exact locked firmware set](https://github.com/NixOS/nixpkgs/blob/d407951447dcd00442e97087bf374aad70c04cea/nixos/modules/hardware/all-firmware.nix)
- [Exact locked NetworkManager module](https://github.com/NixOS/nixpkgs/blob/d407951447dcd00442e97087bf374aad70c04cea/nixos/modules/services/networking/networkmanager.nix)
- [NixOS/nixos-hardware](https://github.com/NixOS/nixos-hardware)
- [NetworkManager keyfile format](https://networkmanager.dev/docs/api/latest/nm-settings-keyfile.html)
- [NetworkManager settings and secret flags](https://networkmanager.dev/docs/api/latest/nm-settings-nmcli.html)

## EXPAND

- **Lead H1:** build a deterministic Facter v2 sanitizer from an allowlist of
  fields actually consumed by Nixpkgs `d407951`, then fuzz it with serial/MAC/UUID
  fixtures and prove the sanitized report still yields identical driver/module
  decisions.
- **Lead H2:** encode the demonstrated Facter-DHCP/NetworkManager collision as an
  exported flake check so a future Nixpkgs change cannot silently restore two
  network managers.
- **Lead H3:** prototype authenticated live-ISO NetworkManager keyfile handoff in
  the existing tmpfs/extra-files helper, including strict host verification,
  mode/owner/symlink validation, cleanup traps and a no-secret log audit.
- **Lead H4:** enroll the actual laptop that showed only `lo` and `docker0`:
  capture numeric controller IDs, bound/unbound driver, firmware failures and
  Facter report locally, then select its exact host capability. Configuration
  alone cannot identify absent hardware evidence.
- **Lead H5:** create a cold-store offline-kit test using Ventoy storage and a
  direct-Ethernet/USB-Ethernet install VM; merely running `--offline` against the
  warm workstation store is a false positive.
- **Lead H6:** inventory whether each physical model has an exact
  `nixos-hardware` profile and diff that profile against Facter before import.

## CLAIMS

- **C-HOST-1 (high, executed):** current Linux outputs are architecture-named and
  share one workstation/storage/UEFI aspect; they are not concrete portable host
  definitions.
- **C-HOST-2 (high, primary source):** Facter 0.4.4 plus locked Nixpkgs can supply
  generic detected hardware decisions, but not destructive disk choice, full
  boot-chain selection, proprietary NVIDIA policy or model-specific quirks.
- **C-NET-1 (high, executed):** at locked Nixpkgs `d407951`, enabling Facter with
  a detected physical interface and NetworkManager starts dhcpcd as well unless
  `hardware.facter.detected.dhcp.enable = false`.
- **C-NET-2 (high, exact source):** current NetworkManager intentionally owns a
  DBus-controlled wpa_supplicant; evaluated `networking.wireless.enable = true`
  is not a second independent Wi-Fi manager.
- **C-SEC-1 (high, source inspection):** raw Facter reports contain persistent
  identifiers and `reportPath` enters the Nix store; sanitize before tracking or
  evaluating the report.
- **C-FW-1 (high, exact source):** redistributable firmware is the correct shared
  baseline; `enableAllFirmware` is a bounded unfree set, not universal driver
  support, and should be a reviewed per-host exception.
- **C-WIFI-1 (high, primary source):** imperative NetworkManager profiles persist
  outside the Nix store; literal declarative passwords do not. Runtime secret
  files or root-only keyfile handoff are required for seamless boot without store
  leakage.
- **C-OFFLINE-1 (high, Nix semantics):** a Git checkout on USB is insufficient;
  an offline install needs archived inputs, the complete named-host closure,
  installer tooling closure and a tested physical transport.
- **C-LIMIT-1 (high):** no static research can certify Wi-Fi, suspend, GPU or
  hotplug on an unidentified physical target; those claims remain blocked until
  the physical enrollment/runtime matrix passes.
