# Cause Disappearance

| cause_id | expected truth | previous observation | last_seen | disconfirming observation | replacement cause | status | violation gone? |
|---|---|---|---|---|---|---|---|
| K1 | Explicit chown resolves validator | Retry still fails same validator branch | 2026-07-13 | latest live retry | pending | refuted | no |
| K2 | Destination substitution errors recur | Latest retry omits them | prior retry | latest live retry | local-only transfer policy | resolved | yes |
| K3 | Numeric root ownership renders `root:root` during pre-users activation | named=UNKNOWN:UNKNOWN:700 while numeric=0:0:700 | 2026-07-13 | numeric directives remain stable | `%U:%G` NSS dependency | active | no |
| K4 | Transfer hook failed or later metadata mutation caused recurrence | exact transfer produces 0:0 700/600; exact empty-NSS activation fails unchanged inode | 2026-07-13 | multi-lane exact repro | pre-users name lookup | refuted | yes |
| K3 | Numeric root ownership renders root names before users | named UNKNOWN caused exact failure | 2026-07-13 | numeric validator passes same empty-NSS fixture | numeric ownership invariant | resolved | yes |
| K5 | Numeric checks might weaken root ownership | hostile NSS old check accepts UID/GID 1000/1234 while new rejects | 2026-07-13 | executed counterexample | none | refuted | yes |
