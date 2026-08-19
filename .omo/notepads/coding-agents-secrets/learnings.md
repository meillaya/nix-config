
## SOPS + Age Setup (2026-07-27)

### Key Findings
- No `~/.ssh/id_ed25519` exists on this machine; sops.nix references it but it's absent
- `ssh-to-age` is NOT installed; only `age-keygen` is available via nix profile
- Generated age key at `~/.config/sops/age/keys.txt` with public key: `age1xxj3ft4g9gkfryedx85z9je76s07xxfqcvzl4c3t777d45hfgpvqwkpclc`
- `sops` is not in PATH directly; must use `nix run nixpkgs#sops --` to invoke

### SOPS Encryption Gotcha
- `sops --encrypt` matches creation rules by **file path**. Encrypting from `/tmp/` won't match `secrets/coding-agents\.yaml$` path_regex
- Solution: write plaintext to the target path, then `sops --encrypt --in-place <path>` from the repo root
- The `.sops.yaml` must be in the working directory (or use `--config`) for creation rules to apply

### .gitignore Pattern
- Repo uses `secrets/*` (glob) not `secrets/` (directory ignore)
- Exception `!secrets/coding-agents.yaml` added after `!secrets/README.md`
- `git check-ignore` returns exit 1 (not ignored) — confirmed trackable

## sops.secrets declarations in sops.nix (2026-07-27)
- sops.secrets entries go INSIDE each platform submodule (nixos/darwin) in `den.aspects.sops`, after `environment.systemPackages`
- sopsFile path `../../../secrets/coding-agents.yaml` is relative to `modules/aspects/features/sops.nix` (features -> aspects -> modules -> repo root)
- `format = "yaml"` is required for YAML sops files
- Verification: `nix eval .#nixosConfigurations.x86_64-linux.config.sops.secrets --apply 's: builtins.attrNames s'` confirms declared secrets
- The git tree shows uncommitted changes warning during eval - that's expected, not an error

## Secret Delivery Verification (2026-07-27)
- All 3 verification methods pass:
  1. `sops --decrypt` shows all 5 keys: OPENAI_API_KEY, ANTHROPIC_API_KEY, GEMINI_API_KEY, OPENROUTER_API_KEY, GITHUB_TOKEN
  2. `sops exec-env` delivers all 5 as env vars (confirmed via grep)
  3. `nix eval .#nixosConfigurations.x86_64-linux.config.sops.secrets --apply 's: builtins.attrNames s'` returns all 5 attr names
- Values are placeholders (e.g. `placeholder-openai-key`) — correct for initial setup
- sops-nix activation-time delivery is wired and evaluable
