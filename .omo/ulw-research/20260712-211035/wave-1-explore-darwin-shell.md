# Wave 1 — Darwin shell activation

## Findings
- Darwin `users.users.mei.shell` evaluates to Nushell, but `users.knownUsers` and `users.uids` omit mei.
- Generated `system.activationScripts.users.text` has zero `mei` and zero `UserShell` occurrences.
- Pinned nix-darwin forms createdUsers only from known users with UIDs and writes UserShell only for createdUsers.
- nix-darwin explicitly warns not to add an admin/system user to knownUsers.
- Minimal safe direction: idempotent root activation reconciles `/Users/mei UserShell` to `/run/current-system/sw/bin/nu`; `/etc/shells` already includes that path.

## Evidence
- `modules/entities/hosts.nix:17-20`
- `modules/aspects/users/mei.nix:3-17`
- pinned nix-darwin `modules/users/default.nix:17-24,61-68,275-315`
- evaluated users/activation outputs captured by worker

## EXPAND
- LEAD: live macOS `dscl . -read /Users/mei UserShell` after activation — WHY: physical Directory Service confirmation — ANGLE: user-machine QA; unavailable on Linux runner, retain as explicit residual validation.
