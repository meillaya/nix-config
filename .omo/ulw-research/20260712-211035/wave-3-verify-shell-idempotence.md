# Wave 3 — Shell activation stub verification

## Results
- mismatch `/bin/zsh`: status 0, one read, exactly one create.
- matching `/run/current-system/sw/bin/nu`: status 0, one read, zero creates.
- read failure: status 41, no create.
- create failure: status 42.
- exact create: `. -create /Users/mei UserShell /run/current-system/sw/bin/nu`.
- production Nix string must escape shell interpolation as `''${current_shell#UserShell: }`.
- cleanup complete; no temp or tracked residue.

## EXPAND
none — mismatch, match, read failure, and write failure converged.
