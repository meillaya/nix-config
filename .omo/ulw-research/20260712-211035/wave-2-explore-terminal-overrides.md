# Wave 2 — Terminal and tmux shell overrides

## Findings
- Darwin renders no Ghostty/Kitty/iTerm2/Apple Terminal command/profile override.
- Home Manager tmux shell is null; rendered config has no default-shell/default-command and inherits account state.
- No current/history override forces zsh in those macOS terminals. Fresh tmux uses current account/default shell.
- Latent Emacs vterm zsh exists only in an unmanaged config.org and is outside this requested surface.
- Existing pre-change tmux server can retain old state; live acceptance must restart it.

## EXPAND
- DEAD END: declarative terminal override cause — none exists.
- LEAD: live host restart/dscl validation — environment-gated to physical Mac; record as residual acceptance step.
