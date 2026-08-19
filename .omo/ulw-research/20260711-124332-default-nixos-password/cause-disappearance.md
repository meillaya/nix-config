# Cause Disappearance

| cause_id | expected truth | previous observation | last_seen | disconfirming observation | replacement cause | status | violation no longer observed |
|---|---|---|---|---|---|---|---|
| CA1 | `mei` has a usable fresh-install credential | Production repo has no password and configured SSH key mismatches source workstation | 2026-07-11 | Isolated candidate evaluates and validates safely | Production change not requested | proposed resolution only | no |
| CA2 | Installer-staged hash is visible at first activation | Early wave proposed `/run` | wave 1 | install/initrd source and integration test show `/run` unavailable, `/var/lib` persists | `/var/lib/nixos-bootstrap` | resolved research cause | yes |
