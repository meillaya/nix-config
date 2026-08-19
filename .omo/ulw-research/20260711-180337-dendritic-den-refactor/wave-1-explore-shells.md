# Wave 1 — shell and terminal precedence
Observer: Explorer the 16th · 2026-07-11

## Digest
Live account shell is Fish, but declarative NixOS and Darwin assign Zsh. Shared Home Manager enables Bash/Fish/Zsh. Standalone Ghostty explicitly launches `/bin/fish --login`, so login-shell changes alone cannot make Nushell the terminal default. tmux inherits its server context; the OMX wrapper forces SHELL toward Zsh. Nushell is wholly absent today. Existing shebang-pinned scripts should remain in their native interpreters.

## Claim candidates
- Set Nushell at account level and explicit terminal command; register Nushell, Bash, Zsh, and Fish as valid shells.
- Preserve all shebang languages; primary interactive shell does not imply script migration.
- Audit OMX/tmux environment precedence after deployment.

## EXPAND
none — all tracked shell declarations, launch commands, shebangs, eval projections, live state, and history were searched.
