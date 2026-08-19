# Wave 3 — Repo-specific design ranking

## Ranking
1. `/var/lib` bootstrap hash validated before users and replaced with `!` after users.
2. Persistent `/var/lib` `hashedPasswordFile` (simpler, stale duplicate verifier risk).
3. Per-host agenix encrypted hash (good later, unsafe now due missing identity lifecycle).

## Findings
- Sentinel design removes duplicate verifier, avoids later missing-file warnings, and preserves mutable existing password.
- Requires pre-users validation, after-users atomic `!` replacement, and assertion that mutable classic backend remains enabled.
- Password rotation on installed machine remains imperative (`passwd mei`); next reinstall stages a new hash.
- Explicit key-only SSH policy should accompany local password provisioning.

## EXPAND
- LEAD: Empirically verify before/after activation ordering and validation policy — already scheduled Phase 3.
- LEAD: Pin SSH policy in eventual implementation — separate recommendation, not required to answer password mechanism.
- CLOSED: Design ranking converged under current repo constraints.
