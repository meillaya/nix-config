# Expansion Log

## Wave 0
- Session initialized.
- Leads open: NixOS password options; hash generation; secret storage; mutableUsers semantics; installation/recovery UX; repo compatibility; adversarial failure modes.

## Wave 0 planner recovery
- Original plan agent: inconclusive and closed.
- Narrow planner: completed.
- New leads: pinned-option semantics; repo import trace; prototype evaluation; acceptance paths.

## Wave 1 return — adversarial design
- Leads opened: durable decryption identity provisioning; FDE/recovery custody.

## Wave 1 returns — repo auth and option semantics
- Leads opened: first-boot agenix identity; root key-login intent; explicit SSH policy.
- Option semantics lane converged with no open lead.

## Wave 1 returns — secret handling, nixos-anywhere, regressions
- Leads opened: sysusers/userborn verification; historical secret exposure; post-install policy; one-shot vs persistent hash file.
- Unrelated install-app defect recorded but closed out of scope.

## Wave 2 return — local backend/security
- Closed: backend, FDE, configured/local key match, active agenix secret status.
- Leads retained: target runtime audit; first-boot identity custody.

## Wave 2 returns — laptop policy, layout, agenix
- Policy converged on unique per-install local password plus key-only SSH.
- Critical contradiction opened: `/run` one-shot path vs `/var/lib` persistent path.
- Agenix host-key bootstrap is viable but operationally more complex.

## Wave 2 return — one-shot fail-closed
- Opened: empirical validation/sentinel ordering proof.
- Closed: missing, malformed, empty, mutable, immutable semantics from source.

## Wave 2 return — exposure audit
- Closed: current/history plaintext/hash/private-key exposure; no finding.

## Wave 3 return — /run counter-search
- Critical contradiction resolved: /run refuted, /var/lib supported.
- No new lead.

## Wave 3 return — operational secrecy
- Opened only empirical checks: yescrypt support; single password source.
- No new conceptual lead.

## Wave 3 return — activation feasibility
- Opened only scheduled empirical proofs and lifecycle choice.

## Wave 3 return — design ranking
- Recommended sentinel lifecycle; no new research territory beyond scheduled execution proof.

## Wave 3 return — skeptical hybrid review
- Recommendation survives with wrong-key and no-FDE caveats.
- No new password-mechanism lead.

## Wave 3 return — claim audit
- Adjusted wording/risk classification; no unchecked lead.
- Three expansion waves complete; conceptual convergence reached. Remaining work is empirical verification.
