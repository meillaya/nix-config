# Wave 1 — Den shell battery and forwarding
Observer: Librarian the 23rd · Den pin 1614f6f8ed435c5bb257408bf91fd662f9aac43e · 2026-07-11

## Digest
`den.batteries.user-shell` is unsuitable for Nushell because it unconditionally emits `programs.nushell.enable` in NixOS/Darwin, where no such OS module exists. Use an explicit mei user aspect: Home Manager enables Nushell; NixOS/Darwin register and assign pkgs.nushell directly. Keep shell logic user-parametric and HM on the user aspect to avoid known routing drops. Den tests only Fish/NixOS; Darwin and Nushell need target-specific regression fixtures.

## EXPAND
- Two-platform Nushell fixture.
- Target-pin Darwin shell registration.
- Force HM package evaluation for user-shell issue #55 class.
- Reproduce/avoid #473/#609/#629 routing edges.
