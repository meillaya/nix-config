# Verification Economics

| claim | risk | error cost | verification cost/time | chosen path | decision | outcome | residual risk |
|---|---|---|---|---|---|---|---|
| Actual failing metadata tuple | high | repeated destructive install | medium, needs target observation | improve diagnostic + faithful namespace repro | verify | pending | live target credentials unavailable to agent |
| nixos-install path context | high | wrong fix location | low | inspect exact pinned source and execute activation harness | verify | pending | none expected |
| upstream chown semantics | high | repeat failure | low | exact source + local tar/chown simulation | verify | pending | filesystem differences |
| Name-vs-numeric stat cause | high | another destructive retry | low | empty-NSS mount-namespace execution of generated validator | verify | CONFIRMED | live target tuple still uncaptured but exact error reproduced |
