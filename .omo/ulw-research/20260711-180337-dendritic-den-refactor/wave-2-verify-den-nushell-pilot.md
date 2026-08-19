# Wave 2 — target-lock Den/Nushell pilot
Observer: Explorer the 26th · 2026-07-11

## Verdict: CONFIRMED
A temporary fixture matched this repo's locked nixpkgs 59e6964, HM abfad3d, and nix-darwin 43975d7 while pinning Den 1614f6f. Explicit NixOS/Darwin environment.shells + mei shell and HM programs.nushell evaluate successfully. Den user-shell Nushell battery is invalid. Linux flake check passed; Darwin config evaluated on Linux but could not be built. Fixture was removed.

## Key output
- NixOS: Nushell 0.104.0 account shell, HM enabled, environment shells includes Nu and Bash.
- Darwin: /run/current-system/sw/bin/nu registration, Nushell package account shell, HM enabled.

## EXPAND
none
