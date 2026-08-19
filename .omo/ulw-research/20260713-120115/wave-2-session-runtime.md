# Wave 2 — Niri/Noctalia/session/theme generated-runtime proof

Research date: 2026-07-13. Production revision: `e9f78180748f1feb428ffb20f9d932c5d9918a48`. Exact root pins used here include Nixpkgs `d407951447dcd00442e97087bf374aad70c04cea`, Noctalia `d8d8ed597e6a3b5a6846c0b474e6f67f573dc630`, and Home Manager `a1645f40777620c4bd2b6d854b290c2fc354a266`. This lane made no production edits.

## Bottom line

The Niri session evaluates and its generated KDL is syntactically valid, the portal split is internally coherent, the exact Niri and Noctalia binaries both implement `ext-session-lock-v1`, and the shared Kitty palette plus FiraCode Nerd Font package path reaches Linux and macOS Home Manager policy. Those successes do **not** make the generated desktop ready.

Five generated-runtime defects are decisive:

1. `Super+Alt+L` runs a command that the exact Noctalia binary rejects. The generated bind is `noctalia msg screen-lock`; the registered command is `noctalia msg session lock`.
2. Notification ownership has **three** competing candidates, not two: Noctalia requests `org.freedesktop.Notifications`, while the realized user profile publishes both Mako and Dunst activation files for that same name. Dunst also has a managed user unit. Whichever starts first wins; Noctalia explicitly disables its notification service when another owner wins.
3. The Niri graphical-session dependency graph actively starts X11-era services: Picom, xautolock, xss-lock/i3lock, and Polybar. They are not merely orphaned source files.
4. The managed OBS desktop entry is valid syntax but cannot launch on the realized NixOS profile: neither system nor Home Manager profile has `bin/obs`; the managed wrapper deterministically exits 127.
5. Theme output has conflicting authorities and missing assets: generated GTK 3/4 files contain duplicate `[Settings]` groups for Adwaita then Sweet, `GTK_THEME` force-selects Sweet, Qt is divided among Kvantum/KDE/qt5ct/qt6ct, `Sweet-cursors` is absent, and Fira Sans/Sarasa UI SC are absent. Only the configured Kitty FiraCode Nerd Font family is actually present.

## Exact generated artifacts inspected

| Artifact | Exact realized path | Result |
|---|---|---|
| x86_64 NixOS system | `/nix/store/2skzh1yk3bzz5g30zxf6ngcai78m3vci-nixos-system-nixos-26.11.20260705.d407951` | Realized and inspected |
| NixOS user units | `/nix/store/4djmx9wz8s0jsmf0hpl6nln6mk46ns5n-user-units` | Realized and inspected |
| integrated HM generation | `/nix/store/b77d20kdnbdab85v3pmnvz0nprcshshi-home-manager-generation` | Realized and inspected |
| HM files tree | `/nix/store/6pc2hllhb476p0h9y4cx8rw764qw3kvm-home-manager-files` | Realized and inspected |
| HM profile | `/nix/store/kci26nh1d74r87q0yjbpdpl1p98dlqp8-home-manager-path` | Realized and inspected |
| session desktops | `/nix/store/qw91iy0m3p69x3c12s42qn09drbjdwk6-desktops` | Contains only `wayland-sessions/niri.desktop`; `xsessions` is empty |
| Niri | `/nix/store/plm81i836y55vi9kgawh8zw8blp3hka0-niri-26.04` | Exact generated session and protocol support inspected |
| Noctalia | `/nix/store/vwfxwdszqyy4glajh8qhxwp0nywl0w7s-noctalia-5.0.0` | Exact CLI/config validator and pinned source inspected |

Store paths are evidence for this pinned evaluation, not interfaces future code should hard-code.

## Session and service graph

### What the display manager can start

The generated desktop tree has exactly one entry:

```ini
[Desktop Entry]
Name=Niri
Exec=niri-session
DesktopNames=niri
```

