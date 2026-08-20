Place local sops-encrypted secret files in this directory when needed.

This directory is intentionally ignored by git (except for this file and
`coding-agents.yaml`) so the public flake can bootstrap on fresh macOS
and Linux installs without fetching a private GitHub secrets repository
during evaluation.

The single tracked file is `coding-agents.yaml`, encrypted with `sops-nix`
using the two age recipients declared in `../.sops.yaml`. Operators who
need a personal override (e.g. a different provider key set) can
replace it locally; the working-tree replacement is untracked by git.

For per-tool runtime API keys (OpenAI, Anthropic, etc.), use the
`codex-wrapped` shim that injects the sops-decoded values from
`coding-agents.yaml` into the agent's environment.
