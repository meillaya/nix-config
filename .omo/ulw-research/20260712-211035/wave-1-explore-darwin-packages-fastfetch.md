# Wave 1 — Darwin packages, history, and Fastfetch ownership

## Findings
- Both Darwin package surfaces contain ghostty-bin and Fastfetch but omit Kitty; Kitty was deliberately removed historically and later restored only for standalone Linux.
- The user explicitly requests Kitty now, so the historical non-install policy is superseded for this task.
- Both current Darwin HM sources contain config.jsonc and the byte-identical Snoopy PNG after d9ab9e3.
- Historical evaluation at d9ab9e3^ proved the config existed but the asset did not; local Fastfetch reproduced missing-source ASCII fallback.
- Kitty absence did not cause the historical fallback. Current graphical rendering remains separately unverified.
- Coverage lacks Darwin Kitty package assertions and evaluated Fastfetch protocol shape.

## Evidence
- `modules/darwin/packages.nix:4-25`
- `modules/shared/packages.nix:205-217`
- `modules/shared/files.nix:26-29`
- `modules/shared/config/fastfetch/config.jsonc:4-5`
- commit d9ab9e3 and historical commit 99641d0
- dual-architecture Nix eval and Fastfetch 2.65.1 reproduction

## EXPAND
none — repo ownership/history/evaluation converged; only physical macOS activation/rendering remains environment-gated.
