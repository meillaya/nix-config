# Wave 3 — Operationally safe hash staging

## Findings
- Generate yescrypt interactively with `mkpasswd --method=yescrypt` redirected directly to a private file; no plaintext in argv/env/history.
- Stage locally in `$XDG_RUNTIME_DIR` only after confirming tmpfs; directory 0700, target tree and hash 0600.
- Validate yescrypt structure without printing hash; avoid `--debug`, shell tracing, clipboard, terminal recording, and build logs.
- `--extra-files` preserves modes and extracts as root due `--no-same-owner`.
- Cleanup local staging on exit/signals; target copy may persist after failed installation and must be treated as sensitive.

## Sources
- https://github.com/besser82/libxcrypt/blob/174c24d6e87aeae631bc0a7bb1ba983cf8def4de/doc/crypt.5#L172-L182
- https://github.com/nix-community/nixos-anywhere/blob/4dfb813db065afb0aba1f61658ef77993d382db1/src/nixos-anywhere.sh#L303-L308
- https://github.com/nix-community/nixos-anywhere/blob/4dfb813db065afb0aba1f61658ef77993d382db1/src/nixos-anywhere.sh#L876-L885

## EXPAND
- LEAD: Confirm local mkpasswd supports yescrypt — WHY: workflow runtime prerequisite — ANGLE: executed CLI help.
- LEAD: Confirm candidate config has only hashedPasswordFile — WHY: avoid ambiguous precedence — ANGLE: isolated eval.
- CLOSED: Shell-safe staging and cleanup pattern established.
