# Expansion log

Core question: easiest and fastest way on a fresh laptop/PC to install NixOS with https://github.com/Meillaya/nix-config.

Axes:
1. Repo constraints: flake outputs, Disko layout, user/session assumptions.
2. Official/local ISO install: NixOS installer + disko-install.
3. Remote install: nixos-anywhere over SSH to reduce laptop typing/disk-ID pain.
4. Determinate/alternative ISOs: whether they materially simplify install.
5. Recovery/fallback: when accidental GUI install exists or graphical boot fails.

Tier: LIGHT — research/runbook only, no code changes.
Skills: omo:ulw-research for explicit research request; git-master not used because no git operation requested.

## Wave 1
- Repo constraints captured.
- New lead: nixos-anywhere disk override feasibility.

## Wave 2
- Installer options checked from docs and live CLI help.
- Closed lead: nixos-anywhere does not have a direct `--disk` override; use local temp clone edit or repo branch if remote-installing.
- Opened leads: low-RAM/no-space mitigation; disk identification menu.
