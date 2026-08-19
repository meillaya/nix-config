# Claim Graph

## Verified claims

| claim_id | verified claim | evidence |
|---|---|---|
| C1 | A unique per-install yescrypt verifier can be delivered outside Git/store through nixos-anywhere `--extra-files` to persistent `/var/lib`, then consumed by `hashedPasswordFile`. | O2, O3, O4, O8, O10, V1 |
| C2 | Plaintext password options and committed reusable hashes are unsafe for this public repo; use an external runtime file and never interpolate secret contents into Nix. | O3, O5, O6, O9 |
| C3 | With the current classic backend and `users.mutableUsers=true`, a password source initializes a fresh account while later imperative password changes persist. | O2, O3, O11, V1 |
| C5 | Stock missing/malformed-file behavior is not fail-closed enough; an ordered validator can reject bad inputs, and `!` is a safe consumed sentinel for later mutable-user activations. | O3, O11, O12, V2 |

| claim_id | statement | type | risk | scope | intent ids | supports | contradicts | independent groups | convergence | counter-search | primary source | dependencies | status | synthesis location |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| C1 | Unique per-install local password via external yescrypt hash is feasible | config/security | high | repo/install | I1,I2 | O2,O3,O4,O8,O10,V1 | early O4 `/run` subclaim refuted | repo runtime, nixpkgs, nixos-anywhere, execution | converged | `/run`, inline hash, agenix alternatives searched | nixpkgs+nixos-anywhere | C3,C5 | supported | Executive recommendation |
| C2 | No plaintext or reusable hash should be committed | security | high | public repo | I2 | O3,O5,O6,O9 | none stronger | Nix manual, nixpkgs, NIST, repo audit | converged | salted-hash harmlessness counter-searched | Nix manual+nixpkgs+NIST | none | supported | Safety rationale |
| C3 | Mutable-user lifecycle preserves later password changes | semantics | high | NixOS | I3 | O2,O3,O11,V1 | none | local eval, upstream source, activation analysis | converged | sysusers/userborn checked and false | nixpkgs | C1 | supported | Lifecycle |
| C4 | Candidate preserves groups, SSH keys, and system evaluation | regression | normal | repo | I4 | O1,V1 | wrong SSH key remains pre-existing | repo inspection, overlay eval | converged | adjacent imports/session checked | repo config | C1 | supported | Repo fit |
| C5 | Ordered validation plus consumed `!` sentinel fails closed | security | high | activation | I5 | O11,O12,V2 | stock updater alone only warns | upstream source, shadow semantics, executed validator matrix | converged | empty/missing/multiline/malformed/mode cases run | nixpkgs+shadow | C1,C3 | supported | Failure modes |
| C6 | On-disk `/run` staging works across first boot | install semantics | high | installer | I1 | early O4 | O8,O10 | two upstream source analyses + integration test | refuted | both initrd paths checked | nixpkgs+nixos-anywhere | none | refuted | Contradictions |
| C7 | Hybrid local password plus key-only SSH is best for this laptop | policy inference | normal | laptop | I1,I4 | O1,O7,O13 | SSH-only viable under stronger assumptions | repo UX/security observations | conditional | adversarial critic completed | repo config+nixpkgs | C1 | partial | Recommendation caveats |