`niri-session` imports the login environment into both systemd-user and D-Bus, starts `niri.service`, waits for it, and tears down `graphical-session.target` after Niri exits. The generated `niri.service` executes exact Niri with `--session` and binds to `graphical-session.target`. This is a sound session skeleton.

### What that target actually starts

Generated dependency inspection, not source inference, proves:

- NixOS `graphical-session.target.wants/` contains `noctalia.service` and `picom.service`.
- HM `graphical-session.target.wants/` contains `udiskie.service`, `xautolock-session.service`, and `xss-lock.service`.
- `udiskie.service` requires `tray.target`.
- HM `tray.target.wants/` contains `polybar.service`.
- `xss-lock` launches `i3lock-fancy-rapid`; `xautolock` asks logind to lock after ten minutes, while the actual locker remains the X11 xss-lock/i3lock path.
- Picom has no Niri/Wayland condition and is wanted by every graphical session.

Therefore a clean Niri login attempts all of Noctalia, Picom, xautolock, xss-lock/i3lock, and Polybar. The correct steady state is one Niri-native shell/lock/notification/wallpaper authority, not this mixed graph.

There is **not** a duplicate Noctalia systemd unit in the integrated NixOS generation: the NixOS aspect owns the Noctalia unit, while `modules/nixos/files.nix` owns the config file. The Home Manager Noctalia unit is used by the separate standalone output. The earlier suspicion of NixOS-module plus HM-module double unit ownership is disproved for this revision.

## Lock path: exact failure and correct protocol

Executed against the exact Noctalia package:

```text
$ noctalia msg screen-lock --help
error: unknown command (try: noctalia msg --help)
exit 1
```

`noctalia msg --help` registers `session <lock|suspend|lock-and-suspend|logout|reboot|shutdown>`. Pinned source `src/shell/session/session_ipc.cpp:37-82` registers only the `session` handler and dispatches `lock` to `LockScreen::lock()`. No alias named `screen-lock` exists. The generated Niri config nevertheless contains:

```kdl
Super+ALT+L { spawn-sh "noctalia msg screen-lock"; }
```

The exact command must be `noctalia msg session lock`.

A clean, isolated `noctalia config export full` over the declared TOML showed `[lockscreen].enabled = true` and an enabled built-in session action `action = "lock"`. Both exact binaries contain `ext_session_lock_v1`; pinned Noctalia uses `ext_session_lock_manager_v1_lock()` and Niri exposes the server protocol. Thus the intended secure path is sound once the IPC invocation is fixed.

The TOML string `command = "noctalia:screen-lock"` under the **disabled** idle behavior is an internal Noctalia action, not the rejected CLI spelling; it must not be conflated with the Niri bind. The larger issue is that automatic lock is disabled in Noctalia while incompatible X11 idle lockers are enabled.

The current research host is CachyOS, not the target NixOS closure. As supporting but non-target evidence, `noctalia msg session lock` did lock its live Niri session and Niri logged lock/unlock transitions. This does not replace a post-install laptop lock drill.

## Notification name collision: three owners

The realized integrated NixOS HM profile publishes both:

```ini
# fr.emersion.mako.service
Name=org.freedesktop.Notifications
Exec=.../bin/mako

# org.knopwob.dunst.service
Name=org.freedesktop.Notifications
Exec=.../bin/dunst
SystemdService=dunst.service
```

The managed Dunst unit is `Type=dbus` with the same `BusName`. Exact Noctalia source `src/dbus/notification/notification_service.cpp:51-69` requests the same name with `AllowReplacement|DoNotQueue`; if it already exists, Noctalia throws. `src/app/application_services.cpp:171-190` then logs that notifications are disabled. Only one implementation can satisfy the Freedesktop notification name.

The current non-NixOS live session demonstrated the failure mode rather than merely suggesting it: D-Bus activated Mako, and exact-version Noctalia logged `notifications disabled ... org.freedesktop.Notifications is owned by another service`. This is supporting evidence for the collision semantics; generated activation files establish that the same candidates exist in the NixOS user profile.

