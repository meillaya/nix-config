# nix-config

Personal Nix config for **macOS** (via `nix-darwin`) and **standalone Linux**
machines (via Determinate Nix + Home Manager). NixOS configurations
live in the sibling `~/NixOS-config/` repo.

## Hosts

- `darwinConfigurations.aarch64-darwin` — Apple Silicon Mac
  (`aarch64-darwin`).
- `homeConfigurations.standalone-linux` — generic Linux
  (x86_64) with Determinate Nix.
- `homeConfigurations.standalone-linux-aarch64` — generic Linux
  (aarch64) with Determinate Nix.

The `mei` user account on every managed host is declared by
`modules/aspects/users/mei.nix`.

## macOS

```bash
nix run .#build-switch       # real sudo darwin-rebuild switch
nix run .#build              # build only
nix run .#clean              # delete generations older than 7 days
nix run .#update             # flake inputs
nix run .#search-pkgs -- <query>
nix run .#nh -- os switch --hostname aarch64-darwin
```

On the first switch, native Darwin build, activation, relogin, rollback,
and TCC checks remain **NOT VERIFIED** until the first real switch.
Build before switching, and if the activation goes wrong roll back with
`sudo darwin-rebuild rollback`.

`raycast` is installed as a Spotlight replacement via
`modules/darwin/packages.nix`. After the first switch, enable it as
the default launcher (System Settings → Keyboard → Spotlight, or via
the Raycast UI itself) and install extensions interactively.
Per-machine extension/keymap state lives in
`~/Library/Application Support/com.raycast.macos/` and is not vendored.

## Standalone Linux

Install Determinate Nix first:

```bash
curl -fsSL https://install.determinate.systems/nix | sh -s -- install
```

Then switch the standalone home:

```bash
nix run .#home-switch                              # defaults to standalone-linux on x86_64
nix run .#home-switch -- --target standalone-linux-aarch64
nix run .#nh -- home switch --hostname standalone-linux-aarch64
```

Subsequent updates:

```bash
home-manager switch --flake .#standalone-linux
home-manager switch --flake .#standalone-linux-aarch64
```

To read Home Manager news:

```bash
nix run .#home-news
```

Standalone identity is part of the Den home entity declaration. To
support a different user or home directory, add a distinct typed home
entity and output instead of relying on ambient environment overrides.

See `docs/service-notes/wsl-standalone-home-manager.md` for WSL notes.

## Secrets

Only `sops-nix` is wired. The five coding-agent API keys
(`OPENAI_API_KEY`, `ANTHROPIC_API_KEY`, `GEMINI_API_KEY`,
`OPENROUTER_API_KEY`, `GITHUB_TOKEN`) are evaluated from
`secrets/coding-agents.yaml` for both Darwin and standalone-Linux
hosts. The recipient policy is `.sops.yaml` at the repo root.

The ignored local `secrets/` directory holds `coding-agents.yaml`
(tracked, sops-encrypted) and operator-local runtime files such as
`calibre/`. Those plaintext files are not ingested by Home Manager or
referenced from a Nix path; they are installed manually per the
per-service notes in `docs/service-notes/`.

## Coding agents

`codex` and `omo-ai@beta` are installed by the standalone Home Manager
activation block — the wrappers, install hooks, and other agents
(`kimi`, `hermes`, `zeroclaw`, `pi`, `opencode`, `omo-agent-toolkit`)
are removed. `lazycodex` is installed manually via
`npx lazycodex-ai install`. The shared `codex-wrapped` shim injects
provider keys from the sops file at runtime.

## Tooling flakes

The flake registers the same four extras as `~/NixOS-config/`
(see `flake.nix`): `stylix`, `nix-direnv`, `nh`, `preservation`.
`stylix` and `preservation` are NixOS-only and not wired here
(`preservation` is declared as a flake input for lockfile symmetry;
see the comment in `modules/aspects/platforms/darwin.nix`).
`nix-direnv` ships in `modules/shared/packages.nix`, and `.envrc`
contains `use flake` so the flake's dev shell activates automatically.

`nh` (viperML/nh 4.4.2) is exposed as a flake app:

```bash
nix run .#nh -- os switch --hostname aarch64-darwin
nix run .#nh -- home switch --hostname standalone-linux
```

## Layout

```
flake.nix                     repo entry point (flake-parts + Den)
flake.lock                    locked inputs
lib/nixpkgs.nix               unfree-allowlist policy
modules/
  entities/                   host + machine authority
  aspects/
    features/                 leaf capability aspects (darwin-*, noctalia, sops)
    platforms/                OS-level chains (darwin.nix)
    roles/                    workstation-darwin role
    hardware/                 vendor + capability routing
    storage/                  storage policy (Darwin stub)
    named-hosts/              hostname + identity projection
    hosts/                    host aggregates
    users/mei.nix             user + Home Manager projection
    shared-policy/nixpkgs.nix nixpkgs config overlay
  flake/                      flake-parts wiring (dendritic, checks, packages, apps, etc.)
  darwin/                     Darwin implementation modules
  standalone-linux/           standalone Home Manager config + packages + files
  shared/                     cross-platform package + file surfaces
  linux/                      standalone Linux desktop surface (also used by NixOS)
apps/aarch64-darwin/          Darwin build/switch/clean/update/search-pkgs scripts
pkgs/                         repo-local derivations (omniwm is Darwin-only)
secrets/                      sops-encrypted secrets
tests/                        architecture + config-eval + package-policy tests
docs/                         service notes (Darwin + standalone Linux)
config/                       unfree package exceptions
```

The NixOS tree (`modules/nixos/`, NixOS-specific hardware/storage/aspect
modules, NixOS-named hosts) lives in the sibling `~/NixOS-config/`
repo. Shared modules (`modules/shared/`, `modules/linux/`, the `mei`
user aspect, the `noctalia` and `sops` aspects, the `mei` `codex-wrapped`
shim, and `modules/standalone-linux/config/noctalia/config.toml`)
are duplicated bit-for-bit into both repos so neither depends on the
other — changes that touch a shared file must be applied to both.

## Verification

```bash
nix flake check --all-systems --no-build
bash tests/dendritic-architecture.sh
bash tests/dendritic-boundaries.sh
bash tests/dendritic-apps.sh
nix-instantiate --eval --strict --expr 'import ./tests/dendritic-config-eval.nix {}'
bash tests/package-policy.sh
```
