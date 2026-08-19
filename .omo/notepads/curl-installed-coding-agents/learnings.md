## Verification Run — curl-installed-coding-agents plan

Date: 2026-07-29

### nix eval results (all PASS)

| Check | Expected | Actual | Status |
|-------|----------|--------|--------|
| NixOS has `codex-omx` | 1 | 1 | PASS |
| standalone-linux has `codex-omx` | 0 | 0 | PASS |
| standalone-linux has `pi-wrapped` | 1 | 1 | PASS |
| standalone-linux has `hermes-wrapped` | 1 | 1 | PASS |
| standalone-linux has `zeroclaw-wrapped` | 1 | 1 | PASS |
| darwin has `pi-wrapped` | 1 | 1 | PASS |

### Bash test results

- `bash tests/package-policy.sh` → `package-policy-source=PASS`, `package-policy-probe=PASS`, exit 0 → PASS

### nix flake check

- Exit code: 0 (technically passes)
- Stderr includes pre-existing sublimetext4 evaluation refusal:
  > error: Refusing to evaluate package 'sublimetext4-4200' ... broken: Packages, including core ones, do not run without plug-in host depending on insecure OpenSSL.
- This matches inherited wisdom — pre-existing failure unrelated to this plan. Mitigation available via `nixpkgs.config.problems.handlers.sublimetext4.broken = "warn"` but not required for verification.

### Observations

- The "SQLite database ... is busy" warning during parallel nix eval is non-fatal and ignored by Nix.
- The "Git tree has uncommitted changes" warning is from the work-in-progress state of this plan.
- The "Nix search path entry '/home/mei/.nix-defexpr/channels' does not exist" warning on `package-policy.sh` is benign.
- All wrappers (`pi-wrapped`, `hermes-wrapped`, `zeroclaw-wrapped`) are correctly present on standalone-linux and darwin.
- codex-omx is correctly gated: present on NixOS (default), absent on standalone-linux (override `includeCodingAgentDerivations=false`).
