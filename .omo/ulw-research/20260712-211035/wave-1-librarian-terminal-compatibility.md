# Wave 1 — Terminal compatibility

## Key findings
- Kitty is the reference implementation of Kitty graphics; Ghostty supports static Kitty graphics and nixpkgs `ghostty-bin` preserves official macOS app behavior.
- Fastfetch explicitly documents `kitty-direct` for PNG on Kitty/Ghostty. It requires both width and height and avoids ImageMagick conversion.
- Current iTerm2 supports Kitty graphics, but Fastfetch deterministically prefers its native `iterm` type there.
- Apple Terminal has no established inline-image protocol; a Kitty image cannot be expected to render.
- Do not spoof TERM. tmux requires `tmux-256color` and `allow-passthrough on`.

## Sources
1. https://sw.kovidgoyal.net/kitty/graphics-protocol/
2. https://ghostty.org/docs/features
3. https://ghostty.org/docs/install/binary
4. https://github.com/fastfetch-cli/fastfetch/wiki/Logo-options
5. https://iterm2.com/downloads.html
6. https://support.apple.com/en-ca/guide/terminal/trmld4c92d55/mac
7. https://github.com/tmux/tmux/wiki/FAQ
8. https://github.com/fastfetch-cli/fastfetch/blob/e0c31be9d5e8bd227307d50050850c51d80b93a4/src/logo/logo.c#L641-L674

## EXPAND
- LEAD: prove current repo can use kitty-direct with explicit dimensions and managed PNG — WHY: removes conversion and terminal-detection ambiguity — ANGLE: local Fastfetch CLI byte/protocol verification.
- LEAD: inspect tmux config for allow-passthrough — WHY: startup Fastfetch inside tmux may otherwise fall back or emit nothing — ANGLE: repo search and rendered HM config.
- DEAD END: forcing TERM to xterm-kitty — unsupported terminals do not gain graphics capability.
