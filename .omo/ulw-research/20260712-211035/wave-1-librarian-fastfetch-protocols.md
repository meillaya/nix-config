# Wave 1 — Fastfetch protocol and fallback behavior

## Findings
- Explicit missing/unreadable image source or backend failure returns false and falls back to detected built-in ASCII (Apple logo on macOS).
- Merely using an unsupported terminal protocol usually emits ignored bytes and does not cause ASCII fallback; therefore the observed Apple fallback indicates missing source or backend/conversion failure, not simply Apple Terminal lacking Kitty support.
- Current `kitty` mode requires ImageMagick conversion. `kitty-direct` sends a resolved PNG pathname, avoids ImageMagick, and is officially supported by Kitty/Ghostty.
- `kitty-direct` should specify width and height for deterministic layout. The repo asset is PNG, so no conversion is needed.
- `~` expansion is supported on macOS; the path itself is valid once Home Manager deploys the asset.
- Apple Terminal portability would require chafa; the user's explicit Kitty requirement is better met by installing/using Kitty and selecting kitty-direct.

## Primary sources
- https://github.com/fastfetch-cli/fastfetch/blob/e0c31be9d5e8bd227307d50050850c51d80b93a4/src/logo/logo.c#L453-L496
- https://github.com/fastfetch-cli/fastfetch/blob/e0c31be9d5e8bd227307d50050850c51d80b93a4/src/logo/logo.c#L607-L685
- https://github.com/fastfetch-cli/fastfetch/blob/e0c31be9d5e8bd227307d50050850c51d80b93a4/src/logo/image/image.c#L230-L340
- https://github.com/fastfetch-cli/fastfetch/wiki/Logo-options#kitty-direct
- https://sw.kovidgoyal.net/kitty/graphics-protocol/#the-transmission-medium

## Executed evidence
- Fastfetch 2.65.1: missing source for explicit image modes prints `Failed to resolve logo source` then ASCII.
- Existing source with kitty-direct emits `_Ga=T,f=100,t=f` and no ASCII fallback.
- Tilde path expands before protocol emission.

## EXPAND
- LEAD: empirically verify repo Snoopy PNG with proposed kitty-direct and inspect tmux passthrough — WHY: proves exact local artifact/config compatibility — ANGLE: wave-2 execution.
- DEAD END: asset format normalization; current asset is already PNG.
- DEAD END: Powerlevel10k ordering; repo shell startup does not use p10k.
