# Wave 1 — Official nix-darwin shell contract

## Findings
- Current nix-darwin changes existing users only when `knownUsers`, matching `uid`, and non-null `shell` converge; it writes Directory Service with `dscl`, not chsh.
- `users.users.<name>.shell` alone installs/evaluates a shell but does not enroll the user.
- `environment.shells` only generates `/etc/shells`; `system.primaryUser` has no dataflow into knownUsers/UID/shell enrollment.
- Official option guidance says not to add admin/system users to knownUsers, creating a safety tension for the primary admin. A narrow post-activation reconciliation is safer for this repo.
- Correct UserShell does not override Terminal custom commands, persistent tmux defaults, or already-running shells.

## Primary sources
- https://github.com/nix-darwin/nix-darwin/blob/d5bd9cd77aea4c0a8f49e7fd85545671a208ed15/modules/users/default.nix#L17-L41
- https://github.com/nix-darwin/nix-darwin/blob/d5bd9cd77aea4c0a8f49e7fd85545671a208ed15/modules/users/default.nix#L278-L318
- https://github.com/nix-darwin/nix-darwin/blob/d5bd9cd77aea4c0a8f49e7fd85545671a208ed15/modules/system/shells.nix#L11-L54
- https://nix-darwin.github.io/nix-darwin/manual/#opt-users.knownUsers
- https://support.apple.com/en-ca/102360

## Executed upstream verification
- without known user: shell installed, no UserShell dscl.
- with known user and UID: UserShell dscl emitted.
- primaryUser alone: no dscl.
- environment.shells alone: approved path present, package not installed.

## EXPAND
- LEAD: issue #1237 documents stale/safety-conflicting knownUsers guidance — WHY: built-in management would broaden ownership of admin account — ANGLE: close by choosing narrow local activation instead of upstream ownership.
- LEAD: check terminal/tmux explicit-shell overrides after Directory Service correction — WHY: correct account state may still launch another shell — ANGLE: inspect repo terminal configs.
- DEAD END: nix-darwin has no hidden chsh path or primaryUser enrollment.
