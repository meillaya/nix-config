# Wave 3 — Skeptical recommendation review

## Verdict
Hybrid survives with amendments: unique per-install local password is needed for LightDM and passworded sudo; SSH must not be hardened to key-only until the correct key is configured/tested; lack of FDE remains a separate theft risk.

## Findings
- Current SSH defaults allow password and keyboard-interactive authentication; true key-only policy must disable both.
- Current root SSH key login remains allowed under `prohibit-password`; safer default is `PermitRootLogin = "no"` after user recovery is proven.
- If inbound SSH is unnecessary, disabling OpenSSH is simpler/safer than key-only SSH.
- Local password does not protect data at rest on current plaintext Disko layout.

## EXPAND
- LEAD: Correct SSH key/root policy is a prerequisite for a future hardening implementation, not for password-file recommendation itself.
- LEAD: FDE is separate hardening work; do not claim password solves theft.
- CLOSED: Hybrid recommendation survives adversarial review with explicit caveats.
