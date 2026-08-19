
## secretspec.toml secret declarations (2026-07-27)
- 5 coding agent keys added to `[profiles.default]`: OPENAI_API_KEY, ANTHROPIC_API_KEY, GEMINI_API_KEY, OPENROUTER_API_KEY, GITHUB_TOKEN
- All declared `required = false` with description-only (no provider binding)
- Delivery mechanism is `sops exec-env`, NOT secretspec providers — comment documents this to prevent dotenv:// misconfiguration
- secretspec CLI not installed on this host; validated TOML syntax with python3 tomllib instead
- secretspec 0.13.0 (pinned nixpkgs) lacks age provider; that lands in 0.17+
