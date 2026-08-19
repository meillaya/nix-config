# Wave 1B — Videos, community reports, historical tutorials

Observer: `media_community_tutorials`; 20+ searches, three video transcripts/repositories, Reddit via Photon proxy, current official counter-checks; accessed 2026-07-13.

## Source-by-source findings

- **Q-QPtHrvLB0 (Ioga remote installs):** useful nixos-anywhere/Disko/kexec/VM-test/deploy-rs workflow, but destructive prerequisites, pinning, current networking/Secure Boot/RAM constraints and deploy-rs confirmation semantics need stronger/current upstream framing. Current nix.dev provisioning tutorial supersedes it.
- **CwfKlX3rA6E (No Boilerplate):** good motivation for Git/declarative config/generations/HM/dev shells; overclaims instant reproduction and impossibility of unbootable state, ignoring mutable data, firmware, disks, hardware, collected generations, external state and automation risk.
- **ZuVQds2hncs (WSL starter):** useful evidence that WSL should be a distinct host class; 24.05 workflow is stale relative to current `.wsl` upstream releases and includes mutable/imperative choices.
- **Funloop 2015 Arch/Nix:** valuable historical low-risk migration idea; executable guidance is obsolete (`nix-env`, channels, old single-user/Cabal-era workflow).
- **Reddit Arch migration:** recurring qualitative benefits/risks; contradictory stability opinions, so contextual only.
- **Discourse survey comment:** community outreach context, technically irrelevant.
- **NixOS & Flakes Book:** strong community guide for locked inputs, host modules, SSH preflight and distributed builders; “always rollback,” unpinned tool invocation, root deployment and testing documentation require official counter-balance.
- **tsawyer Btrfs/Disko/impermanence:** useful stable-ID/Disko ideas but invalid two-argument flake syntax, moving inputs, password-hash exposure, whole-disk/host specificity and overbroad persistence make it unsafe copy-paste guidance.
- **Hyprland image thread:** aesthetics only, not installation evidence.
- **Dynamic /r/NixOS feed:** lead generation only, not stable evidence.
- **Dendritic Reddit thread:** ordinary shared/per-host modules are sufficient initially; frameworks help at scale but add abstraction/dependency/maintenance risk.

## Primary/current sources

- https://nix.dev/tutorials/nixos/provisioning-remote-machines.html
- https://github.com/nix-community/nixos-anywhere
- https://github.com/nix-community/disko
- https://github.com/serokell/deploy-rs
- https://nixos.org/manual/nixos/stable/
- https://github.com/nix-community/NixOS-WSL/releases
- https://nixos.org/download/
- https://nix.dev/tutorials/nixos/integration-testing-using-virtual-machines.html

## Claims

- Current nix.dev+nixos-anywhere+Disko is the strongest supported remote provisioning path, with explicit destructive/prerequisite caveats.
- Generations do not prevent all bricking and do not roll back mutable data.
- Ordinary module/host boundaries are sufficient initially; Dendritic is an optional scaling tool.
- Community/video/tutorial sources are secondary and often time-bound; operational claims require upstream confirmation.

## EXPAND
- LEAD: authenticated YouTube pinned comments — WHY: possible errata — ANGLE: only if comment-level proof matters; upstream already supersedes operations.
- LEAD: disposable VM execution of tsawyer Disko/impermanence examples — WHY: source review cannot settle low-level behavior — ANGLE: separate verification if those designs are considered.
- DEAD END: survey comment for technical guidance.
- DEAD END: Hyprland image post for reliable installation.
- DEAD END: dynamic subreddit feed as stable evidence.
