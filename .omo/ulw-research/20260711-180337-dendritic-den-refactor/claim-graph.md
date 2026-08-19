# Claim graph

## Verified claims

- C1: Pinned Den inside flake-parts is the selected authority for configuration entities; supported by Den primary docs/source and independent implementations.
- C3: Current output families are characterizable and a flake-parts+Den fixture preserves the same categories; target parity remains implementation-gated.
- C4: Explicit Nushell registration + user shell + HM module works against target locks on NixOS/Darwin evaluation; Den user-shell battery must not be used.
- C5: Flake-parts outer composition with Den configuration outputs and perSystem operational outputs is fixture-confirmed.
- C6: #629 direct host-class user args are silently inert; user HM belongs to user aspects and explicit provides.to-users is the safe cross-entity route.

| claim_id | statement | type | risk | scope | intent ids | support | contradiction | groups | convergence | counter-search | primary | dependencies | status | synthesis |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| C1 | Use pinned Den as configuration entity/aspect layer inside flake-parts | design/code | high | repo | I1,I6 | O1,O2,O10,O11,O14,O19,O22,O25 | Den complexity/v0 churn O19 | 6 independent | converged with minimal subset | plain flake-parts compared | Den docs/source | none | supported | Architecture decision |
| C2 | Migrate by coherent capability aspects, incrementally | design | high | repo | I2,I6 | O3,O8,O11,O14,O20 | one-commit migrations O18 | 5 independent | converged | big-bang search found no authoritative support | Den migration guide | C1 | supported | Migration shape |
| C3 | Preserve all named outputs and critical behavior through characterization | code | high | repo | I3 | O4,O6,O9,O20,O25 | none | repo + independent fixture | converged | output inventory cross-checked | current repo/Den template | C1,C2 | supported | Verification contract |
| C4 | Explicit Nu OS registration/account shell + HM module makes Nu primary while POSIX shells remain | code | high | shells | I4,I5 | O12,O15,O17,O23,O24 | Den user-shell battery invalid for Nu | 5 independent + execution | converged | battery and native module counter-search | Nixpkgs/HM/Darwin source | C1,C3 | supported | Shell decision |
| C5 | Flake-parts outer; Den config outputs; perSystem operational outputs; top-level overlays | code/design | high | flake | I1,I3,I6 | O9,O10,O22,O25 | Den-only minimal template | 4 independent + fixture | converged | alternatives executed/compared | Den output/template source | C1,C3 | supported | Output boundary |
| C6 | Avoid direct host-class user args; use user aspects or explicit to-users routing | code | high | routing | I2,I6 | O17,O21 | stale issue #473 tracker | source + executed fixture | converged | #473/#609/#629 reproduced | Den source/tests | C1 | supported | Routing rules |
| C7 | Migration duration has a reliable general estimate | non-code | high | planning | none | self-reports only | wide range | insufficient | not converged | no average found | none | none | unresolved | Gaps only |
