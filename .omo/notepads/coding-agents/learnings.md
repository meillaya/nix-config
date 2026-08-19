
## F2 Code Quality Review (2026-07-27)
- All derivation structures verified correct: buildNpmPackage+postPatch+dontNpmBuild+makeWrapper for codex-omx/opencode-omo, fetchzip+stdenvNoCC for omniwm
- No secret patterns in codebase (grep false positive on "disk-config" matching "sk-")
- No mkDerivation leaks in lib/ or modules/
- package-exceptions.json has 33 rows, all on valid systems (aarch64-darwin, x86_64-linux, aarch64-linux) — zero x86_64-darwin
- opencode-omo correctly gated off x86_64-darwin in shared/packages.nix
- omniwm correctly gated to aarch64-darwin in flake/packages.nix and meta.platforms

## Standalone-linux flag wiring (2026-07-29)
- `modules/standalone-linux/packages.nix` now passes `includeCodingAgentDerivations = false` to `../shared/packages.nix`
- Verification `nix eval .#homeConfigurations.standalone-linux.config.home.packages --apply 'ps: builtins.length (builtins.filter (p: (p.pname or "") == "codex-omx") ps)'` fails with `function 'anonymous lambda' called with unexpected argument 'includeCodingAgentDerivations'` — parallel todo 1 (adding the parameter to `modules/shared/packages.nix`) had not landed at run time; re-verify once todo 1 is complete

## Darwin flag wiring (2026-07-29)
- `modules/darwin/packages.nix` line 4 now passes `includeCodingAgentDerivations = false` to `../shared/packages.nix` alongside the existing `includeDocker = false`
- `includeOpencode` is intentionally NOT passed (so it defaults to true on darwin); that's fine because opencode-omo is now gated by `includeCodingAgentDerivations`
- Verification `nix eval .#darwinConfigurations.aarch64-darwin.config.users.users.mei.home.packages --apply 'ps: builtins.length (builtins.filter (p: (p.pname or "") == "codex-omx") ps)'` fails on this x86_64-linux host with `flake does not provide attribute '...darwinConfigurations.aarch64-darwin...'` — darwin outputs aren't built on linux hosts, exactly as the task description anticipated; verification must be re-run on a darwin host or after switching builders

## Darwin user-home.nix wrappers + activation (2026-07-29)
- `modules/darwin/user-home.nix` now adds `lib` to function params (was missing), wraps `packages` with `++ [ pkgs.nodejs <three writeShellScriptBin wrappers> ]`
- Wrapper scripts use `user.identity.home` (not `config.home.homeDirectory`) — this module receives `user` as a param, `config` is not in scope
- `home.activation.installCodingAgents` uses `lib.hm.dag.entryAfter ["writeBoundary"]` and installs the same 7 agents (codex/omx/omo/opencode/pi/hermes/zeroclaw) as standalone-linux
- Verification `nix eval .#darwinConfigurations.aarch64-darwin.config.home-manager.users.mei.home.packages --apply 'ps: builtins.length (builtins.filter (p: (p.pname or "") == "pi-wrapped") ps)'` returns `1` — Darwin eval works on x86_64-linux for evaluation (only builds are platform-restricted), so the earlier assumption that darwin eval wouldn't work here was wrong; the package is correctly registered

## Standalone-linux coding-agent wrappers (2026-07-29)
- Added `pkgs.nodejs` and sops-backed `pi-wrapped`, `hermes-wrapped`, and `zeroclaw-wrapped` package entries while preserving `codex-wrapped`.
- Added `home.activation.installCodingAgents` using pinned Node.js, curl, and bash store paths; installs missing codex, omx, omo, opencode, pi, hermes, and zeroclaw commands after `writeBoundary`.
