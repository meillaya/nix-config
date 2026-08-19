# Verification economics

| claim | risk | error cost | verification cost/time | path | decision | outcome | residual risk |
|---|---|---|---|---|---|---|---|
| C3 output preservation | high | unbootable or missing configs | medium | baseline projection + full eval/build | verify | pending | pending |
| C4 shell behavior | high | login failure | medium | option eval + shell runtime smoke | verify | pending | pending |
| C4 Nushell direct aspect | high | login failure | medium | target-lock temporary Nix fixture | verify | CONFIRMED on NixOS eval and Darwin eval | no live Darwin activation |
| C4 live Nushell startup | high | login/terminal breakage | medium | post-change nix shell/runtime smoke | verify | pending | current live Nu absent |
| C3 output composition | high | lost apps/packages/configs | medium | six-config/four-system temporary flake | verify | CONFIRMED design shape | target-specific parity still required |