Decision: remove Mako and Dunst packages/config/unit activation from the Noctalia desktop role and make Noctalia the sole notification owner. The GTK **portal** Notification implementation is not a desktop notification daemon and may remain.

## Portal selectors and D-Bus backends

The generated per-user `niri-portals.conf` is more explicit than Niri's package default:

- GNOME: ScreenCast, RemoteDesktop, Screenshot.
- restricted custom `kde-niri`: FileChooser, AppChooser, Settings.
- GTK: Access and portal Notification.
- GNOME Keyring: Secret.
- default fallback: GNOME then GTK.

The custom `kde-niri.portal` exports only FileChooser/AppChooser/Settings and uses the KDE backend bus name. The realized system includes matching GNOME, GTK, KDE, and GNOME Keyring portal descriptors and D-Bus activation files. GNOME supplies the capture interfaces necessary for Niri/PipeWire screen sharing. NixOS also realizes GNOME Keyring; the standalone HM output still relies on the host to supply it.

Static conclusion: the NixOS portal split is coherent and should be retained. Runtime selection, user-consent dialogs, screen/window enumeration, and Secret unlock remain physical-session checks. The user selector should remain the single selector authority; keeping both `niri-portals.conf` and an identical generic `portals.conf` is redundant and broadens that policy to other desktops.

## Wallpaper ownership and Noctalia state precedence

The generated Niri KDL always spawns `awww-daemon` (falling back to `swww-daemon`), while declared Noctalia has `[wallpaper].enabled = true` and creates its own wallpaper surfaces. The current live session empirically had both `awww-daemon` and Noctalia running, and Noctalia logged wallpaper surfaces on both outputs. This is an actual dual-owner state.

Pinned Noctalia source deep-merges `$XDG_STATE_HOME/noctalia/settings.toml` **after** config-directory TOML. The Home Manager module documents the same runtime override contract. The live research session logged that it loaded `~/.local/state/noctalia/settings.toml`; no credential value was read or reproduced. Therefore a declarative `config.toml` is only a baseline, not proof of effective theme/wallpaper/notification behavior.

Decision: use Noctalia alone for wallpaper if wallpaper-derived palette behavior is wanted; remove the Niri awww/swww startup. Pick one of two explicit state policies: (a) preserve user overrides and test/report drift, or (b) enforce configuration by removing or declaratively managing the override file. Do not claim reproducibility while leaving that choice implicit.

## Noctalia config compatibility

The exact validator accepted the TOML with exit 0 but emitted eight warnings:

- unknown setting: `shell.panel.background_blur`
- unknown value: `shell.panel.launcher_placement = "centered"`
- unknown setting: `wallpaper.automation.interval_minutes`
- unknown settings: `weather.address`, `weather.auto_locate`
- unknown settings: `nightlight.start_time`, `nightlight.stop_time`, `nightlight.use_weather_location`

The integrated NixOS path writes the TOML through `modules/nixos/files.nix`, not through Noctalia's HM module's build-time validator, so these warnings do not appear as a build gate. Convert this validator invocation into a flake check and remove/migrate all warnings; “valid with ignored fields” is not immediate correctness.

## OBS launcher proof

The generated desktop entry passes `desktop-file-validate`. That proves syntax only. Exact realized paths showed:

- no `$HM_PROFILE/bin/obs`;
- no `$NIXOS_SYSTEM/sw/bin/obs`;
- no declared `obs-studio` package in the active profile;
- the managed `~/.local/bin/obs` wrapper searches `PATH` for another OBS executable.

Executed with the realized Home Manager and NixOS profile paths, the wrapper returned:

```text
exit 127
obs wrapper: could not find the real OBS executable
```

Some unrelated FHS rootfs closures contain a private `bin/obs`; those paths are not profile executables and do not make the launcher work. Decision: either install `obs-studio` in the desktop role and retain the Wayland wrapper, or delete the desktop entry/wrapper. Then physically verify OBS PipeWire capture through the GNOME ScreenCast portal.

## Theme, cursor, and font generated output

### GTK

