# Wave 2 — target-lock shell behavior
Observer: Explorer the 27th · 2026-07-11

## Digest
Locked HM provides Nushell options; locked NixOS/Darwin do not. Current HM Nushell is disabled but Yazi already contributes extraConfig. Ghostty hardcodes Fish, tmux inherits Zsh in the tested environment, OMX forces Zsh/Bash, and per-shell OMX PATH precedence differs. Nushell runtime is not installed live. Migration must enable Nu in shared HM, explicitly set OS shell registrations, change Ghostty to Nu, and decide whether OMX's internal POSIX/Zsh compatibility should remain (recommended: retain wrapper interpreter behavior rather than forcing Nu).

## EXPAND
- Post-change generated Nu files and login smoke.
- Verify OMX remains intentionally POSIX/Zsh internally while terminal/user shell is Nu.
