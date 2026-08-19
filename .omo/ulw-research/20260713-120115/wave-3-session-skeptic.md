# Wave 3 — Adversarial Niri/session/portal/theme review

Research date: 2026-07-13. Production revision: `e9f78180748f1feb428ffb20f9d932c5d9918a48`. This is a skeptical re-check of the Wave 1/2 session conclusions against the exact realized x86_64 NixOS generation, exact pinned Niri/Noctalia sources, both Darwin evaluations, and the generated Home Manager files. No production files were changed.

## Executive verdict

Most of the concrete session defects survive adversarial review, but several earlier phrasings were too broad:

- The lock key, notification ownership ambiguity, OBS exit 127, missing cursor/UI-font assets, and Noctalia schema warnings are **upheld** by direct execution or realized-output inspection.
- The X11 services are **unconditionally scheduled**, not proven continuously healthy/active. Their lack of conditions and restart policies still make them defects in a Niri-only generation.
- The awww/Noctalia situation is a real dual-client/dual-surface configuration, but no repository command selects an awww image. It is P1 ambiguity/resource waste, not a demonstrated P0 visible-wallpaper failure.
- The portal split is correct for Niri screencasting, screenshots, GTK access/notification, KDE chooser/settings, and the NixOS Secret backend. However, the explicit GNOME `RemoteDesktop` selection is not backed by Niri's exact interfaces: Niri implements `org.gnome.Mutter.ScreenCast`, not `org.gnome.Mutter.RemoteDesktop`, while the GNOME backend requires the latter for input injection. “The portal split is coherent” must therefore be narrowed to the supported interfaces.
- GTK really has two policy writers. The integrated NixOS Qt settings are mostly redundant but mutually aligned on Kvantum/BeautyLine; a Qt conflict was not demonstrated and is downgraded.
- Noctalia's state override is an intentional upstream feature, not itself a defect. The defect is claiming immutable/reproducible effective settings without choosing and testing a state policy.
- Kitty's exact palette and font policy do reach both Darwin outputs, and Home Manager has a native font-copy path. macOS parity is a physical activation/CoreText proof gap, not a static configuration failure.
- The earlier duplicate-Noctalia-unit suspicion is refuted for integrated NixOS: NixOS owns the service and Home Manager owns the config; the standalone output has its own separate lifecycle.

## Evidence basis and independent replay

Exact realized artifacts re-inspected:

| Artifact | Path |
|---|---|
| NixOS system | `/nix/store/2skzh1yk3bzz5g30zxf6ngcai78m3vci-nixos-system-nixos-26.11.20260705.d407951` |
| NixOS user units | `/nix/store/4djmx9wz8s0jsmf0hpl6nln6mk46ns5n-user-units` |
| Integrated HM generation | `/nix/store/b77d20kdnbdab85v3pmnvz0nprcshshi-home-manager-generation` |
| HM files | `/nix/store/6pc2hllhb476p0h9y4cx8rw764qw3kvm-home-manager-files` |
| HM profile | `/nix/store/kci26nh1d74r87q0yjbpdpl1p98dlqp8-home-manager-path` |
| Noctalia | `/nix/store/vwfxwdszqyy4glajh8qhxwp0nywl0w7s-noctalia-5.0.0` |
| Noctalia source | `/nix/store/rwwxjm035zxwp4adhhbc3341lml5193z-source` |
| Niri source | `/nix/store/bazsf2g3j9imcrqrw18p3zn9911s7lfm-source` |

Independent executions:

