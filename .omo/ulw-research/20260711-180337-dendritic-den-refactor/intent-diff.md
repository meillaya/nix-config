# Intent vs reality

| intent_id | expected truth | observed reality | diff | violated invariant | intent source | supporting observations | status | claim ids |
|---|---|---|---|---|---|---|---|---|
| I1 | Den is authoritative composition layer | Current repo has manual flake/host imports; target design uses pinned Den inside flake-parts | migration required | architecture authority | user + Den docs | O1,O2,O10,O25 | violated | C1,C5 |
| I2 | Concerns are capability-oriented aspects | Current seams exist but are split by platform/host trees | files must be regrouped without changing behavior | dendritic organization | user | O8,O20 | violated | C2 |
| I3 | Existing outputs/behavior preserved | Baseline output families all evaluate; migration matrix and output fixture define preservation path | not yet migrated | no regression | user + current repo | O4,O6,O9,O20,O25 | true baseline / implementation pending | C3,C5 |
| I4 | Nushell is primary terminal/login shell | Live Fish; declarative Zsh; Ghostty hardcodes Fish; Nu absent | explicit account + terminal + HM change required | primary shell | user | O12,O13,O15,O23,O24 | violated | C4 |
| I5 | Bash/Zsh/Fish remain secondary | HM enables all three; NixOS registration incomplete | preserve configs/packages/registration and shebang behavior | secondary compatibility | user | O12,O15,O24 | true baseline / implementation pending | C4 |
| I6 | Clean/logical/smart without gratuitous abstraction | Den provides value but v0 routing/debug complexity is real | use smallest current API and explicit routes only | maintainability | user + examples | O11,O14,O19,O21,O22 | true target decision | C1,C2,C6 |
