# Wave 1 — Transfer Metadata (live digest)

- Pinned order: closure upload -> extra-files tar -> chmod /mnt 755 -> explicit chown mappings -> nixos-install; `set -euo pipefail` means a failed transfer/chown aborts before activation.
- Faithful root experiment: tar over preexisting directory restored mode 700 but preserved the existing directory owner; overwritten file became root-owned 600. Exact `pr -2t` + chown postpass then made both directory and file 0:0 with 700/600.
- Archive headers: `.` 0700, intermediate var/lib 0755, bootstrap dir 0700, hash 0600.

## EXPAND
- LEAD: identify any metadata mutation between chown and validator — WHY: pre-install state is correct in faithful pipeline — ANGLE: nixos-install activation call chain.