Both realized `gtk-3.0/settings.ini` and `gtk-4.0/settings.ini` contain two `[Settings]` groups: first Home Manager's `Adwaita-dark`, then hand-written `Sweet-Dark`/BeautyLine/Fira Sans/Sweet-cursors. The session additionally force-exports `GTK_THEME=Sweet-Dark`, and activation mutates GNOME GSettings to Sweet/BeautyLine. The declared NixOS `gtk.theme.package` is `adwaita-icon-theme`, which is not the owner of Sweet. Later duplicate keys generally win, but this is conflicting policy, not one declarative authority.

Decision: choose Sweet or Adwaita once. If Sweet remains, express the matching theme package through structured HM GTK options, remove the losing Adwaita block, avoid global `GTK_THEME` except as a tested compatibility exception, and do not force legacy GTK settings onto libadwaita applications expecting their own style contract.

### Qt

The realized session exports `QT_STYLE_OVERRIDE=kvantum` and `QT_QUICK_CONTROLS_STYLE=org.kde.desktop`; generated Kvantum selects `Dr460nized`; activation also writes KDE globals plus both qt5ct and qt6ct files. Standalone additionally declares `QT_QPA_PLATFORMTHEME=qt5ct`. These are multiple control planes. Select Kvantum as the widget-style owner and one platform-theme/config owner per Qt major; test Qt5 and Qt6 dialogs separately.

### Cursor and fonts

Executed store-tree and font-family scans proved:

- `pkgs.sweet` contains GTK themes but no `Sweet-cursors` tree.
- neither the realized Home Manager path nor home files contain `Sweet-cursors`.
- FiraCode Nerd Font Mono is present and its exact family name matches Kitty/Konsole.
- no Fira Sans family is present, despite GTK/KDE/Waybar selecting it.
- no Sarasa UI SC family is present, despite the retained Mako config selecting it.

Thus cursor and UI font fallback are guaranteed somewhere; they are not merely untested. Package and configure one cursor family consistently across GTK/XCursor/Qt, add Fira Sans or choose an installed sans family, and delete Mako/Sarasa policy if Noctalia is authoritative.

### Kitty and macOS

The generated Linux Kitty file exactly contains the shared Sweet terminal palette and `font_family FiraCode Nerd Font Mono`. Darwin includes the same shared Home Manager program and the same `nerd-fonts.fira-code` in `home.packages`. At exact Home Manager pin, `modules/targets/darwin/fonts.nix` builds a font environment from `home.packages` and uses `rsync -acL --delete` into `/Users/mei/Library/Fonts/HomeManager`, because macOS does not recognize symlinked fonts. This is a valid declarative path for FiraCode even though nix-darwin's **system** `fonts.packages` lists only JetBrains Mono and symbols-only.

What remains unproved is CoreText registration and Kitty's physical font resolution after activation. The Darwin activation package was evaluated but is not realized on this Linux host; no claim of native activation is made.

## Decision-complete remediation order

### P0 — session correctness/security

1. Replace the Niri lock IPC with `noctalia msg session lock` and add a source assertion rejecting `msg screen-lock`.
2. Make Noctalia the only desktop notification service: remove Dunst and Mako from packages/services/config for this role.
3. Disable/remove Picom, xautolock, xss-lock/i3lock, and Polybar from the Niri role. Enable Noctalia idle lock with a tested timeout if automatic locking is desired.
4. Choose Noctalia as the sole wallpaper owner; remove awww/swww startup.
5. Install OBS Studio or remove its launcher; do not retain a guaranteed exit-127 menu entry.

### P1 — deterministic styling

6. Collapse GTK to one structured theme authority and Qt to one style/platform-theme owner per major.
7. Add an actual cursor package and an installed UI sans font; add evaluation checks that requested family/theme directories exist.
8. Migrate all eight Noctalia warnings and export its validator as a flake check.
9. Declare an explicit Noctalia runtime-state policy and test declared-versus-effective configuration.

### P2 — physical lifecycle proof