1. The exact binary rejected `noctalia msg screen-lock --help` with exit 1 and listed only `session <lock|...>`.
2. The managed OBS wrapper, run with only the exact HM and NixOS profile `PATH`, exited 127 with “could not find the real OBS executable.”
3. An isolated D-Bus session with only the exact HM profile data activated `org.freedesktop.Notifications` as **Mako**, proving the duplicate activation metadata is operational rather than inert. This does not prove Mako always wins after a normal Niri login; it proves ordering matters if a notification request beats Noctalia's name acquisition.
4. Exact `noctalia config validate` exited 0 with eight warnings; the warnings are not fatal validation errors.
5. An isolated state `settings.toml` changing `[theme].mode` changed `noctalia config export merged` from dark to light, directly proving runtime settings override the declarative baseline.
6. Store-only font scanning found FiraCode Nerd Font families but no Fira Sans or Sarasa UI SC. Theme-tree scanning found no `Sweet-cursors`; `pkgs.sweet` contains GTK themes only.
7. Both `darwinConfigurations.aarch64-darwin` and `darwinConfigurations.x86_64-darwin` evaluate the same Kitty Sweet palette and `font_family = "FiraCode Nerd Font Mono"`; the ARM Darwin HM package list includes `nerd-fonts-fira-code`.

## Claim-by-claim challenge

### 1. Invalid lock command — **UPHELD, P0**

The generated bind remains `modules/linux/config/niri/config.kdl:58`:

```kdl
Super+ALT+L { spawn-sh "noctalia msg screen-lock"; }
```

The exact CLI rejects that top-level command. Pinned `src/shell/session/session_ipc.cpp` registers only the `session` handler; the valid spelling is `noctalia msg session lock`. Niri's KDL parser cannot validate an external command, so successful KDL validation is no counterexample.

The X11 idle stack is not a safety fallback for this key. It is neither invoked by `Super+Alt+L` nor capable of securely covering native Wayland surfaces. Noctalia and Niri both carry `ext-session-lock-v1`, so the intended replacement path is technically appropriate, but multi-output/hotplug/suspend behavior still requires a physical drill.

Minimal fix: replace the command; add a check that executes exact `noctalia msg --help`/source assertions and rejects `msg screen-lock`; test lock coverage on every output and after resume.

### 2. Three notification owners — **UPHELD with lifecycle nuance, P0**

The realized profile exposes three candidates for the singleton `org.freedesktop.Notifications` name:

- Noctalia is wanted by `graphical-session.target` and directly calls `RequestName(AllowReplacement|DoNotQueue)`.
- Mako publishes `fr.emersion.mako.service` for the same name.
- Dunst publishes `org.knopwob.dunst.service` and a `Type=dbus`, `BusName=org.freedesktop.Notifications` unit.

Nuance: Mako and Dunst are D-Bus-activatable; neither has a graphical-target wants link in this integrated generation. Noctalia is the only one intentionally target-started. Therefore “three daemons always start together” would be false. Nevertheless, isolated exact-profile activation selected Mako, and Noctalia's pinned code disables its notification service when another process owns the name. This is an actual startup-order hazard, not merely dead packaging.

The GTK portal `Notification` implementation is not a fourth desktop notification daemon and remains correctly excluded from this conflict.

Minimal fix: choose one owner. Given the declared Noctalia shell, remove Dunst and Mako packages/config/activation metadata from the Niri role; verify `busctl --user status org.freedesktop.Notifications` resolves to Noctalia after cold login and after Noctalia restart.

### 3. X11 services in Niri — **UPHELD but wording downgraded, P0/P1**

Realized target links unconditionally schedule:

- NixOS: `picom.service` and `noctalia.service` from `graphical-session.target`.
- HM: `xautolock-session.service`, `xss-lock.service`, and `udiskie.service` from `graphical-session.target`.
- `udiskie.service` requires `tray.target`, whose wants include `polybar.service`.

No Picom/xautolock/xss-lock unit contains `ConditionEnvironment`, compositor checks, or a Niri exclusion. Picom, xautolock, and xss-lock use restart policies. However, whether they reach and remain `active` depends on when `DISPLAY` and Xwayland-satellite become usable. They may instead fail/restart repeatedly. The precise upheld claim is **“unconditionally scheduled and capable of retry churn or attaching to Xwayland,”** not “proven healthy and continuously active.”

