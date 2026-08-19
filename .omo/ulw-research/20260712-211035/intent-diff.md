# Intent vs Reality
| intent_id | expected truth | observed reality | diff | violated invariant | intent source | supporting observations | status | claim ids |
|---|---|---|---|---|---|---|---|---|
| I1 | macOS account login shell is Nushell after activation | option evaluates to Nu but generated account activation omits mei | declaration does not mutate Directory Service | account state must converge, not merely evaluate | user report | O4,O5,O6,O8,O9,O10 | violated | C1,C2 |
| I2 | Kitty is installed on macOS | both Darwin package lists omit Kitty | app and CLI absent | requested terminal must be in Darwin package graph | user report | O7,O13,O15 | violated | C3 |
| I3 | Fastfetch renders Snoopy on macOS | asset now exists, but current `kitty` backend depends on conversion and tmux blocks passthrough | producer/terminal pipeline not deterministic | asset, backend, terminal, multiplexer must agree | user report | O1,O11,O12,O13,O16 | violated | C4,C5,C6 |
