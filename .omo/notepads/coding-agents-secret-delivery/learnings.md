## F3+F4+F5 Final Verification (2026-07-27)

### F3: Nix Eval + Policy + Build
| Check | Result |
|-------|--------|
| hydralauncher count | 1 PASS |
| vesktop count | 1 PASS |
| codex-omx count (standalone-linux) | 1 PASS |
| opencode-omo count | 1 PASS |
| omniwm count (darwin) | 1 PASS |
| darwin toplevel derivation | FAIL - secrets/coding-agents.yaml untracked by git |
| sops.secrets attrNames | 5 keys PASS |
| package-policy.sh | PASS exit 0 |

Darwin toplevel note: Nix flakes use git ls-files for flake source. secrets/coding-agents.yaml exists on disk and is un-ignored but not yet git-added. Requires staging before nix can evaluate toplevel. Deployment prerequisite, not code defect.

### F4: Scope Fidelity - ALL PASS
flake.nix, flake.lock, tests/package-policy.sh, lib/nixpkgs.nix, README.md all unchanged. x86_64-darwin=0, opencode-omo=3, .gitignore has negation. No new overlays. 18 changed files match expected scope.

### F5: Secret Delivery - ALL PASS
sops exec-env delivers all 5 keys. sops-nix 5 secrets configured. standalone-linux codex-wrapped=2. secretspec CLI available via nix run; requires local provider init (documented).

### Key Learnings
- sops CLI not in PATH but available via nix run nixpkgs#sops
- secretspec available via nix run nixpkgs#secretspec (v0.13.0); requires --reason flag and provider init
- Nix flake eval requires all referenced files to be git-tracked; .gitignore negation alone is insufficient

- F2 scope fidelity check: all required out-of-scope paths had empty `git diff HEAD` output; all five required in-scope paths showed changes (94 insertions, 9 deletions). Result: PASS.