Minimal P0 fix: remove xautolock/xss-lock/i3lock from this Wayland role and make the chosen ext-session-lock implementation own idle lock. Minimal P1 fix: remove or explicitly X11-scope Picom and Polybar. Keep udiskie if desired, but do not make a Niri mount daemon drag in an obsolete X11 bar merely to satisfy `tray.target`.

### 4. Dual wallpaper owners — **UPHELD as ambiguity, downgraded from P0 to P1**

Niri always starts `awww-daemon` when available (`config.kdl:194`), and awww is installed. Noctalia has wallpaper enabled and creates wallpaper surfaces. A live non-NixOS Niri session already observed both clients and Noctalia surfaces.

Counterweight: no tracked command runs `awww img`, `awww restore`, `swww img`, or equivalent. Merely starting the awww daemon does not prove the user will see a competing image, palette corruption, or flicker. The correct conclusion is duplicate wallpaper-capable clients/layers and needless authority ambiguity; a visible failure remains unproven.

Minimal fix: if Noctalia owns wallpaper/palette, delete the awww/swww startup and package. Physical probe: assert only one wallpaper client, change wallpaper through Noctalia, hotplug an output, relogin twice, and compare effective palette/wallpaper state.

### 5. OBS launcher exits 127 — **UPHELD, P1**

The managed desktop entry is syntactically valid, but neither exact HM nor system profile provides `bin/obs`. The wrapper searches for a different executable and exits 127 on the exact clean `PATH`. Private OBS binaries inside unrelated FHS closures do not satisfy desktop launch lookup.

This is not a boot/session-security P0, but it violates “everything advertised works immediately.” Minimal fix: install `obs-studio` in the desktop role or remove the wrapper/desktop entry. Then run an actual portal screen/window capture; installing the executable alone does not prove capture.

### 6. Portal correctness — **MOSTLY UPHELD, one newly narrowed interface**

Supported static routing is strong:

- Exact Niri source and README explicitly support monitor/window screencasting through `xdg-desktop-portal-gnome` and implement `org.gnome.Mutter.ScreenCast`.
- Niri implements the GNOME screenshot/introspection interfaces used by the backend.
- The restricted `kde-niri.portal` advertises only FileChooser/AppChooser/Settings and matches its selector ID.
- GTK owns Access and portal Notification; this is compatible with Noctalia owning desktop notifications.
- The realized NixOS system includes GNOME Keyring for Secret. The standalone HM output still depends on its host to provide that backend.

New narrowing: exact Niri source contains no `org.gnome.Mutter.RemoteDesktop` service, while exact xdg-desktop-portal-gnome's `remotedesktop.c` constructs proxies to that name and path. Thus `org.freedesktop.impl.portal.RemoteDesktop=gnome` selects a descriptor that advertises the interface, but input injection cannot work under this Niri pin. ScreenCast can still work because it uses Niri's implemented `org.gnome.Mutter.ScreenCast`. Do not report RemoteDesktop as supported merely because the descriptor lists it.

The duplicate generic `portals.conf` is not harmful to integrated NixOS, which exposes only Niri, but it broadens this policy on standalone Linux hosts with other desktops. Keep `niri-portals.conf` as the compositor-specific authority; use a generic selector only if its cross-desktop effect is intentional.

Minimal fix/check: remove the explicit RemoteDesktop claim or select a Niri-compatible backend when one is actually deployed; retain the current ScreenCast/Screenshot/KDE/GTK/Secret split; physically exercise GTK/Qt choosers, browser and OBS capture consent, screenshot, Secret unlock, and failure logs.

### 7. Missing cursor and fonts — **UPHELD, P1**

The exact realized profile contains FiraCode Nerd Font Mono and its family spelling matches Kitty/Konsole. It does not contain Fira Sans or Sarasa UI SC. `pkgs.sweet` provides `Sweet-Dark` GTK themes but no `Sweet-cursors`, and no other realized tree supplies that cursor name.

