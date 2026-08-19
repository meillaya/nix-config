# nixos-darwin-config

Personal Nix config for:

- macOS via `nix-darwin`
- Linux via `NixOS`
- Existing Linux installs, including WSL, via Determinate Nix + standalone Home Manager

## Recent changes

- The flake now follows Den's dendritic model: flake-parts owns output
  composition, Den owns machine/home entities, and capability aspects own
  configuration. See `docs/architecture/dendritic.md`.
- Nushell is the primary login and Ghostty shell. Bash, Zsh, and Fish remain
  installed, configured, and available as secondary shells.
- Shell UX is aligned across `zsh`, `bash`, `fish`, and Readline-backed shells.
- Package lookup works through `nix run .#search-pkgs -- <query>`.
- Non-NixOS Linux now has a standalone Home Manager path for existing machines like Arch Linux with Niri.
- Niri config is shared between NixOS and standalone Linux Home Manager.
- Noctalia external monitor brightness is documented in
  `docs/service-notes/noctalia-ddc-brightness.md`; root-level DDC/CI setup on
  non-NixOS systems remains an explicit manual OS task.

## Search and add packages

Search before installing:

```bash
nix run .#search-pkgs -- ghostty
```

Then add the chosen attribute to:

- `modules/shared/packages.nix` for all machines
- `modules/darwin/packages.nix` for macOS only
- `modules/nixos/packages.nix` for NixOS only
- `modules/standalone-linux/packages.nix` for existing non-NixOS Linux machines


## Update packages

Use the repo update app instead of plain `nix flake update` when you want
flake inputs and the shared Linux Home Manager source pins to move together:

```bash
nix run .#update
```

This runs `nix flake update` for flake inputs and then runs the repo-local
source updater for the shared Linux Home Manager assets.

You can pass normal flake-update input names after `--`:

```bash
nix run .#update -- nixpkgs home-manager
```

Useful update modes:

```bash
nix run .#update -- --flake-only
nix run .#update -- --local-only --package linux-home-sources
```

## macOS

The declared Apple Silicon machine exposes `build-switch`, `clean`, `update`,
`build`, and `search-pkgs` apps:

```bash
nix run .#build-switch   # real sudo darwin-rebuild switch
nix run .#clean          # delete generations older than 7 days
nix run .#update
nix --extra-experimental-features 'nix-command flakes' run .#build
nix run .#search-pkgs -- <query>
```

On the first switch, native Darwin build, activation, relogin, rollback, TCC,
and runtime checks remain **NOT VERIFIED**. Build before switching, and if the
activation goes wrong roll back with `sudo darwin-rebuild rollback`.

## NixOS

This repo still includes bootstrap placeholders for Linux host values.
The NixOS host enables Niri and links the shared `~/.config/niri/config.kdl`
through Home Manager. Niri is the only graphical login session.

The managed user is declared by the `mei` aspect. Both Linux and macOS accounts
use Nushell by default, while the other managed shells can be launched directly:

```nu
bash
zsh
fish
```

The current NixOS declarations can be built without activating:

```bash
nix --extra-experimental-features 'nix-command flakes' run .#build
```

Linux exposes `build-switch` and `clean` apps:

```bash
nix run .#build-switch -- --host <host>   # default x86_64-linux
nix run .#clean
```

`build-switch` builds the selected toplevel and then runs
`sudo nixos-rebuild switch`; `clean` deletes system generations older than
7 days. Disabled device/capability enrollment only suppresses
enrollment-specific projection and does not force baseline upstream services
off.

## Existing Linux installs

For an existing Linux machine such as Arch Linux with Niri, or for a WSL distro on Windows, this repo exposes the existing standalone Home Manager surface built for Determinate Nix. WSL does **not** get a separate flake output here; use the same `standalone-linux` / `standalone-linux-aarch64` targets that other non-NixOS Linux machines use.

Install Determinate Nix first using the official installer:

```bash
curl -fsSL https://install.determinate.systems/nix | sh -s -- install
```

If the WSL distro already has upstream Nix, follow Determinate's migration guide first before switching this repo's Home Manager config.

Then switch the standalone home config:

```bash
nix run .#home-switch
```

That defaults to the generic `standalone-linux` Home Manager configuration on `x86_64-linux`. Both standalone targets have the explicit identity `mei` at `/home/mei`; they do not derive identity from the invoking shell. On Windows on ARM, use `nix run .#home-switch -- --target standalone-linux-aarch64` instead.
The wrapper uses a timestamped `hm-backup-<timestamp>` extension by default, so
any pre-existing dotfiles that Home Manager needs to take over are backed up on first switch.

After the first switch, normal updates are:

```bash
home-manager switch --flake .#standalone-linux
# or on Windows on ARM / aarch64-linux:
home-manager switch --flake .#standalone-linux-aarch64
```

To read Home Manager news with this flake-based setup, use:

```bash
nix run .#home-news
```

Standalone identity is part of the Den home entity declaration. To support a different user or home directory, add a distinct typed home entity and output instead of relying on ambient environment overrides.

For the repo-specific WSL notes, including the Determinate-only requirement verified against official docs on Friday, July 17, 2026, see `docs/service-notes/wsl-standalone-home-manager.md`.

## Secrets

This repo keeps only `sops-nix` for Nix-evaluated secret delivery. The
aspect at `modules/aspects/features/sops.nix` injects the 5 coding-agent
API keys (`OPENAI_API_KEY`, `ANTHROPIC_API_KEY`, `GEMINI_API_KEY`,
`OPENROUTER_API_KEY`, `GITHUB_TOKEN`) from `secrets/coding-agents.yaml`
into both Darwin and NixOS hosts.

- The recipient policy is `.sops.yaml` at the repo root.
- Both recipients (`&admin` and `&recovery`) must remain trusted for
  existing sops files to decrypt after rotation.
- No first secret is enrolled. Every declared machine in
  `modules/entities/_machine-authority/model.nix` carries
  `publicTrust.state = "disabled"; secretTrust.state = "disabled";`.

The ignored local `secrets/` directory holds `coding-agents.yaml` (tracked,
sops-encrypted) and operator-local runtime files such as `calibre/`. Those
plaintext files are not ingested by Home Manager or referenced from a Nix
path; they are installed manually per the per-service notes in
`docs/service-notes/`.

## Coding agents

Code agents are installed and wrapped by the repo so provider keys flow through
sops wrappers instead of being typed into each tool:

| Agent | Install | Wrapped as | Notes |
|---|---|---|---|
| `codex` | npm `@openai/codex`, via `installCodingAgents` activation | `codex-wrapped` | |
| `omo` (OMO Native) | npm `omo-ai@beta` (5.0.0-0.beta.7, Senpi engine `@code-yeongyu/senpi@2026.8.12-4`), needs node >= 24, via activation | | the native harness launcher CLI — NOT the same tool as `omo-agent-toolkit`; that one is the opencode-harness management CLI from `oh-my-opencode` |
| `lazycodex` | manual one-time `npx lazycodex-ai install` per machine (TUI installer cannot be automated) | | codex-side omo harness replacing omx in role; verify with `npx lazycodex-ai doctor`; requires codex and `~/.local/bin` on PATH |

- **omx (oh-my-codex) is removed** and is no longer a codex agent.
- `secrets/coding-agents.yaml` (sops) injects provider keys via the
  `codex-wrapped` sops wrapper.
