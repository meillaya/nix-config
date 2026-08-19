# Claim Graph

## verified-claims

| claim_id | verified statement | supporting observations | counter-search | status |
|---|---|---|---|---|
| C6 | Exact one-entry transfer/chown produces numeric 0:0 at 0700/0600 before activation | O7,O11,O19 | repeat-directory tar and upstream ordering | supported |
| C7 | Validator runs in the target chroot before passwd/group creation | O10,O12,O13,O15 | wrong-root and NSS-available alternatives | supported |
| C8 | Early abort prevents `/run/current-system`, producing secondary switch ENOENT | O8,O13,O14 | ignored activation status traced through next exec | supported |
| C9/C10 | Numeric ownership is the stable and stricter security invariant | O12,O17,O18,O19,O20 | hostile NSS and wrong-ID matrices | supported |
| C11 | Numeric pre-users creation/mutation works with empty target NSS | O17,O19 | name-based chown/install mutants | supported |
| C12 | Recovery mode depends on observed mount state; default helper rerun is destructive | O14,O16 | pinned phase/mount source and docs | supported |

| claim_id | statement | type | risk | scope | intent_ids | supports | contradicts | groups | convergence | counter-search | primary source | dependencies | status | synthesis location |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| C1 | The validator failure is caused by directory metadata or lookup context, not hash content | causal code | high | activation | I1 | pending | pending | pending | open | pending | module + runtime | none | unresolved | pending |
| C2 | Upstream chown alone is insufficient for this target state | causal code | high | transfer | I2 | pending | pending | pending | open | pending | upstream source + execution | C1 | unresolved | pending |
| C3 | Disabling destination substitution removed the earlier cache errors | behavioral | normal | transfer | I3 | latest log | none | user runtime | partial | pending | upstream source | none | partial | pending |
| C4 | Missing switch-to-configuration is a downstream consequence of activation failure | causal code | normal | install | I4 | pending | pending | pending | open | pending | nixos-install source | C1 | unresolved | pending |
| C5 | Name-based `%U:%G` makes correct numeric root ownership fail before passwd/group exist | causal code | high | activation | I1,I2 | O8,O10 | none yet | activation-member,root-runtime | two-group convergence pending member NSS | active counter-search | generated validator + GNU stat execution | C1 | supported | pending |
| C6 | Exact one-entry extra-files/chown pipeline produces numeric 0:0 and modes 0700/0600 before activation | causal code | high | transfer | I1,I2 | O7,O11 | transfer-failure hypothesis | transfer-member,root-runtime | two independent groups | exact argv + repeat-dir countercase | pinned source + executed repro | none | verified | pending |
| C7 | Validator runs in target chroot before passwd/group creation and therefore sees UNKNOWN names | causal code | high | activation | I1,I5 | O10,O12,O13,O15 | wrong-root/NSS-available alternatives | nss,activation,skeptic,root | four-group convergence | exact chroot and alternate NSS matrix | generated activation + pinned sources | C5 | verified | pending |
| C8 | Validator abort prevents /run/current-system creation; ignored activate failure is followed by switch path ENOENT | causal code | high | install | I4 | O8,O13,O14 | independent switch failure | activation,upstream | two-group convergence | exact source chain | d407951 sources | C7 | verified | pending |
| C9 | Numeric `%u:%g` is the stable early-activation invariant and upstream precedent | design | high | activation | I5 | O12,O14,O15 | alias/NSS variations | nss,upstream,skeptic | three-group convergence | aliases, missing files, systemd NSS | upstream + executed matrix | C7 | verified | pending |
| C10 | Numeric validator fixes empty-NSS false rejection and rejects nonzero IDs named root | security behavioral | high | activation | I1,I5 | O17,O18,O19,O20 | numeric weaker/name equivalent | root,transfer,activation,skeptic | four-group convergence | hostile NSS and wrong-ID matrix | executed validators + generated system | C9 | verified | pending |
| C11 | Numeric pre-users install/chown operations preserve missing-verifier migration under empty NSS | behavioral | high | activation | I5 | O17,O19 | latent branch failure | root,nss,transfer | three-group convergence | root-name mutations pending | lifecycle + command matrix | C9 | supported | pending |
| C12 | Safe retry depends on mount state: install-only while /mnt remains mounted; otherwise documented mount mode | operational | high | recovery | I6 | O16,O14 | default helper rerun | recovery,upstream | two-group convergence | source/official guide | pinned docs/source | C8 | verified | pending |

## Final verified claims
- C6: exact transfer pipeline establishes numeric 0:0 at 0700/0600.
- C7: validator runs in target chroot before passwd/group creation.
- C8: early abort prevents `/run/current-system`, producing the secondary switch ENOENT.
- C9/C10: numeric ownership is the stable invariant and is stricter under hostile NSS.
- C11: numeric pre-users creation/mutation paths pass with empty target NSS.
- C12: recovery mode must be selected from observed mount state; default helper rerun remains destructive.

All material causal claims reached at least two independent observer groups plus executed evidence. Hardware retry remains an explicitly scoped live-only limitation, not an unresolved local cause.