Fallback prevents crashes, so “desktop unusable” would overstate the impact. The real failure is that the requested immediate visual contract cannot be met: GTK/KDE/Waybar select Fira Sans and GTK selects a nonexistent cursor. Sarasa UI SC is only relevant to stale Mako policy; if Mako is removed, do not add a font solely to satisfy dead config.

Minimal fix: package/configure one real cursor family across GTK/XCursor/Qt and either add Fira Sans or select an already installed UI family. Add closure checks that the requested cursor directory and font family exist.

### 8. GTK/Qt authority conflicts — **GTK upheld; Qt downgraded**

GTK output contains two `[Settings]` groups: structured HM Adwaita followed by hand-written Sweet. The environment also forces `GTK_THEME=Sweet-Dark`, and activation mutates GSettings. Later values and `GTK_THEME` make Sweet likely and often deterministic, so random styling is not proven. Still, there are multiple policy writers, an incorrect/irrelevant `adwaita-icon-theme` package attached as the GTK theme package, and a global override that can fight libadwaita's styling contract. This is a real maintainability and cross-application consistency defect.

For integrated NixOS Qt, the mechanisms mostly agree: `QT_STYLE_OVERRIDE=kvantum`, Kvantum selects Dr460nized, KDE globals select Kvantum/BeautyLine, and activation writes the same style/icon values to qt5ct and qt6ct. `QT_QPA_PLATFORMTHEME` is **not** set in the integrated NixOS session, so the qtct files may be dormant. The evidence establishes redundant control planes, not contradictory output. Standalone Linux does force `QT_QPA_PLATFORMTHEME=qt5ct`, which needs separate Qt5/Qt6 runtime verification, but that does not justify calling the NixOS Qt policy broken.

Minimal fix: collapse GTK to one structured owner. For Qt, document Kvantum as widget-style authority, delete dormant qtct writes unless a tested platform-theme path consumes them, and test representative Qt5/Qt6 dialogs before further simplification.

### 9. Noctalia warnings and state drift — **warnings upheld/P1; state-as-defect refuted**

Exact validation reports eight warnings and exits 0. Several are in disabled features, so they do not all cause current runtime failures. Two user-visible examples remain meaningful: the launcher placement is an invalid value, and weather is enabled while its old location keys are unknown. The correct claim is “declared intent is partly ignored and the build does not gate warnings,” not “Noctalia cannot start.”

State `settings.toml` overriding config is deliberate, documented by both the local file and upstream HM module, and confirmed by an isolated merge. Preserving user UI choices can be desirable. It becomes a reproducibility defect only if the project promises declarative settings are always effective. Choose one contract: user-overridable baseline with a drift report, or enforced state. Do not silently delete user state as a generic fix.

Minimal fix: migrate/remove all warnings and export warning-free validation as a check; state the override policy and provide a redacted effective-config/drift diagnostic.

### 10. macOS Kitty parity — **STATIC CLAIM UPHELD; failure claim REFUTED; P2 proof gap**

Both Darwin outputs evaluate the exact same shared Kitty palette, opacity, and `FiraCode Nerd Font Mono` family. FiraCode Nerd Font is present in Darwin Home Manager packages. At the pinned Home Manager revision, the Darwin fonts module copies/dereferences package fonts into `~/Library/Fonts/HomeManager`, which is the correct native shape rather than a Linux fontconfig assumption.

Therefore “Kitty theming does not apply on Mac” is refuted statically. What remains unknown is native activation, CoreText registration after activation/relogin, Kitty's actual family selection/fallback, glyph coverage, and rollback on both ARM and Intel Macs. Linux GTK/Kvantum parity is neither expected nor desirable on macOS; the cross-platform contract should be semantic Kitty palette/font parity.

Minimal physical gate: realize and activate on each Mac architecture, inspect `~/Library/Fonts/HomeManager`, run `kitty +list-fonts --psnames` and `kitty --debug-font-fallback`, relogin, and visually compare palette/opacity/symbol/emoji behavior.

### 11. Branding and asset provenance — **NARROWED, P1/P2**