10. Run the probes below on a freshly installed NixOS laptop and both Darwin architectures before claiming immediate readiness.

## Physical-session acceptance probes (deferred, not disguised as passing)

Run these after a cold login on the installed target:

```bash
# Exactly one intended session stack; all commands must succeed as asserted.
systemctl --user list-dependencies graphical-session.target
systemctl --user is-active niri.service noctalia.service
! systemctl --user is-active dunst.service mako.service picom.service \
    polybar.service xss-lock.service xautolock-session.service
! pgrep -x awww-daemon
! pgrep -x swww-daemon

# The owner executable must resolve to Noctalia.
busctl --user status org.freedesktop.Notifications

# Lock must cover every output and set logind's lock state.
noctalia msg session lock
loginctl show-session "$XDG_SESSION_ID" -p LockedHint

# Portal service/backend health; then test a real chooser and capture consent UI.
systemctl --user --no-pager status xdg-desktop-portal.service \
  xdg-desktop-portal-gnome.service xdg-desktop-portal-kde.service \
  xdg-desktop-portal-gtk.service
journalctl --user -b -u xdg-desktop-portal.service --no-pager
command -v obs && obs --version

# Fonts/theme/cursor. Each requested family/theme must resolve to itself.
fc-match 'Fira Sans'
fc-match 'FiraCode Nerd Font Mono'
find /run/current-system/sw/share/icons "$HOME/.nix-profile/share/icons" \
  -path '*/Sweet-cursors/index.theme' -print
kitty +list-fonts --psnames | grep -F 'FiraCode Nerd Font Mono'
```

Also test: lock/unlock after monitor hotplug; suspend/resume while locked; notification actions; file chooser in GTK3/GTK4/Qt5/Qt6; browser/OBS screen and single-window capture; Secret portal unlock; wallpaper persistence over two logins; 1x/2x cursor rendering; and Noctalia effective-config diff with any sensitive values redacted.

On each physical Mac:

```bash
test -d "$HOME/Library/Fonts/HomeManager"
find "$HOME/Library/Fonts/HomeManager" -iname '*FiraCode*' -print
kitty +list-fonts --psnames | grep -F 'FiraCode Nerd Font Mono'
kitty --debug-font-fallback
```

Verify the rendered family through Kitty/CoreText, palette colors, opacity, symbol/emoji fallback, activation, rollback, and relogin. GTK/Niri/Kvantum parity is not a macOS requirement; semantic Kitty palette and typography parity is.

## Evidence boundaries

High-confidence generated facts: service dependency graph, one Niri desktop entry, invalid/valid IPC spellings, Noctalia protocol/source behavior, three notification candidates, portal interface files, OBS exit 127, config warnings, missing cursor/font assets, generated Kitty configuration, and Home Manager's Darwin font-copy mechanism.

Supporting non-target observation: the current CachyOS Niri session reproduced Mako winning the notification name, Noctalia notification disablement, state-file loading, dual awww/Noctalia wallpaper ownership, and successful `session lock`. It is not a substitute for installed NixOS or macOS acceptance.

Not verified here: LightDM cold login on the newly installed laptop, physical multi-output lock coverage, PAM/keyring behavior on that laptop, portal chooser/capture consent UI, OBS capture, cursor rendering, GTK/Qt screenshots, suspend/resume, or native Darwin activation/CoreText resolution.

## Primary evidence

