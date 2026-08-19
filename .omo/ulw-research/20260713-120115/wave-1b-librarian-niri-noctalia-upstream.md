# Wave 1B — Exact-pin Niri/Noctalia/portal upstream audit

Observer: `niri_noctalia_upstream`; exact local pin and current upstream/source/contracts; observed 2026-07-13.

## Version basis

- Noctalia pin `d8d8ed597e6a3b5a6846c0b474e6f67f573dc630` (2026-07-05, v5.0.0-beta2 lineage).
- Upstream HEAD observed `321880c81f0c941b540716d0d4a7884e8d00c971`, 186 commits ahead.
- nixpkgs pin `d407951447dcd00442e97087bf374aad70c04cea`.

## Findings

1. **High:** local manual lock `noctalia msg screen-lock` is invalid at the exact pin. Registered command is `noctalia msg session lock`; no alias exists.
2. **High/security:** obsolete tracked v4 JSON is ignored by v5 but contains non-empty `wallpaper.wallhavenApiKey`. Rotate/revoke if real; removal alone does not erase history.
3. **High:** Noctalia and Dunst both request/serve `org.freedesktop.Notifications`; only one desktop daemon can own it. GTK portal Notification is complementary forwarding, not a competitor.
4. **High:** i3lock-fancy/screen-locker and Picom are X11 authorities incompatible/redundant in native Niri. Noctalia implements `ext-session-lock-v1` and should be sole lock authority.
5. **High standalone:** NixOS pinned Niri module supplies GNOME Keyring, but standalone HM selects it as Secret portal backend without provisioning it.
6. **High:** OBS launcher is present but `obs-studio` is absent. Correct capture chain would be OBS → portal → GNOME ScreenCast backend → Niri → PipeWire.
7. **Medium:** portal interface split is valid: GNOME capture/remote/screenshot; restricted KDE chooser/settings; GTK access/notification; GNOME Keyring Secret. Per-user niri selector has defined precedence.
8. **Medium:** several local v5 TOML keys are obsolete/unknown (`background_blur`, old weather/location/nightlight keys); exact validator warns but may not fail.
9. **Medium:** Noctalia idle locking is disabled, but lockscreen remains available manually. Legacy X11 auto-lock is not a valid substitute.
10. **Medium:** Noctalia and awww/swww create ambiguous wallpaper authority; use Noctalia alone if it drives palette/wallpaper.
11. **Medium:** XDG state `settings.toml` overrides declarative `config.toml`; Home Manager is baseline, not guaranteed effective runtime truth.
12. **Medium:** both NixOS and HM Noctalia modules may define the same user unit; choose one lifecycle owner.
13. Issue #2272 is closed/not planned and describes obsolete v4 Quickshell restart workarounds; v5 restart authority is systemd user service.

## Primary sources

- https://github.com/noctalia-dev/noctalia/blob/d8d8ed597e6a3b5a6846c0b474e6f67f573dc630/src/shell/session/session_ipc.cpp#L38-L82
- https://github.com/noctalia-dev/noctalia/blob/d8d8ed597e6a3b5a6846c0b474e6f67f573dc630/src/shell/lockscreen/lock_screen.cpp#L90-L151
- https://github.com/noctalia-dev/noctalia/issues/2272
- https://wayland.app/protocols/ext-session-lock-v1
- https://github.com/niri-wm/niri/wiki/Security-Model
- https://github.com/niri-wm/niri/wiki/Screencasting
- https://flatpak.github.io/xdg-desktop-portal/docs/portals.conf.html
- https://flatpak.github.io/xdg-desktop-portal/docs/doc-org.freedesktop.portal.ScreenCast.html
- https://specifications.freedesktop.org/notification/latest-single/
- https://github.com/NixOS/nixpkgs/blob/d407951447dcd00442e97087bf374aad70c04cea/nixos/modules/programs/wayland/niri.nix

## Authority boundary

Niri: compositor/capture producer. Noctalia: shell/lock/notifications/wallpaper. xdg-desktop-portal: frontend. GNOME: capture/remote/screenshot. Restricted KDE: file/app/settings. GTK: access and portal notification forwarding. GNOME Keyring: Secret. System PipeWire/WirePlumber: transport/policy. GTK and Qt/Kvantum: toolkit themes. One Noctalia systemd user unit. HM config TOML: baseline; private XDG state: user override.

## Claims

- Lock command mismatch, notification conflict, X11 lock incompatibility, standalone keyring gap and missing OBS are exact-pin supported with high confidence.
- Portal split is supported; runtime state overriding declarative TOML is intentional.
- Stale TOML fields are warnings, not necessarily fatal.

## EXPAND
none — exact pin/current upstream and interface contracts converged.