The two local NixOS-logo rasters are not current canonical branding, but neither is active in the default Fastfetch profile. This is not an immediate desktop-theme defect. Updating/removing them is P2 unless those alternate profiles are advertised.

The active Fastfetch Snoopy/One Piece-derived raster has no recorded source/license. That is a provenance unknown, not proof of infringement. The login wallpaper is byte-identical to an upstream CC BY-NC-ND asset but lacks local attribution/license notice; this is a more concrete compliance/documentation issue. Locally copied BeautyLine/Dr460nized subsets also omit upstream license files/notices. Treat these as P1 distribution/provenance remediation, not as driver/session blockers. Prefer owned/permissively licensed assets and retain source, commit, license, and modification notices.

Current NixOS brand colors/logo should come from `NixOS/branding`; old local colors can be kept only when clearly described as historical/unofficial. Branding consistency does not require replacing the user's Sweet desktop palette with official NixOS colors.

### 12. Duplicate Noctalia unit — **REFUTED for integrated NixOS**

The exact integrated NixOS generation has one `noctalia.service`, produced by the NixOS Noctalia aspect. `modules/nixos/files.nix` contributes its config but not a second unit. The standalone Home Manager output uses the HM Noctalia unit in a separate output, which is appropriate. No remediation is needed beyond keeping lifecycle ownership explicit.

## Minimal priority set

### P0 — security and deterministic session authority

1. Fix `Super+Alt+L` to `noctalia msg session lock`; add exact-pin regression coverage.
2. Remove the X11 lock path from Niri and explicitly configure/test Noctalia idle locking if automatic laptop lock is required.
3. Make one notification daemon authoritative (Noctalia in the current design); remove Mako/Dunst activation candidates and cold-login/restart test the D-Bus owner.

### P1 — immediate usability and deterministic presentation

4. Remove or X11-scope Picom/Polybar without coupling udiskie to the obsolete bar; verify no restart churn.
5. Install OBS Studio or remove its advertised launcher; physically test PipeWire portal capture.
6. Remove unused awww/swww startup if Noctalia owns wallpaper.
7. Add a real cursor and UI font or select installed assets; remove dead Sarasa/Mako policy rather than adding unnecessary packages.
8. Collapse GTK ownership; simplify Qt only where runtime tests show a control plane is dormant.
9. Make Noctalia validation warning-free and declare an intentional runtime-state policy.
10. Narrow portal claims: keep the proven ScreenCast/Screenshot/chooser/Secret routing; do not promise RemoteDesktop input injection under the exact Niri pin.
11. Repair asset provenance/license notices or replace uncertain artwork.

### P2 — hardware-only acceptance, not static “passes”

12. Execute fresh-login session, portal, lock/hotplug/suspend, styling, and wallpaper drills on the installed NixOS laptop.
13. Execute native Home Manager/Kitty/CoreText activation and rollback drills on ARM and Intel Darwin.

## Physical probes required before “works immediately”

```bash
# Unit graph and retry churn.
systemctl --user list-dependencies graphical-session.target tray.target
systemctl --user --failed
journalctl --user -b -p warning --no-pager

# One notification owner, stable across restart.
busctl --user status org.freedesktop.Notifications
systemctl --user restart noctalia.service
busctl --user status org.freedesktop.Notifications

# Secure lock on every output and after resume/hotplug.
noctalia msg session lock
loginctl show-session "$XDG_SESSION_ID" -p LockedHint

# Supported portal paths and unsupported RemoteDesktop boundary.
systemctl --user status xdg-desktop-portal{,-gnome,-kde,-gtk}.service
journalctl --user -b -u xdg-desktop-portal.service --no-pager
# Then exercise real GTK3/GTK4/Qt5/Qt6 choosers, browser/OBS screen and
# single-window capture, Screenshot, and Secret unlock through UI clients.

# Exact assets, without accepting unrelated fallback.
fc-match 'Fira Sans'
fc-match 'FiraCode Nerd Font Mono'
find /run/current-system/sw/share/icons "$HOME/.nix-profile/share/icons" \
  -path '*/Sweet-cursors/index.theme' -print
kitty +list-fonts --psnames | grep -F 'FiraCode Nerd Font Mono'

# Effective Noctalia state; redact sensitive fields before saving/reporting.
noctalia config validate
noctalia config export merged
```

