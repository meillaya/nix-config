# Wave 3 — Claim convergence audit

## Findings
- Supported: plaintext options leak; hashedPasswordFile externalizes hash; mutable users preserve existing password; `/var/lib` persists on persistent root; `!` disables password login; agenix needs preprovisioned identity.
- Inline-hash offline cracking was marked partial by this lane alone, but earlier NIST/OWASP/libxcrypt observations independently supply the missing threat-model evidence.
- Generic phrase “/run is masked” was too broad. Final wording must be precise: a file staged into the on-disk target `/run` is unavailable at first users activation because nixos-install does not activate users and boot mounts runtime tmpfs at `/run` over that location.
- Hybrid fit is a policy recommendation inferred from LightDM, passworded sudo, wrong-key incident, and laptop use; do not present it as an externally proven universal fact.

## EXPAND
- DEAD END: No new lead; wording and claim-risk adjustments recorded.