- Repository anchors: `modules/linux/config/niri/config.kdl:53-58,191-194`; `modules/nixos/home-manager.nix:46-121`; `modules/nixos/system.nix:65-210`; `modules/linux/home-manager.nix:257-291,512-609,805-931`; `modules/aspects/features/noctalia.nix`; `modules/shared/home-manager.nix:402-440`; `modules/shared/packages.nix:232-242`; `modules/darwin/base.nix:34-43`.
- Exact Noctalia IPC: https://github.com/noctalia-dev/noctalia/blob/d8d8ed597e6a3b5a6846c0b474e6f67f573dc630/src/shell/session/session_ipc.cpp#L37-L82
- Exact Noctalia notification acquisition: https://github.com/noctalia-dev/noctalia/blob/d8d8ed597e6a3b5a6846c0b474e6f67f573dc630/src/dbus/notification/notification_service.cpp#L40-L86
- Exact Noctalia NixOS module: https://github.com/noctalia-dev/noctalia/blob/d8d8ed597e6a3b5a6846c0b474e6f67f573dc630/nix/nixos-module.nix
- Exact Noctalia HM module/state warning: https://github.com/noctalia-dev/noctalia/blob/d8d8ed597e6a3b5a6846c0b474e6f67f573dc630/nix/home-module.nix#L35-L59
- `ext-session-lock-v1`: https://wayland.app/protocols/ext-session-lock-v1
- Portal selector contract: https://flatpak.github.io/xdg-desktop-portal/docs/portals.conf.html
- Freedesktop notification singleton contract: https://specifications.freedesktop.org/notification/latest-single/

## EXPAND

- LEAD: clean NixOS laptop session drill — WHY: generated evidence proves intended graph defects but cannot prove PAM, hotplug, suspend, capture UI, keyring unlock, or rendering — ANGLE: execute the physical-session acceptance matrix after P0/P1 changes.
- LEAD: physical ARM/Intel macOS Kitty/CoreText drill — WHY: source and evaluation establish the font-copy path but not native activation or CoreText resolution — ANGLE: realize/activate, relogin, inspect HomeManager font copies and Kitty debug fallback.
- DEAD END: more static searching for the lock spelling, notification owner candidates, OBS binary, cursor package, Fira Sans, or state precedence — exact binaries, realized profiles, generated units, source, and one live reproduction already converge.

## CLAIMS

- CLAIM: The generated Niri lock key is deterministically broken, while `noctalia msg session lock` is the exact registered secure-protocol path. — RISK: high — EVIDENCE: exact CLI execution, generated KDL, pinned IPC source, isolated effective config, protocol symbols — COUNTER: Niri KDL validation passes because it cannot validate spawned external command semantics — CONFIDENCE: high.
- CLAIM: The realized desktop exposes three competing Freedesktop notification implementations (Noctalia, Mako, Dunst), so notification behavior is first-owner dependent. — RISK: high — EVIDENCE: realized DBus activation files/unit plus pinned Noctalia RequestName source; current live session reproduced Mako winning and Noctalia disabling notifications — COUNTER: GTK portal Notification is intentionally excluded because it is a portal backend, not the desktop daemon — CONFIDENCE: high.
- CLAIM: Picom, xautolock, xss-lock/i3lock, and Polybar are active generated dependencies of the Niri graphical session rather than harmless stale files. — RISK: high — EVIDENCE: exact NixOS/HM target-wants trees and unit contents — COUNTER: no Niri/Wayland conditions were found; even a service failure remains a broken login graph — CONFIDENCE: high.
- CLAIM: The generated OBS menu entry cannot work on the clean realized profile. — RISK: high — EVIDENCE: no profile/system `bin/obs`; managed wrapper executed with realized PATH and exited 127 — COUNTER: private `bin/obs` paths inside unrelated FHS rootfs closures are not profile commands — CONFIDENCE: high.
- CLAIM: Linux theming is not deterministic because GTK/Qt have split authorities and requested `Sweet-cursors`, Fira Sans, and Sarasa UI SC assets are absent. — RISK: normal — EVIDENCE: generated GTK/Qt files, session variables, realized Sweet tree and font-family scans — COUNTER: fallback fonts/cursors may make apps render, but fallback is precisely the failure of the requested immediate theme contract — CONFIDENCE: high.
- CLAIM: Shared Kitty palette/font policy reaches Darwin configuration and Home Manager has a valid native font-copy mechanism, but physical CoreText resolution remains unverified. — RISK: normal — EVIDENCE: shared HM source, Darwin package graph, exact HM Darwin fonts module, Darwin output evaluation — COUNTER: no native Darwin generation was realized or activated here — CONFIDENCE: medium-high.
