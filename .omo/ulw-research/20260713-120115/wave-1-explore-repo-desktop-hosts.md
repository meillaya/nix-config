# Wave 1 — Repository desktop/Niri/theming/host-role audit

Observer: `repo_desktop_hosts`; read-only source, evaluation and history audit; observed 2026-07-13.

## Findings

1. **High:** Niri is the only login session, but Picom, xautolock/xss-lock+i3lock, Dunst, Polybar and BSPWM/SXHKD/Rofi/X11 assets remain. Picom and X11 lock services target every graphical session; Dunst and Noctalia both claim notifications. Noctalia idle locking is disabled. This makes automatic Wayland locking and DBus notification ownership unreliable.
2. **High:** the managed OBS desktop entry/wrapper searches for a real OBS binary, but no evaluated NixOS/standalone package list contains OBS. Clean NixOS launch deterministically exits 127.
3. **High:** no server/headless/WSL/laptop role exists. Both NixOS architectures and standalone outputs receive desktop-heavy workstation policy, including hard-coded dual-monitor Niri layout (`DP-1`/`DP-2`).
4. **High:** standalone USER/HOME overrides are contradicted by Noctalia paths hard-coded to `/home/mei` for avatar and wallpapers.
5. **High/medium:** NixOS has GNOME/GTK/KDE/keyring portals, with duplicated GNOME/GTK entries; standalone selects gnome-keyring as Secret backend without installing/managing it and relies on ambient host services. NixOS keyring unlock under LightDM is not explicitly wired.
6. **Medium:** theming has competing authorities: structured Adwaita vs force-written Sweet/BeautyLine/GSettings/GTK_THEME; Qt is split across Kvantum, KDE globals, qt5ct/qt6ct, and standalone `QT_QPA_PLATFORMTHEME=qt5ct`. Sweet cursor, Fira Sans, and Sarasa UI SC are referenced but not managed.
7. **Medium/security:** Noctalia is active wallpaper authority, while awww/swaybg/legacy wallpaper assets remain. A tracked, ignored legacy `settings.json` contains a Wallhaven API key; it is stale runtime state but still repository/history exposure. Runtime Noctalia state may override declared TOML.
8. **Medium:** Waybar/Mako/Wlogout artifacts are stale or broken: CachyOS icon path and uninstalled `ags`, `blueman-manager`, and `swaylock` commands.
9. **Medium:** `modules/nixos/files.nix` uses `builtins.getEnv "HOME"`; pure evaluation yields `/.config/...` textual paths. Home Manager still places file targets under home, but embedded legacy script paths remain wrong. Existing impure tests mask this.
10. **Medium/low:** Kitty config is shared to Darwin, but configured FiraCode Nerd Font is not registered through Darwin `fonts.packages`; system and Home Manager duplicate Darwin packages. macOS parity is intentionally partial and x86_64-darwin is nearing upstream support end.

## Evidence anchors

- `modules/nixos/system.nix:65-210`
- `modules/nixos/home-manager.nix:46-121`
- `modules/nixos/files.nix:3-7,13-369`
- `modules/nixos/niri.nix:29-55`
- `modules/linux/home-manager.nix:232-288,516-609,660-695,805-931`
- `modules/linux/config/niri/config.kdl:30-58,194`
- `modules/standalone-linux/home-manager.nix:4-13,56-61`
- `modules/standalone-linux/config/noctalia/config.toml:1-112`
- `modules/standalone-linux/config/noctalia/settings.json:855` (secret value intentionally not copied)
- `modules/aspects/users/mei.nix:37-75`
- `modules/darwin/base.nix:34-43`
- commit `7624c84`

## Claim candidates

- NixOS is Niri layered over unreconciled X11-era services.
- Repo-provided OBS launcher cannot launch OBS on clean NixOS.
- Host selection distinguishes architecture/platform, not machine role.
- Standalone home override does not parameterize all desktop data.
- Standalone Secret portal depends on undeclared ambient keyring support.
- GTK/Qt state has multiple conflicting authorities and missing assets.
- Wayland automatic lock behavior is unproven and likely ineffective with X11 lockers.
- Noctalia is the active shell/bar/wallpaper authority while alternate artifacts remain stale.
- Darwin Kitty font may fall back because the configured font is not registered.

## EXPAND
- LEAD: live Niri user-service/DBus/login lock audit — WHY: settle notification, portal and lock ownership — ANGLE: systemctl --user, busctl, loginctl on activated host.
- LEAD: inspect live Noctalia runtime state — WHY: declared TOML may not be effective truth — ANGLE: per-host intent/runtime diff.
- LEAD: live font/GTK/Qt/Kitty diagnostics on Darwin/NixOS/standalone — WHY: confirm inferred fallbacks — ANGLE: fc-match, GTK inspector, qtpaths, Kitty diagnostics and screenshots.
- DEAD END: pure `/.config` target escapes home; Home Manager joins it beneath home, though embedded strings remain wrong.
- DEAD END: Noctalia recommended services secretly provide keyring/portals; pinned module does not.
