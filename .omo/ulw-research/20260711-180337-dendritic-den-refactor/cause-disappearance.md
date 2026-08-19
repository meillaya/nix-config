# Cause disappearance ledger

| cause id | expected truth | previous observation | last_seen | disconfirming observation | replacement cause | status | no longer observed |
|---|---|---|---|---|---|---|---|
| D1 | #473 to-users route works | issue reported broken | issue remains open 2026-07-11 | pinned custom fixture passes OS-user and HM delivery | current pipeline-native provides | resolved at pin | yes in fixture |
| D2 | host-scope HM implicitly reaches users | old intuitive assumption | pre-v0.18 semantics | #609 tests prove class-local suppression | explicit user aspect/to-users route | intentionally false | yes |
| D3 | Den user-shell can configure Nushell | generic battery name suggests yes | current pin | target-lock fixture proves missing OS programs.nushell | explicit OS registration + HM Nu | refuted | yes |