Also test: notification actions; Noctalia crash/restart; lock after monitor hotplug; suspend/resume while locked; a clean login with no prior XDG state; wallpaper change/relogin across two outputs; cursor at 1x/2x; GTK/libadwaita and Qt5/Qt6 screenshots; and the advertised OBS desktop entry from the launcher rather than a shell with an enriched `PATH`.

On each physical Mac:

```bash
test -d "$HOME/Library/Fonts/HomeManager"
find "$HOME/Library/Fonts/HomeManager" -iname '*FiraCode*' -print
kitty +list-fonts --psnames | grep -F 'FiraCode Nerd Font Mono'
kitty --debug-font-fallback
```

## Primary evidence

- Repository: `modules/linux/config/niri/config.kdl:53-58,191-194`; `modules/nixos/home-manager.nix:46-121`; `modules/nixos/system.nix:131-151`; `modules/linux/home-manager.nix:260-288,509-609,805-931`; `modules/standalone-linux/config/noctalia/config.toml`; `modules/aspects/features/noctalia.nix`; `modules/shared/home-manager.nix`; `modules/darwin/base.nix`.
- Noctalia IPC: <https://github.com/noctalia-dev/noctalia/blob/d8d8ed597e6a3b5a6846c0b474e6f67f573dc630/src/shell/session/session_ipc.cpp#L37-L82>
- Noctalia notification acquisition: <https://github.com/noctalia-dev/noctalia/blob/d8d8ed597e6a3b5a6846c0b474e6f67f573dc630/src/dbus/notification/notification_service.cpp#L40-L86>
- Noctalia HM/runtime override contract: <https://github.com/noctalia-dev/noctalia/blob/d8d8ed597e6a3b5a6846c0b474e6f67f573dc630/nix/home-module.nix#L35-L59>
- Exact Niri source `README.md`, `resources/niri-portals.conf`, and `src/dbus/mutter_screen_cast.rs`, realized from the pinned package source.
- Exact xdg-desktop-portal-gnome 50.0 `src/remotedesktop.c`, which proxies `org.gnome.Mutter.RemoteDesktop`.
- Portal selection contract: <https://flatpak.github.io/xdg-desktop-portal/docs/portals.conf.html>
- Freedesktop notification singleton: <https://specifications.freedesktop.org/notification/latest-single/>
- Current NixOS brand authority: <https://nixos.org/branding/> and <https://github.com/NixOS/branding>

## Evidence boundary

No installed target NixOS session or physical Mac was available in this lane. Realized store trees prove generated files, dependencies, executable availability, exact CLI behavior, and static interface compatibility; they do not prove cold-login timing, compositor rendering, PAM/keyring behavior, multi-output lock coverage, capture consent UI, suspend/resume, CoreText registration, or visual parity. Those remain explicit physical gates.

## EXPAND

- LEAD: exact Niri RemoteDesktop boundary — WHY: Wave 2 called the portal split coherent, but exact Niri lacks `org.gnome.Mutter.RemoteDesktop` while GNOME's backend requires it — ANGLE: either scope the promise to ScreenCast or identify/deploy a Niri-compatible input-injection backend and exercise it physically.
- LEAD: clean NixOS cold-login timing — WHY: generated wants links prove scheduling but cannot decide whether Noctalia acquires notifications before an early app activates Mako or whether X11 services fail/retry/attach — ANGLE: capture monotonic user-journal and D-Bus owner from login through first notification.
- LEAD: physical ARM/Intel Darwin activation — WHY: exact settings and font-copy policy converge, but CoreText/Kitty resolution and rollback are platform-only evidence — ANGLE: activate, relogin, inspect fonts, render glyph/palette test, roll back.
- DEAD END: more static searching for lock spelling, OBS availability, cursor/Fira Sans presence, or duplicate integrated Noctalia units — direct execution and realized outputs already settle those claims.

