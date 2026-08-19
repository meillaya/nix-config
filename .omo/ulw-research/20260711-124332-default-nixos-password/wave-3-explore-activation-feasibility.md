# Wave 3 — Activation ordering feasibility

## Findings
- Hypothetical repo shape: set `users.users.mei.hashedPasswordFile = "/var/lib/nixos-bootstrap/mei-password.hash"`.
- Add `bootstrapPasswordHash` activation fragment that validates existence, one-line format, ownership/mode, and crypt syntax; make `users.deps` include it.
- Explicit assertion should lock classic backend (`!sysusers && !userborn`).
- Synthetic evaluation put validator before users activation.
- Lifecycle remains a policy decision: retain real hash or accept `!` sentinel and post-users replacement.

## Evidence
- Pinned activation option supports `{ text, deps, supportsDryActivation }`.
- `hosts/nixos/default.nix:272-283` is insertion point.
- Local pinned users updater only warns on missing file.

## EXPAND
- LEAD: Execute isolated overlay evaluation and malformed/missing validation — WHY: feasibility must be proven by commands — ANGLE: Phase 3 empirical verification.
- LEAD: Resolve retained hash vs sentinel lifecycle — WHY: validation regex and cleanup differ — ANGLE: design review.
