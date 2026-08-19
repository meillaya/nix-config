# Wave 2 — one-shot file and fail-closed behavior

## Findings
- Classic backend reads `hashedPasswordFile` every activation, but mutable existing accounts retain their shadow hash.
- Missing file only warns; fresh account gets locked `!`; existing mutable account retains old hash; immutable account is reset/locked.
- File contents are not format-validated; empty file means passwordless login, making pre-activation validation mandatory.
- A persistent external file can be atomically replaced with `!` after users activation: later activations see a safe sentinel without warnings, while mutable existing password remains unchanged.
- Do not combine with lower-precedence fallback password sources.

## Sources
- https://github.com/NixOS/nixpkgs/blob/2f710f761a236666bcb740287a93427871db7ece/nixos/modules/config/update-users-groups.pl#L215-L315
- https://github.com/NixOS/nixpkgs/blob/2f710f761a236666bcb740287a93427871db7ece/nixos/modules/config/users-groups.nix#L50-L59
- https://github.com/NixOS/nixpkgs/blob/2f710f761a236666bcb740287a93427871db7ece/nixos/tests/password-option-override-ordering.nix#L52-L132

## EXPAND
- LEAD: Empirically test validation and post-users sentinel replacement ordering — WHY: safest one-shot design depends on it — ANGLE: isolated activation script or VM.
- CLOSED: Backend difference already resolved for current repo (classic mutable).