## CLAIMS

- CLAIM: The generated lock key is definitively broken and the exact registered replacement is `noctalia msg session lock`. — RISK: critical session security — EVIDENCE: exact CLI execution, generated KDL, pinned IPC source — COUNTER: KDL syntax validation cannot validate external command semantics — STATUS: upheld — CONFIDENCE: high.
- CLAIM: Notification behavior is ordering-dependent because Noctalia is target-started while Mako and Dunst remain activatable for the same singleton name. — RISK: high usability/session authority — EVIDENCE: realized service metadata, pinned RequestName behavior, isolated exact-profile activation selecting Mako — COUNTER: Mako/Dunst are not both target-wanted, so three simultaneous processes are not guaranteed — STATUS: upheld with narrower lifecycle wording — CONFIDENCE: high.
- CLAIM: Picom, xautolock, xss-lock, and Polybar are unconditional Niri-session dependencies, but their healthy continuous activity is not statically proven. — RISK: high for lock authority, normal for retry churn/UI duplication — EVIDENCE: realized wants/requires links, unit contents, absence of conditions — COUNTER: missing/tardy DISPLAY can make them fail rather than remain active — STATUS: upheld scheduling; downgraded activity wording — CONFIDENCE: high.
- CLAIM: The generated OBS entry cannot launch on the exact clean profile. — RISK: normal — EVIDENCE: exact PATH execution exits 127; no profile binary — COUNTER: unrelated private closure binaries are not command lookup candidates — STATUS: upheld — CONFIDENCE: high.
- CLAIM: The portal routing is sound for Niri capture/chooser/Secret but not for GNOME RemoteDesktop input injection. — RISK: normal — EVIDENCE: exact Niri ScreenCast implementation and absent RemoteDesktop service; exact GNOME backend proxy requirement — COUNTER: backend descriptor advertising RemoteDesktop does not create the compositor service — STATUS: narrowed; new unsupported boundary — CONFIDENCE: high.
- CLAIM: GTK has conflicting writers and requested cursor/UI font assets are absent; integrated Qt is redundant but not shown contradictory. — RISK: normal — EVIDENCE: realized GTK files/env, font/theme scans, aligned Kvantum/qtct values — COUNTER: fallback avoids crashes and Qt values mostly converge — STATUS: GTK/assets upheld, Qt downgraded — CONFIDENCE: high.
- CLAIM: Noctalia warnings represent ignored intent, while runtime state override is intentional behavior rather than an inherent defect. — RISK: normal — EVIDENCE: exact validator and isolated state-merge replay, upstream module contract — COUNTER: validator exits 0 and several warned sections are disabled — STATUS: warnings upheld; state-as-defect refuted — CONFIDENCE: high.
- CLAIM: Shared Kitty theming reaches both Darwin outputs; only native activation/CoreText proof remains. — RISK: normal — EVIDENCE: both Darwin evaluations, Darwin HM font package, pinned HM font-copy mechanism — COUNTER: no physical Darwin activation — STATUS: static parity upheld; alleged Mac omission refuted — CONFIDENCE: medium-high.
- CLAIM: Awww and Noctalia are both wallpaper-capable clients, but a visible wallpaper conflict is not yet proven because no tracked awww image command exists. — RISK: normal — EVIDENCE: generated startup/package plus Noctalia wallpaper config/source; repository-wide command search — COUNTER: daemon presence alone need not change the visible image — STATUS: upheld ambiguity, severity downgraded — CONFIDENCE: high.
- CLAIM: The integrated NixOS generation has one Noctalia unit, not duplicate NixOS+HM ownership. — RISK: low — EVIDENCE: exact unit tree and aspect/file ownership — COUNTER: standalone output has a distinct HM unit by design — STATUS: earlier suspicion refuted — CONFIDENCE: high.
