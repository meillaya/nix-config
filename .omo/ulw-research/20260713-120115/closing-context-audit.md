# Closing repository-context audit

**Audit date:** 2026-07-13  
**Production revision:** `e9f78180748f1feb428ffb20f9d932c5d9918a48`  
**Scope:** read-only review of current tracked files and binding Lore commit
decisions that were not fully represented in the first converged synthesis.

This closing pass was triggered by the final independent context review. It
does not change the 60-entry supplied-source ledger. It adds seven repository-
local observations and makes their constraints explicit in the canonical claim
graph and final report.

## Findings added to the decision model

1. **Emacs is not currently reproducible or offline-ready.**
   `modules/shared/config/emacs/init.el:13-75` uses an HTTP GNU ELPA archive,
   installs packages during startup, and bootstraps the moving Straight
   `develop` branch by downloading and evaluating its installer. A fresh or
   cache-miss startup can therefore depend on mutable network state on both
   Linux and Darwin.
2. **The standalone-install documentation has an unresolved trust boundary.**
   `README.md:117-121` pipes the moving Determinate installer into a shell.
   This conflicts with the report's general rejection of unauthenticated moving
   `curl | sh` bootstrap paths unless a version, digest/signature, review step,
   and offline/verified alternative are supplied.
3. **Standalone Linux is an incremental-adoption contract, not a hidden NixOS
   migration.** Lore commits `e7f9110` and `7c24572` require generic output
   names, backup-safe dotfile takeover, bootstrap without private flake
   credentials, and continued host ownership of gaming/GPU/system integration
   on existing Arch/CachyOS systems.
4. **Darwin is deliberately Homebrew-free.** Lore commit `455aac5` and
   `docs/service-notes/homebrew-free-migration.md` prohibit reintroducing casks
   or `/opt/homebrew` fallbacks without a new explicit migration decision.
5. **Public compatibility interfaces are intentional.** Lore commits `7e2c120`,
   `73338ff`, and `e9f7818` require preservation of the architecture-named
   public NixOS outputs, paired Bash/Nushell installation examples, and a
   Niri-only installed login session even after named host leaves are added.
6. **External-display brightness has a known privilege boundary.** Lore commit
   `6894ba7` and `docs/service-notes/noctalia-ddc-brightness.md` assign I2C
   plumbing declaratively to NixOS while standalone Home Manager uses an
   explicit privileged helper. Acceptance begins with `/dev/i2c-*` and
   `ddcutil detect`; restarting the compositor is not the diagnostic.
7. **Timezone and keyboard layout are host/location policy.**
   `modules/nixos/system.nix:30,89-92` globally fixes `America/New_York` and
   `us`. Those defaults may suit the current user, but they cannot be part of a
   truthful portable machine baseline without per-host/user override.

## Required closure evidence

- Emacs starts from a clean home with the network disabled on native Linux and
  Darwin, with all package sources HTTPS and package revisions content-bound or
  Nix-owned.
- The standalone installer is version/digest/signature-bound or replaced by a
  reviewed/offline route; a cold machine test does not depend on a moving
  script response.
- A non-NixOS adoption rehearsal preserves backups, current desktop data, and
  host-managed gaming/GPU/system packages.
- Darwin evaluation and native activation contain no Homebrew module, cask, or
  `/opt/homebrew` fallback.
- Compatibility tests retain `x86_64-linux`/`aarch64-linux`, validate paired
  Bash/Nushell snippets, and expose only Niri on installed NixOS.
- Physical external-display tests prove I2C permissions and DDC control on each
  claimed host; standalone activation never performs surprise sudo work.
- At least two host/location fixtures select different timezone and keyboard
  policies without editing shared workstation modules.

## Disposition

All seven findings are now represented by observations O135-O141, claims
P1-19-P1-25, intents I14-I20, and the final synthesis. They are implementation
constraints or physical acceptance gates; none upgrades current production
readiness.
