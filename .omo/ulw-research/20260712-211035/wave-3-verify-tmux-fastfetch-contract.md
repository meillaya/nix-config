# Wave 3 — Rendered tmux and parsed Fastfetch contract

## Findings
- Home Manager has no dedicated allowPassthrough option; `programs.tmux.extraConfig` is appended to rendered tmux.conf.
- Exact insertion: first line of existing extraConfig: `set -g allow-passthrough on`.
- Exact-line counts can assert one occurrence in both extraConfig and rendered xdg tmux text.
- Fastfetch JSONC must be parsed with a string-aware comment stripper; naive `//` removal corrupts schema URLs and command strings.
- Current RED: tmux counts 0; logo type kitty; height missing. Temp override GREEN: counts 1; kitty-direct width 40 height 30.

## EXPAND
none — Home Manager option surface, render behavior, JSONC parsing, and false-positive-resistant assertions converged.
